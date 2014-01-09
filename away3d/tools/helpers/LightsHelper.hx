package away3d.tools.helpers;

	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.IMaterialOwner;
	import away3d.core.base.SubMesh;
	import away3d.entities.Mesh;
	import away3d.lights.LightBase;
	import away3d.materials.lightpickers.StaticLightPicker;
	
	/**
	 * Helper Class for the LightBase objects <code>LightsHelper</code>
	 * A series of methods to ease work with LightBase objects
	 */
	
	class LightsHelper
	{
		
		private static var _lightsArray:Array<Dynamic>;
		private static var _light:LightBase;
		private static var _state:UInt;
		
		/**
		 * Applys a series of lights to all materials found into an objectcontainer and its children.
		 * The lights eventually set previously are replaced by the new ones.
		 * @param     objectContainer3D    ObjectContainer3D. The target ObjectContainer3D object to be inspected.
		 * @param     lights                        Vector.&lt;LightBase&gt;. A series of lights to be set to all materials found during parsing of the target ObjectContainer3D.
		 */
		public static addStaticLightsToMaterials(objectContainer3D:ObjectContainer3D, lights:Array<LightBase>):Void
		{
			if (lights.length == 0)
				return;
			
			_lightsArray = [];
			
			// For loop conversion - 						for (var i:UInt = 0; i < lights.length; ++i)
			
			var i:UInt = 0;
			
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
		public static addStaticLightToMaterials(objectContainer3D:ObjectContainer3D, light:LightBase):Void
		{
			parse(objectContainer3D, light, 1);
		}
		
		/**
		 * Removes a given light from all materials found into an objectcontainer and its children.
		 * @param     objectContainer3D    ObjectContainer3D. The target ObjectContainer3D object to be inspected.
		 * @param     light                            LightBase. The light to be removed from all materials found during the parsing of the target ObjectContainer3D.
		 */
		public static removeStaticLightFromMaterials(objectContainer3D:ObjectContainer3D, light:LightBase):Void
		{
			parse(objectContainer3D, light, 2);
		}
		
		private static function parse(objectContainer3D:ObjectContainer3D, light:LightBase, id:UInt):Void
		{
			_light = light;
			if (!_light)
				return;
			_state = id;
			parseContainer(objectContainer3D);
		}
		
		private static function parseContainer(objectContainer3D:ObjectContainer3D):Void
		{
			if (objectContainer3D is Mesh && objectContainer3D.numChildren == 0)
				parseMesh(Mesh(objectContainer3D));
			
			// For loop conversion - 						for (var i:UInt = 0; i < objectContainer3D.numChildren; ++i)
			
			var i:UInt = 0;
			
			for (i in 0...objectContainer3D.numChildren)
				parseContainer(ObjectContainer3D(objectContainer3D.getChildAt(i)));
		}
		
		private static function apply(materialOwner:IMaterialOwner):Void
		{
			var picker:StaticLightPicker;
			var aLights:Array<Dynamic>;
			var hasLight:Bool;
			var i:UInt = 0;
			// TODO: not used
			//	var j : UInt;
			
			if (materialOwner.material) {
				switch (_state) {
					case 0:
						picker = materialOwner.material.lightPicker as StaticLightPicker;
						if (!picker || picker.lights != _lightsArray)
							materialOwner.material.lightPicker = new StaticLightPicker(_lightsArray);
						break;
					
					case 1:
						if (!materialOwner.material.lightPicker) materialOwner.material.lightPicker = new StaticLightPicker([]);
						picker = materialOwner.material.lightPicker as StaticLightPicker;
						if (picker) {
							aLights = picker.lights;
							if (aLights && aLights.length > 0) {
								// For loop conversion - 								for (i = 0; i < aLights.length; ++i)
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
									break;
								}
								
							} else
								picker.lights = [_light];
						}
						break;
					
					case 2:
						if (!materialOwner.material.lightPicker) materialOwner.material.lightPicker = new StaticLightPicker([]);
						picker = materialOwner.material.lightPicker as StaticLightPicker;
						if (picker) {
							aLights = picker.lights;
							if (aLights) {
								// For loop conversion - 								for (i = 0; i < aLights.length; ++i)
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
			var i:UInt = 0;
			var subMeshes:Array<SubMesh> = mesh.subMeshes;
			
			apply(mesh);
			
			// For loop conversion - 						for (i = 0; i < subMeshes.length; ++i)
			
			for (i in 0...subMeshes.length)
				apply(subMeshes[i]);
		}
	}

