package away3d.materials.methods;

	import away3d.*;
	import away3d.errors.*;
	import away3d.library.assets.*;
	import away3d.lights.*;
	import away3d.lights.shadowmaps.*;
	import away3d.materials.compilation.*;
	
	//use namespace arcane;

	/**
	 * ShadowMapMethodBase provides an abstract base method for shadow map methods.
	 */
	class ShadowMapMethodBase extends ShadingMethodBase implements IAsset
	{
		var _castingLight:LightBase;
		var _shadowMapper:ShadowMapperBase;
		
		var _epsilon:Float = .02;
		var _alpha:Float = 1;

		/**
		 * Creates a new ShadowMapMethodBase object.
		 * @param castingLight The light used to cast shadows.
		 */
		public function new(castingLight:LightBase)
		{
			super();
			_castingLight = castingLight;
			castingLight.castsShadows = true;
			_shadowMapper = castingLight.shadowMapper;
		}

		/**
		 * @inheritDoc
		 */
		public var assetType(get, null) : String;
		public function get_assetType() : String
		{
			return AssetType.SHADOW_MAP_METHOD;
		}

		/**
		 * The "transparency" of the shadows. This allows making shadows less strong.
		 */
		public var alpha(get, set) : Float;
		public function get_alpha() : Float
		{
			return _alpha;
		}
		
		public function set_alpha(value:Float) : Float
		{
			_alpha = value;
			return _alpha;
		}

		/**
		 * The light casting the shadows.
		 */
		public var castingLight(get, null) : LightBase;
		public function get_castingLight() : LightBase
		{
			return _castingLight;
		}

		/**
		 * A small value to counter floating point precision errors when comparing values in the shadow map with the
		 * calculated depth value. Increase this if shadow banding occurs, decrease it if the shadow seems to be too detached.
		 */
		public var epsilon(get, set) : Float;
		public function get_epsilon() : Float
		{
			return _epsilon;
		}
		
		public function set_epsilon(value:Float) : Float
		{
			_epsilon = value;
			return _epsilon;
		}

		/**
		 * @inheritDoc
		 */
		public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			throw new AbstractMethodError();
			return null;
		}
	}

