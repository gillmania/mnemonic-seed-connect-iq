import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;

// Collects physical d6 rolls. A 3×2 grid of dice faces is shown; the selected
// die (highlighted white) is committed with START. UP/DOWN cycle the selection.
// On touch screens the user can tap a die to commit it directly.
// BACK undoes the last roll; when no rolls exist it returns false (natural pop).
class DiceEntryView extends WatchUi.View {

    // Set > 0 only to shorten dice entry while testing the UI in the simulator;
    // 0 uses the real Bip39.requiredRolls count (50 for 128-bit, 100 for 256-bit).
    private const DEBUG_ROLL_OVERRIDE = 0;

    private var _strengthBits as Number;
    private var _needed as Number;
    private var _rolls as String = "";
    private var _selectedValue as Number = 1;

    // Grid geometry computed each frame and cached for hit-testing.
    private var _dieSize as Number = 0;
    private var _gap as Number = 0;
    private var _gridX as Number = 0;
    private var _gridY as Number = 0;

    function initialize(strengthBits as Number) {
        View.initialize();
        _strengthBits = strengthBits;
        _needed = (DEBUG_ROLL_OVERRIDE > 0) ? DEBUG_ROLL_OVERRIDE : Bip39.requiredRolls(strengthBits);
    }

    function getStrength() as Number { return _strengthBits; }
    function getRolls() as String { return _rolls; }
    function getCount() as Number { return _rolls.length(); }
    function isComplete() as Boolean { return _rolls.length() >= _needed; }

    function reset() as Void {
        _rolls = "";
        _selectedValue = 1;
        WatchUi.requestUpdate();
    }

    function incSelected() as Void {
        _selectedValue = (_selectedValue % 6) + 1;
        WatchUi.requestUpdate();
    }

    function decSelected() as Void {
        _selectedValue = (_selectedValue <= 1) ? 6 : _selectedValue - 1;
        WatchUi.requestUpdate();
    }

    function commit() as Void {
        if (_rolls.length() < _needed) {
            _rolls += _selectedValue.toString();
            WatchUi.requestUpdate();
        }
    }

