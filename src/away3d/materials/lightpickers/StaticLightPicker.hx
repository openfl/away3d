/**
 * StaticLightPicker is a light picker that provides a static set of lights. The lights can be reassigned, but
 * if the configuration changes (number of directional lights, point lights, etc), a material recompilation may
 * occur.
 */
package away3d.materials.lightpickers;

import flash.Vector;
import flash.events.Event;
import away3d.events.LightEvent;
import away3d.lights.DirectionalLight;
import away3d.lights.LightBase;
import away3d.lights.LightProbe;
import away3d.lights.PointLight;

class StaticLightPicker extends LightPickerBase {
    public var lights(get_lights, set_lights):Array<Dynamic>;

    private var _lights:Array<Dynamic>;
/**
	 * Creates a new StaticLightPicker object.
	 * @param lights The lights to be used for shading.
	 */

    public function new(lights:Array<Dynamic>) {
        this.lights = lights;
        super();
    }

/**
	 * The lights used for shading.
	 */

    public function get_lights():Array<Dynamic> {
        return _lights;
    }

    public function set_lights(value:Array<Dynamic>):Array<Dynamic> {
        var numPointLights:Int = 0;
        var numDirectionalLights:Int = 0;
        var numCastingPointLights:Int = 0;
        var numCastingDirectionalLights:Int = 0;
        var numLightProbes:Int = 0;
        var light:LightBase;
        if (_lights != null) clearListeners();
        _lights = value;
        _allPickedLights = Vector.ofArray(cast value);
        _pointLights = new Vector<PointLight>();
        _castingPointLights = new Vector<PointLight>();
        _directionalLights = new Vector<DirectionalLight>();
        _castingDirectionalLights = new Vector<DirectionalLight>();
        _lightProbes = new Vector<LightProbe>();
        var len:Int = value.length;
        var i:Int = 0;
        while (i < len) {
            light = value[i];
            light.addEventListener(LightEvent.CASTS_SHADOW_CHANGE, onCastShadowChange);
            if (Std.is(light, PointLight)) {
                if (light.castsShadows) _castingPointLights[numCastingPointLights++] = cast((light), PointLight)
                else _pointLights[numPointLights++] = cast((light), PointLight);
            }

            else if (Std.is(light, DirectionalLight)) {
                if (light.castsShadows) _castingDirectionalLights[numCastingDirectionalLights++] = cast((light), DirectionalLight)
                else _directionalLights[numDirectionalLights++] = cast((light), DirectionalLight);
            }

            else if (Std.is(light, LightProbe)) _lightProbes[numLightProbes++] = cast((light), LightProbe);
            ++i;
        }
        if (_numDirectionalLights == numDirectionalLights && _numPointLights == numPointLights && _numLightProbes == numLightProbes && _numCastingPointLights == numCastingPointLights && _numCastingDirectionalLights == numCastingDirectionalLights) {
            return value;
        }
        _numDirectionalLights = numDirectionalLights;
        _numCastingDirectionalLights = numCastingDirectionalLights;
        _numPointLights = numPointLights;
        _numCastingPointLights = numCastingPointLights;
        _numLightProbes = numLightProbes;
// MUST HAVE MULTIPLE OF 4 ELEMENTS!
        _lightProbeWeights = new Vector<Float>(Math.ceil(numLightProbes / 4) * 4, true);
// notify material lights have changed
        dispatchEvent(new Event(Event.CHANGE));
        return value;
    }

/**
	 * Remove configuration change listeners on the lights.
	 */

    private function clearListeners():Void {
        var len:Int = _lights.length;
        var i:Int = 0;
        while (i < len) {
            _lights[i].removeEventListener(LightEvent.CASTS_SHADOW_CHANGE, onCastShadowChange);
            ++i;
        }
    }

/**
	 * Notifies the material of a configuration change.
	 */

    private function onCastShadowChange(event:LightEvent):Void {
// TODO: Assign to special caster collections, just append it to the lights in SinglePass
// But keep seperated in multipass
        var light:LightBase = cast((event.target), LightBase);
        if (Std.is(light, PointLight)) updatePointCasting(cast(light, PointLight))
        else if (Std.is(light, DirectionalLight)) updateDirectionalCasting(cast(light, DirectionalLight));
        dispatchEvent(new Event(Event.CHANGE));
    }

/**
	 * Called when a directional light's shadow casting configuration changes.
	 */

    private function updateDirectionalCasting(light:DirectionalLight):Void {
        if (light.castsShadows) {
            --_numDirectionalLights;
            ++_numCastingDirectionalLights;
            _directionalLights.splice(_directionalLights.indexOf(cast(light, DirectionalLight)), 1);
            _castingDirectionalLights.push(light);
        }

        else {
            ++_numDirectionalLights;
            --_numCastingDirectionalLights;
            _castingDirectionalLights.splice(_castingDirectionalLights.indexOf(cast(light, DirectionalLight)), 1);
            _directionalLights.push(light);
        }

    }

/**
	 * Called when a point light's shadow casting configuration changes.
	 */

    private function updatePointCasting(light:PointLight):Void {
        if (light.castsShadows) {
            --_numPointLights;
            ++_numCastingPointLights;
            _pointLights.splice(_pointLights.indexOf(cast(light, PointLight)), 1);
            _castingPointLights.push(light);
        }

        else {
            ++_numPointLights;
            --_numCastingPointLights;
            _castingPointLights.splice(_castingPointLights.indexOf(cast(light, PointLight)), 1);
            _pointLights.push(light);
        }

    }

}

