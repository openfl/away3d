package away3d.materials.methods;

	//import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	
	//use namespace arcane;

	/**
	 * BasicNormalMethod is the default method for standard tangent-space normal mapping.
	 */
	class BasicNormalMethod extends ShadingMethodBase
	{
		var _texture:Texture2DBase;
		var _useTexture:Bool;
		var _normalTextureRegister:ShaderRegisterElement;

		/**
		 * Creates a new BasicNormalMethod object.
		 */
		public function new()
		{
			super();
		}

		/**
		 * @inheritDoc
		 */
		override public function initVO(vo:MethodVO):Void
		{
			vo.needsUV = (_texture!=null);
		}

		/**
		 * Indicates whether or not this method outputs normals in tangent space. Override for object-space normals.
		 */
		public var tangentSpace(get, null) : Bool;
		public function get_tangentSpace() : Bool
		{
			return true;
		}
		
		/**
		 * Indicates if the normal method output is not based on a texture (if not, it will usually always return true)
		 * Override if subclasses are different.
		 */
		public var hasOutput(get, null) : Bool;
		public function get_hasOutput() : Bool
		{
			return _useTexture;
		}

		/**
		 * @inheritDoc
		 */
		override public function copyFrom(method:ShadingMethodBase):Void
		{
			normalMap = cast(method, BasicNormalMethod).normalMap;
		}

		/**
		 * The texture containing the normals per pixel.
		 */
		public var normalMap(get, set) : Texture2DBase;
		public function get_normalMap() : Texture2DBase
		{
			return _texture;
		}
		
		public function set_normalMap(value:Texture2DBase) : Texture2DBase
		{
			if ((value!=null && _useTexture) ||
				(value!=null && _texture!=null && (value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format))) {
				invalidateShaderProgram();
			}
			_useTexture = (value!=null);
			_texture = value;
			return _texture;
		}

		/**
		 * @inheritDoc
		 */
		override function cleanCompilationData():Void
		{
			super.cleanCompilationData();
			_normalTextureRegister = null;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose():Void
		{
			if (_texture!=null)
				_texture = null;
		}


		/**
		 * @inheritDoc
		 */
		override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			if (vo.texturesIndex >= 0)
				stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
		}

		/**
		 * @inheritDoc
		 */
		public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			_normalTextureRegister = regCache.getFreeTextureReg();
			vo.texturesIndex = _normalTextureRegister.index;
			return getTex2DSampleCode(vo, targetReg, _normalTextureRegister, _texture) +
				"sub " + targetReg + ".xyz, " + targetReg + ".xyz, " + _sharedRegisters.commons + ".xxx	\n" +
				"nrm " + targetReg + ".xyz, " + targetReg + ".xyz							\n";
		}
	}