    // Select and immediately commit a specific value (used by touch handler).
    function commitValue(value as Number) as Void {
        _selectedValue = value;
        if (_rolls.length() < _needed) {
            _rolls += value.toString();
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

    // Returns the die value (1-6) for a tap position, snapping to the nearest
    // die cell so that taps in the gaps between dice still register correctly.
    function dieValueAt(tapX as Number, tapY as Number) as Number {
        if (_dieSize == 0) { return 0; }
        var cellW = _dieSize + _gap;
        var cellH = _dieSize + _gap;
        var gridW = 3 * cellW - _gap;
        var gridH = 2 * cellH - _gap;
        var margin = _dieSize / 2; // generous hit tolerance outside the grid
        var relX = tapX - _gridX;
        var relY = tapY - _gridY;
        if (relX < -margin || relX > gridW + margin) { return 0; }
        if (relY < -margin || relY > gridH + margin) { return 0; }
        var col = relX / cellW;
        var row = relY / cellH;
        if (col < 0) { col = 0; } if (col > 2) { col = 2; }
        if (row < 0) { row = 0; } if (row > 1) { row = 1; }
        return row * 3 + col + 1;
    }

    private function drawDots(dc as Graphics.Dc, cx as Number, cy as Number, spread as Number, dotR as Number, value as Number) as Void {
        if (value == 1) {
            dc.fillCircle(cx, cy, dotR);
        } else if (value == 2) {
            dc.fillCircle(cx - spread, cy - spread, dotR);
            dc.fillCircle(cx + spread, cy + spread, dotR);
        } else if (value == 3) {
            dc.fillCircle(cx - spread, cy - spread, dotR);
            dc.fillCircle(cx, cy, dotR);
            dc.fillCircle(cx + spread, cy + spread, dotR);
        } else if (value == 4) {
            dc.fillCircle(cx - spread, cy - spread, dotR);
            dc.fillCircle(cx + spread, cy - spread, dotR);
            dc.fillCircle(cx - spread, cy + spread, dotR);
            dc.fillCircle(cx + spread, cy + spread, dotR);
        } else if (value == 5) {
            dc.fillCircle(cx - spread, cy - spread, dotR);
            dc.fillCircle(cx + spread, cy - spread, dotR);
            dc.fillCircle(cx, cy, dotR);
            dc.fillCircle(cx - spread, cy + spread, dotR);
            dc.fillCircle(cx + spread, cy + spread, dotR);
        } else {
            dc.fillCircle(cx - spread, cy - spread, dotR);
            dc.fillCircle(cx + spread, cy - spread, dotR);
            dc.fillCircle(cx - spread, cy, dotR);
            dc.fillCircle(cx + spread, cy, dotR);
            dc.fillCircle(cx - spread, cy + spread, dotR);
            dc.fillCircle(cx + spread, cy + spread, dotR);
        }
    }

    private function drawDie(dc as Graphics.Dc, x as Number, y as Number, value as Number, selected as Boolean) as Void {
        var s = _dieSize;
        var cornerR = (s * 0.16).toNumber();
        if (cornerR < 3) { cornerR = 3; }

        if (selected) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        }
        dc.fillRoundedRectangle(x, y, s, s, cornerR);

        var dotR = (s * 0.10).toNumber();
        if (dotR < 2) { dotR = 2; }
        var spread = (s * 0.28).toNumber();
        var cx = x + s / 2;
        var cy = y + s / 2;

        if (selected) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        drawDots(dc, cx, cy, spread, dotR, value);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();

        // Smaller dice so the grid breathes and the bottom bar fits.
        _dieSize = (w * 0.23).toNumber();
        _gap = (w * 0.04).toNumber();
        if (_gap < 4) { _gap = 4; }
        var gridW = 3 * _dieSize + 2 * _gap;
        var gridH = 2 * _dieSize + _gap;
        _gridX = (w - gridW) / 2;
        // On round screens the top corners of the grid get clipped if gridY is too small.
        // Safe minimum: for a grid of width gridW centred in a circle of radius w/2, the
        // top corners must sit inside the circle → gridY > w/2 - sqrt((w/2)²-(gridW/2)²).
        var r = w / 2;
        var halfGridW = gridW / 2;
        var safeMinY = (r - Math.sqrt((r * r - halfGridW * halfGridW).toFloat())).toNumber() + 4;
        var centredY = ((h * 0.78).toNumber() - gridH) / 2;
        _gridY = (centredY > safeMinY) ? centredY : safeMinY;

        // 3×2 dice grid.
        for (var row = 0; row < 2; row++) {
            for (var col = 0; col < 3; col++) {
                var value = row * 3 + col + 1;
                var dx = _gridX + col * (_dieSize + _gap);
                var dy = _gridY + row * (_dieSize + _gap);
                drawDie(dc, dx, dy, value, value == _selectedValue);
            }
        }

        // Progress bar — wider and taller so it's visible even at 1 roll.
        var barW = (w * 0.72).toNumber();
        var barX = (w - barW) / 2;
        var barY = (h * 0.78).toNumber();
        var barH = 10;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(barX, barY, barW, barH, barH / 2);
        var frac = _rolls.length().toFloat() / _needed;
        if (frac > 1.0) { frac = 1.0; }
        if (frac > 0.0) {
            var filledW = (barW * frac).toNumber();
            if (filledW < barH) { filledW = barH; } // at least round end cap visible
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barX, barY, filledW, barH, barH / 2);
        }

        // Roll counter below the bar.
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 0.89).toNumber(), Graphics.FONT_XTINY,
            _rolls.length() + " / " + _needed,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class DiceEntryDelegate extends WatchUi.BehaviorDelegate {

    private var _view as DiceEntryView;

    function initialize(view as DiceEntryView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onPreviousPage() as Boolean {
        _view.incSelected();
        return true;
    }

    function onNextPage() as Boolean {
        _view.decSelected();
        return true;
    }

    function onSelect() as Boolean {
        _view.commit();
        if (_view.isComplete()) { finish(); }
        return true;
    }

    function onBack() as Boolean {
        if (_view.getCount() > 0) {
            _view.undo();
            return true;
        }
        return false; // nothing entered yet → let default pop the view
    }

    // MENU (long BACK / LIGHT on most watches): exit immediately without undoing.
    function onMenu() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        var value = _view.dieValueAt(coords[0], coords[1]);
        if (value > 0) {
            _view.commitValue(value);
            if (_view.isComplete()) { finish(); }
            return true;
        }
        return false;
    }

    function resetSelf() as Void {
        _view.reset();
    }

    function finish() as Void {
        var entropy = Bip39.mixEntropy(_view.getRolls(), _view.getStrength());
        var words = Bip39.indicesToWords(Bip39.entropyToIndices(entropy));
        var resultView = new SeedResultView(words);
        WatchUi.pushView(resultView, new SeedResultDelegate(resultView, method(:resetSelf)), WatchUi.SLIDE_UP);
    }
}
