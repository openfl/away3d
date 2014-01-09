package away3d.materials.compilation;

	//import away3d.arcane;
	import away3d.materials.LightSources;
	import away3d.materials.methods.EffectMethodBase;
	import away3d.materials.methods.MethodVO;
	import away3d.materials.methods.MethodVOSet;
	import away3d.materials.methods.ShaderMethodSetup;
	import away3d.materials.methods.ShadingMethodBase;

	/**
	 * ShaderCompiler is an abstract base class for shader compilers that use modular shader methods to assemble a
	 * material. Concrete subclasses are used by the default materials.
	 *
	 * @see away3d.materials.methods.ShadingMethodBase
	 */
	class ShaderCompiler
	{
		var _sharedRegisters:ShaderRegisterData;
		var _registerCache:ShaderRegisterCache;
		var _dependencyCounter:MethodDependencyCounter;
		var _methodSetup:ShaderMethodSetup;

		var _smooth:Bool;
		var _repeat:Bool;
		var _mipmap:Bool;
		var _enableLightFallOff:Bool;
		var _preserveAlpha:Bool = true;
		var _animateUVs:Bool;
		var _alphaPremultiplied:Bool;
		var _vertexConstantData:Array<Float>;
		var _fragmentConstantData:Array<Float>;

		var _vertexCode:String;
		var _fragmentCode:String;
		var _fragmentLightCode:String;
		var _fragmentPostLightCode:String;
		var _commonsDataIndex:Int = -1;

		var _animatableAttributes:Array<String>;
		var _animationTargetRegisters:Array<String>;

		var _lightProbeDiffuseIndices:Array<UInt>;
		var _lightProbeSpecularIndices:Array<UInt>;
		var _uvBufferIndex:Int = -1;
		var _uvTransformIndex:Int = -1;
		var _secondaryUVBufferIndex:Int = -1;
		var _normalBufferIndex:Int = -1;
		var _tangentBufferIndex:Int = -1;
		var _lightFragmentConstantIndex:Int = -1;
		var _sceneMatrixIndex:Int = -1;
		var _sceneNormalMatrixIndex:Int = -1;
		var _cameraPositionIndex:Int = -1;
		var _probeWeightsIndex:Int = -1;

		var _specularLightSources:UInt;
		var _diffuseLightSources:UInt;

		var _numLights:Int;
		var _numLightProbes:UInt;
		var _numPointLights:UInt;
		var _numDirectionalLights:UInt;

		var _numProbeRegisters:UInt;
		var _combinedLightSources:UInt;

		var _usingSpecularMethod:Bool;

		var _needUVAnimation:Bool;
		var _UVTarget:String;
		var _UVSource:String;

		var _profile:String;

		var _forceSeperateMVP:Bool;

		//use namespace arcane;

		/**
		 * Creates a new ShaderCompiler object.
		 * @param profile The compatibility profile of the renderer.
		 */
		public function new(profile:String)
		{
			_sharedRegisters = new ShaderRegisterData();
			_dependencyCounter = new MethodDependencyCounter();
			_profile = profile;
			initRegisterCache(profile);
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
			_enableLightFallOff = value;
			return _enableLightFallOff;
		}

		/**
		 * Indicates whether the compiled code needs UV animation.
		 */
		public var needUVAnimation(get, null) : Bool;
		public function get_needUVAnimation() : Bool
		{
			return _needUVAnimation;
		}

		/**
		 * The target register to place the animated UV coordinate.
		 */
		public var UVTarget(get, null) : String;
		public function get_UVTarget() : String
		{
			return _UVTarget;
		}

		/**
		 * The souce register providing the UV coordinate to animate.
		 */
		public var UVSource(get, null) : String;
		public function get_UVSource() : String
		{
			return _UVSource;
		}

		/**
		 * Indicates whether the screen projection should be calculated by forcing a separate scene matrix and
		 * view-projection matrix. This is used to prevent rounding errors when using multiple passes with different
		 * projection code.
		 */
		public var forceSeperateMVP(get, set) : Bool;
		public function get_forceSeperateMVP() : Bool
		{
			return _forceSeperateMVP;
		}

		public function set_forceSeperateMVP(value:Bool) : Bool
		{
			_forceSeperateMVP = value;
			return _forceSeperateMVP;
		}

		/**
		 * Initialized the register cache.
		 * @param profile The compatibility profile of the renderer.
		 */
		private function initRegisterCache(profile:String):Void
		{
			_registerCache = new ShaderRegisterCache(profile);
			_registerCache.vertexAttributesOffset = 1;
			_registerCache.reset();
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
			return _animateUVs;
		}

		/**
		 * Indicates whether visible textures (or other pixels) used by this material have
		 * already been premultiplied.
		 */
		public var alphaPremultiplied(get, set) : Bool;
		public function get_alphaPremultiplied() : Bool
		{
			return _alphaPremultiplied;
		}

		public function set_alphaPremultiplied(value:Bool) : Bool
		{
			_alphaPremultiplied = value;
			return _alphaPremultiplied;
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
			_preserveAlpha = value;
			return _preserveAlpha;
		}

		/**
		 * Sets the default texture sampling properties.
		 * @param smooth Indicates whether the texture should be filtered when sampled. Defaults to true.
		 * @param repeat Indicates whether the texture should be tiled when sampled. Defaults to true.
		 * @param mipmap Indicates whether or not any used textures should use mipmapping. Defaults to true.
		 */
		public function setTextureSampling(smooth:Bool, repeat:Bool, mipmap:Bool):Void
		{
			_smooth = smooth;
			_repeat = repeat;
			_mipmap = mipmap;
		}

		/**
		 * Sets the constant buffers allocated by the material. This allows setting constant data during compilation.
		 * @param vertexConstantData The vertex constant data buffer.
		 * @param fragmentConstantData The fragment constant data buffer.
		 */
		public function setConstantDataBuffers(vertexConstantData:Array<Float>, fragmentConstantData:Array<Float>):Void
		{
			_vertexConstantData = vertexConstantData;
			_fragmentConstantData = fragmentConstantData;
		}

		/**
		 * The shader method setup object containing the method configuration and their value objects for the material being compiled.
		 */
		public var methodSetup(get, set) : ShaderMethodSetup;
		public function get_methodSetup() : ShaderMethodSetup
		{
			return _methodSetup;
		}

		public function set_methodSetup(value:ShaderMethodSetup) : ShaderMethodSetup
		{
			_methodSetup = value;
			return _methodSetup;
		}

		/**
		 * Compiles the code after all setup on the compiler has finished.
		 */
		public function compile():Void
		{
			initRegisterIndices();
			initLightData();

			_animatableAttributes = ["va0"];
			_animationTargetRegisters = ["vt0"];
			_vertexCode = "";
			_fragmentCode = "";

			_sharedRegisters.localPosition = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(_sharedRegisters.localPosition, 1);

			createCommons();
			calculateDependencies();
			updateMethodRegisters();

			// For loop conversion - 			for (var i:UInt = 0; i < 4; ++i)

			var i:UInt = 0;

			for (i in 0...4)
				_registerCache.getFreeVertexConstant();

			createNormalRegisters();
			if (_dependencyCounter.globalPosDependencies > 0 || _forceSeperateMVP)
				compileGlobalPositionCode();
			compileProjectionCode();
			compileMethodsCode();
			compileFragmentOutput();
			_fragmentPostLightCode = fragmentCode;
		}

		/**
		 * Creates the registers to contain the normal data.
		 */
		private function createNormalRegisters():Void
		{

		}

		/**
		 * Compile the code for the methods.
		 */
		private function compileMethodsCode():Void
		{
			if (_dependencyCounter.uvDependencies > 0)
				compileUVCode();
			if (_dependencyCounter.secondaryUVDependencies > 0)
				compileSecondaryUVCode();
			if (_dependencyCounter.normalDependencies > 0)
				compileNormalCode();
			if (_dependencyCounter.viewDirDependencies > 0)
				compileViewDirCode();
			compileLightingCode();
			_fragmentLightCode = _fragmentCode;
			_fragmentCode = "";
			compileMethods();
		}

		/**
		 * Compile the lighting code.
		 */
		private function compileLightingCode():Void
		{

		}

		/**
		 * Calculate the view direction.
		 */
		private function compileViewDirCode():Void
		{

		}

		/**
		 * Calculate the normal.
		 */
		private function compileNormalCode():Void
		{

		}

		/**
		 * Calculate the (possibly animated) UV coordinates.
		 */
		private function compileUVCode():Void
		{
			var uvAttributeReg:ShaderRegisterElement = _registerCache.getFreeVertexAttribute();
			_uvBufferIndex = uvAttributeReg.index;

			var varying:ShaderRegisterElement = _registerCache.getFreeVarying();

			_sharedRegisters.uvVarying = varying;

			if (animateUVs) {
				// a, b, 0, tx
				// c, d, 0, ty
				var uvTransform1:ShaderRegisterElement = _registerCache.getFreeVertexConstant();
				var uvTransform2:ShaderRegisterElement = _registerCache.getFreeVertexConstant();
				_uvTransformIndex = uvTransform1.index*4;

				_vertexCode += "dp4 " + varying + ".x, " + uvAttributeReg + ", " + uvTransform1 + "\n" +
					"dp4 " + varying + ".y, " + uvAttributeReg + ", " + uvTransform2 + "\n" +
					"mov " + varying + ".zw, " + uvAttributeReg + ".zw \n";
			} else {
				_uvTransformIndex = -1;
				_needUVAnimation = true;
				_UVTarget = varying.toString();
				_UVSource = uvAttributeReg.toString();
			}
		}

		/**
		 * Provide the secondary UV coordinates.
		 */
		private function compileSecondaryUVCode():Void
		{
			var uvAttributeReg:ShaderRegisterElement = _registerCache.getFreeVertexAttribute();
			_secondaryUVBufferIndex = uvAttributeReg.index;
			_sharedRegisters.secondaryUVVarying = _registerCache.getFreeVarying();
			_vertexCode += "mov " + _sharedRegisters.secondaryUVVarying + ", " + uvAttributeReg + "\n";
		}

		/**
		 * Compile the world-space position.
		 */
		private function compileGlobalPositionCode():Void
		{
			_sharedRegisters.globalPositionVertex = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(_sharedRegisters.globalPositionVertex, _dependencyCounter.globalPosDependencies);
			var positionMatrixReg:ShaderRegisterElement = _registerCache.getFreeVertexConstant();
			_registerCache.getFreeVertexConstant();
			_registerCache.getFreeVertexConstant();
			_registerCache.getFreeVertexConstant();
			_sceneMatrixIndex = positionMatrixReg.index*4;

			_vertexCode += "m44 " + _sharedRegisters.globalPositionVertex + ", " + _sharedRegisters.localPosition + ", " + positionMatrixReg + "\n";

			if (_dependencyCounter.usesGlobalPosFragment) {
				_sharedRegisters.globalPositionVarying = _registerCache.getFreeVarying();
				_vertexCode += "mov " + _sharedRegisters.globalPositionVarying + ", " + _sharedRegisters.globalPositionVertex + "\n";
			}
		}

		/**
		 * Get the projection coordinates.
		 */
		private function compileProjectionCode():Void
		{
			var pos:String = _dependencyCounter.globalPosDependencies > 0 || _forceSeperateMVP? _sharedRegisters.globalPositionVertex.toString() : _animationTargetRegisters[0];
			var code:String;

			if (_dependencyCounter.projectionDependencies > 0) {
				_sharedRegisters.projectionFragment = _registerCache.getFreeVarying();
				code = "m44 vt5, " + pos + ", vc0		\n" +
					"mov " + _sharedRegisters.projectionFragment + ", vt5\n" +
					"mov op, vt5\n";
			} else
				code = "m44 op, " + pos + ", vc0		\n";

			_vertexCode += code;
		}

		/**
		 * Assign the final output colour the the output register.
		 */
		private function compileFragmentOutput():Void
		{
			_fragmentCode += "mov " + _registerCache.fragmentOutputRegister + ", " + _sharedRegisters.shadedTarget + "\n";
			_registerCache.removeFragmentTempUsage(_sharedRegisters.shadedTarget);
		}

		/**
		 * Reset all the indices to "unused".
		 */
		private function initRegisterIndices():Void
		{
			_commonsDataIndex = -1;
			_cameraPositionIndex = -1;
			_uvBufferIndex = -1;
			_uvTransformIndex = -1;
			_secondaryUVBufferIndex = -1;
			_normalBufferIndex = -1;
			_tangentBufferIndex = -1;
			_lightFragmentConstantIndex = -1;
			_sceneMatrixIndex = -1;
			_sceneNormalMatrixIndex = -1;
			_probeWeightsIndex = -1;
		}

		/**
		 * Prepares the setup for the light code.
		 */
		private function initLightData():Void
		{
			_numLights = _numPointLights + _numDirectionalLights;
			_numProbeRegisters = Math.ceil(_numLightProbes/4);

			if (_methodSetup._specularMethod!=null)
				_combinedLightSources = _specularLightSources | _diffuseLightSources;
			else
				_combinedLightSources = _diffuseLightSources;

			_usingSpecularMethod = (_methodSetup._specularMethod!=null && (
				usesLightsForSpecular() ||
				usesProbesForSpecular()));
		}

		/**
		 * Create the commonly shared constant register.
		 */
		private function createCommons():Void
		{
			_sharedRegisters.commons = _registerCache.getFreeFragmentConstant();
			_commonsDataIndex = _sharedRegisters.commons.index*4;
		}

		/**
		 * Figure out which named registers are required, and how often.
		 */
		private function calculateDependencies():Void
		{
			_dependencyCounter.reset();

			var methods:Array<MethodVOSet> = _methodSetup._methods;
			var len:UInt;

			setupAndCountMethodDependencies(_methodSetup._diffuseMethod, _methodSetup._diffuseMethodVO);
			if (_methodSetup._shadowMethod!=null)
				setupAndCountMethodDependencies(_methodSetup._shadowMethod, _methodSetup._shadowMethodVO);
			setupAndCountMethodDependencies(_methodSetup._ambientMethod, _methodSetup._ambientMethodVO);
			if (_usingSpecularMethod)
				setupAndCountMethodDependencies(_methodSetup._specularMethod, _methodSetup._specularMethodVO);
			if (_methodSetup._colorTransformMethod!=null)
				setupAndCountMethodDependencies(_methodSetup._colorTransformMethod, _methodSetup._colorTransformMethodVO);

			len = methods.length;
			// For loop conversion - 			for (var i:UInt = 0; i < len; ++i)
			var i:UInt = 0;
			for (i in 0...len)
				setupAndCountMethodDependencies(methods[i].method, methods[i].data);

			if (usesNormals)
				setupAndCountMethodDependencies(_methodSetup._normalMethod, _methodSetup._normalMethodVO);

			// todo: add spotlights to count check
			_dependencyCounter.setPositionedLights(_numPointLights, _combinedLightSources);
		}

		/**
		 * Counts the dependencies for a given method.
		 * @param method The method to count the dependencies for.
		 * @param methodVO The method's data for this material.
		 */
		private function setupAndCountMethodDependencies(method:ShadingMethodBase, methodVO:MethodVO):Void
		{
			setupMethod(method, methodVO);
			_dependencyCounter.includeMethodVO(methodVO);
		}

		/**
		 * Assigns all prerequisite data for the methods, so we can calculate dependencies for them.
		 */
		private function setupMethod(method:ShadingMethodBase, methodVO:MethodVO):Void
		{
			method.reset();
			methodVO.reset();
			methodVO.vertexData = _vertexConstantData;
			methodVO.fragmentData = _fragmentConstantData;
			methodVO.useSmoothTextures = _smooth;
			methodVO.repeatTextures = _repeat;
			methodVO.useMipmapping = _mipmap;
			methodVO.useLightFallOff = _enableLightFallOff && _profile != "baselineConstrained";
			methodVO.numLights = _numLights + _numLightProbes;
			method.initVO(methodVO);
		}

		/**
		 * The index for the common data register.
		 */
		public var commonsDataIndex(get, null) : Int;
		public function get_commonsDataIndex() : Int
		{
			return _commonsDataIndex;
		}

		/**
		 * Assigns the shared register data to all methods.
		 */
		private function updateMethodRegisters():Void
		{
			_methodSetup._normalMethod.sharedRegisters = _sharedRegisters;
			_methodSetup._diffuseMethod.sharedRegisters = _sharedRegisters;
			if (_methodSetup._shadowMethod!=null)
				_methodSetup._shadowMethod.sharedRegisters = _sharedRegisters;
			_methodSetup._ambientMethod.sharedRegisters = _sharedRegisters;
			if (_methodSetup._specularMethod!=null)
				_methodSetup._specularMethod.sharedRegisters = _sharedRegisters;
			if (_methodSetup._colorTransformMethod!=null)
				_methodSetup._colorTransformMethod.sharedRegisters = _sharedRegisters;

			var methods:Array<MethodVOSet> = _methodSetup._methods;
			var len:Int = methods.length;
			// For loop conversion - 			for (var i:UInt = 0; i < len; ++i)
			var i:UInt = 0;
			for (i in 0...len)
				methods[i].method.sharedRegisters = _sharedRegisters;
		}

		/**
		 * The amount of vertex constants used by the material. Any animation code to be added can append its vertex
		 * constant data after this.
		 */
		public var numUsedVertexConstants(get, null) : UInt;
		public function get_numUsedVertexConstants() : UInt
		{
			return _registerCache.numUsedVertexConstants;
		}

		/**
		 * The amount of fragment constants used by the material. Any animation code to be added can append its vertex
		 * constant data after this.
		 */
		public var numUsedFragmentConstants(get, null) : UInt;
		public function get_numUsedFragmentConstants() : UInt
		{
			return _registerCache.numUsedFragmentConstants;
		}

		/**
		 * The amount of vertex attribute streams used by the material. Any animation code to be added can add its
		 * streams after this. Also used to automatically disable attribute slots on pass deactivation.
		 */
		public var numUsedStreams(get, null) : UInt;
		public function get_numUsedStreams() : UInt
		{
			return _registerCache.numUsedStreams;
		}

		/**
		 * The amount of textures used by the material. Used to automatically disable texture slots on pass deactivation.
		 */
		public var numUsedTextures(get, null) : UInt;
		public function get_numUsedTextures() : UInt
		{
			return _registerCache.numUsedTextures;
		}

		/**
		 * Number of used varyings. Any animation code to be added can add its used varyings after this.
		 */
		public var numUsedVaryings(get, null) : UInt;
		public function get_numUsedVaryings() : UInt
		{
			return _registerCache.numUsedVaryings;
		}

		/**
		 * Indicates whether lights are used for specular reflections.
		 */
		private function usesLightsForSpecular():Bool
		{
			return _numLights > 0 && (_specularLightSources & LightSources.LIGHTS) != 0;
		}

		/**
		 * Indicates whether lights are used for diffuse reflections.
		 */
		private function usesLightsForDiffuse():Bool
		{
			return _numLights > 0 && (_diffuseLightSources & LightSources.LIGHTS) != 0;
		}

		/**
		 * Disposes all resources used by the compiler.
		 */
		public function dispose():Void
		{
			cleanUpMethods();
			_registerCache.dispose();
			_registerCache = null;
			_sharedRegisters = null;
		}

		/**
		 * Clean up method's compilation data after compilation finished.
		 */
		private function cleanUpMethods():Void
		{
			if (_methodSetup._normalMethod!=null)
				_methodSetup._normalMethod.cleanCompilationData();
			if (_methodSetup._diffuseMethod!=null)
				_methodSetup._diffuseMethod.cleanCompilationData();
			if (_methodSetup._ambientMethod!=null)
				_methodSetup._ambientMethod.cleanCompilationData();
			if (_methodSetup._specularMethod!=null)
				_methodSetup._specularMethod.cleanCompilationData();
			if (_methodSetup._shadowMethod!=null)
				_methodSetup._shadowMethod.cleanCompilationData();
			if (_methodSetup._colorTransformMethod!=null)
				_methodSetup._colorTransformMethod.cleanCompilationData();

			var methods:Array<MethodVOSet> = _methodSetup._methods;
			var len:UInt = methods.length;
			// For loop conversion - 			for (var i:UInt = 0; i < len; ++i)
			var i:UInt = 0;
			for (i in 0...len)
				methods[i].method.cleanCompilationData();
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

		/**
		 * Indicates whether light probes are being used for specular reflections.
		 */
		private function usesProbesForSpecular():Bool
		{
			return _numLightProbes > 0 && (_specularLightSources & LightSources.PROBES) != 0;
		}

		/**
		 * Indicates whether light probes are being used for diffuse reflections.
		 */
		private function usesProbesForDiffuse():Bool
		{
			return _numLightProbes > 0 && (_diffuseLightSources & LightSources.PROBES) != 0;
		}

		/**
		 * Indicates whether any light probes are used.
		 */
		private function usesProbes():Bool
		{
			return _numLightProbes > 0 && ((_diffuseLightSources | _specularLightSources) & LightSources.PROBES) != 0;
		}

		/**
		 * The index for the UV vertex attribute stream.
		 */
		public var uvBufferIndex(get, null) : Int;
		public function get_uvBufferIndex() : Int
		{
			return _uvBufferIndex;
		}

		/**
		 * The index for the UV transformation matrix vertex constant.
		 */
		public var uvTransformIndex(get, null) : Int;
		public function get_uvTransformIndex() : Int
		{
			return _uvTransformIndex;
		}

		/**
		 * The index for the secondary UV vertex attribute stream.
		 */
		public var secondaryUVBufferIndex(get, null) : Int;
		public function get_secondaryUVBufferIndex() : Int
		{
			return _secondaryUVBufferIndex;
		}

		/**
		 * The index for the vertex normal attribute stream.
		 */
		public var normalBufferIndex(get, null) : Int;
		public function get_normalBufferIndex() : Int
		{
			return _normalBufferIndex;
		}

		/**
		 * The index for the vertex tangent attribute stream.
		 */
		public var tangentBufferIndex(get, null) : Int;
		public function get_tangentBufferIndex() : Int
		{
			return _tangentBufferIndex;
		}

		/**
		 * The first index for the fragment constants containing the light data.
		 */
		public var lightFragmentConstantIndex(get, null) : Int;
		public function get_lightFragmentConstantIndex() : Int
		{
			return _lightFragmentConstantIndex;
		}

		/**
		 * The index of the vertex constant containing the camera position.
		 */
		public var cameraPositionIndex(get, null) : Int;
		public function get_cameraPositionIndex() : Int
		{
			return _cameraPositionIndex;
		}

		/**
		 * The index of the vertex constant containing the scene matrix.
		 */
		public var sceneMatrixIndex(get, null) : Int;
		public function get_sceneMatrixIndex() : Int
		{
			return _sceneMatrixIndex;
		}

		/**
		 * The index of the vertex constant containing the uniform scene matrix (the inverse transpose).
		 */
		public var sceneNormalMatrixIndex(get, null) : Int;
		public function get_sceneNormalMatrixIndex() : Int
		{
			return _sceneNormalMatrixIndex;
		}

		/**
		 * The index of the fragment constant containing the weights for the light probes.
		 */
		public var probeWeightsIndex(get, null) : Int;
		public function get_probeWeightsIndex() : Int
		{
			return _probeWeightsIndex;
		}

		/**
		 * The generated vertex code.
		 */
		public var vertexCode(get, null) : String;
		public function get_vertexCode() : String
		{
			return _vertexCode;
		}

		/**
		 * The generated fragment code.
		 */
		public var fragmentCode(get, null) : String;
		public function get_fragmentCode() : String
		{
			return _fragmentCode;
		}

		/**
		 * The code containing the lighting calculations.
		 */
		public var fragmentLightCode(get, null) : String;
		public function get_fragmentLightCode() : String
		{
			return _fragmentLightCode;
		}

		/**
		 * The code containing the post-lighting calculations.
		 */
		public var fragmentPostLightCode(get, null) : String;
		public function get_fragmentPostLightCode() : String
		{
			return _fragmentPostLightCode;
		}

		/**
		 * The register name containing the final shaded colour.
		 */
		public var shadedTarget(get, null) : String;
		public function get_shadedTarget() : String
		{
			return _sharedRegisters.shadedTarget.toString();
		}

		/**
		 * The amount of point lights that need to be supported.
		 */
		public var numPointLights(get, set) : UInt;
		public function get_numPointLights() : UInt
		{
			return _numPointLights;
		}

		public function set_numPointLights(numPointLights:UInt) : UInt
		{
			_numPointLights = numPointLights;
			return _numPointLights;
		}

		/**
		 * The amount of directional lights that need to be supported.
		 */
		public var numDirectionalLights(get, set) : UInt;
		public function get_numDirectionalLights() : UInt
		{
			return _numDirectionalLights;
		}

		public function set_numDirectionalLights(value:UInt) : UInt
		{
			_numDirectionalLights = value;
			return _numDirectionalLights;
		}

		/**
		 * The amount of light probes that need to be supported.
		 */
		public var numLightProbes(get, set) : UInt;
		public function get_numLightProbes() : UInt
		{
			return _numLightProbes;
		}

		public function set_numLightProbes(value:UInt) : UInt
		{
			_numLightProbes = value;
			return _numLightProbes;
		}

		/**
		 * Indicates whether the specular method is used.
		 */
		public var usingSpecularMethod(get, null) : Bool;
		public function get_usingSpecularMethod() : Bool
		{
			return _usingSpecularMethod;
		}

		/**
		 * The attributes that need to be animated by animators.
		 */
		public var animatableAttributes(get, null) : Array<String>;
		public function get_animatableAttributes() : Array<String>
		{
			return _animatableAttributes;
		}

		/**
		 * The target registers for animated properties, written to by the animators.
		 */
		public var animationTargetRegisters(get, null) : Array<String>;
		public function get_animationTargetRegisters() : Array<String>
		{
			return _animationTargetRegisters;
		}

		/**
		 * Indicates whether the compiled shader uses normals.
		 */
		public var usesNormals(get, null) : Bool;
		public function get_usesNormals() : Bool
		{
			return _dependencyCounter.normalDependencies > 0 && _methodSetup._normalMethod.hasOutput;
		}

		/**
		 * Indicates whether the compiled shader uses lights.
		 */
		private function usesLights():Bool
		{
			return _numLights > 0 && (_combinedLightSources & LightSources.LIGHTS) != 0;
		}

		/**
		 * Compiles the code for the methods.
		 */
		private function compileMethods():Void
		{
			var methods:Array<MethodVOSet> = _methodSetup._methods;
			var numMethods:UInt = methods.length;
			var method:EffectMethodBase;
			var data:MethodVO;
			var alphaReg:ShaderRegisterElement = null;

			if (_preserveAlpha) {
				alphaReg = _registerCache.getFreeFragmentSingleTemp();
				_registerCache.addFragmentTempUsages(alphaReg, 1);
				_fragmentCode += "mov " + alphaReg + ", " + _sharedRegisters.shadedTarget + ".w\n";
			}

			// For loop conversion - 			for (var i:UInt = 0; i < numMethods; ++i)

			var i:UInt = 0;

			for (i in 0...numMethods) {
				method = methods[i].method;
				data = methods[i].data;
				_vertexCode += method.getVertexCode(data, _registerCache);
				if (data.needsGlobalVertexPos || data.needsGlobalFragmentPos)
					_registerCache.removeVertexTempUsage(_sharedRegisters.globalPositionVertex);

				_fragmentCode += method.getFragmentCode(data, _registerCache, _sharedRegisters.shadedTarget);
				if (data.needsNormals)
					_registerCache.removeFragmentTempUsage(_sharedRegisters.normalFragment);
				if (data.needsView)
					_registerCache.removeFragmentTempUsage(_sharedRegisters.viewDirFragment);
			}

			if (_preserveAlpha) {
				_fragmentCode += "mov " + _sharedRegisters.shadedTarget + ".w, " + alphaReg + "\n";
				_registerCache.removeFragmentTempUsage(alphaReg);
			}

			if (_methodSetup._colorTransformMethod!=null) {
				_vertexCode += _methodSetup._colorTransformMethod.getVertexCode(_methodSetup._colorTransformMethodVO, _registerCache);
				_fragmentCode += _methodSetup._colorTransformMethod.getFragmentCode(_methodSetup._colorTransformMethodVO, _registerCache, _sharedRegisters.shadedTarget);
			}
		}

		/**
		 * Indices for the light probe diffuse textures.
		 */
		public var lightProbeDiffuseIndices(get, null) : Array<UInt>;
		public function get_lightProbeDiffuseIndices() : Array<UInt>
		{
			return _lightProbeDiffuseIndices;
		}

		/**
		 * Indices for the light probe specular textures.
		 */
		public var lightProbeSpecularIndices(get, null) : Array<UInt>;
		public function get_lightProbeSpecularIndices() : Array<UInt>
		{
			return _lightProbeSpecularIndices;
		}
	}

