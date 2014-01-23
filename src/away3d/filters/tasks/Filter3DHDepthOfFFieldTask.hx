package away3d.filters.tasks;


import flash.Vector;
import away3d.cameras.Camera3D;
import away3d.core.managers.Stage3DProxy;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.textures.Texture;

class Filter3DHDepthOfFFieldTask extends Filter3DTaskBase {
    public var stepSize(get_stepSize, set_stepSize):Int;
    public var range(get_range, set_range):Float;
    public var focusDistance(get_focusDistance, set_focusDistance):Float;
    public var maxBlur(get_maxBlur, set_maxBlur):Int;

    static private var MAX_AUTO_SAMPLES:Int = 10;
    private var _maxBlur:Int;
    private var _data:Vector<Float>;
    private var _focusDistance:Float;
    private var _range:Float;
    private var _stepSize:Int;
    private var _realStepSize:Float;
/**
	 * Creates a new Filter3DHDepthOfFFieldTask
	 * @param amount The maximum amount of blur to apply in pixels at the most out-of-focus areas
	 * @param stepSize The distance between samples. Set to -1 to autodetect with acceptable quality.
	 */

    public function new(maxBlur:Int, stepSize:Int = -1) {
        _range = 1000;
        super(true);
        _maxBlur = maxBlur;
        _data = Vector.ofArray(cast [0, 0, 0, _focusDistance, 0, 0, 0, 0, _range, 0, 0, 0, 1.0, 1 / 255.0, 1 / 65025.0, 1 / 16581375.0]);
        this.stepSize = stepSize;
    }

    public function get_stepSize():Int {
        return _stepSize;
    }

    public function set_stepSize(value:Int):Int {
        if (value == _stepSize) return value;
        _stepSize = value;
        calculateStepSize();
        invalidateProgram3D();
        updateBlurData();
        return value;
    }

    public function get_range():Float {
        return _range;
    }

    public function set_range(value:Float):Float {
        _range = value;
        _data[8] = 1 / value;
        return value;
    }

    public function get_focusDistance():Float {
        return _focusDistance;
    }

    public function set_focusDistance(value:Float):Float {
        _data[3] = _focusDistance = value;
        return value;
    }

    public function get_maxBlur():Int {
        return _maxBlur;
    }

    public function set_maxBlur(value:Int):Int {
        if (_maxBlur == value) return value;
        _maxBlur = value;
        invalidateProgram3D();
        updateBlurData();
        calculateStepSize();
        return value;
    }

    override public function getFragmentCode():String {
        var code:String;
        var numSamples:Int = 1;
// sample depth, unpack & get blur amount (offset point + step size)
        code = "tex ft0, v0, fs1 <2d, nearest>	\n" + "dp4 ft1.z, ft0, fc3				\n" + "sub ft1.z, ft1.z, fc1.z			\n" + // d = d - f

        "rcp ft1.z, ft1.z			\n" + // screenZ = -n*f/(d-f)

        "mul ft1.z, fc1.w, ft1.z			\n" + // screenZ = -n*f/(d-f)

        "sub ft1.z, ft1.z, fc0.w			\n" + // screenZ - dist

        "mul ft1.z, ft1.z, fc2.x			\n" + // (screenZ - dist)/range

        "abs ft1.z, ft1.z					\n" + // abs(screenZ - dist)/range

        "sat ft1.z, ft1.z					\n" + // sat(abs(screenZ - dist)/range)

        "mul ft6.xy, ft1.z, fc0.xy			\n";
        code += "mov ft0, v0	\n" + "sub ft0.x, ft0.x, ft6.x\n" + "tex ft1, ft0, fs0 <2d,linear,clamp>\n";
        var x:Float = _realStepSize;
        while (x <= _maxBlur) {
            code += "add ft0.x, ft0.x, ft6.y	\n" + "tex ft2, ft0, fs0 <2d,linear,clamp>\n" + "add ft1, ft1, ft2 \n";
            ++numSamples;
            x += _realStepSize;
        }
        code += "mul oc, ft1, fc0.z";
        _data[2] = 1 / numSamples;
        return code;
    }

    override public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D, depthTexture:Texture):Void {
        var context:Context3D = stage3DProxy._context3D;
        var n:Float = camera.lens.near;
        var f:Float = camera.lens.far;
        _data[6] = f / (f - n);
        _data[7] = -n * _data[6];
        context.setTextureAt(1, depthTexture);
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 4);
    }

    override public function deactivate(stage3DProxy:Stage3DProxy):Void {
        stage3DProxy._context3D.setTextureAt(1, null);
    }

    override private function updateTextures(stage:Stage3DProxy):Void {
        super.updateTextures(stage);
        updateBlurData();
    }

    private function updateBlurData():Void {
// todo: replace with view width once texture rendering is scissored?
        var invW:Float = 1 / _textureWidth;
        _data[0] = _maxBlur * .5 * invW;
        _data[1] = _realStepSize * invW;
    }

    private function calculateStepSize():Void {
        _realStepSize = _stepSize > (0) ? _stepSize : _maxBlur > (MAX_AUTO_SAMPLES) ? _maxBlur / MAX_AUTO_SAMPLES : 1;
    }

}

