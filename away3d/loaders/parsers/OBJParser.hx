package away3d.loaders.parsers;

import away3d.core.base.Geometry;
import away3d.core.base.ISubGeometry;
import away3d.core.base.data.UV;
import away3d.core.base.data.Vertex;
import away3d.debug.Debug;
import away3d.entities.Mesh;
import away3d.library.assets.Asset3DType;
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

import openfl.errors.Error;
import openfl.net.URLRequest;
import openfl.Vector;

/**
 * OBJParser provides a parser for the OBJ data type.
 */
class OBJParser extends ParserBase
{
	private var _textData:String;
	private var _startedParsing:Bool;
	private var _charIndex:Int;
	private var _oldIndex:Int;
	private var _stringLength:Int;
	private var _currentObject:ObjectGroup;
	private var _currentGroup:Group;
	private var _currentMaterialGroup:MaterialGroup;
	private var _objects:Vector<ObjectGroup>;
	private var _materialIDs:Vector<String>;
	private var _materialLoaded:Vector<LoadedMaterial>;
	private var _materialSpecularData:Vector<SpecularData>;
	private var _meshes:Vector<Mesh>;
	private var _lastMtlID:String;
	private var _objectIndex:Int;
	private var _realIndices:Map<String, Int>;
	private var _vertexIndex:Int;
	private var _vertices:Vector<Vertex>;
	private var _vertexNormals:Vector<Vertex>;
	private var _uvs:Vector<UV>;
	private var _scale:Float;
	private var _mtlLib:Bool;
	private var _mtlLibLoaded:Bool = true;
	private var _activeMaterialID:String = "";
	
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
	public var scale(null, set):Float;
	
