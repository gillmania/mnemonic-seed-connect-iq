import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.Attention;

// Shows the generated mnemonic. Navigation uses three states:
//   STATE_MENU    — "Show seed" / "Generate again" selection (initial state)
//   STATE_WORDS   — paged word display with reveal mechanic; BACK returns to menu
//   STATE_CONFIRM — "Clear seed?" confirmation; only reachable via BACK from menu
// The words are never persisted; clear() wipes them when leaving.
class SeedResultView extends WatchUi.View {

    private const REVEAL_TIMEOUT_MS = 60000;
    private const PER_PAGE = 4;

    private const STATE_MENU    = 0;
    private const STATE_WORDS   = 1;
    private const STATE_CONFIRM = 2;

    private var _words as Array<String>?;
    private var _state as Number = STATE_MENU;
    private var _menuIndex as Number = 0;   // 0 = Show seed, 1 = Generate again
    private var _page as Number = 0;
    private var _revealed as Boolean = false;
    private var _timer as Timer.Timer?;

    function initialize(words as Array<String>) {
        View.initialize();
        _words = words;
    }

    function onShow() as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(50, 300)] as Array<Attention.VibeProfile>);
        }
    }

    function onHide() as Void {
        if (_timer != null) { _timer.stop(); }
    }

    // --- state queries ---

    function isMenu() as Boolean    { return _state == STATE_MENU; }
    function isWords() as Boolean   { return _state == STATE_WORDS; }
    function isConfirm() as Boolean { return _state == STATE_CONFIRM; }
    function isRevealed() as Boolean { return _revealed; }
    function getMenuIndex() as Number { return _menuIndex; }

    // --- state transitions ---

    function cycleMenu(dir as Number) as Void {
        _menuIndex = (_menuIndex + dir + 2) % 2;
        WatchUi.requestUpdate();
    }

    function gotoWords() as Void {
        _state = STATE_WORDS;
        _page = 0;
        _revealed = false;
        WatchUi.requestUpdate();
    }

    function gotoMenu() as Void {
        _state = STATE_MENU;
        WatchUi.requestUpdate();
    }

    function startConfirm() as Void {
        _state = STATE_CONFIRM;
        WatchUi.requestUpdate();
    }

    function cancelConfirm() as Void {
        _state = STATE_MENU;
        WatchUi.requestUpdate();
    }

    function reveal() as Void {
        _revealed = true;
        if (_timer == null) { _timer = new Timer.Timer(); }
        _timer.stop();
        _timer.start(method(:onTimeout), REVEAL_TIMEOUT_MS, false);
        WatchUi.requestUpdate();
    }

    function onTimeout() as Void {
        _revealed = false;
        WatchUi.requestUpdate();
    }

    function nextPage() as Void {
        if (_words != null && _page < wordPages() - 1) {
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

    function wordPages() as Number {
        if (_words == null) { return 0; }
        return (_words.size() + PER_PAGE - 1) / PER_PAGE;
    }

    function clear() as Void {
        if (_timer != null) { _timer.stop(); _timer = null; }
        _words = null;
        _state = STATE_MENU;
        _revealed = false;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();

        if (_state == STATE_CONFIRM) {
            drawConfirm(dc, w, h);
            return;
        }

        if (_state == STATE_MENU) {
            drawMenu(dc, w, h);
            return;
        }

        // STATE_WORDS
        drawWords(dc, w, h);
    }

    private function drawConfirm(dc as Graphics.Dc, w as Number, h as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 0.38).toNumber(), Graphics.FONT_SMALL, "Clear seed?",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 0.52).toNumber(), Graphics.FONT_XTINY, "wipe from memory",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w / 2, (h * 0.70).toNumber(), Graphics.FONT_XTINY, "START=yes   BACK=no",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawMenu(dc as Graphics.Dc, w as Number, h as Number) as Void {
        var cx = w / 2;
        var item0Y = (h * 0.38).toNumber();
        var item1Y = (h * 0.62).toNumber();
        var fontH = dc.getFontHeight(Graphics.FONT_SMALL);
        var boxW = (w * 0.68).toNumber();
        var boxH = fontH + (h * 0.06).toNumber();
        var boxR = (boxH * 0.30).toNumber();

        // Draw selection border around active item.
        var selY = (_menuIndex == 0) ? item0Y : item1Y;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(cx - boxW / 2, selY - boxH / 2, boxW, boxH, boxR);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, item0Y, Graphics.FONT_SMALL, "Show seed",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, item1Y, Graphics.FONT_SMALL, "Generate again",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawWords(dc as Graphics.Dc, w as Number, h as Number) as Void {
        var words = _words;
        if (!_revealed || words == null) {
            dc.drawText(w / 2, (h * 0.38).toNumber(), Graphics.FONT_SMALL, "Seed ready",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, (h * 0.54).toNumber(), Graphics.FONT_XTINY, "press START to reveal",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 0.10).toNumber(), Graphics.FONT_XTINY,
            "Write offline  " + (_page + 1) + "/" + wordPages(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var start = _page * PER_PAGE;
        var end = start + PER_PAGE;
        if (end > words.size()) { end = words.size(); }
        var y = h * 0.26;
        var step = (h * 0.50) / PER_PAGE;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = start; i < end; i++) {
            dc.drawText(w / 2, y.toNumber(), Graphics.FONT_SMALL,
                (i + 1) + ". " + words[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            y += step;
        }

        // Scroll arrows.
        var s = (w * 0.035).toNumber();
        if (s < 5) { s = 5; }
        var cx = w / 2;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        if (_page > 0) {
            var ay = (h * 0.04).toNumber();
            dc.fillPolygon([[cx, ay - s], [cx - s, ay + s], [cx + s, ay + s]]);
        }
        if (_page < wordPages() - 1) {
            var ay = (h * 0.96).toNumber();
            dc.fillPolygon([[cx, ay + s], [cx - s, ay - s], [cx + s, ay - s]]);
        }
    }
}

class SeedResultDelegate extends WatchUi.BehaviorDelegate {

    private var _result as SeedResultView;
    private var _resetEntry as Method?;

    function initialize(result as SeedResultView, resetEntry as Method?) {
        BehaviorDelegate.initialize();
        _result = result;
        _resetEntry = resetEntry;
    }

    function onSelect() as Boolean {
        if (_result.isConfirm()) {
            finish();
        } else if (_result.isMenu()) {
            if (_result.getMenuIndex() == 0) {
                _result.gotoWords();
            } else {
                generateAgain();
            }
        } else { // STATE_WORDS
            if (!_result.isRevealed()) { _result.reveal(); }
            // Deliberate no-op if already revealed: prevents accidental state change
            // while the user is reading.
        }
        return true;
    }

    function onNextPage() as Boolean {
        if (_result.isMenu()) {
            _result.cycleMenu(1);
        } else if (_result.isWords()) {
            _result.nextPage();
        }
        return true;
    }

    function onPreviousPage() as Boolean {
        if (_result.isMenu()) {
            _result.cycleMenu(-1);
        } else if (_result.isWords()) {
            _result.prevPage();
        }
        return true;
    }

    // BACK: confirm → cancel back to menu; words → back to menu; menu → ask to clear.
    function onBack() as Boolean {
        if (_result.isConfirm()) {
            _result.cancelConfirm();
        } else if (_result.isWords()) {
            _result.gotoMenu();
        } else { // STATE_MENU
            _result.startConfirm();
        }
        return true;
    }

    function generateAgain() as Void {
        _result.clear();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        if (_resetEntry != null) {
            (_resetEntry as Method).invoke();
        }
    }

    // Wipe and return to the main menu (stack: Main→Strength→Method→Entry→Result).
    function finish() as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([
                new Attention.VibeProfile(100, 150),
                new Attention.VibeProfile(0, 90),
                new Attention.VibeProfile(100, 150)
            ] as Array<Attention.VibeProfile>);
        }
        _result.clear();
        WatchUi.popView(WatchUi.SLIDE_DOWN); // Result → Entry
        WatchUi.popView(WatchUi.SLIDE_DOWN); // Entry → Method
        WatchUi.popView(WatchUi.SLIDE_DOWN); // Method → Strength
        WatchUi.popView(WatchUi.SLIDE_DOWN); // Strength → Main
    }
}
