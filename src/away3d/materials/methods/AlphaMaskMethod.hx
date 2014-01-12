package away3d.materials.methods;

	//import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	
	//use namespace arcane;
	
	/**
	 * AlphaMaskMethod allows the use of an additional texture to specify the alpha value of the material. When used
	 * with the secondary uv set, it allows for a tiled main texture with independently varying alpha (useful for water
	 * etc).
	 */
	class AlphaMaskMethod extends EffectMethodBase
	{
		var _texture:Texture2DBase;
		var _useSecondaryUV:Bool;

		/**
		 * Creates a new AlphaMaskMethod object
		 * @param texture The texture to use as the alpha mask.
		 * @param useSecondaryUV Indicated whether or not the secondary uv set for the mask. This allows mapping alpha independently.
		 */
		public function new(texture:Texture2DBase, useSecondaryUV:Bool = false)
		{
			super();
			_texture = texture;
			_useSecondaryUV = useSecondaryUV;
		}

		/**
		 * @inheritDoc
		 */
		override public function initVO(vo:MethodVO):Void
		{
			vo.needsSecondaryUV = _useSecondaryUV;
			vo.needsUV = !_useSecondaryUV;
		}

		/**
		 * Indicated whether or not the secondary uv set for the mask. This allows mapping alpha independently, for
		 * instance to tile the main texture and normal map while providing untiled alpha, for example to define the
		 * transparency over a tiled water surface.
		 */
		public var useSecondaryUV(get, set) : Bool;
		public function get_useSecondaryUV() : Bool
		{
			return _useSecondaryUV;
		}
		
		public function set_useSecondaryUV(value:Bool) : Bool
		{
			if (_useSecondaryUV == value)
				return;
			_useSecondaryUV = value;
			invalidateShaderProgram();
		}

		/**
		 * The texture to use as the alpha mask.
		 */
		public var texture(get, set) : Texture2DBase;
		public function get_texture() : Texture2DBase
		{
			return _texture;
		}
		
		public function set_texture(value:Texture2DBase) : Texture2DBase
		{
			_texture = value;
		}

		/**
		 * @inheritDoc
		 */
		override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
		}

		/**
		 * @inheritDoc
		 */
		override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var textureReg:ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var uvReg:ShaderRegisterElement = _useSecondaryUV? _sharedRegisters.secondaryUVVarying : _sharedRegisters.uvVarying;
			vo.texturesIndex = textureReg.index;
			
			return getTex2DSampleCode(vo, temp, textureReg, _texture, uvReg) +
				"mul " + targetReg + ", " + targetReg + ", " + temp + ".x\n";
		}
	}

