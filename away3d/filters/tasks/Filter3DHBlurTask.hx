package away3d.filters.tasks;

import away3d.cameras.Camera3D;
import away3d.core.managers.Stage3DProxy;

import openfl.display3D.Context3DProgramType;
import openfl.display3D.textures.Texture;
import openfl.Vector;

class Filter3DHBlurTask extends Filter3DTaskBase
{
	public var amount(get, set):Int;
	public var stepSize(get, set):Int;
	
	private static inline var MAX_AUTO_SAMPLES:Int = 15;
	private var _amount:Int;
	private var _data:Vector<Float>;
	private var _stepSize:Int = 1;
	private var _realStepSize:Float;
	
	/**
	 * Creates a new Filter3DHDepthOfFFieldTask
	 * @param amount The maximum amount of blur to apply in pixels at the most out-of-focus areas
	 * @param stepSize The distance between samples. Set to -1 to autodetect with acceptable quality.
	 */
	public function new(amount:Int, stepSize:Int = -1)
	{
		super();
		_amount = amount;
		_data = Vector.ofArray([ 0.0, 0.0, 0.0, 1.0 ]);
		this.stepSize = stepSize;
	}
	
	private function get_amount():Int
	{
		return _amount;
	}
	
	private function set_amount(value:Int):Int
	{
		if (value == _amount)
			return value;
		_amount = value;
		
		invalidateProgram3D();
		updateBlurData();
		calculateStepSize();
		return value;
	}
	
	private function get_stepSize():Int
	{
		return _stepSize;
	}
	
	private function set_stepSize(value:Int):Int
	{
		if (value == _stepSize)
			return value;
		_stepSize = value;
		calculateStepSize();
		invalidateProgram3D();
		updateBlurData();
		return value;
	}
	
	override private function getFragmentCode():String
	{
		var code:String;
		var numSamples:Int = 1;
		
		code = "mov ft0, v0	\n" +
			"sub ft0.x, v0.x, fc0.x\n";
		
		code += "tex ft1, ft0, fs0 <2d,linear,clamp>\n";
		
		var x:Float = _realStepSize;
		while (x <= _amount) {
			code += "add ft0.x, ft0.x, fc0.y	\n" +
				"tex ft2, ft0, fs0 <2d,linear,clamp>\n" +
				"add ft1, ft1, ft2 \n";
			++numSamples;
			x += _realStepSize;
		}
		
		code += "mul oc, ft1, fc0.z";
		
		_data[2] = 1/numSamples;
		
		return code;
	}
	
	override public function activate(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:Texture):Void
	{
		stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 1);
	}
	
	override private function updateTextures(stage:Stage3DProxy):Void
	{
		super.updateTextures(stage);
		
		updateBlurData();
	}
	
	private function updateBlurData():Void
	{
		// todo: must be normalized using view size ratio instead of texture
		var invW:Float = 1 / _textureWidth;
		
		_data[0] = _amount*.5*invW;
		_data[1] = _realStepSize*invW;
	}
	
	private function calculateStepSize():Void
	{
		_realStepSize = _stepSize > 0? _stepSize :
			_amount > MAX_AUTO_SAMPLES? _amount/MAX_AUTO_SAMPLES :
			1;
	
	}
}