/**
 * Extended camera used to hover round a specified target object.
 *
 * @see    away3d.containers.View3D
 */
package away3d.controllers;


import away3d.core.math.MathConsts;
import away3d.core.math.MathConsts;
import away3d.entities.Entity;
import away3d.containers.ObjectContainer3D;
import flash.geom.Vector3D;

class HoverController extends LookAtController {
    public var steps(get_steps, set_steps):Int;
    public var panAngle(get_panAngle, set_panAngle):Float;
    public var tiltAngle(get_tiltAngle, set_tiltAngle):Float;
    public var distance(get_distance, set_distance):Float;
    public var minPanAngle(get_minPanAngle, set_minPanAngle):Float;
    public var maxPanAngle(get_maxPanAngle, set_maxPanAngle):Float;
    public var minTiltAngle(get_minTiltAngle, set_minTiltAngle):Float;
    public var maxTiltAngle(get_maxTiltAngle, set_maxTiltAngle):Float;
    public var yFactor(get_yFactor, set_yFactor):Float;
    public var wrapPanAngle(get_wrapPanAngle, set_wrapPanAngle):Bool;

    private var _currentPanAngle:Float;
    private var _currentTiltAngle:Float;
    private var _panAngle:Float;
    private var _tiltAngle:Float;
    private var _distance:Float;
    private var _minPanAngle:Float;
    private var _maxPanAngle:Float;
    private var _minTiltAngle:Float;
    private var _maxTiltAngle:Float;
    private var _steps:Int;
    private var _yFactor:Float;
    private var _wrapPanAngle:Bool;
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
        val = Math.max(_minPanAngle, Math.min(_maxPanAngle, val));
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
	 * Distance between the camera and the specified target. Defaults to 1000.
	 */

    public function get_distance():Float {
        return _distance;
    }

    public function set_distance(val:Float):Float {
        if (_distance == val) return val;
        _distance = val;
        notifyUpdate();
        return val;
    }

/**
	 * Minimum bounds for the <code>panAngle</code>. Defaults to -Infinity.
	 *
	 * @see    #panAngle
	 */

    public function get_minPanAngle():Float {
        return _minPanAngle;
    }

    public function set_minPanAngle(val:Float):Float {
        if (_minPanAngle == val) return val;
        _minPanAngle = val;
        panAngle = Math.max(_minPanAngle, Math.min(_maxPanAngle, _panAngle));
        return val;
    }

/**
	 * Maximum bounds for the <code>panAngle</code>. Defaults to Infinity.
	 *
	 * @see    #panAngle
	 */

    public function get_maxPanAngle():Float {
        return _maxPanAngle;
    }

    public function set_maxPanAngle(val:Float):Float {
        if (_maxPanAngle == val) return val;
        _maxPanAngle = val;
        panAngle = Math.max(_minPanAngle, Math.min(_maxPanAngle, _panAngle));
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
	 * Fractional difference in distance between the horizontal camera orientation and vertical camera orientation. Defaults to 2.
	 *
	 * @see    #distance
	 */

    public function get_yFactor():Float {
        return _yFactor;
    }

    public function set_yFactor(val:Float):Float {
        if (_yFactor == val) return val;
        _yFactor = val;
        notifyUpdate();
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

    public function new(targetObject:Entity = null, lookAtObject:ObjectContainer3D = null, panAngle:Float = 0, tiltAngle:Float = 90, distance:Float = 1000, minTiltAngle:Float = -90, maxTiltAngle:Float = 90, ? minPanAngle:Float = null, ? maxPanAngle:Float = null, ?steps:Int = 8, ?yFactor:Float = 2, ?wrapPanAngle:Bool = false) {
        _currentPanAngle = 0;
        _currentTiltAngle = 90;
        _panAngle = 0;
        _tiltAngle = 90;
        _distance = 1000;
        _minPanAngle = -MathConsts.Infinity;
        _maxPanAngle = MathConsts.Infinity;
        _minTiltAngle = -90;
        _maxTiltAngle = 90;
        _steps = 8;
        _yFactor = 2;
        _wrapPanAngle = false;
        super(targetObject, lookAtObject);
        this.distance = distance;
        this.panAngle = panAngle;
        this.tiltAngle = tiltAngle;
        this.minPanAngle = minPanAngle ;
        if (Math.isNaN(this.minPanAngle)) this.minPanAngle = -MathConsts.Infinity;
        this.maxPanAngle = maxPanAngle;
        if (Math.isNaN(this.maxPanAngle)) this.maxPanAngle = MathConsts.Infinity;
        this.minTiltAngle = minTiltAngle;
        this.maxTiltAngle = maxTiltAngle;
        this.steps = steps;
        this.yFactor = yFactor;
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
                _currentPanAngle = _panAngle;
                _currentTiltAngle = _tiltAngle;
            }

//snap coords if angle differences are close
            if ((Math.abs(tiltAngle - _currentTiltAngle) < 0.01) && (Math.abs(_panAngle - _currentPanAngle) < 0.01)) {
                _currentTiltAngle = _tiltAngle;
                _currentPanAngle = _panAngle;
            }
        }
        var pos:Vector3D = ((lookAtObject != null)) ? lookAtObject.position : ((lookAtPosition != null)) ? lookAtPosition : _origin;
        targetObject.x = pos.x + distance * Math.sin(_currentPanAngle * MathConsts.DEGREES_TO_RADIANS) * Math.cos(_currentTiltAngle * MathConsts.DEGREES_TO_RADIANS);
        targetObject.z = pos.z + distance * Math.cos(_currentPanAngle * MathConsts.DEGREES_TO_RADIANS) * Math.cos(_currentTiltAngle * MathConsts.DEGREES_TO_RADIANS);
        targetObject.y = pos.y + distance * Math.sin(_currentTiltAngle * MathConsts.DEGREES_TO_RADIANS) * yFactor;

        super.update();
    }

}

