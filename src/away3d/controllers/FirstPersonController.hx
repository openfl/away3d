package away3d.controllers;

	//import away3d.arcane;
	import away3d.core.math.*;
	import away3d.entities.*;
	
	//use namespace arcane;
	
	/**
	 * Extended camera used to hover round a specified target object.
	 *
	 * @see    away3d.containers.View3D
	 */
	class FirstPersonController extends ControllerBase
	{
		/*arcane*/ public var _currentPanAngle:Float = 0;
		/*arcane*/ public var _currentTiltAngle:Float = 90;
		
		var _panAngle:Float = 0;
		var _tiltAngle:Float = 90;
		var _minTiltAngle:Float = -90;
		var _maxTiltAngle:Float = 90;
		var _steps:UInt = 8;
		var _walkIncrement:Float = 0;
		var _strafeIncrement:Float = 0;
		var _wrapPanAngle:Bool = false;
		
		public var fly:Bool = false;
		
		/**
		 * Fractional step taken each time the <code>hover()</code> method is called. Defaults to 8.
		 *
		 * Affects the speed at which the <code>tiltAngle</code> and <code>panAngle</code> resolve to their targets.
		 *
		 * @see    #tiltAngle
		 * @see    #panAngle
		 */
		public var steps(get, set) : UInt;
		public function get_steps() : UInt
		{
			return _steps;
		}
		
		public function set_steps(val:UInt) : UInt
		{
			val = (val < 1)? 1 : val;
			
			if (_steps == val)
				return;
			
			_steps = val;
			
			notifyUpdate();
		}
		
		/**
		 * Rotation of the camera in degrees around the y axis. Defaults to 0.
		 */
		public var panAngle(get, set) : Float;
		public function get_panAngle() : Float
		{
			return _panAngle;
		}
		
		public function set_panAngle(val:Float) : Float
		{
			if (_panAngle == val)
				return;
			
			_panAngle = val;
			
			notifyUpdate();
		}
		
		/**
		 * Elevation angle of the camera in degrees. Defaults to 90.
		 */
		public var tiltAngle(get, set) : Float;
		public function get_tiltAngle() : Float
		{
			return _tiltAngle;
		}
		
		public function set_tiltAngle(val:Float) : Float
		{
			val = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, val));
			
			if (_tiltAngle == val)
				return;
			
			_tiltAngle = val;
			
			notifyUpdate();
		}
		
		/**
		 * Minimum bounds for the <code>tiltAngle</code>. Defaults to -90.
		 *
		 * @see    #tiltAngle
		 */
		public var minTiltAngle(get, set) : Float;
		public function get_minTiltAngle() : Float
		{
			return _minTiltAngle;
		}
		
		public function set_minTiltAngle(val:Float) : Float
		{
			if (_minTiltAngle == val)
				return;
			
			_minTiltAngle = val;
			
			tiltAngle = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, _tiltAngle));
		}
		
		/**
		 * Maximum bounds for the <code>tiltAngle</code>. Defaults to 90.
		 *
		 * @see    #tiltAngle
		 */
		public var maxTiltAngle(get, set) : Float;
		public function get_maxTiltAngle() : Float
		{
			return _maxTiltAngle;
		}
		
		public function set_maxTiltAngle(val:Float) : Float
		{
			if (_maxTiltAngle == val)
				return;
			
			_maxTiltAngle = val;
			
			tiltAngle = Math.max(_minTiltAngle, Math.min(_maxTiltAngle, _tiltAngle));
		}
		
		
		/**
		 * Defines whether the value of the pan angle wraps when over 360 degrees or under 0 degrees. Defaults to false.
		 */
		public var wrapPanAngle(get, set) : Bool;
		public function get_wrapPanAngle() : Bool
		{
			return _wrapPanAngle;
		}
		
		public function set_wrapPanAngle(val:Bool) : Bool
		{
			if (_wrapPanAngle == val)
				return;
			
			_wrapPanAngle = val;
			
			notifyUpdate();
		}
		
		/**
		 * Creates a new <code>HoverController</code> object.
		 */
		public function new(targetObject:Entity = null, panAngle:Float = 0, tiltAngle:Float = 90, minTiltAngle:Float = -90, maxTiltAngle:Float = 90, steps:UInt = 8, wrapPanAngle:Bool = false)
		{
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
		public override function update(interpolate:Bool = true):Void
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
			
			if (_walkIncrement) {
				if (fly)
					targetObject.moveForward(_walkIncrement);
				else {
					targetObject.x += _walkIncrement*Math.sin(_panAngle*MathConsts.DEGREES_TO_RADIANS);
					targetObject.z += _walkIncrement*Math.cos(_panAngle*MathConsts.DEGREES_TO_RADIANS);
				}
				_walkIncrement = 0;
			}
			
			if (_strafeIncrement) {
				targetObject.moveRight(_strafeIncrement);
				_strafeIncrement = 0;
			}
		
		}
		
		public function incrementWalk(val:Float):Void
		{
			if (val == 0)
				return;
			
			_walkIncrement += val;
			
			notifyUpdate();
		}
		
		public function incrementStrafe(val:Float):Void
		{
			if (val == 0)
				return;
			
			_strafeIncrement += val;
			
			notifyUpdate();
		}
	
	}