	private function set_scale(value:Float):Float
	{
		return _scale = value;
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
		var hasV:Bool = false;
		var hasF:Bool = false;
		
		if (content != null) {
			hasV = content.indexOf("\nv ") != -1;
			hasF = content.indexOf("\nf ") != -1;
		}
		
		return hasV && hasF;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function resolveDependency(resourceDependency:ResourceDependency):Void
	{
		if (resourceDependency.id == 'mtl') {
			var str:String = ParserUtil.toString(resourceDependency.data);
			parseMtl(str);
			
		} else {
			
			var asset:IAsset;
			
			if (resourceDependency.assets.length != 1)
				return;
			
			asset = resourceDependency.assets[0];
			
			if (asset.assetType == Asset3DType.TEXTURE) {
				var lm:LoadedMaterial = new LoadedMaterial();
				lm.materialID = resourceDependency.id;
				lm.texture = cast(asset, Texture2DBase);
				
				_materialLoaded.push(lm);
				
				if (_meshes.length > 0)
					applyMaterial(lm);
			}
		}
	}
	
	/**
	 * @inheritDoc
	 */
	override private function resolveDependencyFailure(resourceDependency:ResourceDependency):Void
	{
		var lm:LoadedMaterial = null;
		if (resourceDependency.id == "mtl") {
			_mtlLib = false;
			_mtlLibLoaded = false;
		} else {
			lm = new LoadedMaterial();
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
		var trunk:Array<String>;
		
		if (!_startedParsing) {
			_textData = getTextData();
			// Merge linebreaks that are immediately preceeded by
			// the "escape" backward slash into single lines.
			var reg:EReg = ~/\\[\r\n]+\s*/gm;
			_textData = reg.replace(_textData, ' ');
		}
		
		if (_textData.indexOf(creturn) == -1)
			creturn = String.fromCharCode(13);
		
		if (!_startedParsing) {
			_startedParsing = true;
			_vertices = new Vector<Vertex>();
			_vertexNormals = new Vector<Vertex>();
			_materialIDs = new Vector<String>();
			_materialLoaded = new Vector<LoadedMaterial>();
			_meshes = new Vector<Mesh>();
			_uvs = new Vector<UV>();
			_stringLength = _textData.length;
			_charIndex = _textData.indexOf(creturn, 0);
			_oldIndex = 0;
			_objects = new Vector<ObjectGroup>();
			_objectIndex = 0;
		}
		
		while (_charIndex < _stringLength && hasTime()) {
			_charIndex = _textData.indexOf(creturn, _oldIndex);
			
			if (_charIndex == -1)
				_charIndex = _stringLength;
			
			line = _textData.substring(_oldIndex, _charIndex);
			line = line.split('\r').join("");
			line = StringTools.replace(line, "  ", " ");
			trunk = line.split(" ");
			_oldIndex = _charIndex + 1;
			parseLine(trunk);
			
			// If whatever was parsed on this line resulted in the
			// parsing being paused to retrieve dependencies, break
			// here and do not continue parsing until un-paused.
			if (parsingPaused)
				return ParserBase.MORE_TO_PARSE;
		}
		
		if (_charIndex >= _stringLength) {
			
			if (_mtlLib && !_mtlLibLoaded)
				return ParserBase.MORE_TO_PARSE;
			
			translate();
			applyMaterials();
			
			return ParserBase.PARSING_DONE;
		}
		
		return ParserBase.MORE_TO_PARSE;
	}
	
	/**
	 * Parses a single line in the OBJ file.
	 */
	private function parseLine(trunk:Array<String>):Void
	{
		switch (trunk[0]) {
			case "mtllib":
				_mtlLib = true;
				_mtlLibLoaded = false;
				loadMtl(trunk[1]);
			case "g":
				createGroup(trunk);
			case "o":
				createObject(trunk);
			case "usemtl":
				if (_mtlLib) {
					if (trunk[1] == "")
						trunk[1] = "def000";
					_materialIDs.push(trunk[1]);
					_activeMaterialID = trunk[1];
					if (_currentGroup != null)
						_currentGroup.materialID = _activeMaterialID;
				}
			case "v":
				parseVertex(trunk);
			case "vt":
				parseUV(trunk);
			case "vn":
				parseVertexNormal(trunk);
			case "f":
				parseFace(trunk);
		}
	}
	
	/**
	 * Converts the parsed data into an Away3D scenegraph structure
	 */
	private function translate():Void
	{
		for (objIndex in 0..._objects.length) {
			var groups:Vector<Group> = _objects[objIndex].groups;
			var numGroups:UInt = groups.length;
			var materialGroups:Vector<MaterialGroup>;
			var numMaterialGroups:UInt;
			var geometry:Geometry;
			var mesh:Mesh;
			
			var m:Int;
			var sm:Int;
			var bmMaterial:MaterialBase;
			
			for (g in 0...numGroups) {
				geometry = new Geometry();
				materialGroups = groups[g].materialGroups;
				numMaterialGroups = materialGroups.length;
				
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
				
				if (_objects[objIndex].name != null) {
					// this is a full independent object ('o' tag in OBJ file)
					mesh.name = _objects[objIndex].name;
				} else if (groups[g].name != null) {
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
		var faces:Vector<FaceData> = materialGroup.faces;
		var face:FaceData;
		var numFaces:UInt = faces.length;
		var numVerts:UInt;
		var subs:Vector<ISubGeometry>;
		
		var vertices:Vector<Float> = new Vector<Float>();
		var uvs:Vector<Float> = new Vector<Float>();
		var normals:Vector<Float> = new Vector<Float>();
		var indices:Vector<UInt> = new Vector<UInt>();
		
		_realIndices = new Map<String, Int>();
		_vertexIndex = 0;
		
		for (i in 0...numFaces) {
			face = faces[i];
			numVerts = face.indexIds.length - 1;
			for (j in 1...numVerts) {
				translateVertexData(face, j, vertices, uvs, indices, normals);
				translateVertexData(face, 0, vertices, uvs, indices, normals);
				translateVertexData(face, j + 1, vertices, uvs, indices, normals);
			}
		}
		if (vertices.length > 0) {
			subs = GeomUtil.fromVectors(vertices, indices, uvs, normals, null, null, null);
			for (i in 0...subs.length)
				geometry.addSubGeometry(subs[i]);
		}
	}
	
	private function translateVertexData(face:FaceData, vertexIndex:Int, vertices:Vector<Float>, uvs:Vector<Float>, indices:Vector<UInt>, normals:Vector<Float>):Void
	{
		var index:Int;
		var vertex:Vertex;
		var vertexNormal:Vertex;
		var uv:UV;
		
		if (!_realIndices.exists(face.indexIds[vertexIndex])) {
			index = _vertexIndex;
			_realIndices.set(face.indexIds[vertexIndex], ++_vertexIndex);
			vertex = _vertices[face.vertexIndices[vertexIndex] - 1];
			vertices.push(vertex.x * _scale);
			vertices.push(vertex.y * _scale);
			vertices.push(vertex.z * _scale);
			
			if (face.normalIndices.length > 0) {
				vertexNormal = _vertexNormals[face.normalIndices[vertexIndex] - 1];
				normals.push(vertexNormal.x);
				normals.push(vertexNormal.y);
				normals.push(vertexNormal.z);
			}
			
			if (face.uvIndices.length > 0) {
				
				try {
					uv = _uvs[face.uvIndices[vertexIndex] - 1];
					uvs.push(uv.u);
					uvs.push(uv.v);
					
				} catch (e:Error) {
					
					switch (vertexIndex) {
						case 0:
							uvs.push(0);
							uvs.push(1);
						case 1:
							uvs.push(.5);
							uvs.push(0);
						case 2:
							uvs.push(1);
							uvs.push(1);
					}
				}
				
			}
			
		} else
			index = _realIndices.get(face.indexIds[vertexIndex]) - 1;
		
		indices.push(index);
	}
	
	/**
	 * Creates a new object group.
	 * @param trunk The data block containing the object tag and its parameters
	 */
	private function createObject(trunk:Array<String>):Void
	{
		_currentGroup = null;
		_currentMaterialGroup = null;
		_objects.push(_currentObject = new ObjectGroup());
		
		if (trunk != null)
			_currentObject.name = trunk[1];
	}
	
	/**
	 * Creates a new group.
	 * @param trunk The data block containing the group tag and its parameters
	 */
	private function createGroup(trunk:Array<String>):Void
	{
		if (_currentObject == null)
			createObject(null);
		_currentGroup = new Group();
		
		_currentGroup.materialID = _activeMaterialID;
		
		if (trunk != null)
			_currentGroup.name = trunk[1];
		_currentObject.groups.push(_currentGroup);
		
		createMaterialGroup(null);
	}
	
	/**
	 * Creates a new material group.
	 * @param trunk The data block containing the material tag and its parameters
	 */
	private function createMaterialGroup(trunk:Array<String>):Void
	{
		_currentMaterialGroup = new MaterialGroup();
		if (trunk != null)
			_currentMaterialGroup.url = trunk[1];
		_currentGroup.materialGroups.push(_currentMaterialGroup);
	}
	
	/**
	 * Reads the next vertex coordinates.
	 * @param trunk The data block containing the vertex tag and its parameters
	 */
	private function parseVertex(trunk:Array<String>):Void
	{
		//for the very rare cases of other delimiters/charcodes seen in some obj files
		if (trunk.length > 4) {
			var nTrunk:Array<Float> = [];
			var val:Float;
			for (i in 1...trunk.length) {
				val = Std.parseFloat(trunk[i]);
				if (!Math.isNaN(val))
					nTrunk.push(val);
			}
			_vertices.push(new Vertex(nTrunk[0], nTrunk[1], -nTrunk[2]));
		} else
			_vertices.push(new Vertex(Std.parseFloat(trunk[1]), Std.parseFloat(trunk[2]), -Std.parseFloat(trunk[3])));
	
	}
	
	/**
	 * Reads the next uv coordinates.
	 * @param trunk The data block containing the uv tag and its parameters
	 */
	private function parseUV(trunk:Array<String>):Void
	{
		if (trunk.length > 3) {
			var nTrunk:Array<Float> = [];
			var val:Float;
			for (i in 1...trunk.length) {
				val = Std.parseFloat(trunk[i]);
				if (!Math.isNaN(val))
					nTrunk.push(val);
			}
			_uvs.push(new UV(nTrunk[0], 1 - nTrunk[1]));
			
		} else
			_uvs.push(new UV(Std.parseFloat(trunk[1]), 1 - Std.parseFloat(trunk[2])));
	
	}
	
	/**
	 * Reads the next vertex normal coordinates.
	 * @param trunk The data block containing the vertex normal tag and its parameters
	 */
	private function parseVertexNormal(trunk:Array<String>):Void
	{
		if (trunk.length > 4) {
			var nTrunk:Array<Float> = [];
			var val:Float;
			for (i in 1...trunk.length) {
				val = Std.parseFloat(trunk[i]);
				if (!Math.isNaN(val))
					nTrunk.push(val);
			}
			_vertexNormals.push(new Vertex(nTrunk[0], nTrunk[1], -nTrunk[2]));
			
		} else
			_vertexNormals.push(new Vertex(Std.parseFloat(trunk[1]), Std.parseFloat(trunk[2]), -Std.parseFloat(trunk[3])));
	}
	
	/**
	 * Reads the next face's indices.
	 * @param trunk The data block containing the face tag and its parameters
	 */
	private function parseFace(trunk:Array<String>):Void
	{
		var len:Int = trunk.length;
		var face:FaceData = new FaceData();
		
		if (_currentGroup == null)
			createGroup(null);
		
		var indices:Array<String>;
		for (i in 1...len) {
			if (trunk[i] == "")
				continue;
			indices = trunk[i].split("/");
			face.vertexIndices.push(parseIndex(Std.parseInt(indices[0]), _vertices.length));
			if (indices[1] != null && indices[1].length > 0)
				face.uvIndices.push(parseIndex(Std.parseInt(indices[1]), _uvs.length));
			if (indices[2] != null && indices[2].length > 0)
				face.normalIndices.push(parseIndex(Std.parseInt(indices[2]), _vertexNormals.length));
			face.indexIds.push(trunk[i]);
		}
		
		_currentMaterialGroup.faces.push(face);
	}
	
	/**
	 * This is a hack around negative face coords
	 */
	private function parseIndex(index:Int, length:Int):Int
	{
		if (index < 0)
			return index + length + 1;
		else
			return index;
	}
	
	private function parseMtl(data:String):Void
	{
		var materialDefinitions:Array<String> = data.split('newmtl');
		var lines:Array<String>;
		var trunk:Array<String>;
		var j:Int;
		
		var basicSpecularMethod:BasicSpecularMethod;
		var useSpecular:Bool;
		var useColor:Bool;
		var diffuseColor:UInt;
		var ambientColor:UInt;
		var specularColor:UInt;
		var specular:Float;
		var alpha:Float;
		var mapkd:String;
		
		for (i in 0...materialDefinitions.length) {
			
			lines = materialDefinitions[i].split('\r').join("").split('\n');
			
			if (lines.length == 1)
				lines = materialDefinitions[i].split(String.fromCharCode(13));
			
			diffuseColor = ambientColor = specularColor = 0xFFFFFF;
			specular = 0;
			useSpecular = false;
			useColor = false;
			alpha = 1;
			mapkd = "";
			
			for (j in 0...lines.length) {
				var ereg:EReg = ~/\s+$/;
				lines[j] = ereg.replace(lines[j], "");
				
				if (lines[j].substring(0, 1) != "#" && (j == 0 || lines[j] != "")) {
					trunk = lines[j].split(" ");
					
					if (trunk[0].charCodeAt(0) == 9 || trunk[0].charCodeAt(0) == 32)
						trunk[0] = trunk[0].substring(1, trunk[0].length);
					
					if (j == 0) {
						_lastMtlID = trunk.join("");
						_lastMtlID = (_lastMtlID == "")? "def000" : _lastMtlID;
						
					} else {
						
						switch (trunk[0]) {
							
							case "Ka":
								if (trunk[1] != "" && !Math.isNaN(Std.parseFloat(trunk[1])) &&
									trunk[2] != "" && !Math.isNaN(Std.parseFloat(trunk[2])) &&
									trunk[3] != "" && !Math.isNaN(Std.parseFloat(trunk[3])))
									ambientColor = toColor(trunk[1], trunk[2], trunk[3]);
							
							case "Ks":
								if (trunk[1] != "" && !Math.isNaN(Std.parseFloat(trunk[1])) &&
									trunk[2] != "" && !Math.isNaN(Std.parseFloat(trunk[2])) &&
									trunk[3] != "" && !Math.isNaN(Std.parseFloat(trunk[3]))) {
									specularColor = toColor(trunk[1], trunk[2], trunk[3]);
									useSpecular = true;
								}
							
							case "Ns":
								if (trunk[1] != "" && !Math.isNaN(Std.parseFloat(trunk[1])))
									specular = Std.parseFloat(trunk[1]) * 0.001;
								if (specular == 0)
									useSpecular = false;
							
							case "Kd":
								if (trunk[1] != "" && !Math.isNaN(Std.parseFloat(trunk[1])) &&
									trunk[2] != "" && !Math.isNaN(Std.parseFloat(trunk[2])) &&
									trunk[3] != "" && !Math.isNaN(Std.parseFloat(trunk[3]))) {
									diffuseColor = toColor(trunk[1], trunk[2], trunk[3]);
									useColor = true;
								}
							
							case "tr", "d":
								if (trunk[1] != "" && !Math.isNaN(Std.parseFloat(trunk[1])))
									alpha = Std.parseFloat(trunk[1]);
							
							case "map_Kd":
								mapkd = parseMapKdString(trunk);
								mapkd = StringTools.replace(mapkd, "\\", "/");
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
					
					if (_materialSpecularData == null)
						_materialSpecularData = new Vector<SpecularData>();
					
					_materialSpecularData.push(specularData);
				}
				
				addDependency(_lastMtlID, new URLRequest(mapkd));
				
			} else if (useColor && !Math.isNaN(diffuseColor)) {
				
				var lm:LoadedMaterial = new LoadedMaterial();
				lm.materialID = _lastMtlID;
				
				if (alpha == 0)
					Debug.trace("Warning: an alpha value of 0 was found in mtl color tag (Tr or d) ref:" + _lastMtlID + ", mesh(es) using it will be invisible!");
				
				var cm:MaterialBase;
				if (materialMode < 2) {
					cm = new ColorMaterial(diffuseColor);
					cast(cm, ColorMaterial).alpha = alpha;
					cast(cm, ColorMaterial).ambientColor = ambientColor;
					cast(cm, ColorMaterial).repeat = true;
					if (useSpecular) {
						cast(cm, ColorMaterial).specularColor = specularColor;
						cast(cm, ColorMaterial).specular = specular;
					}
				} else {
					cm = new ColorMultiPassMaterial(diffuseColor);
					cast(cm, ColorMultiPassMaterial).ambientColor = ambientColor;
					cast(cm, ColorMultiPassMaterial).repeat = true;
					if (useSpecular) {
						cast(cm, ColorMultiPassMaterial).specularColor = specularColor;
						cast(cm, ColorMultiPassMaterial).specular = specular;
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
	
	private function toColor(r:String, g:String, b:String):UInt
	{
		return Std.int(Std.parseFloat(r) * 255) << 16 | Std.int(Std.parseFloat(g) * 255) << 8 | Std.int(Std.parseFloat(b) * 255);
	}
	
	private function parseMapKdString(trunk:Array<String>):String
	{
		var url:String = "";
		var i:Int;
		var breakflag:Bool = false;
		
		i = 1;
		while (i < trunk.length) {
			switch (trunk[i]) {
				case "-blendu", "-blendv", "-cc", "-clamp", "-texres":
					i += 2; //Skip ahead 1 attribute
				case "-mm":
					i += 3; //Skip ahead 2 attributes
				case "-o", "-s", "-t":
					i += 4; //Skip ahead 3 attributes
					continue;
				default:
					breakflag = true;
			}
			
			if (breakflag)
				break;
		}
		
		//Reconstruct URL/filename
		while (i < trunk.length) {
			url += trunk[i];
			url += " ";
			i++;
		}
		
		//Remove the extraneous space and/or newline from the right side
		url = ~/\s+$/.replace(url, "");
		
		return url;
	}
	
	private function loadMtl(mtlurl:String):Void
	{
		// CPP target cannot be recognized./
		if(mtlurl.indexOf("./") == 0){
			mtlurl = mtlurl.substr(2);
		}
		// Add raw-data dependency to queue and load dependencies now,
		// which will pause the parsing in the meantime.
		addDependency('mtl', new URLRequest(mtlurl), true);
		pauseAndRetrieveDependencies();
	}
	
	private function applyMaterial(lm:LoadedMaterial):Void
	{
		var decomposeID:Array<String> = null;
		var mesh:Mesh = null;
		var mat:MaterialBase = null;
		var specularData:SpecularData = null;
		
		var i:Int = 0;
		while (i < _meshes.length) {
			mesh = _meshes[i];
			decomposeID = mesh.material.name.split("~");
			
			if (decomposeID[0] == lm.materialID) {
				
				if (lm.cm != null) {
					if (mesh.material != null)
						mesh.material = null;
					mesh.material = lm.cm;
					
				} else if (lm.texture != null) {
					if (materialMode < 2) { // if materialMode is 0 or 1, we create a SinglePass				
						mat = cast(mesh.material, TextureMaterial);
						cast(mat, TextureMaterial).texture = lm.texture;
						cast(mat, TextureMaterial).ambientColor = lm.ambientColor;
						cast(mat, TextureMaterial).alpha = lm.alpha;
						cast(mat, TextureMaterial).repeat = true;
						
						if (lm.specularMethod != null) {
							// By setting the specularMethod property to null before assigning
							// the actual method instance, we avoid having the properties of
							// the new method being overridden with the settings from the old
							// one, which is default behavior of the setter.
							cast(mat, TextureMaterial).specularMethod = null;
							cast(mat, TextureMaterial).specularMethod = lm.specularMethod;
						} else if (_materialSpecularData != null) {
							for (j in 0..._materialSpecularData.length) {
								specularData = _materialSpecularData[j];
								if (specularData.materialID == lm.materialID) {
									cast(mat, TextureMaterial).specularMethod = null; // Prevent property overwrite (see above)
									cast(mat, TextureMaterial).specularMethod = specularData.basicSpecularMethod;
									cast(mat, TextureMaterial).ambientColor = specularData.ambientColor;
									cast(mat, TextureMaterial).alpha = specularData.alpha;
									break;
								}
							}
						}
					} else { //if materialMode==2 this is a MultiPassTexture					
						mat = cast(mesh.material, TextureMultiPassMaterial);
						cast(mat, TextureMultiPassMaterial).texture = lm.texture;
						cast(mat, TextureMultiPassMaterial).ambientColor = lm.ambientColor;
						cast(mat, TextureMultiPassMaterial).repeat = true;
						
						if (lm.specularMethod != null) {
							// By setting the specularMethod property to null before assigning
							// the actual method instance, we avoid having the properties of
							// the new method being overridden with the settings from the old
							// one, which is default behavior of the setter.
							cast(mat, TextureMultiPassMaterial).specularMethod = null;
							cast(mat, TextureMultiPassMaterial).specularMethod = lm.specularMethod;
						} else if (_materialSpecularData != null) {
							for (j in 0..._materialSpecularData.length) {
								specularData = _materialSpecularData[j];
								if (specularData.materialID == lm.materialID) {
									cast(mat, TextureMultiPassMaterial).specularMethod = null; // Prevent property overwrite (see above)
									cast(mat, TextureMultiPassMaterial).specularMethod = specularData.basicSpecularMethod;
									cast(mat, TextureMultiPassMaterial).ambientColor = specularData.ambientColor;
									break;
								}
							}
						}
					}
				}
				
				mesh.material.name = decomposeID[0] == "def000" ? decomposeID[1] + ".material" : decomposeID[0];
				_meshes.splice(i, 1);
				--i;
			}
			i++;
		}
		
		if (lm.cm != null || mat != null) {
			var m:MaterialBase = lm.cm != null ? lm.cm : mat;
			finalizeAsset(m);
		}
	}
	
	private function applyMaterials():Void
	{
		if (_materialLoaded.length == 0)
			return;
		
		for (i in 0..._materialLoaded.length)
			applyMaterial(_materialLoaded[i]);
	}
}

class ObjectGroup
{
	public var name:String;
	public var groups:Vector<Group> = new Vector<Group>();
	
	public function new()
	{
	}
}

class Group
{
	public var name:String;
	public var materialID:String;
	public var materialGroups:Vector<MaterialGroup> = new Vector<MaterialGroup>();
	
	public function new()
	{
	}
}

class MaterialGroup
{
	public var url:String;
	public var faces:Vector<FaceData> = new Vector<FaceData>();
	
	public function new()
	{
	}
}

class SpecularData
{
	public var materialID:String;
	public var basicSpecularMethod:BasicSpecularMethod;
	public var ambientColor:UInt = 0xFFFFFF;
	public var alpha:Float = 1;
	
	public function new()
	{
	}
}

class LoadedMaterial
{
	public var materialID:String;
	public var texture:Texture2DBase;
	public var cm:MaterialBase;
	public var specularMethod:BasicSpecularMethod;
	public var ambientColor:UInt = 0xFFFFFF;
	public var alpha:Float = 1;
	
	public function new()
	{
	}
}

class FaceData
{
	public var vertexIndices:Vector<UInt> = new Vector<UInt>();
	public var uvIndices:Vector<UInt> = new Vector<UInt>();
	public var normalIndices:Vector<UInt> = new Vector<UInt>();
	public var indexIds:Vector<String> = new Vector<String>(); // used for real index lookups

	public function new()
	{
	}
}