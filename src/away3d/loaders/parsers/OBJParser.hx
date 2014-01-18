package away3d.loaders.parsers;

	//import away3d.arcane;
	import away3d.core.base.Geometry;
	import away3d.core.base.ISubGeometry;
	import away3d.core.base.data.UV;
	import away3d.core.base.data.Vertex;
	import away3d.entities.Mesh;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.loaders.misc.ResourceDependency;
	import away3d.loaders.parsers.utils.ParserUtil;
	import away3d.materials.ColorMaterial;
	import away3d.materials.ColorMultiPassMaterial;
	import away3d.materials.MaterialBase;
	import away3d.materials.TextureMaterial;
	import away3d.materials.TextureMultiPassMaterial;
	import away3d.materials.methods.BasicSpecularMethod;
	import away3d.materials.utils.DefaultMaterialManager;
	import away3d.textures.Texture2DBase;
	import away3d.tools.utils.GeomUtil;
	
	import flash.net.URLRequest;
	
	//use namespace arcane;
	
	/**
	 * OBJParser provides a parser for the OBJ data type.
	 */
	class OBJParser extends ParserBase
	{
		var _textData:String;
		var _startedParsing:Bool;
		var _charIndex:UInt;
		var _oldIndex:UInt;
		var _stringLength:UInt;
		var _currentObject:ObjectGroup;
		var _currentGroup:Group;
		var _currentMaterialGroup:MaterialGroup;
		var _objects:Array<ObjectGroup>;
		var _materialIDs:Array<String>;
		var _materialLoaded:Array<LoadedMaterial>;
		var _materialSpecularData:Array<SpecularData>;
		var _meshes:Array<Mesh>;
		var _lastMtlID:String;
		var _objectIndex:UInt;
		var _realIndices:Array<Dynamic>;
		var _vertexIndex:UInt;
		var _vertices:Array<Vertex>;
		var _vertexNormals:Array<Vertex>;
		var _uvs:Array<UV>;
		var _scale:Float;
		var _mtlLib:Bool;
		var _mtlLibLoaded:Bool = true;
		var _activeMaterialID:String = "";
		
		/**
		 * Creates a new OBJParser object.
		 * @param uri The url or id of the data or file to be parsed.
		 * @param extra The holder for extra contextual data that the parser might need.
		 */
		public function new(scale:Float = 1)
		{
			super(ParserDataFormat.PLAIN_TEXT);
			_scale = scale;
		}
		
		/**
		 * Scaling factor applied directly to vertices data
		 * @param value The scaling factor.
		 */
		public var scale(null, set) : Void;
		public function set_scale(value:Float) : Void
		{
			_scale = value;
		}
		
		/**
		 * Indicates whether or not a given file extension is supported by the parser.
		 * @param extension The file extension of a potential file to be parsed.
		 * @return Whether or not the given file type is supported.
		 */
		public static function supportsType(extension:String):Bool
		{
			extension = extension.toLowerCase();
			return extension == "obj";
		}
		
		/**
		 * Tests whether a data block can be parsed by the parser.
		 * @param data The data block to potentially be parsed.
		 * @return Whether or not the given data is supported.
		 */
		public static function supportsData(data:Dynamic):Bool
		{
			var content:String = ParserUtil.toString(data);
			var hasV:Bool;
			var hasF:Bool;
			
			if (content) {
				hasV = content.indexOf("\nv ") != -1;
				hasF = content.indexOf("\nf ") != -1;
			}
			
			return hasV && hasF;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function resolveDependency(resourceDependency:ResourceDependency):Void
		{
			if (resourceDependency.id == 'mtl') {
				var str:String = ParserUtil.toString(resourceDependency.data);
				parseMtl(str);
				
			} else {
				
				var asset:IAsset;
				
				if (resourceDependency.assets.length != 1)
					return;
				
				asset = resourceDependency.assets[0];
				
				if (asset.assetType == AssetType.TEXTURE) {
					var lm:LoadedMaterial = new LoadedMaterial();
					lm.materialID = resourceDependency.id;
					lm.texture = asset as Texture2DBase;
					
					_materialLoaded.push(lm);
					
					if (_meshes.length > 0)
						applyMaterial(lm);
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function resolveDependencyFailure(resourceDependency:ResourceDependency):Void
		{
			if (resourceDependency.id == "mtl") {
				_mtlLib = false;
				_mtlLibLoaded = false;
			} else {
				var lm:LoadedMaterial = new LoadedMaterial();
				lm.materialID = resourceDependency.id;
				_materialLoaded.push(lm);
			}
			
			if (_meshes.length > 0)
				applyMaterial(lm);
		}
		
		/**
		 * @inheritDoc
		 */
		override private function proceedParsing():Bool
		{
			var line:String;
			var creturn:String = String.fromCharCode(10);
			var trunk:Array<Dynamic>;
			
			if (!_startedParsing) {
				_textData = getTextData();
				// Merge linebreaks that are immediately preceeded by
				// the "escape" backward slash into single lines.
				_textData = _textData.replace(/\\[\r\n]+\s*/gm, ' ');
			}
			
			if (_textData.indexOf(creturn) == -1)
				creturn = String.fromCharCode(13);
			
			if (!_startedParsing) {
				_startedParsing = true;
				_vertices = new Array<Vertex>();
				_vertexNormals = new Array<Vertex>();
				_materialIDs = new Array<String>();
				_materialLoaded = new Array<LoadedMaterial>();
				_meshes = new Array<Mesh>();
				_uvs = new Array<UV>();
				_stringLength = _textData.length;
				_charIndex = _textData.indexOf(creturn, 0);
				_oldIndex = 0;
				_objects = new Array<ObjectGroup>();
				_objectIndex = 0;
			}
			
			while (_charIndex < _stringLength && hasTime()) {
				_charIndex = _textData.indexOf(creturn, _oldIndex);
				
				if (_charIndex == -1)
					_charIndex = _stringLength;
				
				line = _textData.substring(_oldIndex, _charIndex);
				line = line.split('\r').join("");
				line = line.replace("  ", " ");
				trunk = line.split(" ");
				_oldIndex = _charIndex + 1;
				parseLine(trunk);
				
				// If whatever was parsed on this line resulted in the
				// parsing being paused to retrieve dependencies, break
				// here and do not continue parsing until un-paused.
				if (parsingPaused)
					return MORE_TO_PARSE;
			}
			
			if (_charIndex >= _stringLength) {
				
				if (_mtlLib && !_mtlLibLoaded)
					return MORE_TO_PARSE;
				
				translate();
				applyMaterials();
				
				return PARSING_DONE;
			}
			
			return MORE_TO_PARSE;
		}
		
		/**
		 * Parses a single line in the OBJ file.
		 */
		private function parseLine(trunk:Array<Dynamic>):Void
		{
			switch (trunk[0]) {
				case "mtllib":
					_mtlLib = true;
					_mtlLibLoaded = false;
					loadMtl(trunk[1]);
					break;
				case "g":
					createGroup(trunk);
					break;
				case "o":
					createObject(trunk);
					break;
				case "usemtl":
					if (_mtlLib) {
						if (!trunk[1])
							trunk[1] = "def000";
						_materialIDs.push(trunk[1]);
						_activeMaterialID = trunk[1];
						if (_currentGroup)
							_currentGroup.materialID = _activeMaterialID;
					}
					break;
				case "v":
					parseVertex(trunk);
					break;
				case "vt":
					parseUV(trunk);
					break;
				case "vn":
					parseVertexNormal(trunk);
					break;
				case "f":
					parseFace(trunk);
			}
		}
		
		/**
		 * Converts the parsed data into an Away3D scenegraph structure
		 */
		private function translate():Void
		{
			// For loop conversion - 			for (var objIndex:Int = 0; objIndex < _objects.length; ++objIndex)
			var objIndex:Int;
			for (objIndex in 0..._objects.length) {
				var groups:Array<Group> = _objects[objIndex].groups;
				var numGroups:UInt = groups.length;
				var materialGroups:Array<MaterialGroup>;
				var numMaterialGroups:UInt;
				var geometry:Geometry;
				var mesh:Mesh;
				
				var m:UInt;
				var sm:UInt;
				var bmMaterial:MaterialBase;
				
				// For loop conversion - 								for (var g:UInt = 0; g < numGroups; ++g)
				
				var g:UInt;
				
				for (g in 0...numGroups) {
					geometry = new Geometry();
					materialGroups = groups[g].materialGroups;
					numMaterialGroups = materialGroups.length;
					
					// For loop conversion - 										for (m = 0; m < numMaterialGroups; ++m)
					
					for (m in 0...numMaterialGroups)
						translateMaterialGroup(materialGroups[m], geometry);
					
					if (geometry.subGeometries.length == 0)
						continue;
					
					// Finalize and force type-based name
					finalizeAsset(geometry, "");
					if (materialMode < 2)
						bmMaterial = new TextureMaterial(DefaultMaterialManager.getDefaultTexture());
					else
						bmMaterial = new TextureMultiPassMaterial(DefaultMaterialManager.getDefaultTexture());
					//bmMaterial = new TextureMaterial(DefaultMaterialManager.getDefaultTexture());
					mesh = new Mesh(geometry, bmMaterial);
					
					if (_objects[objIndex].name) {
						// this is a full independent object ('o' tag in OBJ file)
						mesh.name = _objects[objIndex].name;
					} else if (groups[g].name) {
						// this is a group so the sub groups contain the actual mesh object names ('g' tag in OBJ file)
						mesh.name = groups[g].name;
					} else {
						// No name stored. Use empty string which will force it
						// to be overridden by finalizeAsset() to type default.
						mesh.name = "";
					}
					
					_meshes.push(mesh);
					
					if (groups[g].materialID != "")
						bmMaterial.name = groups[g].materialID + "~" + mesh.name;
					else
						bmMaterial.name = _lastMtlID + "~" + mesh.name;
					
					if (mesh.subMeshes.length > 1) {
						// For loop conversion - 						for (sm = 1; sm < mesh.subMeshes.length; ++sm)
						for (sm in 1...mesh.subMeshes.length)
							mesh.subMeshes[sm].material = bmMaterial;
					}
					
					finalizeAsset(mesh);
				}
			}
		}
		
		/**
		 * Translates an obj's material group to a subgeometry.
		 * @param materialGroup The material group data to convert.
		 * @param geometry The Geometry to contain the converted SubGeometry.
		 */
		private function translateMaterialGroup(materialGroup:MaterialGroup, geometry:Geometry):Void
		{
			var faces:Array<FaceData> = materialGroup.faces;
			var face:FaceData;
			var numFaces:UInt = faces.length;
			var numVerts:UInt;
			var subs:Array<ISubGeometry>;
			
			var vertices:Array<Float> = new Array<Float>();
			var uvs:Array<Float> = new Array<Float>();
			var normals:Array<Float> = new Array<Float>();
			var indices:Array<UInt> = new Array<UInt>();
			
			_realIndices = [];
			_vertexIndex = 0;
			
			var j:UInt;
			// For loop conversion - 			for (var i:UInt = 0; i < numFaces; ++i)
			var i:UInt = 0;
			for (i in 0...numFaces) {
				face = faces[i];
				numVerts = face.indexIds.length - 1;
				// For loop conversion - 				for (j = 1; j < numVerts; ++j)
				for (j in 1...numVerts) {
					translateVertexData(face, j, vertices, uvs, indices, normals);
					translateVertexData(face, 0, vertices, uvs, indices, normals);
					translateVertexData(face, j + 1, vertices, uvs, indices, normals);
				}
			}
			if (vertices.length > 0) {
				subs = GeomUtil.fromVectors(vertices, indices, uvs, normals, null, null, null);
				// For loop conversion - 				for (i = 0; i < subs.length; i++)
				for (i in 0...subs.length)
					geometry.addSubGeometry(subs[i]);
			}
		}
		
		private function translateVertexData(face:FaceData, vertexIndex:Int, vertices:Array<Float>, uvs:Array<Float>, indices:Array<UInt>, normals:Array<Float>):Void
		{
			var index:UInt;
			var vertex:Vertex;
			var vertexNormal:Vertex;
			var uv:UV;
			
			if (!_realIndices[face.indexIds[vertexIndex]]) {
				index = _vertexIndex;
				_realIndices[face.indexIds[vertexIndex]] = ++_vertexIndex;
				vertex = _vertices[face.vertexIndices[vertexIndex] - 1];
				vertices.push(vertex.x*_scale, vertex.y*_scale, vertex.z*_scale);
				
				if (face.normalIndices.length > 0) {
					vertexNormal = _vertexNormals[face.normalIndices[vertexIndex] - 1];
					normals.push(vertexNormal.x, vertexNormal.y, vertexNormal.z);
				}
				
				if (face.uvIndices.length > 0) {
					
					try {
						uv = _uvs[face.uvIndices[vertexIndex] - 1];
						uvs.push(uv.u, uv.v);
						
					} catch (e:Error) {
						
						switch (vertexIndex) {
							case 0:
								uvs.push(0, 1);
								break;
							case 1:
								uvs.push(.5, 0);
								break;
							case 2:
								uvs.push(1, 1);
						}
					}
					
				}
				
			} else
				index = _realIndices[face.indexIds[vertexIndex]] - 1;
			
			indices.push(index);
		}
		
		/**
		 * Creates a new object group.
		 * @param trunk The data block containing the object tag and its parameters
		 */
		private function createObject(trunk:Array<Dynamic>):Void
		{
			_currentGroup = null;
			_currentMaterialGroup = null;
			_objects.push(_currentObject = new ObjectGroup());
			
			if (trunk)
				_currentObject.name = trunk[1];
		}
		
		/**
		 * Creates a new group.
		 * @param trunk The data block containing the group tag and its parameters
		 */
		private function createGroup(trunk:Array<Dynamic>):Void
		{
			if (!_currentObject)
				createObject(null);
			_currentGroup = new Group();
			
			_currentGroup.materialID = _activeMaterialID;
			
			if (trunk)
				_currentGroup.name = trunk[1];
			_currentObject.groups.push(_currentGroup);
			
			createMaterialGroup(null);
		}
		
		/**
		 * Creates a new material group.
		 * @param trunk The data block containing the material tag and its parameters
		 */
		private function createMaterialGroup(trunk:Array<Dynamic>):Void
		{
			_currentMaterialGroup = new MaterialGroup();
			if (trunk)
				_currentMaterialGroup.url = trunk[1];
			_currentGroup.materialGroups.push(_currentMaterialGroup);
		}
		
		/**
		 * Reads the next vertex coordinates.
		 * @param trunk The data block containing the vertex tag and its parameters
		 */
		private function parseVertex(trunk:Array<Dynamic>):Void
		{
			//for the very rare cases of other delimiters/charcodes seen in some obj files
			if (trunk.length > 4) {
				var nTrunk:Array<Dynamic> = [];
				var val:Float;
				// For loop conversion - 				for (var i:UInt = 1; i < trunk.length; ++i)
				var i:UInt = 0;
				for (i in 1...trunk.length) {
					val = parseFloat(trunk[i]);
					if (!isNaN(val))
						nTrunk.push(val);
				}
				_vertices.push(new Vertex(nTrunk[0], nTrunk[1], -nTrunk[2]));
			} else
				_vertices.push(new Vertex(parseFloat(trunk[1]), parseFloat(trunk[2]), -parseFloat(trunk[3])));
		
		}
		
		/**
		 * Reads the next uv coordinates.
		 * @param trunk The data block containing the uv tag and its parameters
		 */
		private function parseUV(trunk:Array<Dynamic>):Void
		{
			if (trunk.length > 3) {
				var nTrunk:Array<Dynamic> = [];
				var val:Float;
				// For loop conversion - 				for (var i:UInt = 1; i < trunk.length; ++i)
				var i:UInt = 0;
				for (i in 1...trunk.length) {
					val = parseFloat(trunk[i]);
					if (!isNaN(val))
						nTrunk.push(val);
				}
				_uvs.push(new UV(nTrunk[0], 1 - nTrunk[1]));
				
			} else
				_uvs.push(new UV(parseFloat(trunk[1]), 1 - parseFloat(trunk[2])));
		
		}
		
		/**
		 * Reads the next vertex normal coordinates.
		 * @param trunk The data block containing the vertex normal tag and its parameters
		 */
		private function parseVertexNormal(trunk:Array<Dynamic>):Void
		{
			if (trunk.length > 4) {
				var nTrunk:Array<Dynamic> = [];
				var val:Float;
				// For loop conversion - 				for (var i:UInt = 1; i < trunk.length; ++i)
				var i:UInt = 0;
				for (i in 1...trunk.length) {
					val = parseFloat(trunk[i]);
					if (!isNaN(val))
						nTrunk.push(val);
				}
				_vertexNormals.push(new Vertex(nTrunk[0], nTrunk[1], -nTrunk[2]));
				
			} else
				_vertexNormals.push(new Vertex(parseFloat(trunk[1]), parseFloat(trunk[2]), -parseFloat(trunk[3])));
		}
		
		/**
		 * Reads the next face's indices.
		 * @param trunk The data block containing the face tag and its parameters
		 */
		private function parseFace(trunk:Array<Dynamic>):Void
		{
			var len:UInt = trunk.length;
			var face:FaceData = new FaceData();
			
			if (!_currentGroup)
				createGroup(null);
			
			var indices:Array<Dynamic>;
			// For loop conversion - 			for (var i:UInt = 1; i < len; ++i)
			var i:UInt = 0;
			for (i in 1...len) {
				if (trunk[i] == "")
					continue;
				indices = trunk[i].split("/");
				face.vertexIndices.push(parseIndex(parseInt(indices[0]), _vertices.length));
				if (indices[1] && String(indices[1]).length > 0)
					face.uvIndices.push(parseIndex(parseInt(indices[1]), _uvs.length));
				if (indices[2] && String(indices[2]).length > 0)
					face.normalIndices.push(parseIndex(parseInt(indices[2]), _vertexNormals.length));
				face.indexIds.push(trunk[i]);
			}
			
			_currentMaterialGroup.faces.push(face);
		}
		
		/**
		 * This is a hack around negative face coords
		 */
		private function parseIndex(index:Int, length:UInt):Int
		{
			if (index < 0)
				return index + length + 1;
			else
				return index;
		}
		
		private function parseMtl(data:String):Void
		{
			var materialDefinitions:Array<Dynamic> = data.split('newmtl');
			var lines:Array<Dynamic>;
			var trunk:Array<Dynamic>;
			var j:UInt;
			
			var basicSpecularMethod:BasicSpecularMethod;
			var useSpecular:Bool;
			var useColor:Bool;
			var diffuseColor:UInt;
			var ambientColor:UInt;
			var specularColor:UInt;
			var specular:Float;
			var alpha:Float;
			var mapkd:String;
			
			// For loop conversion - 						for (var i:UInt = 0; i < materialDefinitions.length; ++i)
			
			var i:UInt = 0;
			
			for (i in 0...materialDefinitions.length) {
				
				lines = (materialDefinitions[i].split('\r') as Array).join("").split('\n');
				
				if (lines.length == 1)
					lines = materialDefinitions[i].split(String.fromCharCode(13));
				
				diffuseColor = ambientColor = specularColor = 0xFFFFFF;
				specular = 0;
				useSpecular = false;
				useColor = false;
				alpha = 1;
				mapkd = "";
				
				// For loop conversion - 								for (j = 0; j < lines.length; ++j)
				
				for (j in 0...lines.length) {
					lines[j] = lines[j].replace(/\s+$/, "");
					
					if (lines[j].substring(0, 1) != "#" && (j == 0 || lines[j] != "")) {
						trunk = lines[j].split(" ");
						
						if (String(trunk[0]).charCodeAt(0) == 9 || String(trunk[0]).charCodeAt(0) == 32)
							trunk[0] = trunk[0].substring(1, trunk[0].length);
						
						if (j == 0) {
							_lastMtlID = trunk.join("");
							_lastMtlID = (_lastMtlID == "")? "def000" : _lastMtlID;
							
						} else {
							
							switch (trunk[0]) {
								
								case "Ka":
									if (trunk[1] && !isNaN(Number(trunk[1])) && trunk[2] && !isNaN(Number(trunk[2])) && trunk[3] && !isNaN(Number(trunk[3])))
										ambientColor = trunk[1]*255 << 16 | trunk[2]*255 << 8 | trunk[3]*255;
									break;
								
								case "Ks":
									if (trunk[1] && !isNaN(Number(trunk[1])) && trunk[2] && !isNaN(Number(trunk[2])) && trunk[3] && !isNaN(Number(trunk[3]))) {
										specularColor = trunk[1]*255 << 16 | trunk[2]*255 << 8 | trunk[3]*255;
										useSpecular = true;
									}
									break;
								
								case "Ns":
									if (trunk[1] && !isNaN(Number(trunk[1])))
										specular = Number(trunk[1])*0.001;
									if (specular == 0)
										useSpecular = false;
									break;
								
								case "Kd":
									if (trunk[1] && !isNaN(Number(trunk[1])) && trunk[2] && !isNaN(Number(trunk[2])) && trunk[3] && !isNaN(Number(trunk[3]))) {
										diffuseColor = trunk[1]*255 << 16 | trunk[2]*255 << 8 | trunk[3]*255;
										useColor = true;
									}
									break;
								
								case "tr":
								case "d":
									if (trunk[1] && !isNaN(Number(trunk[1])))
										alpha = Number(trunk[1]);
									break;
								
								case "map_Kd":
									mapkd = parseMapKdString(trunk);
									mapkd = mapkd.replace(/\\/g, "/");
							}
						}
					}
				}
				
				if (mapkd != "") {
					
					if (useSpecular) {
						
						basicSpecularMethod = new BasicSpecularMethod();
						basicSpecularMethod.specularColor = specularColor;
						basicSpecularMethod.specular = specular;
						
						var specularData:SpecularData = new SpecularData();
						specularData.alpha = alpha;
						specularData.basicSpecularMethod = basicSpecularMethod;
						specularData.materialID = _lastMtlID;
						
						if (!_materialSpecularData)
							_materialSpecularData = new Array<SpecularData>();
						
						_materialSpecularData.push(specularData);
					}
					
					addDependency(_lastMtlID, new URLRequest(mapkd));
					
				} else if (useColor && !isNaN(diffuseColor)) {
					
					var lm:LoadedMaterial = new LoadedMaterial();
					lm.materialID = _lastMtlID;
					
					if (alpha == 0)
						trace("Warning: an alpha value of 0 was found in mtl color tag (Tr or d) ref:" + _lastMtlID + ", mesh(es) using it will be invisible!");
					
					var cm:MaterialBase;
					if (materialMode < 2) {
						cm = new ColorMaterial(diffuseColor);
						ColorMaterial(cm).alpha = alpha;
						ColorMaterial(cm).ambientColor = ambientColor;
						ColorMaterial(cm).repeat = true;
						if (useSpecular) {
							ColorMaterial(cm).specularColor = specularColor;
							ColorMaterial(cm).specular = specular;
						}
					} else {
						cm = new ColorMultiPassMaterial(diffuseColor);
						ColorMultiPassMaterial(cm).ambientColor = ambientColor;
						ColorMultiPassMaterial(cm).repeat = true;
						if (useSpecular) {
							ColorMultiPassMaterial(cm).specularColor = specularColor;
							ColorMultiPassMaterial(cm).specular = specular;
						}
					}
					
					lm.cm = cm;
					_materialLoaded.push(lm);
					
					if (_meshes.length > 0)
						applyMaterial(lm);
					
				}
			}
			
			_mtlLibLoaded = true;
		}
		
		private function parseMapKdString(trunk:Array<Dynamic>):String
		{
			var url:String = "";
			var i:Int;
			var breakflag:Bool;
			
			// For loop conversion - 						for (i = 1; i < trunk.length; )
			
			for (i in 1...trunk.length) {
				switch (trunk[i]) {
					case "-blendu":
					case "-blendv":
					case "-cc":
					case "-clamp":
					case "-texres":
						i += 2; //Skip ahead 1 attribute
						break;
					case "-mm":
						i += 3; //Skip ahead 2 attributes
						break;
					case "-o":
					case "-s":
					case "-t":
						i += 4; //Skip ahead 3 attributes
						continue;
					default:
						breakflag = true;
						break;
				}
				
				if (breakflag)
					break;
			}
			
			//Reconstruct URL/filename
			for (i; i < trunk.length; i++) {
				url += trunk[i];
				url += " ";
			}
			
			//Remove the extraneous space and/or newline from the right side
			url = url.replace(/\s+$/, "");
			
			return url;
		}
		
		private function loadMtl(mtlurl:String):Void
		{
			// Add raw-data dependency to queue and load dependencies now,
			// which will pause the parsing in the meantime.
			addDependency('mtl', new URLRequest(mtlurl), true);
			pauseAndRetrieveDependencies();
		}
		
		private function applyMaterial(lm:LoadedMaterial):Void
		{
			var decomposeID:Array<Dynamic>;
			var mesh:Mesh;
			var mat:MaterialBase;
			var j:UInt;
			var specularData:SpecularData;
			
			// For loop conversion - 						for (var i:UInt = 0; i < _meshes.length; ++i)
			
			var i:UInt = 0;
			
			for (i in 0..._meshes.length) {
				mesh = _meshes[i];
				decomposeID = mesh.material.name.split("~");
				
				if (decomposeID[0] == lm.materialID) {
					
					if (lm.cm) {
						if (mesh.material)
							mesh.material = null;
						mesh.material = lm.cm;
						
					} else if (lm.texture) {
						if (materialMode < 2) { // if materialMode is 0 or 1, we create a SinglePass				
							mat = TextureMaterial(mesh.material);
							TextureMaterial(mat).texture = lm.texture;
							TextureMaterial(mat).ambientColor = lm.ambientColor;
							TextureMaterial(mat).alpha = lm.alpha;
							TextureMaterial(mat).repeat = true;
							
							if (lm.specularMethod) {
								// By setting the specularMethod property to null before assigning
								// the actual method instance, we avoid having the properties of
								// the new method being overridden with the settings from the old
								// one, which is default behavior of the setter.
								TextureMaterial(mat).specularMethod = null;
								TextureMaterial(mat).specularMethod = lm.specularMethod;
							} else if (_materialSpecularData) {
								// For loop conversion - 								for (j = 0; j < _materialSpecularData.length; ++j)
								for (j in 0..._materialSpecularData.length) {
									specularData = _materialSpecularData[j];
									if (specularData.materialID == lm.materialID) {
										TextureMaterial(mat).specularMethod = null; // Prevent property overwrite (see above)
										TextureMaterial(mat).specularMethod = specularData.basicSpecularMethod;
										TextureMaterial(mat).ambientColor = specularData.ambientColor;
										TextureMaterial(mat).alpha = specularData.alpha;
										break;
									}
								}
							}
						} else { //if materialMode==2 this is a MultiPassTexture					
							mat = TextureMultiPassMaterial(mesh.material);
							TextureMultiPassMaterial(mat).texture = lm.texture;
							TextureMultiPassMaterial(mat).ambientColor = lm.ambientColor;
							TextureMultiPassMaterial(mat).repeat = true;
							
							if (lm.specularMethod) {
								// By setting the specularMethod property to null before assigning
								// the actual method instance, we avoid having the properties of
								// the new method being overridden with the settings from the old
								// one, which is default behavior of the setter.
								TextureMultiPassMaterial(mat).specularMethod = null;
								TextureMultiPassMaterial(mat).specularMethod = lm.specularMethod;
							} else if (_materialSpecularData) {
								// For loop conversion - 								for (j = 0; j < _materialSpecularData.length; ++j)
								for (j in 0..._materialSpecularData.length) {
									specularData = _materialSpecularData[j];
									if (specularData.materialID == lm.materialID) {
										TextureMultiPassMaterial(mat).specularMethod = null; // Prevent property overwrite (see above)
										TextureMultiPassMaterial(mat).specularMethod = specularData.basicSpecularMethod;
										TextureMultiPassMaterial(mat).ambientColor = specularData.ambientColor;
										break;
									}
								}
							}
						}
					}
					
					mesh.material.name = decomposeID[1]? decomposeID[1] : decomposeID[0];
					_meshes.splice(i, 1);
					--i;
				}
			}
			
			if (lm.cm || mat)
				finalizeAsset(lm.cm || mat);
		}
		
		private function applyMaterials():Void
		{
			if (_materialLoaded.length == 0)
				return;
			
			// For loop conversion - 						for (var i:UInt = 0; i < _materialLoaded.length; ++i)
			
			var i:UInt = 0;
			
			for (i in 0..._materialLoaded.length)
				applyMaterial(_materialLoaded[i]);
		}
	}
}

import away3d.materials.MaterialBase;
import away3d.materials.methods.BasicSpecularMethod;
import away3d.textures.Texture2DBase;

class ObjectGroup
{
	public var name:String;
	public var groups:Array<Group> = new Array<Group>();
	
	public function ObjectGroup()
	{
	}
}

class Group
{
	public var name:String;
	public var materialID:String;
	public var materialGroups:Array<MaterialGroup> = new Array<MaterialGroup>();
	
	public function Group()
	{
	}
}

class MaterialGroup
{
	public var url:String;
	public var faces:Array<FaceData> = new Array<FaceData>();
	
	public function MaterialGroup()
	{
	}
}

class SpecularData
{
	public var materialID:String;
	public var basicSpecularMethod:BasicSpecularMethod;
	public var ambientColor:UInt = 0xFFFFFF;
	public var alpha:Float = 1;
	
	public function SpecularData()
	{
	}
}

class LoadedMaterial
{
	import away3d.materials.ColorMaterial;
	
	public var materialID:String;
	public var texture:Texture2DBase;
	public var cm:MaterialBase;
	public var specularMethod:BasicSpecularMethod;
	public var ambientColor:UInt = 0xFFFFFF;
	public var alpha:Float = 1;
	
	public function LoadedMaterial()
	{
	}
}

class FaceData
{
	public var vertexIndices:Array<UInt> = new Array<UInt>();
	public var uvIndices:Array<UInt> = new Array<UInt>();
	public var normalIndices:Array<UInt> = new Array<UInt>();
	public var indexIds:Array<String> = new Array<String>(); // used for real index lookups
	
	public function FaceData()
	{
	}

