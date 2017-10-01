package away3d.materials.methods;

import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.textures.Texture2DBase;

import openfl.display.BlendMode;
import openfl.errors.Error;

/**
 * LightMapDiffuseMethod provides a diffuse shading method that uses a light map to modulate the calculated diffuse
 * lighting. It is different from LightMapMethod in that the latter modulates the entire calculated pixel color, rather
 * than only the diffuse lighting value.
 */
class LightMapDiffuseMethod extends CompositeDiffuseMethod
{
	public var blendMode(get, set):BlendMode;
	public var lightMapTexture(get, set):Texture2DBase;
	
	/**
	 * Indicates the light map should be multiplied with the calculated shading result.
	 * This can be used to add pre-calculated shadows or occlusion.
	 */
	public static inline var MULTIPLY:BlendMode = BlendMode.MULTIPLY;

	/**
	 * Indicates the light map should be added into the calculated shading result.
	 * This can be used to add pre-calculated lighting or global illumination.
	 */
	public static inline var ADD:BlendMode = BlendMode.ADD;
	
	//private var _texture:Texture2DBase;
	private var _blendMode:BlendMode;
	private var _useSecondaryUV:Bool;
	
	/**
	 * Creates a new LightMapDiffuseMethod method.
	 * @param lightMap The texture containing the light map.
	 * @param blendMode The blend mode with which the light map should be applied to the lighting result.
	 * @param useSecondaryUV Indicates whether the secondary UV set should be used to map the light map.
	 * @param baseMethod The diffuse method used to calculate the regular light-based lighting.
	 */
	public function new(lightMap:Texture2DBase, blendMode:BlendMode = BlendMode.MULTIPLY, useSecondaryUV:Bool = false, baseMethod:BasicDiffuseMethod = null)
	{
		super(null, baseMethod);
		_useSecondaryUV = useSecondaryUV;
		_texture = lightMap;
		this.blendMode = blendMode;
	}

	/**
	 * @inheritDoc
	 */
	override private function initVO(vo:MethodVO):Void
	{
		vo.needsSecondaryUV = _useSecondaryUV;
		vo.needsUV = !_useSecondaryUV;
	}

	/**
	 * The blend mode with which the light map should be applied to the lighting result.
	 *
	 * @see LightMapDiffuseMethod.ADD
	 * @see LightMapDiffuseMethod.MULTIPLY
	 */
	private function get_blendMode():BlendMode
	{
		return _blendMode;
	}
	
	private function set_blendMode(value:BlendMode):BlendMode
	{
		if (value != LightMapDiffuseMethod.ADD && value != LightMapDiffuseMethod.MULTIPLY)
			throw new Error("Unknown blendmode!");
		if (_blendMode == value)
			return value;
		_blendMode = value;
		invalidateShaderProgram();
		return value;
	}

	/**
	 * The texture containing the light map data.
	 */
	private function get_lightMapTexture():Texture2DBase
	{
		return _texture;
	}
	
	private function set_lightMapTexture(value:Texture2DBase):Texture2DBase
	{
		_texture = value;
		return value;
	}

	/**
	 * @inheritDoc
	 */
	override private function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		stage3DProxy._context3D.setTextureAt(vo.secondaryTexturesIndex, _texture.getTextureForStage3D(stage3DProxy));
		super.activate(vo, stage3DProxy);
	}

	/**
	 * @inheritDoc
	 */
	override private function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var code:String;
		var lightMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
		var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		vo.secondaryTexturesIndex = lightMapReg.index;
		
		code = getTex2DSampleCode(vo, temp, lightMapReg, _texture, _sharedRegisters.secondaryUVVarying);
		
		switch(_blendMode) {
			case MULTIPLY:
				code += "mul " + _totalLightColorReg + ", " + _totalLightColorReg + ", " + temp + "\n";
			case ADD:
				code += "add " + _totalLightColorReg + ", " + _totalLightColorReg + ", " + temp + "\n";
			default:
		}
		
		code += super.getFragmentPostLightingCode(vo, regCache, targetReg);
		
		return code;
	}
}