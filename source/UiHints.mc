import Toybox.Graphics;
import Toybox.Lang;

// Device-agnostic action hints. Draws a compact text legend near the bottom of
// the screen with BACK / UP/DN / START labels (when provided) plus optional
// ▲/▼ scroll indicators. This works on every supported form factor:
// - Classic 5-button round watches (fr955, fenix, epix...)
// - 3-button + touch watches (venu3, vivoactive...)
// - Rectangular bike/golf computers (edge*, approach*)
// - Small screens (fr165, instinct e, descent...)
// No assumptions about button physical positions or round bezel angles.
//
// hints Dictionary keys (all optional):
//   :start, :back, :up, :down  -> String label (e.g. "add", "undo", "+10 throws")
//   :upArrow, :downArrow        -> true to draw ▲ / ▼ scroll triangles
module UiHints {

    function draw(dc as Graphics.Dc, hints as Dictionary) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var font = Graphics.FONT_XTINY;
        var gray = Graphics.COLOR_LT_GRAY;

        dc.setColor(gray, Graphics.COLOR_TRANSPARENT);

        var hintY = h - (h * 0.09).toNumber();
        if (hintY < 12) { hintY = 12; }

        var leftX = (w * 0.10).toNumber();
        var centerX = w / 2;
        var rightX = (w * 0.90).toNumber();

        var hasBack = hints.hasKey(:back);
        var hasUp = hints.hasKey(:up);
        var hasDown = hints.hasKey(:down);
        var hasStart = hints.hasKey(:start);
        var hasUpArrow = hints.hasKey(:upArrow) && hints[:upArrow];
        var hasDownArrow = hints.hasKey(:downArrow) && hints[:downArrow];

        // Action labels in three zones (left / center / right) to stay readable
        // even when screen is narrow or very short.
        if (hasBack || hasUp || hasDown || hasStart) {
            if (hasBack) {
                var s = hints[:back] as String;
                dc.drawText(leftX, hintY, font, s + " BACK",
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
            if (hasStart) {
                var s = hints[:start] as String;
                dc.drawText(rightX, hintY, font, "START " + s,
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
            if (hasUp || hasDown) {
                var label = "";
                if (hasUp) { label += (hints[:up] as String) + " "; }
                if (hasDown) { label += (hints[:down] as String); }
                if (label.length() > 0) {
                    label += " UP/DN";
                    dc.drawText(centerX, hintY, font, label,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                }
            }
        }

        // Scroll arrows (used on word-list pages and info). Drawn above the
        // text line so they don't collide with labels.
        if (hasUpArrow || hasDownArrow) {
            var arrSize = (w * 0.028).toNumber();
            if (arrSize < 4) { arrSize = 4; }
            var arrY = hintY - (h * 0.055).toNumber();
            if (hasUpArrow) {
                var pts = [[centerX, arrY - arrSize],
                           [centerX - arrSize, arrY + arrSize],
                           [centerX + arrSize, arrY + arrSize]];
                dc.fillPolygon(pts);
            }
            if (hasDownArrow) {
                var dY = arrY + (hasUpArrow ? arrSize * 2 + 3 : 0);
                var pts = [[centerX, dY + arrSize],
                           [centerX - arrSize, dY - arrSize],
                           [centerX + arrSize, dY - arrSize]];
                dc.fillPolygon(pts);
            }
        }
    }
}
