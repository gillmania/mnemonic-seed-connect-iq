import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.Timer;
import Toybox.Cryptography;
import Toybox.Math;

// Collects entropy from the accelerometer while the user shakes the watch.
// A ball rolls and bounces around on screen driven by live motion so the user
// can see real sensor data being captured — building trust.
//
// Motion is read with Sensor.registerSensorDataListener (a real high-rate
// stream, ~25 Hz). getInfo().accel only refreshes ~1 Hz, so polling it looked
// frozen. The listener delivers a burst of samples roughly once per second;
// those samples are buffered and animated smoothly across the render ticks so
// the ball floats continuously instead of lurching once per second.
class MotionEntryView extends WatchUi.View {

    private const SAMPLES_NEEDED = 120;  // ~5 s of shaking at 25 Hz
    private const SAMPLE_RATE = 25;      // Hz requested from the accelerometer
    private const RENDER_MS = 50;        // ball animation tick (20 fps)

    private var _strengthBits as Number;
    private var _sampleCount as Number = 0;
    private var _hash as Cryptography.Hash?;
    private var _renderTimer as Timer.Timer?;

    // Buffered accel samples awaiting animation playback.
    private var _bufX as Array<Number> = [] as Array<Number>;
    private var _bufY as Array<Number> = [] as Array<Number>;
    private var _readIdx as Number = 0;

    // Ball physics (screen-relative offset from play-area centre).
    private var _ballX as Float = 0.0;
    private var _ballY as Float = 0.0;
    private var _vx as Float = 0.0;
    private var _vy as Float = 0.0;
    private var _prevAccelX as Number = 0;
    private var _prevAccelY as Number = 0;
    private var _havePrev as Boolean = false;
    private var _maxR as Float = 1.0;

    private var _accelX as Number = 0;  // latest sample, for the live readout
    private var _accelY as Number = 0;
    private var _hasSensor as Boolean = false;
    private var _usingListener as Boolean = false;
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
        _bufX = [] as Array<Number>;
        _bufY = [] as Array<Number>;
        _readIdx = 0;
        _ballX = 0.0;
        _ballY = 0.0;
        _vx = 0.0;
        _vy = 0.0;
        _havePrev = false;
        _accelX = 0;
        _accelY = 0;
        _hasSensor = false;
        _hash = new Cryptography.Hash({:algorithm => Cryptography.HASH_SHA256});

        // Try the real accelerometer stream. If unavailable (e.g. the simulator
        // with no motion feed), _usingListener stays false and the render tick
        // falls back to a device-RNG random walk so collection still completes.
        _usingListener = false;
        try {
            Sensor.registerSensorDataListener(method(:onAccelData), {
                :period => 1,
                :accelerometer => {
                    :enabled => true,
                    :sampleRate => SAMPLE_RATE
                }
            });
            _usingListener = true;
        } catch (e) {
            _usingListener = false;
        }

