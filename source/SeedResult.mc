import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.Attention;

// Shows the generated mnemonic. The words start hidden behind a reveal gate
// (shoulder-surfing protection) and auto-hide after a timeout. The words are
// never persisted; they are cleared from memory when leaving the view.
class SeedResultView extends WatchUi.View {

    private const REVEAL_TIMEOUT_MS = 60000;
    private const PER_PAGE = 4;

    private var _words as Array<String>?;
    private var _revealed as Boolean = false;
    private var _confirming as Boolean = false;
    private var _page as Number = 0;
    private var _timer as Timer.Timer?;

    function initialize(words as Array<String>) {
        View.initialize();
        _words = words;
    }

    function onShow() as Void {
        // Signal that the seed is ready.
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(50, 300)] as Array<Attention.VibeProfile>);
        }
    }

    function onHide() as Void {
        if (_timer != null) { _timer.stop(); }
    }

    function isRevealed() as Boolean { return _revealed; }

    function reveal() as Void {
        _revealed = true;
        if (_timer == null) { _timer = new Timer.Timer(); }
        _timer.stop();
        _timer.start(method(:onTimeout), REVEAL_TIMEOUT_MS, false);
        WatchUi.requestUpdate();
    }

    function onTimeout() as Void {
        _revealed = false; // hide again; re-tap to reveal
        WatchUi.requestUpdate();
    }

    function nextPage() as Void {
        if (_words != null && _page < totalPages() - 1) {
            _page++;
            WatchUi.requestUpdate();
        }
    }

    function prevPage() as Void {
        if (_page > 0) {
            _page--;
            WatchUi.requestUpdate();
        }
    }

    // Number of pages that show words.
    function wordPages() as Number {
        if (_words == null) { return 0; }
        return (_words.size() + PER_PAGE - 1) / PER_PAGE;
    }

    // Word pages + one trailing action page (Regenerate / Done).
    function totalPages() as Number {
        return wordPages() + 1;
    }

    function isActionPage() as Boolean {
        return _page == wordPages();
    }

    function isConfirming() as Boolean { return _confirming; }

    function startConfirm() as Void {
        _confirming = true;
        WatchUi.requestUpdate();
    }

    // "No": dismiss the confirmation and return to the first seed page.
    function cancelConfirm() as Void {
        _confirming = false;
        _page = 0;
        WatchUi.requestUpdate();
    }

    // Wipe sensitive data when the flow is finished.
    function clear() as Void {
        if (_timer != null) { _timer.stop(); _timer = null; }
        _words = null;
        _revealed = false;
        _confirming = false;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var words = _words;

        if (!_revealed || words == null) {
            dc.drawText(w / 2, (h * 0.36).toNumber(), Graphics.FONT_SMALL, "Seed ready",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(w / 2, (h * 0.54).toNumber(), Graphics.FONT_XTINY, "no peeking eyes!",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            UiHints.draw(dc, {:start => "reveal", :back => "cancel"});
            return;
        }

        // Exit confirmation (shown when BACK is pressed on the action page).
        if (_confirming) {
            dc.drawText(w / 2, (h * 0.42).toNumber(), Graphics.FONT_SMALL, "Clear seed?",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(w / 2, (h * 0.58).toNumber(), Graphics.FONT_XTINY, "wipe from memory",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            UiHints.draw(dc, {:start => "yes, wipe", :back => "no, keep"});
            return;
        }

        // Trailing action page: finished, see the seed again, or add more entropy.
        if (isActionPage()) {
            dc.drawText(w / 2, (h * 0.42).toNumber(), Graphics.FONT_SMALL, "Finished?",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            UiHints.draw(dc, {:start => "yes", :up => "see seed", :down => "+10 throws"});
            return;
        }

        dc.drawText(w / 2, (h * 0.10).toNumber(), Graphics.FONT_XTINY,
            "Write offline  " + (_page + 1) + "/" + wordPages(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var start = _page * PER_PAGE;
        var end = start + PER_PAGE;
        if (end > words.size()) { end = words.size(); }
        var y = h * 0.26;
        var step = (h * 0.50) / PER_PAGE;
        for (var i = start; i < end; i++) {
            dc.drawText(w / 2, y.toNumber(), Graphics.FONT_SMALL,
                (i + 1) + ". " + words[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            y += step;
        }
        // UP/DOWN page through words; past the last word is the "Finished?" page.
        var hints = {:downArrow => true} as Dictionary;
        if (_page > 0) { hints[:upArrow] = true; }
        UiHints.draw(dc, hints);
    }
}

class SeedResultDelegate extends WatchUi.BehaviorDelegate {

    private const ADD_THROWS = 10;

    private var _result as SeedResultView;
    private var _dice as DiceEntryView;

    function initialize(result as SeedResultView, dice as DiceEntryView) {
        BehaviorDelegate.initialize();
        _result = result;
        _dice = dice;
    }

    // START: reveal -> (action page) "yes, finished" asks to clear -> wipe+exit.
    function onSelect() as Boolean {
        if (!_result.isRevealed()) {
            _result.reveal();
        } else if (_result.isConfirming()) {
            finish();                  // "yes, wipe": clear + exit
        } else if (_result.isActionPage()) {
            _result.startConfirm();    // "yes" finished -> ask "Clear seed?"
        }
        // On word pages START does nothing, so the seed can't be lost by a stray press.
        return true;
    }

    // DOWN: page forward; on the action page it adds more throws.
    function onNextPage() as Boolean {
        if (_result.isConfirming()) {
            // ignore
        } else if (_result.isActionPage()) {
            addThrows();
        } else {
            _result.nextPage();
        }
        return true;
    }

    // UP: page back (works from the action page back to the last word page).
    function onPreviousPage() as Boolean {
        if (!_result.isConfirming()) { _result.prevPage(); }
        return true;
    }

    // BACK: cancels before reveal; answers "no" to the confirm; otherwise pages
    // back. After reveal it never exits directly, so the seed can't be dropped
    // by accident - the only way out is the deliberate "yes" -> "yes, wipe".
    function onBack() as Boolean {
        if (!_result.isRevealed()) {
            finish();
        } else if (_result.isConfirming()) {
            _result.cancelConfirm();   // "no": back to the seed
        } else {
            _result.prevPage();
        }
        return true;
    }

    // MENU (on devices that have it): add more entropy.
    function onMenu() as Boolean {
        if (_result.isRevealed() && !_result.isConfirming()) { addThrows(); }
        return true;
    }

    // Keep the accumulated rolls, return to the dice view and require ADD_THROWS
    // more rolls; reaching the new target re-mixes a fresh seed (see DiceEntry).
    function addThrows() as Void {
        _result.clear();
        WatchUi.popView(WatchUi.SLIDE_DOWN); // Result -> Dice (rolls preserved)
        _dice.extend(ADD_THROWS);
    }

    // Wipe and return to the main menu (stack: Main->Strength->Dice->Result).
    function finish() as Void {
        // Distinct "destroyed" feedback: two strong pulses (reveal is one soft buzz).
        if (Attention has :vibrate) {
            Attention.vibrate([
                new Attention.VibeProfile(100, 150),
                new Attention.VibeProfile(0, 90),
                new Attention.VibeProfile(100, 150)
            ] as Array<Attention.VibeProfile>);
        }
        _result.clear();
        WatchUi.popView(WatchUi.SLIDE_DOWN); // Result -> Dice
        WatchUi.popView(WatchUi.SLIDE_DOWN); // Dice -> Strength
        WatchUi.popView(WatchUi.SLIDE_DOWN); // Strength -> Main
    }
}
