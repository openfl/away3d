package away3d.materials.passes;

	//import away3d.arcane;
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
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix;
	import away3d.geom.Matrix3D;

	import flash.Vector;

	import flash.display3D.shaders.glsl.GLSLProgram;

	import away3d.core.managers.AGALProgram3DCache;

	import openfl.gl.GL;
	import openfl.gl.GLProgram;
	
	//use namespace arcane;

	/**
	 * CompiledPass forms an abstract base class for the default compiled pass materials provided by Away3D,
	 * using material methods to define their appearance.
	 */
	class CompiledPass extends MaterialPassBase
	{
		/*arcane*/ public var _passes:Array<MaterialPassBase>;
		/*arcane*/ public var _passesDirty:Bool;
		
		var _specularLightSources:UInt = 0x01;
		var _diffuseLightSources:UInt = 0x03;
		
		var _vertexCode:String;
		var _fragmentLightCode:String;
		var _framentPostLightCode:String;
		
		var _vertexConstantData:Array<Float>;
		var _fragmentConstantData:Array<Float>;
		var _commonsDataIndex:Int;
		var _probeWeightsIndex:Int;
		var _uvBufferIndex:Int;
		var _secondaryUVBufferIndex:Int;
		var _normalBufferIndex:Int;
		var _tangentBufferIndex:Int;
		var _sceneMatrixIndex:Int;
		var _sceneNormalMatrixIndex:Int;
		var _lightFragmentConstantIndex:Int;
		var _cameraPositionIndex:Int;
		var _uvTransformIndex:Int;
		var _lightProbeDiffuseIndices:Array<UInt>;
		var _lightProbeSpecularIndices:Array<UInt>;
		
		var _ambientLightR:Float;
		var _ambientLightG:Float;
		var _ambientLightB:Float;
		
		var _compiler:ShaderCompiler;
		
		var _methodSetup:ShaderMethodSetup;
		
		var _usingSpecularMethod:Bool;
		var _usesNormals:Bool;
		var _preserveAlpha:Bool = true;
		var _animateUVs:Bool;
		
		var _numPointLights:UInt;
		var _numDirectionalLights:UInt;
		var _numLightProbes:UInt;
		
		var _enableLightFallOff:Bool = true;
		
		var _forceSeparateMVP:Bool;

		/**
		 * Creates a new CompiledPass object.
		 * @param material The material to which this pass belongs.
		 */
		public function new(material:MaterialBase)
		{
			super();

			_vertexConstantData = new Array<Float>();
			_fragmentConstantData = new Array<Float>();

			_material = material;
			
			init();
		}

		/**
		 * Whether or not to use fallOff and radius properties for lights. This can be used to improve performance and
		 * compatibility for constrained mode.
		 */
		public var enableLightFallOff(get, set) : Bool;
		public function get_enableLightFallOff() : Bool
		{
			return _enableLightFallOff;
		}
		
		public function set_enableLightFallOff(value:Bool) : Bool
		{
			if (value != _enableLightFallOff)
				invalidateShaderProgram(true);
			_enableLightFallOff = value;
			return _enableLightFallOff;
		}

		/**
		 * Indicates whether the screen projection should be calculated by forcing a separate scene matrix and
		 * view-projection matrix. This is used to prevent rounding errors when using multiple passes with different
		 * projection code.
		 */
		public var forceSeparateMVP(get, set) : Bool;
		public function get_forceSeparateMVP() : Bool
		{
			return _forceSeparateMVP;
		}
		
		public function set_forceSeparateMVP(value:Bool) : Bool
		{
			_forceSeparateMVP = value;
			return _forceSeparateMVP;
		}

		/**
		 * The amount of point lights that need to be supported.
		 */
		public var numPointLights(get, null) : UInt;
		public function get_numPointLights() : UInt
		{
			return _numPointLights;
		}

		/**
		 * The amount of directional lights that need to be supported.
		 */
		public var numDirectionalLights(get, null) : UInt;
		public function get_numDirectionalLights() : UInt
		{
			return _numDirectionalLights;
		}

		/**
		 * The amount of light probes that need to be supported.
		 */
		public var numLightProbes(get, null) : UInt;
		public function get_numLightProbes() : UInt
		{
			return _numLightProbes;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function updateProgram(stage3DProxy:Stage3DProxy):Void
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
			//_vertexConstantData.length = _numUsedVertexConstants*4;
			//_fragmentConstantData.length = _numUsedFragmentConstants*4;
			
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
			_compiler.setTextureSampling(_smooth, _repeat, _mipmap);
			_compiler.setConstantDataBuffers(_vertexConstantData, _fragmentConstantData);
			_compiler.animateUVs = _animateUVs;
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
		public var preserveAlpha(get, set) : Bool;
		public function get_preserveAlpha() : Bool
		{
			return _preserveAlpha;
		}
		
		public function set_preserveAlpha(value:Bool) : Bool
		{
			if (_preserveAlpha == value)
				return _preserveAlpha;
			_preserveAlpha = value;
			invalidateShaderProgram();
			return _preserveAlpha;
		}

		/**
		 * Indicate whether UV coordinates need to be animated using the renderable's transformUV matrix.
		 */
		public var animateUVs(get, set) : Bool;
		public function get_animateUVs() : Bool
		{
			return _animateUVs;
		}
		
		public function set_animateUVs(value:Bool) : Bool
		{
			_animateUVs = value;
			if ((value && !_animateUVs) || (!value && _animateUVs))
				invalidateShaderProgram();
			return _animateUVs;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set_mipmap(value:Bool) : Bool
		{
			if (_mipmap == value)
				return _mipmap;
			super.mipmap = value;
			return _mipmap;
		}

		/**
		 * The normal map to modulate the direction of the surface for each texel. The default normal method expects
		 * tangent-space normal maps, but others could expect object-space maps.
		 */
		public var normalMap(get, set) : Texture2DBase;
		public function get_normalMap() : Texture2DBase
		{
			return _methodSetup._normalMethod.normalMap;
		}
		
		public function set_normalMap(value:Texture2DBase) : Texture2DBase
		{
			_methodSetup._normalMethod.normalMap = value;
			return value;
		}

		/**
		 * The method used to generate the per-pixel normals. Defaults to BasicNormalMethod.
		 */
		public var normalMethod(get, set) : BasicNormalMethod;
		public function get_normalMethod() : BasicNormalMethod
		{
			return _methodSetup.normalMethod;
		}
		
		public function set_normalMethod(value:BasicNormalMethod) : BasicNormalMethod
		{
			_methodSetup.normalMethod = value;
			return value;
		}

		/**
		 * The method that provides the ambient lighting contribution. Defaults to BasicAmbientMethod.
		 */
		public var ambientMethod(get, set) : BasicAmbientMethod;
		public function get_ambientMethod() : BasicAmbientMethod
		{
			return _methodSetup.ambientMethod;
		}
		
		public function set_ambientMethod(value:BasicAmbientMethod) : BasicAmbientMethod
		{
			_methodSetup.ambientMethod = value;
			return value;
		}

		/**
		 * The method used to render shadows cast on this surface, or null if no shadows are to be rendered. Defaults to null.
		 */
		public var shadowMethod(get, set) : ShadowMapMethodBase;
		public function get_shadowMethod() : ShadowMapMethodBase
		{
			return _methodSetup.shadowMethod;
		}
		
		public function set_shadowMethod(value:ShadowMapMethodBase) : ShadowMapMethodBase
		{
			_methodSetup.shadowMethod = value;
			return value;
		}

		/**
		 * The method that provides the diffuse lighting contribution. Defaults to BasicDiffuseMethod.
		 */
		public var diffuseMethod(get, set) : BasicDiffuseMethod;
		public function get_diffuseMethod() : BasicDiffuseMethod
		{
			return _methodSetup.diffuseMethod;
		}
		
		public function set_diffuseMethod(value:BasicDiffuseMethod) : BasicDiffuseMethod
		{
			_methodSetup.diffuseMethod = value;
			return value;
		}

		/**
		 * The method that provides the specular lighting contribution. Defaults to BasicSpecularMethod.
		 */
		public var specularMethod(get, set) : BasicSpecularMethod;
		public function get_specularMethod() : BasicSpecularMethod
		{
			return _methodSetup.specularMethod;
		}
		
		public function set_specularMethod(value:BasicSpecularMethod) : BasicSpecularMethod
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
		override function invalidateShaderProgram(updateMaterial:Bool = true):Void
		{
			var oldPasses:Array<MaterialPassBase> = _passes;
			_passes = new Array<MaterialPassBase>();
			
			if (_methodSetup!=null)
				addPassesFromMethods();
			
			if (oldPasses==null || _passes.length != oldPasses.length) {
				_passesDirty = true;
				return;
			}
			
			// For loop conversion - 						for (var i:Int = 0; i < _passes.length; ++i)
			
			var i:Int;
			
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
			if (_methodSetup._normalMethod!=null && _methodSetup._normalMethod.hasOutput)
				addPasses(_methodSetup._normalMethod.passes);
			if (_methodSetup._ambientMethod!=null)
				addPasses(_methodSetup._ambientMethod.passes);
			if (_methodSetup._shadowMethod!=null)
				addPasses(_methodSetup._shadowMethod.passes);
			if (_methodSetup._diffuseMethod!=null)
				addPasses(_methodSetup._diffuseMethod.passes);
			if (_methodSetup._specularMethod!=null)
				addPasses(_methodSetup._specularMethod.passes);
		}
		
		/**
		 * Adds internal passes to the material.
		 *
		 * @param passes The passes to add.
		 */
		private function addPasses(passes:Array<MaterialPassBase>):Void
		{
			if (passes==null)
				return;
			
			var len:UInt = passes.length;
			
			// For loop conversion - 						for (var i:UInt = 0; i < len; ++i)
			
			var i:UInt = 0;
			
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
			if (_methodSetup._normalMethod!=null)
				_methodSetup._normalMethod.initConstants(_methodSetup._normalMethodVO);
			if (_methodSetup._diffuseMethod!=null)
				_methodSetup._diffuseMethod.initConstants(_methodSetup._diffuseMethodVO);
			if (_methodSetup._ambientMethod!=null)
				_methodSetup._ambientMethod.initConstants(_methodSetup._ambientMethodVO);
			if (_usingSpecularMethod)
				_methodSetup._specularMethod.initConstants(_methodSetup._specularMethodVO);
			if (_methodSetup._shadowMethod!=null)
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
		override function getVertexCode():String
		{
			return _vertexCode;
		}
		
		/**
		 * @inheritDoc
		 */
		override function getFragmentCode(animatorCode:String):String
		{
			return _fragmentLightCode + animatorCode + _framentPostLightCode;
		}
		
		// RENDER LOOP
		
		/**
		 * @inheritDoc
		 */
		override public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):Void
		{
			super.activate(stage3DProxy, camera);
			
			if (_usesNormals)
				_methodSetup._normalMethod.activate(_methodSetup._normalMethodVO, stage3DProxy);
			_methodSetup._ambientMethod.activate(_methodSetup._ambientMethodVO, stage3DProxy);
			if (_methodSetup._shadowMethod!=null)
				_methodSetup._shadowMethod.activate(_methodSetup._shadowMethodVO, stage3DProxy);
			_methodSetup._diffuseMethod.activate(_methodSetup._diffuseMethodVO, stage3DProxy);
			if (_usingSpecularMethod)
				_methodSetup._specularMethod.activate(_methodSetup._specularMethodVO, stage3DProxy);
		}
		
		/**
		 * @inheritDoc
		 */
		override function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):Void
		{
			var i:UInt = 0;
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
				if (uvTransform!=null) {
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
			
			if (_methodSetup._shadowMethod!=null)
				_methodSetup._shadowMethod.setRenderState(_methodSetup._shadowMethodVO, renderable, stage3DProxy, camera);
			_methodSetup._diffuseMethod.setRenderState(_methodSetup._diffuseMethodVO, renderable, stage3DProxy, camera);
			if (_usingSpecularMethod)
				_methodSetup._specularMethod.setRenderState(_methodSetup._specularMethodVO, renderable, stage3DProxy, camera);
			if (_methodSetup._colorTransformMethod!=null)
				_methodSetup._colorTransformMethod.setRenderState(_methodSetup._colorTransformMethodVO, renderable, stage3DProxy, camera);
			
			var methods:Array<MethodVOSet> = _methodSetup._methods;
			var len:UInt = methods.length;
			// For loop conversion - 			for (i = 0; i < len; ++i)
			for (i in 0...len) {
				var set:MethodVOSet = methods[i];
				set.method.setRenderState(set.data, renderable, stage3DProxy, camera);
			}
			
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _vertexConstantData, _numUsedVertexConstants);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _fragmentConstantData, _numUsedFragmentConstants);
			
			renderable.activateVertexBuffer(0, stage3DProxy);

			context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
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
		override function deactivate(stage3DProxy:Stage3DProxy):Void
		{
			super.deactivate(stage3DProxy);
			
			if (_usesNormals)
				_methodSetup._normalMethod.deactivate(_methodSetup._normalMethodVO, stage3DProxy);
			_methodSetup._ambientMethod.deactivate(_methodSetup._ambientMethodVO, stage3DProxy);
			if (_methodSetup._shadowMethod!=null)
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
		public var specularLightSources(get, set) : UInt;
		public function get_specularLightSources() : UInt
		{
			return _specularLightSources;
		}
		
		public function set_specularLightSources(value:UInt) : UInt
		{
			_specularLightSources = value;
			return _specularLightSources;
		}

		/**
		 * Define which light source types to use for diffuse reflections. This allows choosing between regular lights
		 * and/or light probes for diffuse reflections.
		 *
		 * @see away3d.materials.LightSources
		 */
		public var diffuseLightSources(get, set) : UInt;
		public function get_diffuseLightSources() : UInt
		{
			return _diffuseLightSources;
		}
		
		public function set_diffuseLightSources(value:UInt) : UInt
		{
			_diffuseLightSources = value;
			return _diffuseLightSources;
		}
	}

