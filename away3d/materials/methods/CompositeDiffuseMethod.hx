package away3d.materials.methods;

import away3d.core.managers.Stage3DProxy;
import away3d.events.ShadingMethodEvent;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterData;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.textures.Texture2DBase;

/**
 * CompositeDiffuseMethod provides a base class for diffuse methods that wrap a diffuse method to alter the
 * calculated diffuse reflection strength.
 */
class CompositeDiffuseMethod extends BasicDiffuseMethod
{
	public var baseMethod(get, set):BasicDiffuseMethod;
	
	private var _baseMethod:BasicDiffuseMethod;
	
	/**
	 * Creates a new WrapDiffuseMethod object.
	 * @param modulateMethod The method which will add the code to alter the base method's strength. It needs to have the signature clampDiffuse(t : ShaderRegisterElement, regCache : ShaderRegisterCache) : String, in which t.w will contain the diffuse strength.
	 * @param baseDiffuseMethod The base diffuse method on which this method's shading is based.
	 */
	public function new(modulateMethod:Dynamic = null, ?baseDiffuseMethod:BasicDiffuseMethod = null)
	{
		_baseMethod = baseDiffuseMethod;
		if (_baseMethod == null) _baseMethod = new BasicDiffuseMethod();
		_baseMethod._modulateMethod = modulateMethod;
		_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		super();
	}

	/**
	 * The base diffuse method on which this method's shading is based.
	 */
	private function get_baseMethod():BasicDiffuseMethod
	{
		return _baseMethod;
	}

	private function set_baseMethod(value:BasicDiffuseMethod):BasicDiffuseMethod
	{
		if (_baseMethod == value)
			return value;
		_baseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		_baseMethod = value;
		_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated, false, 0, true);
		invalidateShaderProgram();
		return value;
	}

	/**
	 * @inheritDoc
	 */
	override private function initVO(vo:MethodVO):Void
	{
		_baseMethod.initVO(vo);
	}

	/**
	 * @inheritDoc
	 */
	override private function initConstants(vo:MethodVO):Void
	{
		_baseMethod.initConstants(vo);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function dispose():Void
	{
		_baseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		_baseMethod.dispose();
	}

	/**
	 * @inheritDoc
	 */
	override private function get_alphaThreshold():Float
	{
		return _baseMethod.alphaThreshold;
	}
	
	override private function set_alphaThreshold(value:Float):Float
	{
		_baseMethod.alphaThreshold = value;
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function get_texture():Texture2DBase
	{
		return _baseMethod.texture;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function set_texture(value:Texture2DBase):Texture2DBase
	{
		_baseMethod.texture = value;
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function get_diffuseAlpha():Float
	{
		return _baseMethod.diffuseAlpha;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function get_diffuseColor():Int
	{
		return _baseMethod.diffuseColor;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function set_diffuseColor(diffuseColor:Int):Int
	{
		_baseMethod.diffuseColor = diffuseColor;
		return diffuseColor;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function set_diffuseAlpha(value:Float):Float
	{
		_baseMethod.diffuseAlpha = value;
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		return _baseMethod.getFragmentPreLightingCode(vo, regCache);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getFragmentCodePerLight(vo:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String
	{
		var code:String = _baseMethod.getFragmentCodePerLight(vo, lightDirReg, lightColReg, regCache);
		_totalLightColorReg = _baseMethod._totalLightColorReg;
		return code;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getFragmentCodePerProbe(vo:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, regCache:ShaderRegisterCache):String
	{
		var code:String = _baseMethod.getFragmentCodePerProbe(vo, cubeMapReg, weightRegister, regCache);
		_totalLightColorReg = _baseMethod._totalLightColorReg;
		return code;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		_baseMethod.activate(vo, stage3DProxy);
	}

	/**
	 * @inheritDoc
	 */
	override private function deactivate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		_baseMethod.deactivate(vo, stage3DProxy);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		return _baseMethod.getVertexCode(vo, regCache);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		return _baseMethod.getFragmentPostLightingCode(vo, regCache, targetReg);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function reset():Void
	{
		_baseMethod.reset();
	}

	/**
	 * @inheritDoc
	 */
	override private function cleanCompilationData():Void
	{
		super.cleanCompilationData();
		_baseMethod.cleanCompilationData();
	}
	
	/**
	 * @inheritDoc
	 */
	override private function set_sharedRegisters(value:ShaderRegisterData):ShaderRegisterData
	{
		super.sharedRegisters = _baseMethod.sharedRegisters = value;
		return value;
	}

	/**
	 * @inheritDoc
	 */
	override private function set_shadowRegister(value:ShaderRegisterElement):ShaderRegisterElement
	{
		super.shadowRegister = value;
		_baseMethod.shadowRegister = value;
		return value;
	}

	/**
	 * Called when the base method's shader code is invalidated.
	 */
	private function onShaderInvalidated(event:ShadingMethodEvent):Void
	{
		invalidateShaderProgram();
	}
}