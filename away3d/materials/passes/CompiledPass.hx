package away3d.materials.passes;

import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.core.math.Matrix3DUtils;
import away3d.errors.AbstractMethodError;
import away3d.events.ShadingMethodEvent;
import away3d.materials.LightSources;
import away3d.materials.MaterialBase;
import away3d.materials.compilation.ShaderCompiler;
import away3d.materials.methods.BasicAmbientMethod;
import away3d.materials.methods.BasicDiffuseMethod;
import away3d.materials.methods.BasicNormalMethod;
import away3d.materials.methods.BasicSpecularMethod;
import away3d.materials.methods.MethodVOSet;
import away3d.materials.methods.ShaderMethodSetup;
import away3d.materials.methods.ShadowMapMethodBase;
import away3d.textures.Texture2DBase;
import away3d.textures.Anisotropy;

import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.geom.Matrix;
import openfl.geom.Matrix3D;
import openfl.Vector;

/**
 * CompiledPass forms an abstract base class for the default compiled pass materials provided by Away3D,
 * using material methods to define their appearance.
 */
class CompiledPass extends MaterialPassBase
{
	public var enableLightFallOff(get, set):Bool;
	public var forceSeparateMVP(get, set):Bool;
	public var numPointLights(get, never):Int;
	public var numDirectionalLights(get, never):Int;
	public var numLightProbes(get, never):Int;
	public var preserveAlpha(get, set):Bool;
	public var animateUVs(get, set):Bool;
	public var animateUVs2(get, set):Bool;
	public var normalMap(get, set):Texture2DBase;
	public var normalMethod(get, set):BasicNormalMethod;
	public var ambientMethod(get, set):BasicAmbientMethod;
	public var shadowMethod(get, set):ShadowMapMethodBase;
	public var diffuseMethod(get, set):BasicDiffuseMethod;
	public var specularMethod(get, set):BasicSpecularMethod;
	public var specularLightSources(get, set):Int;
	public var diffuseLightSources(get, set):Int;
	
	public var _passes:Vector<MaterialPassBase>;
	public var _passesDirty:Bool;
	
	private var _specularLightSources:Int = 0x01;
	private var _diffuseLightSources:Int = 0x03;
	
	private var _vertexCode:String;
	private var _fragmentLightCode:String;
	private var _framentPostLightCode:String;
	
	private var _vertexConstantData:Vector<Float> = new Vector<Float>();
	private var _fragmentConstantData:Vector<Float> = new Vector<Float>();
	private var _commonsDataIndex:Int;
	private var _probeWeightsIndex:Int;
	private var _uvBufferIndex:Int;
	private var _secondaryUVBufferIndex:Int;
	private var _normalBufferIndex:Int;
	private var _tangentBufferIndex:Int;
	private var _sceneMatrixIndex:Int;
	private var _sceneNormalMatrixIndex:Int;
	private var _lightFragmentConstantIndex:Int;
	private var _cameraPositionIndex:Int;
	private var _uvTransformIndex:Int;
	private var _uvTransformIndex2:Int;
	private var _lightProbeDiffuseIndices:Vector<UInt>;
	private var _lightProbeSpecularIndices:Vector<UInt>;
	
	private var _ambientLightR:Float;
	private var _ambientLightG:Float;
	private var _ambientLightB:Float;
	
	private var _compiler:ShaderCompiler;
	
	private var _methodSetup:ShaderMethodSetup;
	
	private var _usingSpecularMethod:Bool;
	private var _usesNormals:Bool;
	private var _preserveAlpha:Bool = true;
	private var _animateUVs:Bool;
	private var _animateUVs2:Bool;
	
	private var _numPointLights:Int;
	private var _numDirectionalLights:Int;
	private var _numLightProbes:Int;
	
	private var _enableLightFallOff:Bool = true;
	
	private var _forceSeparateMVP:Bool;

	/**
	 * Creates a new CompiledPass object.
	 * @param material The material to which this pass belongs.
	 */
	public function new(material:MaterialBase)
	{
		_material = material;
		
		init();
		super();
	}

