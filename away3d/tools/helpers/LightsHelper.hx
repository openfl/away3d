package away3d.tools.helpers;

import away3d.containers.ObjectContainer3D;
import away3d.core.base.IMaterialOwner;
import away3d.core.base.SubMesh;
import away3d.entities.Mesh;
import away3d.lights.LightBase;
import away3d.materials.lightpickers.StaticLightPicker;

import openfl.Vector;

/**
 * Helper Class for the LightBase objects <code>LightsHelper</code>
 * A series of methods to ease work with LightBase objects
 */
class LightsHelper
{
	
	private static var _lightsArray:Array<LightBase>;
	private static var _light:LightBase;
	private static var _state:Int;
	
	/**
	 * Applys a series of lights to all materials found into an objectcontainer and its children.
	 * The lights eventually set previously are replaced by the new ones.
	 * @param     objectContainer3D    ObjectContainer3D. The target ObjectContainer3D object to be inspected.
	 * @param     lights                        Vector.&lt;LightBase&gt;. A series of lights to be set to all materials found during parsing of the target ObjectContainer3D.
	 */
	public static function addStaticLightsToMaterials(objectContainer3D:ObjectContainer3D, lights:Vector<LightBase>):Void
	{
		if (lights.length == 0)
			return;
		
		_lightsArray = [];
		
		for (i in 0...lights.length)
			_lightsArray[i] = lights[i];
		
		_state = 0;
		parseContainer(objectContainer3D);
		_lightsArray = null;
	}
	
	/**
	 * Adds one light to all materials found into an objectcontainer and its children.
	 * The lights eventually set previously on a material are kept unchanged. The new light is added to the lights array of the materials found during parsing.
	 * @param     objectContainer3D    ObjectContainer3D. The target ObjectContainer3D object to be inspected.
	 * @param     light                            LightBase. The light to add to all materials found during the parsing of the target ObjectContainer3D.
	 */
	public static function addStaticLightToMaterials(objectContainer3D:ObjectContainer3D, light:LightBase):Void
	{
		parse(objectContainer3D, light, 1);
	}
	
	/**
	 * Removes a given light from all materials found into an objectcontainer and its children.
	 * @param     objectContainer3D    ObjectContainer3D. The target ObjectContainer3D object to be inspected.
	 * @param     light                            LightBase. The light to be removed from all materials found during the parsing of the target ObjectContainer3D.
	 */
	public static function removeStaticLightFromMaterials(objectContainer3D:ObjectContainer3D, light:LightBase):Void
	{
		parse(objectContainer3D, light, 2);
	}
	
	private static function parse(objectContainer3D:ObjectContainer3D, light:LightBase, id:Int):Void
	{
		_light = light;
		if (_light == null)
			return;
		_state = id;
		parseContainer(objectContainer3D);
	}
	
	private static function parseContainer(objectContainer3D:ObjectContainer3D):Void
	{
		if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(objectContainer3D, Mesh) && objectContainer3D.numChildren == 0)
			parseMesh(cast(objectContainer3D, Mesh));
		
		var child;
		for (i in 0...objectContainer3D.numChildren) {
			child = objectContainer3D.getChildAt(i);
			if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(child, ObjectContainer3D))
				parseContainer(cast child);
		}
	}
	
	private static function apply(materialOwner:IMaterialOwner):Void
	{
		var picker:StaticLightPicker;
		var aLights:Array<LightBase>;
		var hasLight:Bool = false;
		var i:Int = 0;
		// TODO: not used
		//	var j : uint;
		
		if (materialOwner.material != null) {
			switch (_state) {
				case 0:
					picker = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(materialOwner.material.lightPicker, StaticLightPicker) ? cast materialOwner.material.lightPicker : null;
					if (picker == null || picker.lights != _lightsArray) 
						materialOwner.material.lightPicker = new StaticLightPicker(_lightsArray);
				
				case 1:
					if (materialOwner.material.lightPicker == null)
						materialOwner.material.lightPicker = new StaticLightPicker([]);
					picker = null;
					if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(materialOwner.material.lightPicker, StaticLightPicker))
						picker = cast materialOwner.material.lightPicker;
					if (picker != null) {
						aLights = picker.lights;
						if (aLights != null && aLights.length > 0) {
							for (i in 0...aLights.length) {
								if (aLights[i] == _light) {
									hasLight = true;
									break;
								}
							}
							
							if (!hasLight) {
								aLights.push(_light);
								picker.lights = aLights;
							} else {
								hasLight = false;
							}
							
						} else
							picker.lights = [_light];
					}
				
				case 2:
					if (materialOwner.material.lightPicker == null)
						materialOwner.material.lightPicker = new StaticLightPicker([]);
					picker = null;
					if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(materialOwner.material.lightPicker, StaticLightPicker))
						picker = cast materialOwner.material.lightPicker;
					if (picker != null) {
						aLights = picker.lights;
						if (aLights != null) {
							for (i in 0...aLights.length) {
								if (aLights[i] == _light) {
									aLights.splice(i, 1);
									picker.lights = aLights;
									break;
								}
							}
						}
					}
			}
		}
	}
	
	private static function parseMesh(mesh:Mesh):Void
	{
		var i:Int = 0;
		var subMeshes:Vector<SubMesh> = mesh.subMeshes;
		
		apply(mesh);
		
		for (i in 0...subMeshes.length)
			apply(subMeshes[i]);
	}
}