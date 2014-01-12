package away3d.materials;

	//import away3d.arcane;
	import away3d.materials.passes.SkyBoxPass;
	import away3d.textures.CubeTextureBase;
	
	//use namespace arcane;
	
	/**
	 * SkyBoxMaterial is a material exclusively used to render skyboxes
	 *
	 * @see away3d.primitives.SkyBox
	 */
	class SkyBoxMaterial extends MaterialBase
	{
		var _cubeMap:CubeTextureBase;
		var _skyboxPass:SkyBoxPass;
		
		/**
		 * Creates a new SkyBoxMaterial object.
		 * @param cubeMap The CubeMap to use as the skybox.
		 */
		public function new(cubeMap:CubeTextureBase)
		{
			super();
			_cubeMap = cubeMap;
			addPass(_skyboxPass = new SkyBoxPass());
			_skyboxPass.cubeTexture = _cubeMap;
		}
		
		/**
		 * The cube texture to use as the skybox.
		 */
		public var cubeMap(get, set) : CubeTextureBase;
		public function get_cubeMap() : CubeTextureBase
		{
			return _cubeMap;
		}
		
		public function set_cubeMap(value:CubeTextureBase) : CubeTextureBase
		{
			if (value!=null && _cubeMap!=null && (value.hasMipMaps != _cubeMap.hasMipMaps || value.format != _cubeMap.format))
				invalidatePasses(null);
			
			_cubeMap = value;
			
			_skyboxPass.cubeTexture = _cubeMap;
			return _cubeMap;
		}
	}

