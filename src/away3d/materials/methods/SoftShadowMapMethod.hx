package away3d.materials.methods;

	//import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.math.PoissonLookup;
	import away3d.lights.DirectionalLight;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	
	//use namespace arcane;

	/**
	 * SoftShadowMapMethod provides a soft shadowing technique by randomly distributing sample points.
	 */
	class SoftShadowMapMethod extends SimpleShadowMapMethodBase
	{
		var _range:Float = 1;
		var _numSamples:Int;
		var _offsets:Array<Float>;
		
		/**
		 * Creates a new BasicDiffuseMethod object.
		 *
		 * @param castingLight The light casting the shadows
		 * @param numSamples The amount of samples to take for dithering. Minimum 1, maximum 32.
		 */
		public function new(castingLight:DirectionalLight, numSamples:Int = 5, range:Float = 1)
		{
			super(castingLight);
			
			this.numSamples = numSamples;
			this.range = range;
		}

		/**
		 * The amount of samples to take for dithering. Minimum 1, maximum 32. The actual maximum may depend on the
		 * complexity of the shader.
		 */
		public var numSamples(get, set) : Int;
		public function get_numSamples() : Int
		{
			return _numSamples;
		}
		
		public function set_numSamples(value:Int) : Int
		{
			_numSamples = value;
			if (_numSamples < 1)
				_numSamples = 1;
			else if (_numSamples > 32)
				_numSamples = 32;
			
			_offsets = PoissonLookup.getDistribution(_numSamples);
			invalidateShaderProgram();
		}

		/**
		 * The range in the shadow map in which to distribute the samples.
		 */
		public var range(get, set) : Float;
		public function get_range() : Float
		{
			return _range;
		}
		
		public function set_range(value:Float) : Float
		{
			_range = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function initConstants(vo:MethodVO):Void
		{
			super.initConstants(vo);
			
			vo.fragmentData[vo.fragmentConstantsIndex + 8] = 1/_numSamples;
			vo.fragmentData[vo.fragmentConstantsIndex + 9] = 0;
		}

		/**
		 * @inheritDoc
		 */
		override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			super.activate(vo, stage3DProxy);
			var texRange:Float = .5*_range/_castingLight.shadowMapper.depthMapSize;
			var data:Array<Float> = vo.fragmentData;
			var index:UInt = vo.fragmentConstantsIndex + 10;
			var len:UInt = _numSamples << 1;
			
			// For loop conversion - 						for (var i:Int = 0; i < len; ++i)
			
			var i:Int;
			
			for (i in 0...len)
				data[uint(index + i)] = _offsets[i]*texRange;
		}
		
		/**
		 * @inheritDoc
		 */
		override private function getPlanarFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			// todo: move some things to super
			var depthMapRegister:ShaderRegisterElement = regCache.getFreeTextureReg();
			var decReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var customDataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			
			vo.fragmentConstantsIndex = decReg.index*4;
			vo.texturesIndex = depthMapRegister.index;
			
			return getSampleCode(regCache, depthMapRegister, decReg, targetReg, customDataReg);
		}

		/**
		 * Adds the code for another tap to the shader code.
		 * @param uv The uv register for the tap.
		 * @param texture The texture register containing the depth map.
		 * @param decode The register containing the depth map decoding data.
		 * @param target The target register to add the tap comparison result.
		 * @param regCache The register cache managing the registers.
		 * @return
		 */
		private function addSample(uv:ShaderRegisterElement, texture:ShaderRegisterElement, decode:ShaderRegisterElement, target:ShaderRegisterElement, regCache:ShaderRegisterCache):String
		{
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			return "tex " + temp + ", " + uv + ", " + texture + " <2d,nearest,clamp>\n" +
				"dp4 " + temp + ".z, " + temp + ", " + decode + "\n" +
				"slt " + uv + ".w, " + _depthMapCoordReg + ".z, " + temp + ".z\n" + // 0 if in shadow
				"add " + target + ".w, " + target + ".w, " + uv + ".w\n";
		}

		/**
		 * @inheritDoc
		 */
		override public function activateForCascade(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			super.activate(vo, stage3DProxy);
			var texRange:Float = _range/_castingLight.shadowMapper.depthMapSize;
			var data:Array<Float> = vo.fragmentData;
			var index:UInt = vo.secondaryFragmentConstantsIndex;
			var len:UInt = _numSamples << 1;
			data[index] = 1/_numSamples;
			data[uint(index + 1)] = 0;
			index += 2;
			// For loop conversion - 			for (var i:Int = 0; i < len; ++i)
			var i:Int;
			for (i in 0...len)
				data[uint(index + i)] = _offsets[i]*texRange;
			
			if (len%4 == 0) {
				data[uint(index + len)] = 0;
				data[uint(index + len + 1)] = 0;
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function getCascadeFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, decodeRegister:ShaderRegisterElement, depthTexture:ShaderRegisterElement, depthProjection:ShaderRegisterElement, targetRegister:ShaderRegisterElement):String
		{
			_depthMapCoordReg = depthProjection;
			
			var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			vo.secondaryFragmentConstantsIndex = dataReg.index*4;
			
			return getSampleCode(regCache, depthTexture, decodeRegister, targetRegister, dataReg);
		}

		/**
		 * Get the actual shader code for shadow mapping
		 * @param regCache The register cache managing the registers.
		 * @param depthTexture The texture register containing the depth map.
		 * @param decodeRegister The register containing the depth map decoding data.
		 * @param targetReg The target register to add the shadow coverage.
		 * @param dataReg The register containing additional data.
		 */
		private function getSampleCode(regCache:ShaderRegisterCache, depthTexture:ShaderRegisterElement, decodeRegister:ShaderRegisterElement, targetRegister:ShaderRegisterElement, dataReg:ShaderRegisterElement):String
		{
			var uvReg:ShaderRegisterElement;
			var code:String;
			var offsets:Array<String> = new <String>[ dataReg + ".zw" ];
			uvReg = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(uvReg, 1);
			
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			
			var numRegs:Int = _numSamples >> 1;
			// For loop conversion - 			for (var i:Int = 0; i < numRegs; ++i)
			var i:Int;
			for (i in 0...numRegs) {
				var reg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
				offsets.push(reg + ".xy");
				offsets.push(reg + ".zw");
			}
			
			// For loop conversion - 						for (i = 0; i < _numSamples; ++i)
			
			for (i in 0..._numSamples) {
				if (i == 0) {
					code = "add " + uvReg + ", " + _depthMapCoordReg + ", " + dataReg + ".zwyy\n";
					code += "tex " + temp + ", " + uvReg + ", " + depthTexture + " <2d,nearest,clamp>\n" +
						"dp4 " + temp + ".z, " + temp + ", " + decodeRegister + "\n" +
						"slt " + targetRegister + ".w, " + _depthMapCoordReg + ".z, " + temp + ".z\n"; // 0 if in shadow;
				} else {
					code += "add " + uvReg + ".xy, " + _depthMapCoordReg + ".xy, " + offsets[i] + "\n";
					code += addSample(uvReg, depthTexture, decodeRegister, targetRegister, regCache);
				}
			}
			
			regCache.removeFragmentTempUsage(uvReg);
			code += "mul " + targetRegister + ".w, " + targetRegister + ".w, " + dataReg + ".x\n"; // average
			return code;
		}
	}

