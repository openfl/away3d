package away3d.materials.compilation;

	
	/**
	 * ShaderRegister Cache provides the usage management system for all registers during shading compilation.
	 */
	class ShaderRegisterCache
	{
		var _fragmentTempCache:RegisterPool;
		var _vertexTempCache:RegisterPool;
		var _varyingCache:RegisterPool;
		var _fragmentConstantsCache:RegisterPool;
		var _vertexConstantsCache:RegisterPool;
		var _textureCache:RegisterPool;
		var _vertexAttributesCache:RegisterPool;
		var _vertexConstantOffset:UInt;
		var _vertexAttributesOffset:UInt;
		var _varyingsOffset:UInt;
		var _fragmentConstantOffset:UInt;
		
		var _fragmentOutputRegister:ShaderRegisterElement;
		var _vertexOutputRegister:ShaderRegisterElement;
		var _numUsedVertexConstants:UInt;
		var _numUsedFragmentConstants:UInt;
		var _numUsedStreams:UInt;
		var _numUsedTextures:UInt;
		var _numUsedVaryings:UInt;
		var _profile:String;
		
		/**
		 * Create a new ShaderRegisterCache object.
		 *
		 * @param profile The compatibility profile used by the renderer.
		 */
		public function new(profile:String)
		{
			_profile = profile;
		}
		
		/**
		 * Resets all registers.
		 */
		public function reset():Void
		{
			_fragmentTempCache = new RegisterPool("ft", 8, false);
			_vertexTempCache = new RegisterPool("vt", 8, false);
			_varyingCache = new RegisterPool("v", 8);
			_textureCache = new RegisterPool("fs", 8);
			_vertexAttributesCache = new RegisterPool("va", 8);
			_fragmentConstantsCache = new RegisterPool("fc", 28);
			_vertexConstantsCache = new RegisterPool("vc", 128);
			_fragmentOutputRegister = new ShaderRegisterElement("oc", -1);
			_vertexOutputRegister = new ShaderRegisterElement("op", -1);
			_numUsedVertexConstants = 0;
			_numUsedStreams = 0;
			_numUsedTextures = 0;
			_numUsedVaryings = 0;
			_numUsedFragmentConstants = 0;
			var i:Int;
			// For loop conversion - 			for (i = 0; i < _vertexAttributesOffset; ++i)
			for (i in 0..._vertexAttributesOffset)
				getFreeVertexAttribute();
			// For loop conversion - 			for (i = 0; i < _vertexConstantOffset; ++i)
			for (i in 0..._vertexConstantOffset)
				getFreeVertexConstant();
			// For loop conversion - 			for (i = 0; i < _varyingsOffset; ++i)
			for (i in 0..._varyingsOffset)
				getFreeVarying();
			// For loop conversion - 			for (i = 0; i < _fragmentConstantOffset; ++i)
			for (i in 0..._fragmentConstantOffset)
				getFreeFragmentConstant();
		
		}

		/**
		 * Disposes all resources used.
		 */
		public function dispose():Void
		{
			_fragmentTempCache.dispose();
			_vertexTempCache.dispose();
			_varyingCache.dispose();
			_fragmentConstantsCache.dispose();
			_vertexAttributesCache.dispose();
			
			_fragmentTempCache = null;
			_vertexTempCache = null;
			_varyingCache = null;
			_fragmentConstantsCache = null;
			_vertexAttributesCache = null;
			_fragmentOutputRegister = null;
			_vertexOutputRegister = null;
		}
		
		/**
		 * Marks a fragment temporary register as used, so it cannot be retrieved. The register won't be able to be used until removeUsage
		 * has been called usageCount times again.
		 * @param register The register to mark as used.
		 * @param usageCount The amount of usages to add.
		 */
		public function addFragmentTempUsages(register:ShaderRegisterElement, usageCount:UInt):Void
		{
			_fragmentTempCache.addUsage(register, usageCount);
		}
		
		/**
		 * Removes a usage from a fragment temporary register. When usages reach 0, the register is freed again.
		 * @param register The register for which to remove a usage.
		 */
		public function removeFragmentTempUsage(register:ShaderRegisterElement):Void
		{
			_fragmentTempCache.removeUsage(register);
		}
		
		/**
		 * Marks a vertex temporary register as used, so it cannot be retrieved. The register won't be able to be used
		 * until removeUsage has been called usageCount times again.
		 * @param register The register to mark as used.
		 * @param usageCount The amount of usages to add.
		 */
		public function addVertexTempUsages(register:ShaderRegisterElement, usageCount:UInt):Void
		{
			_vertexTempCache.addUsage(register, usageCount);
		}
		
		/**
		 * Removes a usage from a vertex temporary register. When usages reach 0, the register is freed again.
		 * @param register The register for which to remove a usage.
		 */
		public function removeVertexTempUsage(register:ShaderRegisterElement):Void
		{
			_vertexTempCache.removeUsage(register);
		}
		
		/**
		 * Retrieve an entire fragment temporary register that's still available. The register won't be able to be used until removeUsage
		 * has been called usageCount times again.
		 */
		public function getFreeFragmentVectorTemp():ShaderRegisterElement
		{
			return _fragmentTempCache.requestFreeVectorReg();
		}
		
		/**
		 * Retrieve a single component from a fragment temporary register that's still available.
		 */
		public function getFreeFragmentSingleTemp():ShaderRegisterElement
		{
			return _fragmentTempCache.requestFreeRegComponent();
		}
		
		/**
		 * Retrieve an available varying register
		 */
		public function getFreeVarying():ShaderRegisterElement
		{
			++_numUsedVaryings;
			return _varyingCache.requestFreeVectorReg();
		}
		
		/**
		 * Retrieve an available fragment constant register
		 */
		public function getFreeFragmentConstant():ShaderRegisterElement
		{
			++_numUsedFragmentConstants;
			return _fragmentConstantsCache.requestFreeVectorReg();
		}
		
		/**
		 * Retrieve an available vertex constant register
		 */
		public function getFreeVertexConstant():ShaderRegisterElement
		{
			++_numUsedVertexConstants;
			return _vertexConstantsCache.requestFreeVectorReg();
		}
		
		/**
		 * Retrieve an entire vertex temporary register that's still available.
		 */
		public function getFreeVertexVectorTemp():ShaderRegisterElement
		{
			return _vertexTempCache.requestFreeVectorReg();
		}
		
		/**
		 * Retrieve a single component from a vertex temporary register that's still available.
		 */
		public function getFreeVertexSingleTemp():ShaderRegisterElement
		{
			return _vertexTempCache.requestFreeRegComponent();
		}
		
		/**
		 * Retrieve an available vertex attribute register
		 */
		public function getFreeVertexAttribute():ShaderRegisterElement
		{
			++_numUsedStreams;
			return _vertexAttributesCache.requestFreeVectorReg();
		}
		
		/**
		 * Retrieve an available texture register
		 */
		public function getFreeTextureReg():ShaderRegisterElement
		{
			++_numUsedTextures;
			return _textureCache.requestFreeVectorReg();
		}
		
		/**
		 * Indicates the start index from which to retrieve vertex constants.
		 */
		public var vertexConstantOffset(get, set) : UInt;
		public function get_vertexConstantOffset() : UInt
		{
			return _vertexConstantOffset;
		}
		
		public function set_vertexConstantOffset(vertexConstantOffset:UInt) : UInt
		{
			_vertexConstantOffset = vertexConstantOffset;
			return _vertexConstantOffset;
		}
		
		/**
		 * Indicates the start index from which to retrieve vertex attributes.
		 */
		public var vertexAttributesOffset(get, set) : UInt;
		public function get_vertexAttributesOffset() : UInt
		{
			return _vertexAttributesOffset;
		}
		
		public function set_vertexAttributesOffset(value:UInt) : UInt
		{
			_vertexAttributesOffset = value;
			return _vertexAttributesOffset;
		}

		/**
		 * Indicates the start index from which to retrieve varying registers.
		 */
		public var varyingsOffset(get, set) : UInt;
		public function get_varyingsOffset() : UInt
		{
			return _varyingsOffset;
		}
		
		public function set_varyingsOffset(value:UInt) : UInt
		{
			_varyingsOffset = value;
			return _varyingsOffset;
		}

		/**
		 * Indicates the start index from which to retrieve fragment constants.
		 */
		public var fragmentConstantOffset(get, set) : UInt;
		public function get_fragmentConstantOffset() : UInt
		{
			return _fragmentConstantOffset;
		}
		
		public function set_fragmentConstantOffset(value:UInt) : UInt
		{
			_fragmentConstantOffset = value;
			return _fragmentConstantOffset;
		}
		
		/**
		 * The fragment output register.
		 */
		public var fragmentOutputRegister(get, null) : ShaderRegisterElement;
		public function get_fragmentOutputRegister() : ShaderRegisterElement
		{
			return _fragmentOutputRegister;
		}
		
		/**
		 * The amount of used vertex constant registers.
		 */
		public var numUsedVertexConstants(get, null) : UInt;
		public function get_numUsedVertexConstants() : UInt
		{
			return _numUsedVertexConstants;
		}
		
		/**
		 * The amount of used fragment constant registers.
		 */
		public var numUsedFragmentConstants(get, null) : UInt;
		public function get_numUsedFragmentConstants() : UInt
		{
			return _numUsedFragmentConstants;
		}
		
		/**
		 * The amount of used vertex streams.
		 */
		public var numUsedStreams(get, null) : UInt;
		public function get_numUsedStreams() : UInt
		{
			return _numUsedStreams;
		}

		/**
		 * The amount of used texture slots.
		 */
		public var numUsedTextures(get, null) : UInt;
		public function get_numUsedTextures() : UInt
		{
			return _numUsedTextures;
		}

		/**
		 * The amount of used varying registers.
		 */
		public var numUsedVaryings(get, null) : UInt;
		public function get_numUsedVaryings() : UInt
		{
			return _numUsedVaryings;
		}
	}

