package away3d.stereo;

import away3d.cameras.Camera3D;
import away3d.cameras.lenses.LensBase;

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

class StereoCamera3D extends Camera3D
{
	public var leftCamera(get, never):Camera3D;
	public var rightCamera(get, never):Camera3D;
	public var stereoFocus(get, set):Float;
	public var stereoOffset(get, set):Float;
	
	private var _leftCam:Camera3D;
	private var _rightCam:Camera3D;
	
	private var _offset:Float;
	private var _focus:Float;
	private var _focusPoint:Vector3D;
	private var _focusInfinity:Bool;
	
	private var _leftCamDirty:Bool = true;
	private var _rightCamDirty:Bool = true;
	private var _focusPointDirty:Bool = true;
	
	public function new(lens:LensBase = null)
	{
		super(lens);
		
		_leftCam = new Camera3D(lens);
		_rightCam = new Camera3D(lens);
		
		_offset = 0;
		_focus = 1000;
		_focusPoint = new Vector3D();
	}
	
	override private function set_lens(value:LensBase):LensBase
	{
		_leftCam.lens = value;
		_rightCam.lens = value;
		
		super.lens = value;
		return value;
	}
	
	private function get_leftCamera():Camera3D
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
	
	private function get_rightCamera():Camera3D
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
	
	private function get_stereoFocus():Float
	{
		return _focus;
	}
	
	private function set_stereoFocus(value:Float):Float
	{
		_focus = value;
		//			trace('focus:', _focus);
		invalidateStereoCams();
		return value;
	}
	
	private function get_stereoOffset():Float
	{
		return _offset;
	}
	
	private function set_stereoOffset(value:Float):Float
	{
		_offset = value;
		invalidateStereoCams();
		return value;
	}
	
	private function updateFocusPoint():Void
	{
		if (_focus == Math.POSITIVE_INFINITY) 
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

	override private function invalidateTransform():Void
	{
		super.invalidateTransform();
		invalidateStereoCams();
	}
	
	private function invalidateStereoCams():Void
	{
		_leftCamDirty = true;
		_rightCamDirty = true;
		_focusPointDirty = true;
	}
}