	/**
	 * Whether or not to use fallOff and radius properties for lights. This can be used to improve performance and
	 * compatibility for constrained mode.
	 */
	private function get_enableLightFallOff():Bool
	{
		return _enableLightFallOff;
	}
	
	private function set_enableLightFallOff(value:Bool):Bool
	{
		if (value != _enableLightFallOff)
			invalidateShaderProgram(true);
		_enableLightFallOff = value;
		return value;
	}

	/**
	 * Indicates whether the screen projection should be calculated by forcing a separate scene matrix and
	 * view-projection matrix. This is used to prevent rounding errors when using multiple passes with different
	 * projection code.
	 */
	private function get_forceSeparateMVP():Bool
	{
		return _forceSeparateMVP;
	}
	
	private function set_forceSeparateMVP(value:Bool):Bool
	{
		_forceSeparateMVP = value;
		return value;
	}

	/**
	 * The amount of point lights that need to be supported.
	 */
	private function get_numPointLights():Int
	{
		return _numPointLights;
	}

	/**
	 * The amount of directional lights that need to be supported.
	 */
	private function get_numDirectionalLights():Int
	{
		return _numDirectionalLights;
	}

	/**
	 * The amount of light probes that need to be supported.
	 */
	private function get_numLightProbes():Int
	{
		return _numLightProbes;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateProgram(stage3DProxy:Stage3DProxy):Void
	{
		reset(stage3DProxy.profile);
		super.updateProgram(stage3DProxy);
	}
	
	/**
	 * Resets the compilation state.
	 *
	 * @param profile The compatibility profile used by the renderer.
	 */
	private function reset(profile:String):Void
	{
		initCompiler(profile);
		updateShaderProperties();
		initConstantData();
		cleanUp();
	}

	/**
	 * Updates the amount of used register indices.
	 */
	private function updateUsedOffsets():Void
	{
		_numUsedVertexConstants = _compiler.numUsedVertexConstants;
		_numUsedFragmentConstants = _compiler.numUsedFragmentConstants;
		_numUsedStreams = _compiler.numUsedStreams;
		_numUsedTextures = _compiler.numUsedTextures;
		_numUsedVaryings = _compiler.numUsedVaryings;
		_numUsedFragmentConstants = _compiler.numUsedFragmentConstants;
	}

	/**
	 * Initializes the unchanging constant data for this material.
	 */
	private function initConstantData():Void
	{
		_vertexConstantData.length = _numUsedVertexConstants*4;
		_fragmentConstantData.length = _numUsedFragmentConstants*4;
		
		initCommonsData();
		if (_uvTransformIndex >= 0)
			initUVTransformData();
		if (_cameraPositionIndex >= 0)
			_vertexConstantData[_cameraPositionIndex + 3] = 1;
		
		updateMethodConstants();
	}

	/**
	 * Initializes the compiler for this pass.
	 * @param profile The compatibility profile used by the renderer.
	 */
	private function initCompiler(profile:String):Void
	{
		_compiler = createCompiler(profile);
		_compiler.forceSeperateMVP = _forceSeparateMVP;
		_compiler.numPointLights = _numPointLights;
		_compiler.numDirectionalLights = _numDirectionalLights;
		_compiler.numLightProbes = _numLightProbes;
		_compiler.methodSetup = _methodSetup;
		_compiler.diffuseLightSources = _diffuseLightSources;
		_compiler.specularLightSources = _specularLightSources;
		_compiler.setTextureSampling(_smooth, _repeat, _mipmap, _anisotropy);
		_compiler.setConstantDataBuffers(_vertexConstantData, _fragmentConstantData);
		_compiler.animateUVs = _animateUVs;
		_compiler.animateUVs2 = _animateUVs2;
		_compiler.alphaPremultiplied = _alphaPremultiplied && _enableBlending;
		_compiler.preserveAlpha = _preserveAlpha && _enableBlending;
		_compiler.enableLightFallOff = _enableLightFallOff;
		_compiler.compile();
	}

	/**
	 * Factory method to create a concrete compiler object for this pass.
	 * @param profile The compatibility profile used by the renderer.
	 */
	private function createCompiler(profile:String):ShaderCompiler
	{
		throw new AbstractMethodError();
		return null;
	}

	/**
	 * Copies the shader's properties from the compiler.
	 */
	private function updateShaderProperties():Void
	{
		_animatableAttributes = _compiler.animatableAttributes;
		_animationTargetRegisters = _compiler.animationTargetRegisters;
		_vertexCode = _compiler.vertexCode;
		_fragmentLightCode = _compiler.fragmentLightCode;
		_framentPostLightCode = _compiler.fragmentPostLightCode;
		_shadedTarget = _compiler.shadedTarget;
		_usingSpecularMethod = _compiler.usingSpecularMethod;
		_usesNormals = _compiler.usesNormals;
		_needUVAnimation = _compiler.needUVAnimation;
		_UVSource = _compiler.UVSource;
		_UVTarget = _compiler.UVTarget;
		
		updateRegisterIndices();
		updateUsedOffsets();
	}

	/**
	 * Updates the indices for various registers.
	 */
	private function updateRegisterIndices():Void
	{
		_uvBufferIndex = _compiler.uvBufferIndex;
		_uvTransformIndex = _compiler.uvTransformIndex;
		_uvTransformIndex2 = _compiler.uvTransformIndex2;
		_secondaryUVBufferIndex = _compiler.secondaryUVBufferIndex;
		_normalBufferIndex = _compiler.normalBufferIndex;
		_tangentBufferIndex = _compiler.tangentBufferIndex;
		_lightFragmentConstantIndex = _compiler.lightFragmentConstantIndex;
		_cameraPositionIndex = _compiler.cameraPositionIndex;
		_commonsDataIndex = _compiler.commonsDataIndex;
		_sceneMatrixIndex = _compiler.sceneMatrixIndex;
		_sceneNormalMatrixIndex = _compiler.sceneNormalMatrixIndex;
		_probeWeightsIndex = _compiler.probeWeightsIndex;
		_lightProbeDiffuseIndices = _compiler.lightProbeDiffuseIndices;
		_lightProbeSpecularIndices = _compiler.lightProbeSpecularIndices;
	}

	/**
	 * Indicates whether the output alpha value should remain unchanged compared to the material's original alpha.
	 */
	private function get_preserveAlpha():Bool 
	{
		return _preserveAlpha;
	}
	
	private function set_preserveAlpha(value:Bool):Bool
	{
		if (_preserveAlpha == value)
			return value;
		_preserveAlpha = value;
		invalidateShaderProgram();
		return value;
	}

	/**
	 * Indicate whether UV coordinates need to be animated using the renderable's transformUV matrix.
	 */
	private function get_animateUVs():Bool
	{
		return _animateUVs;
	}
	
	private function set_animateUVs(value:Bool):Bool
	{
		if (_animateUVs == value)
			return value;
		
		_animateUVs = value;
		invalidateShaderProgram();
		return value;
	}
	
	/**
	 * Indicate whether UV coordinates need to be animated using the renderable's transformUV matrix.
	 */
	private function get_animateUVs2():Bool
	{
		return _animateUVs2;
	}

	private function set_animateUVs2(value:Bool):Bool
	{
		if (_animateUVs2 == value) return value;
		_animateUVs2 = value;
		invalidateShaderProgram();
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function set_mipmap(value:Bool):Bool
	{
		if (_mipmap == value)
			return value;
		super.mipmap = value;
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function set_anisotropy(value:Anisotropy):Anisotropy
	{
		if (_anisotropy == value)
			return value;
		super.anisotropy = value;
		return value;
	}

	/**
	 * The normal map to modulate the direction of the surface for each texel. The default normal method expects
	 * tangent-space normal maps, but others could expect object-space maps.
	 */
	private function get_normalMap():Texture2DBase
	{
		return _methodSetup._normalMethod.normalMap;
	}
	
	private function set_normalMap(value:Texture2DBase):Texture2DBase
	{
		_methodSetup._normalMethod.normalMap = value;
		return value;
	}

	/**
	 * The method used to generate the per-pixel normals. Defaults to BasicNormalMethod.
	 */
	private function get_normalMethod():BasicNormalMethod
	{
		return _methodSetup.normalMethod;
	}
	
	private function set_normalMethod(value:BasicNormalMethod):BasicNormalMethod
	{
		_methodSetup.normalMethod = value;
		return value;
	}

	/**
	 * The method that provides the ambient lighting contribution. Defaults to BasicAmbientMethod.
	 */
	private function get_ambientMethod():BasicAmbientMethod
	{
		return _methodSetup.ambientMethod;
	}
	
	private function set_ambientMethod(value:BasicAmbientMethod):BasicAmbientMethod
	{
		_methodSetup.ambientMethod = value;
		return value;
	}

	/**
	 * The method used to render shadows cast on this surface, or null if no shadows are to be rendered. Defaults to null.
	 */
	private function get_shadowMethod():ShadowMapMethodBase
	{
		return _methodSetup.shadowMethod;
	}
	
	private function set_shadowMethod(value:ShadowMapMethodBase):ShadowMapMethodBase
	{
		_methodSetup.shadowMethod = value;
		return value;
	}

	/**
	 * The method that provides the diffuse lighting contribution. Defaults to BasicDiffuseMethod.
	 */
	private function get_diffuseMethod():BasicDiffuseMethod
	{
		return _methodSetup.diffuseMethod;
	}
	
	private function set_diffuseMethod(value:BasicDiffuseMethod):BasicDiffuseMethod
	{
		_methodSetup.diffuseMethod = value;
		return value;
	}

	/**
	 * The method that provides the specular lighting contribution. Defaults to BasicSpecularMethod.
	 */
	private function get_specularMethod():BasicSpecularMethod
	{
		return _methodSetup.specularMethod;
	}
	
	private function set_specularMethod(value:BasicSpecularMethod):BasicSpecularMethod
	{
		_methodSetup.specularMethod = value;
		return value;
	}

	/**
	 * Initializes the pass.
	 */
	private function init():Void
	{
		_methodSetup = new ShaderMethodSetup();
		_methodSetup.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function dispose():Void
	{
		super.dispose();
		_methodSetup.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		_methodSetup.dispose();
		_methodSetup = null;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function invalidateShaderProgram(updateMaterial:Bool = true):Void
	{
		var oldPasses:Vector<MaterialPassBase> = _passes;
		_passes = new Vector<MaterialPassBase>();
		
		if (_methodSetup != null) 
			addPassesFromMethods();
		
		if (oldPasses == null || _passes.length != oldPasses.length) {
			_passesDirty = true;
			return;
		}
		
		for (i in 0..._passes.length) {
			if (_passes[i] != oldPasses[i]) {
				_passesDirty = true;
				return;
			}
		}
		
		super.invalidateShaderProgram(updateMaterial);
	}

	/**
	 * Adds any possible passes needed by the used methods.
	 */
	private function addPassesFromMethods():Void
	{
		if (_methodSetup._normalMethod != null && _methodSetup._normalMethod.hasOutput)
			addPasses(_methodSetup._normalMethod.passes);
		if (_methodSetup._ambientMethod != null)
			addPasses(_methodSetup._ambientMethod.passes);
		if (_methodSetup._shadowMethod != null)
			addPasses(_methodSetup._shadowMethod.passes);
		if (_methodSetup._diffuseMethod != null)
			addPasses(_methodSetup._diffuseMethod.passes);
		if (_methodSetup._specularMethod != null)
			addPasses(_methodSetup._specularMethod.passes);
	}
	
	/**
	 * Adds internal passes to the material.
	 *
	 * @param passes The passes to add.
	 */
	private function addPasses(passes:Vector<MaterialPassBase>):Void
	{
		if (passes == null)
			return;
		
		var len:Int = passes.length;
		
		for (i in 0...len) {
			passes[i].material = material;
			passes[i].lightPicker = _lightPicker;
			_passes.push(passes[i]);
		}
	}

	/**
	 * Initializes the default UV transformation matrix.
	 */
	private function initUVTransformData():Void
	{
		_vertexConstantData[_uvTransformIndex] = 1;
		_vertexConstantData[_uvTransformIndex + 1] = 0;
		_vertexConstantData[_uvTransformIndex + 2] = 0;
		_vertexConstantData[_uvTransformIndex + 3] = 0;
		_vertexConstantData[_uvTransformIndex + 4] = 0;
		_vertexConstantData[_uvTransformIndex + 5] = 1;
		_vertexConstantData[_uvTransformIndex + 6] = 0;
		_vertexConstantData[_uvTransformIndex + 7] = 0;
	}

	/**
	 * Initializes the default UV transformation matrix.
	 */
	private function initUVTransformData2():Void
	{
		_vertexConstantData[_uvTransformIndex2] = 1;
		_vertexConstantData[_uvTransformIndex2 + 1] = 0;
		_vertexConstantData[_uvTransformIndex2 + 2] = 0;
		_vertexConstantData[_uvTransformIndex2 + 3] = 0;
		_vertexConstantData[_uvTransformIndex2 + 4] = 0;
		_vertexConstantData[_uvTransformIndex2 + 5] = 1;
		_vertexConstantData[_uvTransformIndex2 + 6] = 0;
		_vertexConstantData[_uvTransformIndex2 + 7] = 0;
	}

	/**
	 * Initializes commonly required constant values.
	 */
	private function initCommonsData():Void
	{
		_fragmentConstantData[_commonsDataIndex] = .5;
		_fragmentConstantData[_commonsDataIndex + 1] = 0;
		_fragmentConstantData[_commonsDataIndex + 2] = 1/255;
		_fragmentConstantData[_commonsDataIndex + 3] = 1;
	}

	/**
	 * Cleans up the after compiling.
	 */
	private function cleanUp():Void
	{
		_compiler.dispose();
		_compiler = null;
	}

	/**
	 * Updates method constants if they have changed.
	 */
	private function updateMethodConstants():Void
	{
		if (_methodSetup._normalMethod != null)
			_methodSetup._normalMethod.initConstants(_methodSetup._normalMethodVO);
		if (_methodSetup._diffuseMethod != null)
			_methodSetup._diffuseMethod.initConstants(_methodSetup._diffuseMethodVO);
		if (_methodSetup._ambientMethod != null)
			_methodSetup._ambientMethod.initConstants(_methodSetup._ambientMethodVO);
		if (_usingSpecularMethod)
			_methodSetup._specularMethod.initConstants(_methodSetup._specularMethodVO);
		if (_methodSetup._shadowMethod != null)
			_methodSetup._shadowMethod.initConstants(_methodSetup._shadowMethodVO);
	}

	/**
	 * Updates constant data render state used by the lights. This method is optional for subclasses to implement.
	 */
	private function updateLightConstants():Void
	{
	    // up to subclasses to optionally implement
	}

	/**
	 * Updates constant data render state used by the light probes. This method is optional for subclasses to implement.
	 */
	private function updateProbes(stage3DProxy:Stage3DProxy):Void
	{
	
	}

	/**
	 * Called when any method's shader code is invalidated.
	 */
	private function onShaderInvalidated(event:ShadingMethodEvent):Void
	{
		invalidateShaderProgram();
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getVertexCode():String
	{
		return _vertexCode;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getFragmentCode(animatorCode:String):String
	{
		return _fragmentLightCode + animatorCode + _framentPostLightCode;
	}
	
	// RENDER LOOP
	
	/**
	 * @inheritDoc
	 */
	override private function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		super.activate(stage3DProxy, camera);
		
		if (_usesNormals)
			_methodSetup._normalMethod.activate(_methodSetup._normalMethodVO, stage3DProxy);
		_methodSetup._ambientMethod.activate(_methodSetup._ambientMethodVO, stage3DProxy);
		if (_methodSetup._shadowMethod != null)
			_methodSetup._shadowMethod.activate(_methodSetup._shadowMethodVO, stage3DProxy);
		_methodSetup._diffuseMethod.activate(_methodSetup._diffuseMethodVO, stage3DProxy);
		if (_usingSpecularMethod)
			_methodSetup._specularMethod.activate(_methodSetup._specularMethodVO, stage3DProxy);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):Void
	{
		var i:Int = 0;
		var context:Context3D = stage3DProxy._context3D;
		if (_uvBufferIndex >= 0)
			renderable.activateUVBuffer(_uvBufferIndex, stage3DProxy);
		if (_secondaryUVBufferIndex >= 0)
			renderable.activateSecondaryUVBuffer(_secondaryUVBufferIndex, stage3DProxy);
		if (_normalBufferIndex >= 0)
			renderable.activateVertexNormalBuffer(_normalBufferIndex, stage3DProxy);
		if (_tangentBufferIndex >= 0)
			renderable.activateVertexTangentBuffer(_tangentBufferIndex, stage3DProxy);
		
		if (_animateUVs) {
			var uvTransform:Matrix = renderable.uvTransform;
			if (uvTransform != null) {
				_vertexConstantData[_uvTransformIndex] = uvTransform.a;
				_vertexConstantData[_uvTransformIndex + 1] = uvTransform.b;
				_vertexConstantData[_uvTransformIndex + 3] = uvTransform.tx;
				_vertexConstantData[_uvTransformIndex + 4] = uvTransform.c;
				_vertexConstantData[_uvTransformIndex + 5] = uvTransform.d;
				_vertexConstantData[_uvTransformIndex + 7] = uvTransform.ty;
			} else {
				_vertexConstantData[_uvTransformIndex] = 1;
				_vertexConstantData[_uvTransformIndex + 1] = 0;
				_vertexConstantData[_uvTransformIndex + 3] = 0;
				_vertexConstantData[_uvTransformIndex + 4] = 0;
				_vertexConstantData[_uvTransformIndex + 5] = 1;
				_vertexConstantData[_uvTransformIndex + 7] = 0;
			}
		}
		
		if (_animateUVs2) {
			var uvTransform2:Matrix = renderable.uvTransform2;
			if (uvTransform2 != null) {
				_vertexConstantData[_uvTransformIndex2] = uvTransform2.a;
				_vertexConstantData[_uvTransformIndex2 + 1] = uvTransform2.b;
				_vertexConstantData[_uvTransformIndex2 + 3] = uvTransform2.tx;
				_vertexConstantData[_uvTransformIndex2 + 4] = uvTransform2.c;
				_vertexConstantData[_uvTransformIndex2 + 5] = uvTransform2.d;
				_vertexConstantData[_uvTransformIndex2 + 7] = uvTransform2.ty;
			}

			else {
				_vertexConstantData[_uvTransformIndex2] = 1;
				_vertexConstantData[_uvTransformIndex2 + 1] = 0;
				_vertexConstantData[_uvTransformIndex2 + 3] = 0;
				_vertexConstantData[_uvTransformIndex2 + 4] = 0;
				_vertexConstantData[_uvTransformIndex2 + 5] = 1;
				_vertexConstantData[_uvTransformIndex2 + 7] = 0;
			}
		}
		
		_ambientLightR = _ambientLightG = _ambientLightB = 0;

		if (usesLights())
			updateLightConstants();

		if (usesProbes())
			updateProbes(stage3DProxy);
		
		if (_sceneMatrixIndex >= 0) {
			renderable.getRenderSceneTransform(camera).copyRawDataTo(_vertexConstantData, _sceneMatrixIndex, true);
			viewProjection.copyRawDataTo(_vertexConstantData, 0, true);
		} else {
			var matrix3D:Matrix3D = Matrix3DUtils.CALCULATION_MATRIX;
			matrix3D.copyFrom(renderable.getRenderSceneTransform(camera));
			matrix3D.append(viewProjection);
			matrix3D.copyRawDataTo(_vertexConstantData, 0, true);
		}
		
		if (_sceneNormalMatrixIndex >= 0)
			renderable.inverseSceneTransform.copyRawDataTo(_vertexConstantData, _sceneNormalMatrixIndex, false);
		
		if (_usesNormals)
			_methodSetup._normalMethod.setRenderState(_methodSetup._normalMethodVO, renderable, stage3DProxy, camera);
		
		var ambientMethod:BasicAmbientMethod = _methodSetup._ambientMethod;
		ambientMethod._lightAmbientR = _ambientLightR;
		ambientMethod._lightAmbientG = _ambientLightG;
		ambientMethod._lightAmbientB = _ambientLightB;
		ambientMethod.setRenderState(_methodSetup._ambientMethodVO, renderable, stage3DProxy, camera);
		
		if (_methodSetup._shadowMethod != null)
			_methodSetup._shadowMethod.setRenderState(_methodSetup._shadowMethodVO, renderable, stage3DProxy, camera);
		_methodSetup._diffuseMethod.setRenderState(_methodSetup._diffuseMethodVO, renderable, stage3DProxy, camera);
		if (_usingSpecularMethod)
			_methodSetup._specularMethod.setRenderState(_methodSetup._specularMethodVO, renderable, stage3DProxy, camera);
		if (_methodSetup._colorTransformMethod != null)
			_methodSetup._colorTransformMethod.setRenderState(_methodSetup._colorTransformMethodVO, renderable, stage3DProxy, camera);
		
		var methods:Vector<MethodVOSet> = _methodSetup._methods;
		var len:Int = methods.length;
		for (i in 0...len) {
			var set:MethodVOSet = methods[i];
			set.method.setRenderState(set.data, renderable, stage3DProxy, camera);
		}
		
		context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _vertexConstantData, _numUsedVertexConstants);
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _fragmentConstantData, _numUsedFragmentConstants);
		
		renderable.activateVertexBuffer(0, stage3DProxy);
		stage3DProxy.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
	}

	/**
	 * Indicates whether the shader uses any light probes.
	 */
	private function usesProbes():Bool
	{
		return _numLightProbes > 0 && ((_diffuseLightSources | _specularLightSources) & LightSources.PROBES) != 0;
	}

	/**
	 * Indicates whether the shader uses any lights.
	 */
	private function usesLights():Bool
	{
		return (_numPointLights > 0 || _numDirectionalLights > 0) && ((_diffuseLightSources | _specularLightSources) & LightSources.LIGHTS) != 0;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function deactivate(stage3DProxy:Stage3DProxy):Void
	{
		super.deactivate(stage3DProxy);
		
		if (_usesNormals)
			_methodSetup._normalMethod.deactivate(_methodSetup._normalMethodVO, stage3DProxy);
		_methodSetup._ambientMethod.deactivate(_methodSetup._ambientMethodVO, stage3DProxy);
		if (_methodSetup._shadowMethod != null)
			_methodSetup._shadowMethod.deactivate(_methodSetup._shadowMethodVO, stage3DProxy);
		_methodSetup._diffuseMethod.deactivate(_methodSetup._diffuseMethodVO, stage3DProxy);
		if (_usingSpecularMethod)
			_methodSetup._specularMethod.deactivate(_methodSetup._specularMethodVO, stage3DProxy);
	}

	/**
	 * Define which light source types to use for specular reflections. This allows choosing between regular lights
	 * and/or light probes for specular reflections.
	 *
	 * @see away3d.materials.LightSources
	 */
	private function get_specularLightSources():Int
	{
		return _specularLightSources;
	}
	
	private function set_specularLightSources(value:Int):Int
	{
		_specularLightSources = value;
		return value;
	}

	/**
	 * Define which light source types to use for diffuse reflections. This allows choosing between regular lights
	 * and/or light probes for diffuse reflections.
	 *
	 * @see away3d.materials.LightSources
	 */
	private function get_diffuseLightSources():Int
	{
		return _diffuseLightSources;
	}
	
	private function set_diffuseLightSources(value:Int):Int
	{
		_diffuseLightSources = value;
		return value;
	}
}