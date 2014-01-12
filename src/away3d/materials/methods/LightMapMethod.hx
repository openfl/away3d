package away3d.materials.methods;

	//import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	
	//use namespace arcane;

	/**
	 * LightMapMethod provides a method that allows applying a light map texture to the calculated pixel colour.
	 * It is different from LightMapDiffuseMethod in that the latter only modulates the diffuse shading value rather
	 * than the whole pixel colour.
	 */
	class LightMapMethod extends EffectMethodBase
	{
		/**
		 * Indicates the light map should be multiplied with the calculated shading result.
		 */
		public static var MULTIPLY:String = "multiply";

		/**
		 * Indicates the light map should be added into the calculated shading result.
		 */
		public static var ADD:String = "add";
		
		var _texture:Texture2DBase;
		
		var _blendMode:String;
		var _useSecondaryUV:Bool;

		/**
		 * Creates a new LightMapMethod object.
		 * @param texture The texture containing the light map.
		 * @param blendMode The blend mode with which the light map should be applied to the lighting result.
		 * @param useSecondaryUV Indicates whether the secondary UV set should be used to map the light map.
		 */
		public function new(texture:Texture2DBase, blendMode:String = "multiply", useSecondaryUV:Bool = false)
		{
			super();
			_useSecondaryUV = useSecondaryUV;
			_texture = texture;
			this.blendMode = blendMode;
		}

		/**
		 * @inheritDoc
		 */
		override public function initVO(vo:MethodVO):Void
		{
			vo.needsUV = !_useSecondaryUV;
			vo.needsSecondaryUV = _useSecondaryUV;
		}

		/**
		 * The blend mode with which the light map should be applied to the lighting result.
		 *
		 * @see LightMapMethod.ADD
		 * @see LightMapMethod.MULTIPLY
		 */
		public var blendMode(get, set) : BlendMode;
		public function get_blendMode() : BlendMode
		{
			return _blendMode;
		}
		
		public function set_blendMode(value:BlendMode) : BlendMode
		{
			if (value != BlendMode.ADD && value != BlendMode,MULTIPLY)
				throw new Error("Unknown blendmode!");
			if (_blendMode == value)
				return _blendMode;
			_blendMode = value;
			invalidateShaderProgram();

			return _blendMode;
		}

		/**
		 * The texture containing the light map.
		 */
		public var texture(get, set) : Texture2DBase;
		public function get_texture() : Texture2DBase
		{
			return _texture;
		}
		
		public function set_texture(value:Texture2DBase) : Texture2DBase
		{
			if (value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format)
				invalidateShaderProgram();
			_texture = value;
		}

		/**
		 * @inheritDoc
		 */
		override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
			super.activate(vo, stage3DProxy);
		}

		/**
		 * @inheritDoc
		 */
		override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var code:String;
			var lightMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			vo.texturesIndex = lightMapReg.index;
			
			code = getTex2DSampleCode(vo, temp, lightMapReg, _texture, _useSecondaryUV? _sharedRegisters.secondaryUVVarying : _sharedRegisters.uvVarying);
			
			switch (_blendMode) {
				case MULTIPLY:
					code += "mul " + targetReg + ", " + targetReg + ", " + temp + "\n";
					break;
				case ADD:
					code += "add " + targetReg + ", " + targetReg + ", " + temp + "\n";
					break;
			}
			
			return code;
		}
	}

