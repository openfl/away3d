package away3d.materials.methods;

import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.textures.Texture2DBase;
import away3d.textures.TextureProxyBase;

import openfl.display3D.Context3D;
import openfl.errors.Error;
import openfl.Vector;

/**
 * TerrainDiffuseMethod provides a diffuse method that uses different tiled textures with alpha masks to create a
 * large surface with high detail and less apparent tiling.
 */
class TerrainDiffuseMethod extends BasicDiffuseMethod
{
	private var _blendingTexture:Texture2DBase;
	private var _splats:Vector<Texture2DBase>;
	private var _numSplattingLayers:Int;
	private var _tileData:Array<Float>;
	
	/**
	 * Creates a new TerrainDiffuseMethod.
	 * @param splatTextures An array of Texture2DProxyBase containing the detailed textures to be tiled.
	 * @param blendingTexture The texture containing the blending data. The red, green, and blue channels contain the blending values for each of the textures in splatTextures, respectively.
	 * @param tileData The amount of times each splat texture needs to be tiled. The first entry in the array applies to the base texture, the others to the splats. If omitted, the default value of 50 is assumed for each.
	 */
	public function new(splatTextures:Array<Texture2DBase>, blendingTexture:Texture2DBase, tileData:Array<Float>)
	{
		super();
		_splats = Vector.ofArray(splatTextures);
		_tileData = tileData;
		_blendingTexture = blendingTexture;
		_numSplattingLayers = _splats.length;
		if (_numSplattingLayers > 4)
			throw new Error("More than 4 splatting layers is not supported!");
	}

	/**
	 * @inheritDoc
	 */
	override private function initConstants(vo:MethodVO):Void
	{
		var data:Vector<Float> = vo.fragmentData;
		var index:Int = vo.fragmentConstantsIndex;
		data[index] = (_tileData != null) ? _tileData[0] : 1;
		for (i in 0..._numSplattingLayers) {
			if (i < 3)
				data[(index + i + 1)] = (_tileData != null) ? _tileData[i + 1] : 50;
			else
				data[(index + i - 4)] = (_tileData != null) ? _tileData[i + 1] : 50;
		}
	}

	/**
	 * @inheritDoc
	 */
	override private function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var code:String = "";
		var albedo:ShaderRegisterElement = null;
		var scaleRegister:ShaderRegisterElement = null;
		var scaleRegister2:ShaderRegisterElement = null;
		
		// incorporate input from ambient
		if (vo.numLights > 0) {
			if (_shadowRegister != null)
				code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + _shadowRegister + ".w\n";
			code += "add " + targetReg + ".xyz, " + _totalLightColorReg + ".xyz, " + targetReg + ".xyz\n" +
				"sat " + targetReg + ".xyz, " + targetReg + ".xyz\n";
			regCache.removeFragmentTempUsage(_totalLightColorReg);
			
			albedo = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(albedo, 1);
		} else
			albedo = targetReg;
		
		if (!_useTexture)
			throw new Error("TerrainDiffuseMethod requires a diffuse texture!");
		_diffuseInputRegister = regCache.getFreeTextureReg();
		vo.texturesIndex = _diffuseInputRegister.index;
		var blendTexReg:ShaderRegisterElement = regCache.getFreeTextureReg();
		
		scaleRegister = regCache.getFreeFragmentConstant();
		if (_numSplattingLayers == 4)
			scaleRegister2 = regCache.getFreeFragmentConstant();
		
		var uv:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		regCache.addFragmentTempUsages(uv, 1);
		
		var uvReg:ShaderRegisterElement = _sharedRegisters.uvVarying;
		
		code += "mul " + uv + ", " + uvReg + ", " + scaleRegister + ".x\n" +
			getSplatSampleCode(vo, albedo, _diffuseInputRegister, texture, uv);
		
		var blendValues:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		regCache.addFragmentTempUsages(blendValues, 1);
		code += getTex2DSampleCode(vo, blendValues, blendTexReg, _blendingTexture, uvReg, "clamp");
		var splatTexReg:ShaderRegisterElement;
		
		vo.fragmentConstantsIndex = scaleRegister.index*4;
		var comps:Vector<String> = Vector.ofArray([ ".x", ".y", ".z", ".w" ]);
		
		for (i in 0..._numSplattingLayers) {
			var scaleRegName:String = i < 3? scaleRegister + comps[i + 1] : scaleRegister2 + comps[i - 3];
			splatTexReg = regCache.getFreeTextureReg();
			code += "mul " + uv + ", " + uvReg + ", " + scaleRegName + "\n" +
				getSplatSampleCode(vo, uv, splatTexReg, _splats[i], uv);
			
			code += "sub " + uv + ", " + uv + ", " + albedo + "\n" +
				"mul " + uv + ", " + uv + ", " + blendValues + comps[i] + "\n" +
				"add " + albedo + ", " + albedo + ", " + uv + "\n";
		}
		regCache.removeFragmentTempUsage(uv);
		regCache.removeFragmentTempUsage(blendValues);
		
		if (vo.numLights > 0) {
			code += "mul " + targetReg + ".xyz, " + albedo + ".xyz, " + targetReg + ".xyz\n" +
				"mov " + targetReg + ".w, " + albedo + ".w\n";
			
			regCache.removeFragmentTempUsage(albedo);
		}
		
		return code;
	}

	/**
	 * @inheritDoc
	 */
	override private function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		var context:Context3D = stage3DProxy._context3D;
		var i:Int;
		var texIndex:Int = vo.texturesIndex;
		super.activate(vo, stage3DProxy);
		context.setTextureAt(texIndex + 1, _blendingTexture.getTextureForStage3D(stage3DProxy));
		
		texIndex += 2;
		for (i in 0..._numSplattingLayers)
			context.setTextureAt(i + texIndex, _splats[i].getTextureForStage3D(stage3DProxy));
	}

	/**
	 * @inheritDoc
	 */
	override private function set_alphaThreshold(value:Float):Float
	{
		if (value > 0)
			throw new Error("Alpha threshold not supported for TerrainDiffuseMethod");
		return value;
	}

	/**
	 * Gets the sample code for a single splat.
	 */
	private function getSplatSampleCode(vo:MethodVO, targetReg:ShaderRegisterElement, inputReg:ShaderRegisterElement, texture:TextureProxyBase, uvReg:ShaderRegisterElement = null):String
	{
		if (uvReg == null)
			uvReg = _sharedRegisters.uvVarying;
		return getTex2DSampleCode(vo, targetReg, inputReg, texture, uvReg, "wrap");
	}
}