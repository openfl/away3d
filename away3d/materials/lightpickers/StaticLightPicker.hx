package away3d.materials.lightpickers;

	import flash.events.Event;
	
	import away3d.events.LightEvent;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightBase;
	import away3d.lights.LightProbe;
	import away3d.lights.PointLight;

	import away3d.utils.ArrayUtils;

	/**
	 * StaticLightPicker is a light picker that provides a static set of lights. The lights can be reassigned, but
	 * if the configuration changes (number of directional lights, point lights, etc), a material recompilation may
	 * occur.
	 */
	class StaticLightPicker extends LightPickerBase
	{
		var _lights:Array<LightBase>;

		/**
		 * Creates a new StaticLightPicker object.
		 * @param lights The lights to be used for shading.
		 */
		public function new(lights:Array<LightBase>)
		{
			super();
			this.lights = lights;
		}

		/**
		 * The lights used for shading.
		 */
		public var lights(get, set) : Array<LightBase>;
		public function get_lights() : Array<LightBase>
		{
			return _lights;
		}
		
		public function set_lights(value:Array<LightBase>) : Array<LightBase>
		{
			var numPointLights:UInt = 0;
			var numDirectionalLights:UInt = 0;
			var numCastingPointLights:UInt = 0;
			var numCastingDirectionalLights:UInt = 0;
			var numLightProbes:UInt = 0;
			var light:LightBase;
			
			if (_lights!=null)
				clearListeners();
			
			_lights = value;
			_allPickedLights = value;
			_pointLights = new Array<PointLight>();
			_castingPointLights = new Array<PointLight>();
			_directionalLights = new Array<DirectionalLight>();
			_castingDirectionalLights = new Array<DirectionalLight>();
			_lightProbes = new Array<LightProbe>();
			
			var len:UInt = value.length;
			// For loop conversion - 			for (var i:UInt = 0; i < len; ++i)
			var i:UInt = 0;
			for (i in 0...len) {
				light = value[i];
				light.addEventListener(LightEvent.CASTS_SHADOW_CHANGE, onCastShadowChange);
				if (Std.is(light, PointLight)) {
					if (light.castsShadows)
						_castingPointLights[numCastingPointLights++] = cast(light, PointLight);
					else
						_pointLights[numPointLights++] = cast(light, PointLight);
					
				} else if (Std.is(light, DirectionalLight)) {
					if (light.castsShadows)
						_castingDirectionalLights[numCastingDirectionalLights++] = cast(light, DirectionalLight);
					else
						_directionalLights[numDirectionalLights++] = cast(light, DirectionalLight);
				} else if (Std.is(light, LightProbe))
					_lightProbes[numLightProbes++] = cast(light, LightProbe);
			}
			
			if (_numDirectionalLights == numDirectionalLights && _numPointLights == numPointLights && _numLightProbes == numLightProbes &&
				_numCastingPointLights == numCastingPointLights && _numCastingDirectionalLights == numCastingDirectionalLights) {
				return value;
			}
			
			_numDirectionalLights = numDirectionalLights;
			_numCastingDirectionalLights = numCastingDirectionalLights;
			_numPointLights = numPointLights;
			_numCastingPointLights = numCastingPointLights;
			_numLightProbes = numLightProbes;
			
			// MUST HAVE MULTIPLE OF 4 ELEMENTS!
			_lightProbeWeights = ArrayUtils.Prefill(new Array<Float>(), Math.ceil(numLightProbes/4)*4, 0);
			
			// notify material lights have changed
			dispatchEvent(new Event(Event.CHANGE));

			return value;
		}

		/**
		 * Remove configuration change listeners on the lights.
		 */
		private function clearListeners():Void
		{
			var len:UInt = _lights.length;
			// For loop conversion - 			for (var i:Int = 0; i < len; ++i)
			var i:Int;
			for (i in 0...len)
				_lights[i].removeEventListener(LightEvent.CASTS_SHADOW_CHANGE, onCastShadowChange);
		}

		/**
		 * Notifies the material of a configuration change.
		 */
		private function onCastShadowChange(event:Event):Void
		{
			// TODO: Assign to special caster collections, just append it to the lights in SinglePass
			// But keep seperated in multipass
			
			var light:LightBase = cast(event.target, LightBase);
			
			if (Std.is(light, PointLight))
				updatePointCasting(cast(light, PointLight));
			else if (Std.is(light, DirectionalLight))
				updateDirectionalCasting(cast(light, DirectionalLight));
			
			dispatchEvent(new Event(Event.CHANGE));
		}

		/**
		 * Called when a directional light's shadow casting configuration changes.
		 */
		private function updateDirectionalCasting(light:DirectionalLight):Void
		{
			if (light.castsShadows) {
				--_numDirectionalLights;
				++_numCastingDirectionalLights;
				_directionalLights.splice(Lambda.indexOf(_directionalLights, cast(light, DirectionalLight)), 1);
				_castingDirectionalLights.push(light);
			} else {
				++_numDirectionalLights;
				--_numCastingDirectionalLights;
				_castingDirectionalLights.splice(Lambda.indexOf(_castingDirectionalLights, cast(light, DirectionalLight)), 1);
				_directionalLights.push(light);
			}
		}

		/**
		 * Called when a point light's shadow casting configuration changes.
		 */
		private function updatePointCasting(light:PointLight):Void
		{
			if (light.castsShadows) {
				--_numPointLights;
				++_numCastingPointLights;
				_pointLights.splice(Lambda.indexOf(_pointLights, cast(light, PointLight)), 1);
				_castingPointLights.push(light);
			} else {
				++_numPointLights;
				--_numCastingPointLights;
				_castingPointLights.splice(Lambda.indexOf(_castingPointLights, cast(light, PointLight)), 1);
				_pointLights.push(light);
			}
		}
	}

