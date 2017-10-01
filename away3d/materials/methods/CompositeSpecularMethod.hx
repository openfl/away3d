package away3d.materials.methods;

import away3d.materials.compilation.ShaderRegisterElement;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterData;
import away3d.textures.Texture2DBase;
import away3d.materials.passes.MaterialPassBase;
import away3d.events.ShadingMethodEvent;

import openfl.Vector;

/**
 * CompositeSpecularMethod provides a base class for specular methods that wrap a specular method to alter the
 * calculated specular reflection strength.
 */
class CompositeSpecularMethod extends BasicSpecularMethod
{
	public var baseMethod(get, set):BasicSpecularMethod;
	
	private var _baseMethod:BasicSpecularMethod;
	
	/**
	 * Creates a new WrapSpecularMethod object.
	 * @param modulateMethod The method which will add the code to alter the base method's strength. It needs to have the signature modSpecular(t : ShaderRegisterElement, regCache : ShaderRegisterCache) : String, in which t.w will contain the specular strength and t.xyz will contain the half-vector or the reflection vector.
	 * @param baseSpecularMethod The base specular method on which this method's shading is based.
	 */
	public function new(modulateMethod:Dynamic, baseSpecularMethod:BasicSpecularMethod = null)
	{
		super();
		_baseMethod = baseSpecularMethod;
		if (_baseMethod == null)_baseMethod = new BasicSpecularMethod();
		_baseMethod._modulateMethod = modulateMethod;
		_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
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
	 * The base specular method on which this method's shading is based.
	 */
	private function get_baseMethod():BasicSpecularMethod
	{
		return _baseMethod;
	}
	
	private function set_baseMethod(value:BasicSpecularMethod):BasicSpecularMethod
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
	override private function get_gloss():Float
	{
		return _baseMethod.gloss;
	}
	
	override private function set_gloss(value:Float):Float
	{
		_baseMethod.gloss = value;
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function get_specular():Float
	{
		return _baseMethod.specular;
	}
	
	override private function set_specular(value:Float):Float
	{
		_baseMethod.specular = value;
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function get_passes():Vector<MaterialPassBase>
	{
		return _baseMethod.passes;
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
	override private function get_texture():Texture2DBase
	{
		return _baseMethod.texture;
	}
	
	override private function set_texture(value:Texture2DBase):Texture2DBase
	{
		_baseMethod.texture = value;
		return value;
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
	override private function set_sharedRegisters(value:ShaderRegisterData):ShaderRegisterData
	{
		super.sharedRegisters = _baseMethod.sharedRegisters = value;
		return value;
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
	override private function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		return _baseMethod.getFragmentPreLightingCode(vo, regCache);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getFragmentCodePerLight(vo:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String
	{
		return _baseMethod.getFragmentCodePerLight(vo, lightDirReg, lightColReg, regCache);
	}
	
	/**
	 * @inheritDoc
	 * @return
	 */
	override private function getFragmentCodePerProbe(vo:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, regCache:ShaderRegisterCache):String
	{
		return _baseMethod.getFragmentCodePerProbe(vo, cubeMapReg, weightRegister, regCache);
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