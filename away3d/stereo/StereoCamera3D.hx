package away3d.stereo;

	//import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.LensBase;
	
	import away3d.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	//use namespace arcane;
	
	class StereoCamera3D extends Camera3D
	{
		var _leftCam:Camera3D;
		var _rightCam:Camera3D;
		
		var _offset:Float;
		var _focus:Float;
		var _focusPoint:Vector3D;
		var _focusInfinity:Bool;
		
		var _leftCamDirty:Bool = true;
		var _rightCamDirty:Bool = true;
		var _focusPointDirty:Bool = true;
		
		public function new(lens:LensBase = null)
		{
			super(lens);
			
			_leftCam = new Camera3D(lens);
			_rightCam = new Camera3D(lens);
			
			_offset = 0;
			_focus = 1000;
			_focusPoint = new Vector3D();
		}
		
		public var lens(null, set) : Void;
		
		override public function set_lens(value:LensBase) : Void
		{
			_leftCam.lens = value;
			_rightCam.lens = value;
			
			super.lens = value;
		}
		
		public var leftCamera(get, null) : Camera3D;
		
		public function get_leftCamera() : Camera3D
		{
			if (_leftCamDirty) {
				var tf:Matrix3D;
				
				if (_focusPointDirty)
					updateFocusPoint();
				
				tf = _leftCam.transform;
				tf.copyFrom(transform);
				tf.prependTranslation(-_offset, 0, 0);
				_leftCam.transform = tf;
				
				if (!_focusInfinity)
					_leftCam.lookAt(_focusPoint);
				
				_leftCamDirty = false;
			}
			
			return _leftCam;
		}
		
		public var rightCamera(get, null) : Camera3D;
		
		public function get_rightCamera() : Camera3D
		{
			if (_rightCamDirty) {
				var tf:Matrix3D;
				
				if (_focusPointDirty)
					updateFocusPoint();
				
				tf = _rightCam.transform;
				tf.copyFrom(transform);
				tf.prependTranslation(_offset, 0, 0);
				_rightCam.transform = tf;
				
				if (!_focusInfinity)
					_rightCam.lookAt(_focusPoint);
				
				_rightCamDirty = false;
			}
			
			return _rightCam;
		}
		
		public var stereoFocus(get, set) : Float;
		
		public function get_stereoFocus() : Float
		{
			return _focus;
		}
		
		public function set_stereoFocus(value:Float) : Float
		{
			_focus = value;
			//			trace('focus:', _focus);
			invalidateStereoCams();
		}
		
		public var stereoOffset(get, set) : Float;
		
		public function get_stereoOffset() : Float
		{
			return _offset;
		}
		
		public function set_stereoOffset(value:Float) : Float
		{
			_offset = value;
			invalidateStereoCams();
		}
		
		private function updateFocusPoint():Void
		{
			if (_focus == Infinity)
				_focusInfinity = true;
			else {
				_focusPoint.x = 0;
				_focusPoint.y = 0;
				_focusPoint.z = _focus;
				
				_focusPoint = transform.transformVector(_focusPoint);
				
				_focusInfinity = false;
				_focusPointDirty = false;
			}
		}
		
		override public function invalidateTransform():Void
		{
			super.invalidateTransform();
			invalidateStereoCams();
		}
		
		public function invalidateStereoCams():Void
		{
			_leftCamDirty = true;
			_rightCamDirty = true;
			_focusPointDirty = true;
		}
	}

