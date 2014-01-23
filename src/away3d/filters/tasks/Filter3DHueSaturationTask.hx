package away3d.filters.tasks;

import flash.Vector;
import away3d.cameras.Camera3D;
import away3d.core.managers.Stage3DProxy;
import flash.display3D.Context3DProgramType;
import flash.display3D.textures.Texture;

class Filter3DHueSaturationTask extends Filter3DTaskBase {
    public var saturation(get_saturation, set_saturation):Float;
    public var r(get_r, set_r):Float;
    public var b(get_b, set_b):Float;
    public var g(get_g, set_g):Float;

    private var _rgbData:Vector<Float>;
    private var _saturation:Float;
    private var _r:Float;
    private var _b:Float;
    private var _g:Float;

    public function new() {
        _saturation = 0.6;
        _r = 1;
        _b = 1;
        _g = 1;
        super();
        updateConstants();
    }

    public function get_saturation():Float {
        return _saturation;
    }

    public function set_saturation(value:Float):Float {
        if (_saturation == value) return value;
        _saturation = value;
        updateConstants();
        return value;
    }

    public function get_r():Float {
        return _r;
    }

    public function set_r(value:Float):Float {
        if (_r == value) return value;
        _r = value;
        updateConstants();
        return value;
    }

    public function get_b():Float {
        return _b;
    }

    public function set_b(value:Float):Float {
        if (_b == value) return value;
        _b = value;
        updateConstants();
        return value;
    }

    public function get_g():Float {
        return _g;
    }

    public function set_g(value:Float):Float {
        if (_g == value) return value;
        _g = value;
        updateConstants();
        return value;
    }

    override public function getFragmentCode():String {
/**
		 * Some reference so I don't go crazy
		 *
		 * ft0-7 : Fragment temp
		 * v0-7 : varying buffer (passed from vertex shader)
		 * fs0-7 : Sampler?
		 *
		 * oc : output color
		 *
		 * Constants
		 * fc0 = Color Constants
		 * fc1 = Desaturation factor
		 *
		 * ft0 - Pixel Color
		 * ft1 - Intensity*Saturation
		 *
		 */
//_____________________________________________________________________
//	Texture
//_____________________________________________________________________
        return "tex ft0, v0, fs0 <2d,linear,clamp>	\n" + //_____________________________________________________________________

//	Color Multiplier
//_____________________________________________________________________
        "mul ft0.xyz, ft0.xyz, fc2.xyz  \n" + // brightness

//_____________________________________________________________________
//	Intensity * Saturation
//_____________________________________________________________________
        "mul ft1, ft0.x, fc0.x          \n" + // 0.3 * red

        "mul ft2, ft0.y, fc0.y          \n" + // 0.59 * green

        "add ft1, ft1, ft2              \n" + // add red and green results

        "mul ft2, ft0.z, fc0.z          \n" + // 0.11 * blue

        "add ft1, ft1, ft2              \n" + // add (red*green) and blue results

        "mul ft1, ft1, fc1.x            \n" + // multiply intensity and saturation

//_____________________________________________________________________
//	RGB Value
//_____________________________________________________________________
        "mul ft0.xyz, ft0.xyz, fc1.y    \n" + // rgb * (1-saturation)

        "add ft0.xyz, ft0.xyz, ft1      \n" + // rgb + intensity

// output the color
        "mov oc, ft0			        \n";
    }

    override public function activate(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:Texture):Void {
        stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _rgbData, 2);
    }

    private function updateConstants():Void {
        _rgbData = Vector.ofArray(cast [0.3, 0.59, 0.11, 0, 1 - _saturation, _saturation, 0, 0, r, g, b, 0]);
    }

}

