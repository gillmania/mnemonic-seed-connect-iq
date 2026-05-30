import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

// Draws short action labels at each physical button's position along the round
// bezel, so the hints follow the watch's circle and sit next to the button that
// triggers them. Angles match the fr955 / 5-button Forerunner layout:
// START/STOP upper-right, BACK lower-right, UP mid-left, DOWN lower-left
// (LIGHT, upper-left, is reserved by the system). Text is kept upright (readable
// on small screens) and inset from the rim so it is never clipped on round,
// square or touch displays.
//
// hints Dictionary keys (all optional):
//   :start, :back, :up, :down  -> String label
//   :upArrow, :downArrow        -> true to draw a scroll triangle at UP/DOWN
module UiHints {

    // Degrees counter-clockwise from the 3 o'clock position.
    const A_START = 42;
    const A_BACK  = -42;
    const A_UP    = 178;
    const A_DOWN  = 216;

    function draw(dc as Graphics.Dc, hints as Dictionary) as Void {
        var cx = dc.getWidth() / 2.0;
        var cy = dc.getHeight() / 2.0;
        var r = (cx < cy ? cx : cy) * 0.86;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);

        if (hints.hasKey(:start)) { label(dc, cx, cy, r, A_START, hints[:start] as String); }
        if (hints.hasKey(:back))  { label(dc, cx, cy, r, A_BACK,  hints[:back] as String); }
        if (hints.hasKey(:up))    { label(dc, cx, cy, r, A_UP,    hints[:up] as String); }
        if (hints.hasKey(:down))  { label(dc, cx, cy, r, A_DOWN,  hints[:down] as String); }

        var s = (dc.getWidth() * 0.035).toNumber();
        if (s < 5) { s = 5; }
        if (hints.hasKey(:upArrow) && hints[:upArrow]) {
            triangleAt(dc, cx, cy, r, A_UP, s, true);
        }
        if (hints.hasKey(:downArrow) && hints[:downArrow]) {
            triangleAt(dc, cx, cy, r, A_DOWN, s, false);
        }
    }

    function pointAt(cx as Float, cy as Float, r as Float, angleDeg as Number) as [Float, Float] {
        var rad = angleDeg * Math.PI / 180.0;
        return [cx + r * Math.cos(rad), cy - r * Math.sin(rad)];
    }

    function label(dc as Graphics.Dc, cx as Float, cy as Float, r as Float, angleDeg as Number, text as String) as Void {
        var p = pointAt(cx, cy, r, angleDeg);
        // Justify the text inward (away from the rim) based on which side it's on.
        var justify = (p[0] >= cx) ? Graphics.TEXT_JUSTIFY_RIGHT : Graphics.TEXT_JUSTIFY_LEFT;
        dc.drawText(p[0].toNumber(), p[1].toNumber(), Graphics.FONT_XTINY, text,
            justify | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function triangleAt(dc as Graphics.Dc, cx as Float, cy as Float, r as Float, angleDeg as Number, s as Number, up as Boolean) as Void {
        var p = pointAt(cx, cy, r, angleDeg);
        var x = p[0].toNumber();
        var y = p[1].toNumber();
        var pts;
        if (up) {
            pts = [[x, y - s], [x - s, y + s], [x + s, y + s]];
        } else {
            pts = [[x, y + s], [x - s, y - s], [x + s, y - s]];
        }
        dc.fillPolygon(pts);
    }
}
