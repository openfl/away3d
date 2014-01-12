package away3d.materials.methods;

	//import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.methods.MethodVO;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.CubeTextureBase;
	
	//use namespace arcane;
	
	/**
	 * EnvMapDiffuseMethod provides a diffuse shading method that uses a diffuse irradiance environment map to
	 * approximate global lighting rather than lights.
	 */
	class EnvMapAmbientMethod extends BasicAmbientMethod
	{
		var _cubeTexture:CubeTextureBase;
		
		/**
		 * Creates a new EnvMapDiffuseMethod object.
		 * @param envMap The cube environment map to use for the diffuse lighting.
		 */
		public function new(envMap:CubeTextureBase)
		{
			super();
			_cubeTexture = envMap;
		}

		/**
		 * @inheritDoc
		 */
		override public function initVO(vo:MethodVO):Void
		{
			super.initVO(vo);
			vo.needsNormals = true;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():Void
		{
		}
		
		/**
		 * The cube environment map to use for the diffuse lighting.
		 */
		public var envMap(get, set) : CubeTextureBase;
		public function get_envMap() : CubeTextureBase
		{
			return _cubeTexture;
		}
		
		public function set_envMap(value:CubeTextureBase) : CubeTextureBase
		{
			_cubeTexture = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			super.activate(vo, stage3DProxy);
			
			stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _cubeTexture.getTextureForStage3D(stage3DProxy));
		}
		
		/**
		 * @inheritDoc
		 */
		override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var code:String = "";
			var cubeMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
			vo.texturesIndex = cubeMapReg.index;
			
			code += getTexCubeSampleCode(vo, targetReg, cubeMapReg, _cubeTexture, _sharedRegisters.normalFragment);
			
			_ambientInputRegister = regCache.getFreeFragmentConstant();
			vo.fragmentConstantsIndex = _ambientInputRegister.index;
			
			code += "add " + targetReg + ".xyz, " + targetReg + ".xyz, " + _ambientInputRegister + ".xyz\n";
			
			return code;
		}
	}

