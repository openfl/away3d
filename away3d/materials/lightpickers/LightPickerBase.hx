package away3d.materials.lightpickers;

	import away3d.*;
	import away3d.core.base.*;
	import away3d.core.traverse.*;
	import away3d.library.assets.*;
	import away3d.lights.*;
	
	import flash.geom.*;
	
	//use namespace arcane;

	/**
	 * LightPickerBase provides an abstract base clase for light picker classes. These classes are responsible for
	 * feeding materials with relevant lights. Usually, StaticLightPicker can be used, but LightPickerBase can be
	 * extended to provide more application-specific dynamic selection of lights.
	 *
	 * @see StaticLightPicker
	 */
	class LightPickerBase extends NamedAssetBase implements IAsset
	{
		var _numPointLights:UInt;
		var _numDirectionalLights:UInt;
		var _numCastingPointLights:UInt;
		var _numCastingDirectionalLights:UInt;
		var _numLightProbes:UInt;
		var _allPickedLights:Array<LightBase>;
		var _pointLights:Array<PointLight>;
		var _castingPointLights:Array<PointLight>;
		var _directionalLights:Array<DirectionalLight>;
		var _castingDirectionalLights:Array<DirectionalLight>;
		var _lightProbes:Array<LightProbe>;
		var _lightProbeWeights:Array<Float>;

		/**
		 * Creates a new LightPickerBase object.
		 */
		public function new()
		{
			super();
		}

		/**
		 * Disposes resources used by the light picker.
		 */
		public function dispose():Void
		{
		}

		/**
		 * @inheritDoc
		 */
		public var assetType(get, null) : String;
		public function get_assetType() : String
		{
			return AssetType.LIGHT_PICKER;
		}
		
		/**
		 * The maximum amount of directional lights that will be provided.
		 */
		public var numDirectionalLights(get, null) : UInt;
		public function get_numDirectionalLights() : UInt
		{
			return _numDirectionalLights;
		}
		
		/**
		 * The maximum amount of point lights that will be provided.
		 */
		public var numPointLights(get, null) : UInt;
		public function get_numPointLights() : UInt
		{
			return _numPointLights;
		}
		
		/**
		 * The maximum amount of directional lights that cast shadows.
		 */
		public var numCastingDirectionalLights(get, null) : UInt;
		public function get_numCastingDirectionalLights() : UInt
		{
			return _numCastingDirectionalLights;
		}
		
		/**
		 * The amount of point lights that cast shadows.
		 */
		public var numCastingPointLights(get, null) : UInt;
		public function get_numCastingPointLights() : UInt
		{
			return _numCastingPointLights;
		}
		
		/**
		 * The maximum amount of light probes that will be provided.
		 */
		public var numLightProbes(get, null) : UInt;
		public function get_numLightProbes() : UInt
		{
			return _numLightProbes;
		}

		/**
		 * The collected point lights to be used for shading.
		 */
		public var pointLights(get, null) : Array<PointLight>;
		public function get_pointLights() : Array<PointLight>
		{
			return _pointLights;
		}

		/**
		 * The collected directional lights to be used for shading.
		 */
		public var directionalLights(get, null) : Array<DirectionalLight>;
		public function get_directionalLights() : Array<DirectionalLight>
		{
			return _directionalLights;
		}

		/**
		 * The collected point lights that cast shadows to be used for shading.
		 */
		public var castingPointLights(get, null) : Array<PointLight>;
		public function get_castingPointLights() : Array<PointLight>
		{
			return _castingPointLights;
		}

		/**
		 * The collected directional lights that cast shadows to be used for shading.
		 */
		public var castingDirectionalLights(get, null) : Array<DirectionalLight>;
		public function get_castingDirectionalLights() : Array<DirectionalLight>
		{
			return _castingDirectionalLights;
		}

		/**
		 * The collected light probes to be used for shading.
		 */
		public var lightProbes(get, null) : Array<LightProbe>;
		public function get_lightProbes() : Array<LightProbe>
		{
			return _lightProbes;
		}

		/**
		 * The weights for each light probe, defining their influence on the object.
		 */
		public var lightProbeWeights(get, null) : Array<Float>;
		public function get_lightProbeWeights() : Array<Float>
		{
			return _lightProbeWeights;
		}

		/**
		 * A collection of all the collected lights.
		 */
		public var allPickedLights(get, null) : Array<LightBase>;
		public function get_allPickedLights() : Array<LightBase>
		{
			return _allPickedLights;
		}
		
		/**
		 * Updates set of lights for a given renderable and EntityCollector. Always call super.collectLights() after custom overridden code.
		 */
		public function collectLights(renderable:IRenderable, entityCollector:EntityCollector):Void
		{
			updateProbeWeights(renderable);
		}

		/**
		 * Updates the weights for the light probes, based on the renderable's position relative to them.
		 * @param renderable The renderble for which to calculate the light probes' influence.
		 */
		private function updateProbeWeights(renderable:IRenderable):Void
		{
			// todo: this will cause the same calculations to occur per SubMesh. See if this can be improved.
			var objectPos:Vector3D = renderable.sourceEntity.scenePosition;
			var lightPos:Vector3D;
			var rx:Float = objectPos.x, ry:Float = objectPos.y, rz:Float = objectPos.z;
			var dx:Float, dy:Float, dz:Float;
			var w:Float, total:Float = 0;
			var i:Int;
			
			// calculates weights for probes
			// For loop conversion - 			for (i = 0; i < _numLightProbes; ++i)
			for (i in 0..._numLightProbes) {
				lightPos = _lightProbes[i].scenePosition;
				dx = rx - lightPos.x;
				dy = ry - lightPos.y;
				dz = rz - lightPos.z;
				// weight is inversely proportional to square of distance
				w = dx*dx + dy*dy + dz*dz;
				
				// just... huge if at the same spot
				w = w > .00001? 1/w : 50000000;
				_lightProbeWeights[i] = w;
				total += w;
			}
			
			// normalize
			total = 1/total;
			// For loop conversion - 			for (i = 0; i < _numLightProbes; ++i)
			for (i in 0..._numLightProbes)
				_lightProbeWeights[i] *= total;
		}
	
	}

