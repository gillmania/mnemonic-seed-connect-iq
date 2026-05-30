import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Collects physical d6 rolls from the user. The candidate value (1-6) is changed
// with UP/DOWN (page buttons / swipes) and committed with SELECT (start / tap).
// When enough rolls are collected, the rolls string is handed to Bip39.mixEntropy.
class DiceEntryView extends WatchUi.View {

    // Set > 0 only to shorten dice entry while testing the UI in the simulator;
    // 0 uses the real Bip39.requiredRolls count (50 for 128-bit, 100 for 256-bit).
    private const DEBUG_ROLL_OVERRIDE = 0;

    private var _strengthBits as Number;
    private var _needed as Number;
    private var _rolls as String = "";
    private var _candidate as Number = 1;

    function initialize(strengthBits as Number) {
        View.initialize();
        _strengthBits = strengthBits;
        _needed = (DEBUG_ROLL_OVERRIDE > 0) ? DEBUG_ROLL_OVERRIDE : Bip39.requiredRolls(strengthBits);
    }

    function getStrength() as Number { return _strengthBits; }
    function getRolls() as String { return _rolls; }
    function getCount() as Number { return _rolls.length(); }
    function isComplete() as Boolean { return _rolls.length() >= _needed; }

    function incCandidate() as Void {
        _candidate = (_candidate % 6) + 1;
        WatchUi.requestUpdate();
    }

    function decCandidate() as Void {
        _candidate = (_candidate <= 1) ? 6 : _candidate - 1;
        WatchUi.requestUpdate();
    }

    function commit() as Void {
        if (_rolls.length() < _needed) {
            _rolls += _candidate.toString();
            WatchUi.requestUpdate();
        }
    }

    function undo() as Void {
        var n = _rolls.length();
        if (n > 0) {
            _rolls = _rolls.substring(0, n - 1);
            WatchUi.requestUpdate();
        }
    }

    // Raise the target so the user can append more rolls ("add throws"); the
    // longer roll string is then re-mixed into a fresh, independent seed.
    function extend(additional as Number) as Void {
        _needed += additional;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.drawText(w / 2, (h * 0.16).toNumber(), Graphics.FONT_SMALL,
            "Roll " + _rolls.length() + " / " + _needed,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.drawText(w / 2, (h * 0.42).toNumber(), Graphics.FONT_NUMBER_MEDIUM,
            _candidate.toString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // progress bar
        var barW = (w * 0.6).toNumber();
        var barX = (w - barW) / 2;
        var barY = (h * 0.74).toNumber();
        var barH = 8;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(barX, barY, barW, barH);
        var frac = _rolls.length().toFloat() / _needed;
        if (frac > 1.0) { frac = 1.0; }
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(barX, barY, (barW * frac).toNumber(), barH);

        // button labels next to the physical buttons
        var back = (_rolls.length() > 0) ? "undo" : "back";
        UiHints.draw(dc, {:up => "+1", :down => "-1", :start => "add", :back => back});
    }
}

class DiceEntryDelegate extends WatchUi.BehaviorDelegate {

    private var _view as DiceEntryView;

    function initialize(view as DiceEntryView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // UP (onPreviousPage) increases the value, DOWN (onNextPage) decreases it.
    function onPreviousPage() as Boolean {
        _view.incCandidate();
        return true;
    }

    function onNextPage() as Boolean {
        _view.decCandidate();
        return true;
    }

    function onSelect() as Boolean {
        _view.commit();
        if (_view.isComplete()) {
            finish();
        }
        return true;
    }

    function onBack() as Boolean {
        if (_view.getCount() > 0) {
            _view.undo();
            return true;
        }
        return false; // nothing entered yet -> let default pop the view
    }

    // Build the seed from the collected rolls and show the result. The entropy
    // ByteArray stays a local and is dropped on return; no persistence/logging.
    function finish() as Void {
        var strengthBits = _view.getStrength();
        var entropy = Bip39.mixEntropy(_view.getRolls(), strengthBits);
        var words = Bip39.indicesToWords(Bip39.entropyToIndices(entropy));

        var resultView = new SeedResultView(words);
        WatchUi.pushView(resultView, new SeedResultDelegate(resultView, _view), WatchUi.SLIDE_UP);
    }
}
