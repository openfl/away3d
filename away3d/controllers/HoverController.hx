package away3d.controllers;

import away3d.containers.*;
import away3d.entities.*;
import away3d.core.math.*;

import openfl.geom.Vector3D;

/**
 * Extended camera used to hover round a specified target object.
 *
 * @see    away3d.containers.View3D
 */
class HoverController extends LookAtController
{
	public var steps(get, set):Int;
	public var panAngle(get, set):Float;
	public var tiltAngle(get, set):Float;
	public var distance(get, set):Float;
	public var minPanAngle(get, set):Float;
	public var maxPanAngle(get, set):Float;
	public var minTiltAngle(get, set):Float;
	public var maxTiltAngle(get, set):Float;
	public var yFactor(get, set):Float;
	public var wrapPanAngle(get, set):Bool;
	
	@:allow(away3d) private var _currentPanAngle:Float = 0;
	@:allow(away3d) private var _currentTiltAngle:Float = 90;
	
	private var _panAngle:Float = 0;
	private var _tiltAngle:Float = 90;
	private var _distance:Float = 1000;
	private var _minPanAngle:Float = Math.NEGATIVE_INFINITY;
	private var _maxPanAngle:Float = Math.POSITIVE_INFINITY;
	private var _minTiltAngle:Float = -90;
	private var _maxTiltAngle:Float = 90;
	private var _steps:Int = 8;
	private var _yFactor:Float = 2;
	private var _wrapPanAngle:Bool = false;
	
	/**
	 * Fractional step taken each time the <code>hover()</code> method is called. Defaults to 8.
	 *
	 * Affects the speed at which the <code>tiltAngle</code> and <code>panAngle</code> resolve to their targets.
	 *
	 * @see    #tiltAngle
	 * @see    #panAngle
	 */
	private function get_steps():Int
	{
		return _steps;
	}
	
	private function set_steps(val:Int):Int
	{
		val = (val < 1)? 1 : val;
		
		if (_steps == val)
			return val;
		
		_steps = val;
		
		notifyUpdate();
		return val;
	}
	
	/**
	 * Rotation of the camera in degrees around the y axis. Defaults to 0.
	 */
	private function get_panAngle():Float
	{
		return _panAngle;
	}
	
	private function set_panAngle(val:Float):Float
	{
		if (Math.isNaN(val))
			val = 0;
		
		val = Math.max(_minPanAngle, Math.min(_maxPanAngle, val));
		
		if (_panAngle == val)
			return val;
		
		_panAngle = val;
		
		notifyUpdate();
		return val;
	}
	
	/**
	 * Elevation angle of the camera in degrees. Defaults to 90.
	 */
	private function get_tiltAngle():Float
	{
		return _tiltAngle;
	}
	
