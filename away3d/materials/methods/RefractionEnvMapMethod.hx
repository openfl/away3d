package away3d.materials.methods;

import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.textures.CubeTextureBase;

import openfl.Vector;

/**
 * RefractionEnvMapMethod provides a method to add refracted transparency based on cube maps.
 */
class RefractionEnvMapMethod extends EffectMethodBase
{
	public var envMap(get, set):CubeTextureBase;
	public var refractionIndex(get, set):Float;
	public var dispersionR(get, set):Float;
	public var dispersionG(get, set):Float;
	public var dispersionB(get, set):Float;
	public var alpha(get, set):Float;
	
	private var _envMap:CubeTextureBase;
	
	private var _dispersionR:Float = 0;
	private var _dispersionG:Float = 0;
	private var _dispersionB:Float = 0;
	private var _useDispersion:Bool;
	private var _refractionIndex:Float;
	private var _alpha:Float = 1;

	/**
	 * Creates a new RefractionEnvMapMethod object. Example values for dispersion are: dispersionR: -0.03, dispersionG: -0.01, dispersionB: = .0015
	 * @param envMap The environment map containing the refracted scene.
	 * @param refractionIndex The refractive index of the material.
	 * @param dispersionR The amount of chromatic dispersion of the red channel. Defaults to 0 (none).
	 * @param dispersionG The amount of chromatic dispersion of the green channel. Defaults to 0 (none).
	 * @param dispersionB The amount of chromatic dispersion of the blue channel. Defaults to 0 (none).
	 */
	public function new(envMap:CubeTextureBase, refractionIndex:Float = .1, dispersionR:Float = 0, dispersionG:Float = 0, dispersionB:Float = 0)
	{
		super();
		_envMap = envMap;
		_dispersionR = dispersionR;
		_dispersionG = dispersionG;
		_dispersionB = dispersionB;
		_useDispersion = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
		_refractionIndex = refractionIndex;
	}

	/**
	 * @inheritDoc
	 */
	override private function initConstants(vo:MethodVO):Void
	{
		var index:Int = vo.fragmentConstantsIndex;
		var data:Vector<Float> = vo.fragmentData;
		data[index + 4] = 1;
		data[index + 5] = 0;
		data[index + 7] = 1;
	}

	/**
	 * @inheritDoc
	 */
	override private function initVO(vo:MethodVO):Void
	{
		vo.needsNormals = true;
		vo.needsView = true;
	}
	
	/**
	 * The cube environment map to use for the refraction.
	 */
	private function get_envMap():CubeTextureBase
	{
		return _envMap;
	}
	
	private function set_envMap(value:CubeTextureBase):CubeTextureBase
	{
		_envMap = value;
		return value;
	}

	/**
	 * The refractive index of the material.
	 */
	private function get_refractionIndex():Float
	{
		return _refractionIndex;
	}
	
	private function set_refractionIndex(value:Float):Float
	{
		_refractionIndex = value;
		return value;
	}

	/**
	 * The amount of chromatic dispersion of the red channel. Defaults to 0 (none).
	 */
	private function get_dispersionR():Float
	{
		return _dispersionR;
	}
	
	private function set_dispersionR(value:Float):Float
	{
		_dispersionR = value;
		
		var useDispersion:Bool = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
		if (_useDispersion != useDispersion) {
			invalidateShaderProgram();
			_useDispersion = useDispersion;
		}
		return value;
	}

	/**
	 * The amount of chromatic dispersion of the green channel. Defaults to 0 (none).
	 */
	private function get_dispersionG():Float
	{
		return _dispersionG;
	}
	
	private function set_dispersionG(value:Float):Float
	{
		_dispersionG = value;
		
		var useDispersion:Bool = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
		if (_useDispersion != useDispersion) {
			invalidateShaderProgram();
			_useDispersion = useDispersion;
		}
		return value;
	}

	/**
	 * The amount of chromatic dispersion of the blue channel. Defaults to 0 (none).
	 */
	private function get_dispersionB():Float
	{
		return _dispersionB;
	}
	
	private function set_dispersionB(value:Float):Float
	{
		_dispersionB = value;
		
		var useDispersion:Bool = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
		if (_useDispersion != useDispersion) {
			invalidateShaderProgram();
			_useDispersion = useDispersion;
		}
		return value;
	}

	/**
	 * The amount of transparency of the object. Warning: the alpha applies to the refracted color, not the actual
	 * material. A value of 1 will make it appear fully transparent.
	 */
	private function get_alpha():Float
	{
		return _alpha;
	}
	
	private function set_alpha(value:Float):Float
	{
		_alpha = value;
		return value;
	}

