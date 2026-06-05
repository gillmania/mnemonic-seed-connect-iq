import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.Timer;
import Toybox.Cryptography;
import Toybox.Math;

// Collects entropy from the accelerometer while the user shakes/tilts the watch.
// A ball rolls around on screen driven by the live X/Y tilt, so the user can see
// the raw sensor data changing — building trust that real motion is captured.
// After SAMPLES_NEEDED readings the digest is mixed with randomBytes().
class MotionEntryView extends WatchUi.View {

    private const SAMPLES_NEEDED = 60;
    private const INTERVAL_MS = 80;

    private var _strengthBits as Number;
    private var _sampleCount as Number = 0;
    private var _hash as Cryptography.Hash?;
    private var _timer as Timer.Timer?;
    private var _ballX as Float = 0.0;
    private var _ballY as Float = 0.0;
    private var _accelX as Number = 0;
    private var _accelY as Number = 0;
    private var _hasSensor as Boolean = false;
    private var _onComplete as Method?;

    function initialize(strengthBits as Number) {
        View.initialize();
        _strengthBits = strengthBits;
    }

    function getStrength() as Number { return _strengthBits; }
    function isComplete() as Boolean { return _sampleCount >= SAMPLES_NEEDED; }

    function setOnComplete(callback as Method) as Void {
        _onComplete = callback;
    }

    function getDigest() as ByteArray {
        return (_hash as Cryptography.Hash).digest();
    }

    function onShow() as Void {
        _sampleCount = 0;
        _ballX = 0.0;
        _ballY = 0.0;
        _hash = new Cryptography.Hash({:algorithm => Cryptography.HASH_SHA256});
        if (_timer != null) { _timer.stop(); }
        _timer = new Timer.Timer();
        _timer.start(method(:onSample), INTERVAL_MS, true);
    }

    function onHide() as Void {
        if (_timer != null) { _timer.stop(); _timer = null; }
    }

    function onSample() as Void {
        if (isComplete()) { return; }

        var bytes = new [6]b;
        var info = Sensor.getInfo();
        if (info has :accel && info.accel != null) {
            var accel = info.accel as Array<Number>;
            _accelX = accel[0];
            _accelY = accel[1];
            var z  = accel[2];
            _hasSensor = true;

            bytes[0] = _accelX & 0xFF;
            bytes[1] = (_accelX >> 8) & 0xFF;
            bytes[2] = _accelY & 0xFF;
            bytes[3] = (_accelY >> 8) & 0xFF;
            bytes[4] = z & 0xFF;
            bytes[5] = (z >> 8) & 0xFF;

            // Ball position = X/Y gravity component (tilt = gravity on those axes).
            _ballX = (_accelX * 0.04).toFloat();
            _ballY = (-_accelY * 0.04).toFloat();
        } else {
            // Simulator / sensor not ready: fall back to device RNG.
            var rand = Cryptography.randomBytes(6);
            for (var i = 0; i < 6; i++) { bytes[i] = rand[i]; }
            _hasSensor = false;
            // Random walk so the ball moves visibly in the simulator.
            _ballX += ((rand[0] & 0xFF) - 127).toFloat() * 0.4;
            _ballY += ((rand[1] & 0xFF) - 127).toFloat() * 0.4;
        }

        (_hash as Cryptography.Hash).update(bytes);
        _sampleCount++;
        WatchUi.requestUpdate();

        if (isComplete() && _onComplete != null) {
            (_onComplete as Method).invoke();
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = (h * 0.50).toNumber();
        var playR = (w * 0.28).toNumber();
        var ballR = (w * 0.05).toNumber();
        if (ballR < 5) { ballR = 5; }

        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.12).toNumber(), Graphics.FONT_SMALL, "Shake watch",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Raw accel values — the user can see them change in real time
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var valText = _hasSensor
            ? "x:" + _accelX + "  y:" + _accelY
            : "tilt to see values";
        dc.drawText(cx, (h * 0.24).toNumber(), Graphics.FONT_XTINY, valText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Play area circle
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, playR);

        // Ball: clamp to stay inside the play area
        var bx = _ballX;
        var by = _ballY;
        var distSq = bx * bx + by * by;
        var maxR = (playR - ballR).toFloat();
        if (distSq > maxR * maxR && distSq > 0.0) {
            var dist = Math.sqrt(distSq).toFloat();
            bx = bx * maxR / dist;
            by = by * maxR / dist;
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx + bx.toNumber(), cy + by.toNumber(), ballR);

        // Progress counter
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.78).toNumber(), Graphics.FONT_XTINY,
            _sampleCount + " / " + SAMPLES_NEEDED,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Progress bar (green)
        var barW = (w * 0.55).toNumber();
        var barX = (w - barW) / 2;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(barX, (h * 0.84).toNumber(), barW, 8);
        var frac = _sampleCount.toFloat() / SAMPLES_NEEDED;
        if (frac > 1.0) { frac = 1.0; }
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(barX, (h * 0.84).toNumber(), (barW * frac).toNumber(), 8);

    }
}

class MotionEntryDelegate extends WatchUi.BehaviorDelegate {

    private var _view as MotionEntryView;

    function initialize(view as MotionEntryView) {
        BehaviorDelegate.initialize();
        _view = view;
        view.setOnComplete(method(:finish));
    }

    function onBack() as Boolean {
        return false; // default pop = cancel
    }

    function resetSelf() as Void {
        // onShow() resets all collection state when this view returns to front.
    }

    function finish() as Void {
        var entropy = Bip39.mixEntropyRaw(_view.getDigest(), _view.getStrength());
        var words = Bip39.indicesToWords(Bip39.entropyToIndices(entropy));
        var resultView = new SeedResultView(words);
        WatchUi.pushView(resultView, new SeedResultDelegate(resultView, method(:resetSelf)), WatchUi.SLIDE_UP);
    }
}
