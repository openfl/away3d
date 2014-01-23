package away3d.stereo;


import away3d.core.math.MathConsts;
import away3d.cameras.Camera3D;
import away3d.cameras.lenses.LensBase;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

class StereoCamera3D extends Camera3D {
    public var leftCamera(get_leftCamera, never):Camera3D;
    public var rightCamera(get_rightCamera, never):Camera3D;
    public var stereoFocus(get_stereoFocus, set_stereoFocus):Float;
    public var stereoOffset(get_stereoOffset, set_stereoOffset):Float;

    private var _leftCam:Camera3D;
    private var _rightCam:Camera3D;
    private var _offset:Float;
    private var _focus:Float;
    private var _focusPoint:Vector3D;
    private var _focusInfinity:Bool;
    private var _leftCamDirty:Bool;
    private var _rightCamDirty:Bool;
    private var _focusPointDirty:Bool;

    public function new(lens:LensBase = null) {
        _leftCamDirty = true;
        _rightCamDirty = true;
        _focusPointDirty = true;
        super(lens);
        _leftCam = new Camera3D(lens);
        _rightCam = new Camera3D(lens);
        _offset = 0;
        _focus = 1000;
        _focusPoint = new Vector3D();
    }

    override public function set_lens(value:LensBase):LensBase {
        _leftCam.lens = value;
        _rightCam.lens = value;
        super.lens = value;
        return value;
    }

    public function get_leftCamera():Camera3D {
        if (_leftCamDirty) {
            var tf:Matrix3D;
            if (_focusPointDirty) updateFocusPoint();
            tf = _leftCam.transform;
            tf.copyFrom(transform);
            tf.prependTranslation(-_offset, 0, 0);
            _leftCam.transform = tf;
            if (!_focusInfinity) _leftCam.lookAt(_focusPoint);
            _leftCamDirty = false;
        }
        return _leftCam;
    }

    public function get_rightCamera():Camera3D {
        if (_rightCamDirty) {
            var tf:Matrix3D;
            if (_focusPointDirty) updateFocusPoint();
            tf = _rightCam.transform;
            tf.copyFrom(transform);
            tf.prependTranslation(_offset, 0, 0);
            _rightCam.transform = tf;
            if (!_focusInfinity) _rightCam.lookAt(_focusPoint);
            _rightCamDirty = false;
        }
        return _rightCam;
    }

    public function get_stereoFocus():Float {
        return _focus;
    }

    public function set_stereoFocus(value:Float):Float {
        _focus = value;
//			trace('focus:', _focus);
        invalidateStereoCams();
        return value;
    }

    public function get_stereoOffset():Float {
        return _offset;
    }

    public function set_stereoOffset(value:Float):Float {
        _offset = value;
        invalidateStereoCams();
        return value;
    }

    private function updateFocusPoint():Void {
        if (_focus == MathConsts.Infinity) _focusInfinity = true
        else {
            _focusPoint.x = 0;
            _focusPoint.y = 0;
            _focusPoint.z = _focus;
            _focusPoint = transform.transformVector(_focusPoint);
            _focusInfinity = false;
            _focusPointDirty = false;
        }

    }

    override private function invalidateTransform():Void {
        super.invalidateTransform();
        invalidateStereoCams();
    }

    private function invalidateStereoCams():Void {
        _leftCamDirty = true;
        _rightCamDirty = true;
        _focusPointDirty = true;
    }

}