	/**
	 * @inheritDoc
	 */
	override private function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		var index:Int = vo.fragmentConstantsIndex;
		var data:Vector<Float> = vo.fragmentData;
		data[index] = _dispersionR + _refractionIndex;
		if (_useDispersion) {
			data[index + 1] = _dispersionG + _refractionIndex;
			data[index + 2] = _dispersionB + _refractionIndex;
		}
		data[index + 3] = _alpha;
		stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _envMap.getTextureForStage3D(stage3DProxy));
	}

	/**
	 * @inheritDoc
	 */
	override private function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		// todo: data2.x could use common reg, so only 1 reg is used
		var data:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		var data2:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		var code:String = "";
		var cubeMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
		var refractionDir:ShaderRegisterElement;
		var refractionColor:ShaderRegisterElement;
		var temp:ShaderRegisterElement;
		
		vo.texturesIndex = cubeMapReg.index;
		vo.fragmentConstantsIndex = data.index*4;
		
		refractionDir = regCache.getFreeFragmentVectorTemp();
		regCache.addFragmentTempUsages(refractionDir, 1);
		refractionColor = regCache.getFreeFragmentVectorTemp();
		regCache.addFragmentTempUsages(refractionColor, 1);
		
		temp = regCache.getFreeFragmentVectorTemp();
		
		var viewDirReg:ShaderRegisterElement = _sharedRegisters.viewDirFragment;
		var normalReg:ShaderRegisterElement = _sharedRegisters.normalFragment;
		
		code += "neg " + viewDirReg + ".xyz, " + viewDirReg + ".xyz\n";
		
		code += "dp3 " + temp + ".x, " + viewDirReg + ".xyz, " + normalReg + ".xyz\n" +
			"mul " + temp + ".w, " + temp + ".x, " + temp + ".x\n" +
			"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
			"mul " + temp + ".w, " + data + ".x, " + temp + ".w\n" +
			"mul " + temp + ".w, " + data + ".x, " + temp + ".w\n" +
			"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
			"sqt " + temp + ".y, " + temp + ".w\n" +
			
			"mul " + temp + ".x, " + data + ".x, " + temp + ".x\n" +
			"add " + temp + ".x, " + temp + ".x, " + temp + ".y\n" +
			"mul " + temp + ".xyz, " + temp + ".x, " + normalReg + ".xyz\n" +
			
			"mul " + refractionDir + ", " + data + ".x, " + viewDirReg + "\n" +
			"sub " + refractionDir + ".xyz, " + refractionDir + ".xyz, " + temp + ".xyz\n" +
			"nrm " + refractionDir + ".xyz, " + refractionDir + ".xyz\n";
		
		code += getTexCubeSampleCode(vo, refractionColor, cubeMapReg, _envMap, refractionDir) +
			"sub " + refractionColor + ".w, " + refractionColor + ".w, fc0.x	\n" +
			"kil " + refractionColor + ".w\n";
		
		if (_useDispersion) {
			// GREEN
			
			code += "dp3 " + temp + ".x, " + viewDirReg + ".xyz, " + normalReg + ".xyz\n" +
				"mul " + temp + ".w, " + temp + ".x, " + temp + ".x\n" +
				"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
				"mul " + temp + ".w, " + data + ".y, " + temp + ".w\n" +
				"mul " + temp + ".w, " + data + ".y, " + temp + ".w\n" +
				"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
				"sqt " + temp + ".y, " + temp + ".w\n" +
				
				"mul " + temp + ".x, " + data + ".y, " + temp + ".x\n" +
				"add " + temp + ".x, " + temp + ".x, " + temp + ".y\n" +
				"mul " + temp + ".xyz, " + temp + ".x, " + normalReg + ".xyz\n" +
				
				"mul " + refractionDir + ", " + data + ".y, " + viewDirReg + "\n" +
				"sub " + refractionDir + ".xyz, " + refractionDir + ".xyz, " + temp + ".xyz\n" +
				"nrm " + refractionDir + ".xyz, " + refractionDir + ".xyz\n";
			//
			code += getTexCubeSampleCode(vo, temp, cubeMapReg, _envMap, refractionDir) +
				"mov " + refractionColor + ".y, " + temp + ".y\n";
			
			// BLUE
			
			code += "dp3 " + temp + ".x, " + viewDirReg + ".xyz, " + normalReg + ".xyz\n" +
				"mul " + temp + ".w, " + temp + ".x, " + temp + ".x\n" +
				"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
				"mul " + temp + ".w, " + data + ".z, " + temp + ".w\n" +
				"mul " + temp + ".w, " + data + ".z, " + temp + ".w\n" +
				"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
				"sqt " + temp + ".y, " + temp + ".w\n" +
				
				"mul " + temp + ".x, " + data + ".z, " + temp + ".x\n" +
				"add " + temp + ".x, " + temp + ".x, " + temp + ".y\n" +
				"mul " + temp + ".xyz, " + temp + ".x, " + normalReg + ".xyz\n" +
				
				"mul " + refractionDir + ", " + data + ".z, " + viewDirReg + "\n" +
				"sub " + refractionDir + ".xyz, " + refractionDir + ".xyz, " + temp + ".xyz\n" +
				"nrm " + refractionDir + ".xyz, " + refractionDir + ".xyz\n";
			
			code += getTexCubeSampleCode(vo, temp, cubeMapReg, _envMap, refractionDir) +
				"mov " + refractionColor + ".z, " + temp + ".z\n";
		}
		
		regCache.removeFragmentTempUsage(refractionDir);
		
		code += "sub " + refractionColor + ".xyz, " + refractionColor + ".xyz, " + targetReg + ".xyz\n" +
			"mul " + refractionColor + ".xyz, " + refractionColor + ".xyz, " + data + ".w\n" +
			"add " + targetReg + ".xyz, " + targetReg + ".xyz, " + refractionColor + ".xyz\n";
		regCache.removeFragmentTempUsage(refractionColor);
		
		// restore
		code += "neg " + viewDirReg + ".xyz, " + viewDirReg + ".xyz\n";
		
		return code;
	}
}