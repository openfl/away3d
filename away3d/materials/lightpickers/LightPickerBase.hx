/**
 * LightPickerBase provides an abstract base clase for light picker classes. These classes are responsible for
 * feeding materials with relevant lights. Usually, StaticLightPicker can be used, but LightPickerBase can be
 * extended to provide more application-specific dynamic selection of lights.
 *
 * @see StaticLightPicker
 */
package away3d.materials.lightpickers;


import openfl.geom.Vector3D;
import away3d.core.traverse.EntityCollector;
import away3d.core.base.IRenderable;
import away3d.library.assets.Asset3DType;
import away3d.lights.LightBase;
import away3d.lights.LightProbe;
import away3d.lights.DirectionalLight;
import away3d.lights.PointLight;
import away3d.library.assets.IAsset;
import away3d.library.assets.NamedAssetBase;

import openfl.Vector;

class LightPickerBase extends NamedAssetBase implements IAsset
{
	public var assetType(get, never):String;
	public var numDirectionalLights(get, never):Int;
	public var numPointLights(get, never):Int;
	public var numCastingDirectionalLights(get, never):Int;
	public var numCastingPointLights(get, never):Int;
	public var numLightProbes(get, never):Int;
	public var pointLights(get, never):Vector<PointLight>;
	public var directionalLights(get, never):Vector<DirectionalLight>;
	public var castingPointLights(get, never):Vector<PointLight>;
	public var castingDirectionalLights(get, never):Vector<DirectionalLight>;
	public var lightProbes(get, never):Vector<LightProbe>;
	public var lightProbeWeights(get, never):Vector<Float>;
	public var allPickedLights(get, never):Vector<LightBase>;

	private var _numPointLights:Int;
	private var _numDirectionalLights:Int;
	private var _numCastingPointLights:Int;
	private var _numCastingDirectionalLights:Int;
	private var _numLightProbes:Int;
	private var _allPickedLights:Vector<LightBase>;
	private var _pointLights:Vector<PointLight>;
	private var _castingPointLights:Vector<PointLight>;
	private var _directionalLights:Vector<DirectionalLight>;
	private var _castingDirectionalLights:Vector<DirectionalLight>;
	private var _lightProbes:Vector<LightProbe>;
	private var _lightProbeWeights:Vector<Float>;
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
	private function get_assetType():String
	{
		return Asset3DType.LIGHT_PICKER;
	}

	/**
	 * The maximum amount of directional lights that will be provided.
	 */
	private function get_numDirectionalLights():Int
	{
		return _numDirectionalLights;
	}

	/**
	 * The maximum amount of point lights that will be provided.
	 */
	private function get_numPointLights():Int
	{
		return _numPointLights;
	}

	/**
	 * The maximum amount of directional lights that cast shadows.
	 */
	private function get_numCastingDirectionalLights():Int
	{
		return _numCastingDirectionalLights;
	}

	/**
	 * The amount of point lights that cast shadows.
	 */
	private function get_numCastingPointLights():Int
	{
		return _numCastingPointLights;
	}

	/**
	 * The maximum amount of light probes that will be provided.
	 */
	private function get_numLightProbes():Int
	{
		return _numLightProbes;
	}

	/**
	 * The collected point lights to be used for shading.
	 */
	private function get_pointLights():Vector<PointLight>
	{
		return _pointLights;
	}

	/**
	 * The collected directional lights to be used for shading.
	 */
	private function get_directionalLights():Vector<DirectionalLight>
	{
		return _directionalLights;
	}

	/**
	 * The collected point lights that cast shadows to be used for shading.
	 */
	private function get_castingPointLights():Vector<PointLight>
	{
		return _castingPointLights;
	}

	/**
	 * The collected directional lights that cast shadows to be used for shading.
	 */
	private function get_castingDirectionalLights():Vector<DirectionalLight>
	{
		return _castingDirectionalLights;
	}

	/**
	 * The collected light probes to be used for shading.
	 */
	private function get_lightProbes():Vector<LightProbe>
	{
		return _lightProbes;
	}

	/**
	 * The weights for each light probe, defining their influence on the object.
	 */
	private function get_lightProbeWeights():Vector<Float>
	{
		return _lightProbeWeights;
	}

	/**
	 * A collection of all the collected lights.
	 */
	private function get_allPickedLights():Vector<LightBase>
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
		var rx:Float = objectPos.x;
		var ry:Float = objectPos.y;
		var rz:Float = objectPos.z;
		var dx:Float;
		var dy:Float;
		var dz:Float;
		var w:Float;
		var total:Float = 0;
		var i:Int;
// calculates weights for probes
		i = 0;
		while (i < _numLightProbes) {
			lightPos = _lightProbes[i].scenePosition;
			dx = rx - lightPos.x;
			dy = ry - lightPos.y;
			dz = rz - lightPos.z;
// weight is inversely proportional to square of distance
			w = dx * dx + dy * dy + dz * dz;
// just... huge if at the same spot
			w = w > (.00001) ? 1 / w : 50000000;
			_lightProbeWeights[i] = w;
			total += w;
			++i;
		}
// normalize
		total = 1 / total;
		i = 0;
		while (i < _numLightProbes) {
			_lightProbeWeights[i] *= total;
			++i;
		}
	}
}

