package away3d.materials.methods;

import openfl.errors.Error;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;

import openfl.Vector;

/**
 * DepthDiffuseMethod provides a debug method to visualise depth maps
 */
class DepthDiffuseMethod extends BasicDiffuseMethod {

	/**
	 * Creates a new BasicDiffuseMethod object.
	 */
	public function new() {
		super();
	}

	/**
	 * @inheritDoc
	 */
	override private function initConstants(vo:MethodVO):Void
	{
		var data:Vector<Float> = vo.fragmentData;
		var index:Int = vo.fragmentConstantsIndex;
		data[index] = 1.0;
		data[index + 1] = 1/255.0;
		data[index + 2] = 1/65025.0;
		data[index + 3] = 1/16581375.0;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var code:String = "";
		var temp:ShaderRegisterElement;
		var decReg:ShaderRegisterElement;
		
		if (!_useTexture)
			throw new Error("DepthDiffuseMethod requires texture!");
		
		// incorporate input from ambient
		if (vo.numLights > 0) {
			if (_shadowRegister != null)
				code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + _shadowRegister + ".w\n";
			code += "add " + targetReg + ".xyz, " + _totalLightColorReg + ".xyz, " + targetReg + ".xyz\n" +
				"sat " + targetReg + ".xyz, " + targetReg + ".xyz\n";
			regCache.removeFragmentTempUsage(_totalLightColorReg);
		}
		
		temp = vo.numLights > 0? regCache.getFreeFragmentVectorTemp() : targetReg;
		
		_diffuseInputRegister = regCache.getFreeTextureReg();
		vo.texturesIndex = _diffuseInputRegister.index;
		decReg = regCache.getFreeFragmentConstant();
		vo.fragmentConstantsIndex = decReg.index*4;
		code += getTex2DSampleCode(vo, temp, _diffuseInputRegister, texture) +
			"dp4 " + temp + ".x, " + temp + ", " + decReg + "\n" +
			"mov " + temp + ".yz, " + temp + ".xx			\n" +
			"mov " + temp + ".w, " + decReg + ".x\n" +
			"sub " + temp + ".xyz, " + decReg + ".xxx, " + temp + ".xyz\n";
		
		if (vo.numLights == 0)
			return code;
		
		code += "mul " + targetReg + ".xyz, " + temp + ".xyz, " + targetReg + ".xyz\n" +
			"mov " + targetReg + ".w, " + temp + ".w\n";
		
		return code;
	}
}