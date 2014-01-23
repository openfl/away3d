/**
 * Extended camera used to hover round a specified target object.
 *
 * @see    away3d.containers.View3D
 */
package away3d.controllers;


import away3d.core.math.MathConsts;
import away3d.entities.Entity;
class FirstPersonController extends ControllerBase {
    public var steps(get_steps, set_steps):Int;
    public var panAngle(get_panAngle, set_panAngle):Float;
    public var tiltAngle(get_tiltAngle, set_tiltAngle):Float;
    public var minTiltAngle(get_minTiltAngle, set_minTiltAngle):Float;
    public var maxTiltAngle(get_maxTiltAngle, set_maxTiltAngle):Float;
    public var wrapPanAngle(get_wrapPanAngle, set_wrapPanAngle):Bool;

    private var _currentPanAngle:Float;
    private var _currentTiltAngle:Float;
    private var _panAngle:Float;
    private var _tiltAngle:Float;
    private var _minTiltAngle:Float;
    private var _maxTiltAngle:Float;
    private var _steps:Int;
    private var _walkIncrement:Float;
    private var _strafeIncrement:Float;
    private var _wrapPanAngle:Bool;
    public var fly:Bool;
/**
	 * Fractional step taken each time the <code>hover()</code> method is called. Defaults to 8.
	 *
	 * Affects the speed at which the <code>tiltAngle</code> and <code>panAngle</code> resolve to their targets.
	 *
	 * @see    #tiltAngle
	 * @see    #panAngle
	 */

    public function get_steps():Int {
        return _steps;
    }

    public function set_steps(val:Int):Int {
        val = ((val < 1)) ? 1 : val;
        if (_steps == val) return val;
        _steps = val;
        notifyUpdate();
        return val;
    }

/**
	 * Rotation of the camera in degrees around the y axis. Defaults to 0.
	 */

    public function get_panAngle():Float {
        return _panAngle;
    }

    public function set_panAngle(val:Float):Float {
        if (_panAngle == val) return val;
        _panAngle = val;
        notifyUpdate();
        return val;
    }

/**
	 * Elevation angle of the camera in degrees. Defaults to 90.
	 */

    public function get_tiltAngle():Float {
        return _tiltAngle;
    }

    public function set_tiltAngle(val:Float):Float {
        val = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, val));
        if (_tiltAngle == val) return val;
        _tiltAngle = val;
        notifyUpdate();
        return val;
    }

/**
	 * Minimum bounds for the <code>tiltAngle</code>. Defaults to -90.
	 *
	 * @see    #tiltAngle
	 */

    public function get_minTiltAngle():Float {
        return _minTiltAngle;
    }

    public function set_minTiltAngle(val:Float):Float {
        if (_minTiltAngle == val) return val;
        _minTiltAngle = val;
        tiltAngle = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, _tiltAngle));
        return val;
    }

/**
	 * Maximum bounds for the <code>tiltAngle</code>. Defaults to 90.
	 *
	 * @see    #tiltAngle
	 */

    public function get_maxTiltAngle():Float {
        return _maxTiltAngle;
    }

    public function set_maxTiltAngle(val:Float):Float {
        if (_maxTiltAngle == val) return val;
        _maxTiltAngle = val;
        tiltAngle = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, _tiltAngle));
        return val;
    }

/**
	 * Defines whether the value of the pan angle wraps when over 360 degrees or under 0 degrees. Defaults to false.
	 */

    public function get_wrapPanAngle():Bool {
        return _wrapPanAngle;
    }

    public function set_wrapPanAngle(val:Bool):Bool {
        if (_wrapPanAngle == val) return val;
        _wrapPanAngle = val;
        notifyUpdate();
        return val;
    }

/**
	 * Creates a new <code>HoverController</code> object.
	 */

    public function new(targetObject:Entity = null, panAngle:Float = 0, tiltAngle:Float = 90, minTiltAngle:Float = -90, maxTiltAngle:Float = 90, steps:Int = 8, wrapPanAngle:Bool = false) {
        _currentPanAngle = 0;
        _currentTiltAngle = 90;
        _panAngle = 0;
        _tiltAngle = 90;
        _minTiltAngle = -90;
        _maxTiltAngle = 90;
        _steps = 8;
        _walkIncrement = 0;
        _strafeIncrement = 0;
        _wrapPanAngle = false;
        fly = false;
        super(targetObject);
        this.panAngle = panAngle;
        this.tiltAngle = tiltAngle;
        this.minTiltAngle = minTiltAngle;
        this.maxTiltAngle = maxTiltAngle;
        this.steps = steps;
        this.wrapPanAngle = wrapPanAngle;
//values passed in contrustor are applied immediately
        _currentPanAngle = _panAngle;
        _currentTiltAngle = _tiltAngle;
    }

/**
	 * Updates the current tilt angle and pan angle values.
	 *
	 * Values are calculated using the defined <code>tiltAngle</code>, <code>panAngle</code> and <code>steps</code> variables.
	 *
	 * @param interpolate   If the update to a target pan- or tiltAngle is interpolated. Default is true.
	 *
	 * @see    #tiltAngle
	 * @see    #panAngle
	 * @see    #steps
	 */

    override public function update(interpolate:Bool = true):Void {
        if (_tiltAngle != _currentTiltAngle || _panAngle != _currentPanAngle) {
            notifyUpdate();
            if (_wrapPanAngle) {
                if (_panAngle < 0) {
                    _currentPanAngle += _panAngle % 360 + 360 - _panAngle;
                    _panAngle = _panAngle % 360 + 360;
                }

                else {
                    _currentPanAngle += _panAngle % 360 - _panAngle;
                    _panAngle = _panAngle % 360;
                }

                while (_panAngle - _currentPanAngle < -180)_currentPanAngle -= 360;
                while (_panAngle - _currentPanAngle > 180)_currentPanAngle += 360;
            }
            if (interpolate) {
                _currentTiltAngle += (_tiltAngle - _currentTiltAngle) / (steps + 1);
                _currentPanAngle += (_panAngle - _currentPanAngle) / (steps + 1);
            }

            else {
                _currentTiltAngle = _tiltAngle;
                _currentPanAngle = _panAngle;
            }

//snap coords if angle differences are close
            if ((Math.abs(tiltAngle - _currentTiltAngle) < 0.01) && (Math.abs(_panAngle - _currentPanAngle) < 0.01)) {
                _currentTiltAngle = _tiltAngle;
                _currentPanAngle = _panAngle;
            }
        }
        targetObject.rotationX = _currentTiltAngle;
        targetObject.rotationY = _currentPanAngle;
        if (!Math.isNaN(_walkIncrement)) {
            if (fly) targetObject.moveForward(_walkIncrement)
            else {
                targetObject.x += _walkIncrement * Math.sin(_panAngle * MathConsts.DEGREES_TO_RADIANS);
                targetObject.z += _walkIncrement * Math.cos(_panAngle * MathConsts.DEGREES_TO_RADIANS);
            }

            _walkIncrement = 0;
        }
        if (!Math.isNaN(_strafeIncrement)) {
            targetObject.moveRight(_strafeIncrement);
            _strafeIncrement = 0;
        }
    }

    public function incrementWalk(val:Float):Void {
        if (val == 0) return;
        _walkIncrement += val;
        notifyUpdate();
    }

    public function incrementStrafe(val:Float):Void {
        if (val == 0) return;
        _strafeIncrement += val;
        notifyUpdate();
    }

}