        if (_renderTimer != null) { _renderTimer.stop(); }
        _renderTimer = new Timer.Timer();
        _renderTimer.start(method(:onRender), RENDER_MS, true);
    }

    function onHide() as Void {
        if (_usingListener) {
            try { Sensor.unregisterSensorDataListener(); } catch (e) {}
            _usingListener = false;
        }
        if (_renderTimer != null) { _renderTimer.stop(); _renderTimer = null; }
    }

    // High-rate accelerometer callback: a burst of samples once per period.
    // Hash every sample for entropy and queue it for smooth animation.
    function onAccelData(sensorData as Sensor.SensorData) as Void {
        if (isComplete()) { return; }
        var accel = sensorData.accelerometerData;
        if (accel == null) { return; }
        var xs = accel.x;
        var ys = accel.y;
        var zs = accel.z;
        if (xs == null || ys == null || zs == null) { return; }

        _hasSensor = true;
        var n = xs.size();
        for (var i = 0; i < n && !isComplete(); i++) {
            var ax = xs[i];
            var ay = ys[i];
            var az = zs[i];

            var bytes = new [6]b;
            bytes[0] = ax & 0xFF;
            bytes[1] = (ax >> 8) & 0xFF;
            bytes[2] = ay & 0xFF;
            bytes[3] = (ay >> 8) & 0xFF;
            bytes[4] = az & 0xFF;
            bytes[5] = (az >> 8) & 0xFF;
            (_hash as Cryptography.Hash).update(bytes);

            _bufX.add(ax);
            _bufY.add(ay);
            _sampleCount++;
        }

        _accelX = xs[n - 1];
        _accelY = ys[n - 1];

        if (isComplete()) {
            if (_usingListener) {
                try { Sensor.unregisterSensorDataListener(); } catch (e) {}
                _usingListener = false;
            }
            if (_onComplete != null) { (_onComplete as Method).invoke(); }
        }
    }

    // Advance the ball one physics step from a single accelerometer sample.
    private function stepBall(ax as Number, ay as Number) as Void {
        if (_havePrev) {
            var dx = (ax - _prevAccelX).toFloat();
            var dy = (ay - _prevAccelY).toFloat();
            // Per-sample integration with damping: rapid changes (shaking)
            // pump energy in; stillness lets it bleed out. No telescoping.
            _vx = _vx * 0.88 + dx * 0.012;
            _vy = _vy * 0.88 - dy * 0.012;
        }
        _prevAccelX = ax;
        _prevAccelY = ay;
        _havePrev = true;

        var vmax = 20.0;
        if (_vx > vmax) { _vx = vmax; } else if (_vx < -vmax) { _vx = -vmax; }
        if (_vy > vmax) { _vy = vmax; } else if (_vy < -vmax) { _vy = -vmax; }

        _ballX += _vx;
        _ballY += _vy;

        // Bounce off the circular wall so the ball ricochets and roams.
        var distSq = _ballX * _ballX + _ballY * _ballY;
        if (distSq > _maxR * _maxR && distSq > 0.0) {
            var dist = Math.sqrt(distSq).toFloat();
            var nx = _ballX / dist;
            var ny = _ballY / dist;
            _ballX = nx * _maxR;
            _ballY = ny * _maxR;
            var dot = _vx * nx + _vy * ny;
            _vx = (_vx - 2.0 * dot * nx) * 0.7;
            _vy = (_vy - 2.0 * dot * ny) * 0.7;
        }
    }

    // Animation tick. Plays buffered samples back smoothly; when there is no
    // real sensor stream, synthesises entropy from the device RNG (simulator).
    function onRender() as Void {
        if (_usingListener || _hasSensor) {
            var pending = _bufX.size() - _readIdx;
            if (pending > 0) {
                // Drain fast enough to keep pace with ~25 Hz arrival without
                // lagging behind; at least one sample per tick for smoothness.
                var take = pending / 6 + 1;
                if (take > 8) { take = 8; }
                for (var i = 0; i < take && _readIdx < _bufX.size(); i++) {
                    stepBall(_bufX[_readIdx], _bufY[_readIdx]);
                    _readIdx++;
                }
                if (_readIdx > 40) {
                    _bufX = _bufX.slice(_readIdx, null);
                    _bufY = _bufY.slice(_readIdx, null);
                    _readIdx = 0;
                }
            } else {
                // No fresh motion: let the ball coast to a stop.
                _ballX += _vx;
                _ballY += _vy;
                _vx *= 0.85;
                _vy *= 0.85;
            }
        } else if (!isComplete()) {
            // Simulator fallback: RNG-driven entropy and a wandering ball.
            var rand = Cryptography.randomBytes(6);
            (_hash as Cryptography.Hash).update(rand);
            stepBall((rand[0] & 0xFF) * 16, (rand[1] & 0xFF) * 16);
            _sampleCount++;
            if (isComplete() && _onComplete != null) {
                (_onComplete as Method).invoke();
            }
        }

        WatchUi.requestUpdate();
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
        _maxR = (playR - ballR).toFloat();

        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.12).toNumber(), Graphics.FONT_SMALL, "Shake watch",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Live accel readout — changes in real time once samples arrive.
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var valText = _hasSensor
            ? "x:" + _accelX + "  y:" + _accelY
            : "shake to start";
        dc.drawText(cx, (h * 0.24).toNumber(), Graphics.FONT_XTINY, valText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Play area circle
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, playR);

        // Ball
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx + _ballX.toNumber(), cy + _ballY.toNumber(), ballR);

        // Progress counter.
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