	private function set_tiltAngle(val:Float):Float
	{
		if (Math.isNaN(val))
			val = 0;
		
		val = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, val));
		
		if (_tiltAngle == val)
			return val;
		
		_tiltAngle = val;
		
		notifyUpdate();
		return val;
	}
	
	/**
	 * Distance between the camera and the specified target. Defaults to 1000.
	 */
	private function get_distance():Float
	{
		return _distance;
	}
	
	private function set_distance(val:Float):Float
	{
		if (_distance == val)
			return val;
		
		_distance = val;
		
		notifyUpdate();
		return val;
	}
	
	/**
	 * Minimum bounds for the <code>panAngle</code>. Defaults to -Infinity.
	 *
	 * @see    #panAngle
	 */
	private function get_minPanAngle():Float
	{
		return _minPanAngle;
	}
	
	private function set_minPanAngle(val:Float):Float
	{
		if (_minPanAngle == val)
			return val;
		
		_minPanAngle = val;
		
		panAngle = Math.max(_minPanAngle, Math.min(_maxPanAngle, _panAngle));
		return val;
	}
	
	/**
	 * Maximum bounds for the <code>panAngle</code>. Defaults to Infinity.
	 *
	 * @see    #panAngle
	 */
	private function get_maxPanAngle():Float
	{
		return _maxPanAngle;
	}
	
	private function set_maxPanAngle(val:Float):Float
	{
		if (_maxPanAngle == val)
			return val;
		
		_maxPanAngle = val;
		
		panAngle = Math.max(_minPanAngle, Math.min(_maxPanAngle, _panAngle));
		return val;
	}
	
	/**
	 * Minimum bounds for the <code>tiltAngle</code>. Defaults to -90.
	 *
	 * @see    #tiltAngle
	 */
	private function get_minTiltAngle():Float
	{
		return _minTiltAngle;
	}
	
	private function set_minTiltAngle(val:Float):Float
	{
		if (_minTiltAngle == val)
			return val;
		
		_minTiltAngle = val;
		
		tiltAngle = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, _tiltAngle));
		return val;
	}
	
	/**
	 * Maximum bounds for the <code>tiltAngle</code>. Defaults to 90.
	 *
	 * @see    #tiltAngle
	 */
	private function get_maxTiltAngle():Float
	{
		return _maxTiltAngle;
	}
	
	private function set_maxTiltAngle(val:Float):Float
	{
		if (_maxTiltAngle == val)
			return val;
		
		_maxTiltAngle = val;
		
		tiltAngle = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, _tiltAngle));
		return val;
	}
	
	/**
	 * Fractional difference in distance between the horizontal camera orientation and vertical camera orientation. Defaults to 2.
	 *
	 * @see    #distance
	 */
	private function get_yFactor():Float
	{
		return _yFactor;
	}
	
	private function set_yFactor(val:Float):Float
	{
		if (_yFactor == val)
			return val;
		
		_yFactor = val;
		
		notifyUpdate();
		return val;
	}
	
	/**
	 * Defines whether the value of the pan angle wraps when over 360 degrees or under 0 degrees. Defaults to false.
	 */
	private function get_wrapPanAngle():Bool
	{
		return _wrapPanAngle;
	}
	
	private function set_wrapPanAngle(val:Bool):Bool
	{
		if (_wrapPanAngle == val)
			return val;
		
		_wrapPanAngle = val;
		
		notifyUpdate();
		return val;
	}
	
	/**
	 * Creates a new <code>HoverController</code> object.
	 */
	public function new(targetObject:Entity = null, lookAtObject:ObjectContainer3D = null, panAngle:Float = 0, tiltAngle:Float = 90, distance:Float = 1000, minTiltAngle:Float = -90, maxTiltAngle:Float = 90, ? minPanAngle:Float = null, ? maxPanAngle:Float = null, ?steps:Int = 8, ?yFactor:Float = 2, ?wrapPanAngle:Bool = false)
	{
		super(targetObject, lookAtObject);
		
		this.distance = distance;
		this.panAngle = panAngle;
		this.tiltAngle = tiltAngle; 
		this.minPanAngle = minPanAngle!=null ? minPanAngle : Math.NEGATIVE_INFINITY;
		this.maxPanAngle = maxPanAngle!=null ? maxPanAngle : Math.POSITIVE_INFINITY;
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
	override public function update(interpolate:Bool = true):Void
	{
		if (_tiltAngle != _currentTiltAngle || _panAngle != _currentPanAngle) {
			
			notifyUpdate();
			
			if (_wrapPanAngle) {
				if (_panAngle < 0) {
					_currentPanAngle += _panAngle%360 + 360 - _panAngle;
					_panAngle = _panAngle%360 + 360;
				} else {
					_currentPanAngle += _panAngle%360 - _panAngle;
					_panAngle = _panAngle%360;
				}
				
				while (_panAngle - _currentPanAngle < -180)
					_currentPanAngle -= 360;
				
				while (_panAngle - _currentPanAngle > 180)
					_currentPanAngle += 360;
			}
			
			if (interpolate) {
				_currentTiltAngle += (_tiltAngle - _currentTiltAngle)/(steps + 1);
				_currentPanAngle += (_panAngle - _currentPanAngle)/(steps + 1);
			} else {
				_currentPanAngle = _panAngle;
				_currentTiltAngle = _tiltAngle;
			}
			
			//snap coords if angle differences are close
			if ((Math.abs(tiltAngle - _currentTiltAngle) < 0.01) && (Math.abs(_panAngle - _currentPanAngle) < 0.01)) {
				_currentTiltAngle = _tiltAngle;
				_currentPanAngle = _panAngle;
			}
		}
		
		if (targetObject == null) return;
		
		if (_lookAtPosition != null) {
			_pos.x = _lookAtPosition.x;
			_pos.y = _lookAtPosition.y;
			_pos.z = _lookAtPosition.z;
		} else if (_lookAtObject != null) {
			if(_targetObject.parent != null && _lookAtObject.parent != null) {
				if(_targetObject.parent != _lookAtObject.parent) {// different spaces
					_pos.x = _lookAtObject.scenePosition.x;
					_pos.y = _lookAtObject.scenePosition.y;
					_pos.z = _lookAtObject.scenePosition.z;
					Matrix3DUtils.transformVector(_targetObject.parent.inverseSceneTransform, _pos, _pos);
				}else{//one parent
					Matrix3DUtils.getTranslation(_lookAtObject.transform, _pos);
				}
			}else if(_lookAtObject.scene != null){
				_pos.x = _lookAtObject.scenePosition.x;
				_pos.y = _lookAtObject.scenePosition.y;
				_pos.z = _lookAtObject.scenePosition.z;
			}else{
				Matrix3DUtils.getTranslation(_lookAtObject.transform, _pos);
			}
		}else{
			_pos.x = _origin.x;
			_pos.y = _origin.y;
			_pos.z = _origin.z;
		}
		
		_targetObject.x = _pos.x + _distance*Math.sin(_currentPanAngle*MathConsts.DEGREES_TO_RADIANS)*Math.cos(_currentTiltAngle*MathConsts.DEGREES_TO_RADIANS);
		_targetObject.z = _pos.z + _distance*Math.cos(_currentPanAngle*MathConsts.DEGREES_TO_RADIANS)*Math.cos(_currentTiltAngle*MathConsts.DEGREES_TO_RADIANS);
		_targetObject.y = _pos.y + _distance*Math.sin(_currentTiltAngle*MathConsts.DEGREES_TO_RADIANS)*_yFactor;
		super.update();
	}
}