package away3d.loaders.parsers;

	import away3d.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	//import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.ISubGeometry;
	import away3d.entities.Mesh;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.loaders.misc.ResourceDependency;
	import away3d.loaders.parsers.utils.ParserUtil;
	import away3d.materials.ColorMaterial;
	import away3d.materials.ColorMultiPassMaterial;
	import away3d.materials.MaterialBase;
	import away3d.materials.MultiPassMaterialBase;
	import away3d.materials.SinglePassMaterialBase;
	import away3d.materials.TextureMaterial;
	import away3d.materials.TextureMultiPassMaterial;
	import away3d.materials.utils.DefaultMaterialManager;
	import away3d.textures.Texture2DBase;
	import away3d.tools.utils.GeomUtil;

	import away3d.materials.MaterialBase;
	import away3d.textures.Texture2DBase;

	import flash.geom.Vector3D;

	import away3d.utils.ArrayUtils;

	import haxe.ds.StringMap;

	//use namespace arcane;
	
	/**
	 * Max3DSParser provides a parser for the 3ds data type.
	 */
	class Max3DSParser extends ParserBase
	{
		var _byteData:ByteArray;
		
		var _textures:StringMap<TextureVO>;
		var _materials:StringMap<MaterialVO>;
		var _unfinalized_objects:StringMap<ObjectVO>;
		
		var _cur_obj_end:UInt;
		var _cur_obj:ObjectVO;
		
		var _cur_mat_end:UInt;
		var _cur_mat:MaterialVO;
		
		public function new()
		{
			super(ParserDataFormat.BINARY);
		}
		
		/**
		 * Indicates whether or not a given file extension is supported by the parser.
		 * @param extension The file extension of a potential file to be parsed.
		 * @return Whether or not the given file type is supported.
		 */
		public static function supportsType(extension:String):Bool
		{
			extension = extension.toLowerCase();
			return extension == "3ds";
		}
		
		/**
		 * Tests whether a data block can be parsed by the parser.
		 * @param data The data block to potentially be parsed.
		 * @return Whether or not the given data is supported.
		 */
		public static function supportsData(data:Dynamic):Bool
		{
			var ba:ByteArray;
			
			ba = ParserUtil.toByteArray(data);
			if (ba!=null) {
				ba.position = 0;
				if (ba.readShort() == 0x4d4d)
					return true;
			}
			
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		override function resolveDependency(resourceDependency:ResourceDependency):Void
		{
trace("Max3DSParser.resolveDependency-1:"+resourceDependency.assets.length);
			for (i in 0...resourceDependency.assets.length) {
trace("Max3DSParser.resolveDependency-1 - :"+Type.getClassName(Type.getClass(resourceDependency.assets[i])));
			}
			
			if (resourceDependency.assets.length == 2) {
				var asset:IAsset;
				
				asset = resourceDependency.assets[1];
trace("Max3DSParser.resolveDependency-2:"+Std.string(asset.assetType)+" resourceDependency.id="+resourceDependency.id);
				if (asset.assetType == AssetType.TEXTURE) {
					var tex:TextureVO;
					
					tex = _textures.get(resourceDependency.id);
trace("Max3DSParser.resolveDependency-3:"+resourceDependency.id+" asset:"+cast(asset, away3d.textures.BitmapTexture).width+"/"+cast(asset, away3d.textures.BitmapTexture).height);
					tex.texture = cast(asset, Texture2DBase);
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override function resolveDependencyFailure(resourceDependency:ResourceDependency):Void
		{
			// TODO: Implement
		}
		
		/**
		 * @inheritDoc
		 */
		private override function proceedParsing():Bool
		{
			if (_byteData==null) {
				_byteData = ParserUtil.toByteArray(_data);
				_byteData.position = 0;
				_byteData.endian = Endian.LITTLE_ENDIAN;
				
				_textures = new StringMap<TextureVO>();
				_materials = new StringMap<MaterialVO>();
				_unfinalized_objects = new StringMap<ObjectVO>();
			}
			
			// TODO: With this construct, the loop will run no-op for as long
			// as there is time once file has finished reading. Consider a nice
			// way to stop loop when byte array is empty, without putting it in
			// the while-conditional, which will prevent finalizations from
			// happening after the last chunk.
			while (hasTime()) {
				
				// If we are currently working on an object, and the most recent chunk was
				// the last one in that object, finalize the current object.
				if (_cur_mat!=null && _byteData.position >= _cur_mat_end) {
					finalizeCurrentMaterial();
				} else if (_cur_obj!=null && _byteData.position >= _cur_obj_end) {
					// Can't finalize at this point, because we have to wait until the full
					// animation section has been parsed for any potential pivot definitions
					_unfinalized_objects.set(_cur_obj.name, _cur_obj);
					_cur_obj_end = 0xffffffff; //uint.MAX_VALUE;
					_cur_obj = null;
				}
				
				if (_byteData.bytesAvailable>0) {
					var cid:UInt;
					var len:UInt;
					var end:UInt;
					
					cid = _byteData.readUnsignedShort();
					len = _byteData.readUnsignedInt();
					end = _byteData.position + (len - 6);

					switch (cid) {
						case 0x4D4D | 0x3D3D | 0xB000: // KEYF3DS
							// This types are "container chunks" and contain only
							// sub-chunks (no data on their own.) This means that
							// there is nothing more to parse at this point, and 
							// instead we should progress to the next chunk, which
							// will be the first sub-chunk of this one.
							continue;
						
						case 0xAFFF: // MATERIAL
							_cur_mat_end = end;
							_cur_mat = parseMaterial();
						
						case 0x4000: // EDIT_OBJECT
							_cur_obj_end = end;
							_cur_obj = new ObjectVO();
							_cur_obj.name = readNulTermString();
							_cur_obj.materials = new Array<String>();
							_cur_obj.materialFaces = new StringMap<Array<UInt>>();
						
						case 0x4100: // OBJ_TRIMESH 
							_cur_obj.type = AssetType.MESH;
						
						case 0x4110: // TRI_VERTEXL
							parseVertexList();
						
						case 0x4120: // TRI_FACELIST
							parseFaceList();
						
						case 0x4140: // TRI_MAPPINGCOORDS
							parseUVList();
						
						case 0x4130: // Face materials
							parseFaceMaterialList();
						
						case 0x4160: // Transform
							_cur_obj.transform = readTransform();
						
						case 0xB002: // Object animation (including pivot)
							parseObjectAnimation(end);
						
						case 0x4150: // Smoothing groups
							parseSmoothingGroups();
						
						default:
							// Skip this (unknown) chunk
							_byteData.position += (len - 6);
					}
					
					// Pause parsing if there were any dependencies found during this
					// iteration (i.e. if there are any dependencies that need to be
					// retrieved at this time.)
					if (dependencies.length>0) {
						pauseAndRetrieveDependencies();
					}
				}
			}
			
			// More parsing is required if the entire byte array has not yet
			// been read, or if there is a currently non-finalized object in
			// the pipeline.
			if (_byteData.bytesAvailable>0 || _cur_obj!=null || _cur_mat!=null)
				return ParserBase.MORE_TO_PARSE;
			else {
				var name:String;
				
				// Finalize any remaining objects before ending.
				for (name in _unfinalized_objects.keys()) {
					var obj:ObjectContainer3D;
					obj = constructObject(_unfinalized_objects.get(name));
					if (obj!=null)
						finalizeAsset(obj, name);
				}
				
				return ParserBase.PARSING_DONE;
			}
		}
		
		private function parseMaterial():MaterialVO
		{
			var mat:MaterialVO;
			
			mat = new MaterialVO();
			
			while (_byteData.position < _cur_mat_end) {
				var cid:UInt;
				var len:UInt;
				var end:UInt;
				
				cid = _byteData.readUnsignedShort();
				len = _byteData.readUnsignedInt();
				end = _byteData.position + (len - 6);
				
				switch (cid) {
					case 0xA000: // Material name
						mat.name = readNulTermString();
					
					case 0xA010: // Ambient color
						mat.ambientColor = readColor();
					
					case 0xA020: // Diffuse color
						mat.diffuseColor = readColor();
					
					case 0xA030: // Specular color
						mat.specularColor = readColor();
					
					case 0xA081: // Two-sided, existence indicates "true"
						mat.twoSided = true;
					
					case 0xA200: // Main (color) texture 
						mat.colorMap = parseTexture(end);
					
					case 0xA204: // Specular map
						mat.specularMap = parseTexture(end);
					
					default:
						_byteData.position = end;
				}
			}
			
			return mat;
		}

		
		private function parseTexture(end:UInt):TextureVO
		{
			var tex:TextureVO;
			
			tex = new TextureVO();
			
			while (_byteData.position < end) {
				var cid:UInt;
				var len:UInt;
				
				cid = _byteData.readUnsignedShort();
				len = _byteData.readUnsignedInt();
				
				switch (cid) {
					case 0xA300:
						tex.url = readNulTermString();
					
					default:
						// Skip this unknown texture sub-chunk
						_byteData.position += (len - 6);
				}
			}
			
			_textures.set(tex.url, tex);
			addDependency(tex.url, new URLRequest(tex.url));
			
			return tex;
		}
		
		private function parseVertexList():Void
		{
			var i:UInt = 0;
			var len:UInt;
			var count:UInt;
			
			count = _byteData.readUnsignedShort();
			_cur_obj.verts = ArrayUtils.Prefill(new Array<Float>(), count*3);
			
			i = 0;
			len = _cur_obj.verts.length;
			while (i < len) {
				var x:Float, y:Float, z:Float;
				
				x = _byteData.readFloat();
				y = _byteData.readFloat();
				z = _byteData.readFloat();
				
				_cur_obj.verts[i++] = x;
				_cur_obj.verts[i++] = z;
				_cur_obj.verts[i++] = y;
			}
		}
		
		private function parseFaceList():Void
		{
			var i:UInt = 0;
			var len:UInt;
			var count:UInt;
			
			count = _byteData.readUnsignedShort();
			_cur_obj.indices = ArrayUtils.Prefill(new Array<UInt>(), count*3);
			
			i = 0;
			len = _cur_obj.indices.length;
			while (i < len) {
				var i0:UInt, i1:UInt, i2:UInt;
				
				i0 = _byteData.readUnsignedShort();
				i1 = _byteData.readUnsignedShort();
				i2 = _byteData.readUnsignedShort();
				
				_cur_obj.indices[i++] = i0;
				_cur_obj.indices[i++] = i2;
				_cur_obj.indices[i++] = i1;
				
				// Skip "face info", irrelevant in Away3D
				_byteData.position += 2;
			}
			
			_cur_obj.smoothingGroups = ArrayUtils.Prefill(new Array<UInt>(), count);
		}
		
		private function parseSmoothingGroups():Void
		{
			var len:UInt = Std.int(_cur_obj.indices.length/3);
			var i:UInt = 0;
			while (i < len) {
				_cur_obj.smoothingGroups[i] = _byteData.readUnsignedInt();
				i++;
			}
		}
		
		private function parseUVList():Void
		{
			var i:UInt = 0;
			var len:UInt;
			var count:UInt;
			
			count = _byteData.readUnsignedShort();
			_cur_obj.uvs = ArrayUtils.Prefill(new Array<Float>(), count*2);
			
			i = 0;
			len = _cur_obj.uvs.length;
			while (i < len) {
				_cur_obj.uvs[i++] = _byteData.readFloat();
				_cur_obj.uvs[i++] = 1.0 - _byteData.readFloat();
			}
		}
		
		private function parseFaceMaterialList():Void
		{
			var mat:String;
			var count:UInt;
			var i:UInt = 0;
			var faces:Array<UInt>;
			
			mat = readNulTermString();
			count = _byteData.readUnsignedShort();
			
			faces = ArrayUtils.Prefill(new Array<UInt>(), count);
			i = 0;
			while (i < faces.length)
				faces[i++] = _byteData.readUnsignedShort();
			
			_cur_obj.materials.push(mat);
			_cur_obj.materialFaces.set(mat, faces);
		}
		
		private function parseObjectAnimation(end:Float):Void
		{
			var vo:ObjectVO;
			var obj:ObjectContainer3D;
			var pivot:Vector3D;
			var name:String = "";
			var hier:Int;
			
			// Pivot defaults to origin
			pivot = new Vector3D();
			
			while (_byteData.position < end) {
				var cid:UInt;
				var len:UInt;
				
				cid = _byteData.readUnsignedShort();
				len = _byteData.readUnsignedInt();
				
				switch (cid) {
					case 0xb010: // Name/hierarchy
						name = readNulTermString();
						_byteData.position += 4;
						hier = _byteData.readShort();
					
					case 0xb013: // Pivot
						pivot.x = _byteData.readFloat();
						pivot.z = _byteData.readFloat();
						pivot.y = _byteData.readFloat();
					
					default:
						_byteData.position += (len - 6);
				}
			}
			
			// If name is "$$$DUMMY" this is an empty object (e.g. a container)
			// and will be ignored in this version of the parser
			// TODO: Implement containers in 3DS parser.
			if (name != "$$$DUMMY" && _unfinalized_objects.exists(name)) {
				vo = _unfinalized_objects.get(name);
				obj = constructObject(vo, pivot);
				
				if (obj!=null)
					finalizeAsset(obj, vo.name);
				
				_unfinalized_objects.remove(name);
			}
		}
		
		private function constructObject(obj:ObjectVO, pivot:Vector3D = null):ObjectContainer3D
		{
			if (obj.type == AssetType.MESH) {
				var i:UInt = 0;
				var subs:Array<ISubGeometry>;
				var geom:Geometry;
				var mat:MaterialBase = null;
				var mesh:Mesh;
				var mtx:Matrix3D;
				var vertices:Array<VertexVO>;
				var faces:Array<FaceVO>;
				
				if (obj.materials.length > 1)
					trace('The Away3D 3DS parser does not support multiple materials per mesh at this point.');
				
				// Ignore empty objects
				if (obj.indices==null || obj.indices.length == 0)
					return null;
				
				vertices = ArrayUtils.Prefill(new Array<VertexVO>(), Std.int(obj.verts.length/3));
				faces = ArrayUtils.Prefill(new Array<FaceVO>(), Std.int(obj.indices.length/3));
				
				prepareData(vertices, faces, obj);
				applySmoothGroups(vertices, faces);
				
				obj.verts = ArrayUtils.Prefill(new Array<Float>(), vertices.length*3);
				// For loop conversion - 				for (i = 0; i < vertices.length; i++)
				for (i in 0...vertices.length) {
					obj.verts[i*3] = vertices[i].x;
					obj.verts[i*3 + 1] = vertices[i].y;
					obj.verts[i*3 + 2] = vertices[i].z;
				}
				obj.indices = ArrayUtils.Prefill(new Array<UInt>(), faces.length*3);
				// For loop conversion - 				for (i = 0; i < faces.length; i++)
				for (i in 0...faces.length) {
					obj.indices[i*3] = faces[i].a;
					obj.indices[i*3 + 1] = faces[i].b;
					obj.indices[i*3 + 2] = faces[i].c;
				}
				
				if (obj.uvs!=null) {
					// If the object had UVs to start with, use UVs generated by
					// smoothing group splitting algorithm. Otherwise those UVs
					// will be nonsense and should be skipped.
					obj.uvs = ArrayUtils.Prefill(new Array<Float>(), vertices.length*2);
					// For loop conversion - 					for (i = 0; i < vertices.length; i++)
					for (i in 0...vertices.length) {
						obj.uvs[i*2] = vertices[i].u;
						obj.uvs[i*2 + 1] = vertices[i].v;
					}
				}
				
				geom = new Geometry();
				
				// Construct sub-geometries (potentially splitting buffers)
				// and add them to geometry.
				subs = GeomUtil.fromVectors(obj.verts, obj.indices, obj.uvs, null, null, null, null);
				// For loop conversion - 				for (i = 0; i < subs.length; i++)
				for (i in 0...subs.length)
					geom.subGeometries.push(subs[i]);
				
				if (obj.materials.length > 0) {
					var mname:String;
					mname = obj.materials[0];
					mat = _materials.get(mname).material;
				}
				
				// Apply pivot translation to geometry if a pivot was
				// found while parsing the keyframe chunk earlier.
				if (pivot!=null) {
					if (obj.transform!=null) {
						// If a transform was found while parsing the
						// object chunk, use it to find the local pivot vector
						var dat:Array<Float> = obj.transform.concat([]);
						dat[12] = 0;
						dat[13] = 0;
						dat[14] = 0;
						mtx = new Matrix3D(dat);
						pivot = mtx.transformVector(pivot);
					}
					
					pivot.scaleBy(-1);
					
					mtx = new Matrix3D();
					mtx.appendTranslation(pivot.x, pivot.y, pivot.z);
					geom.applyTransformation(mtx);
				}
				
				// Apply transformation to geometry if a transformation
				// was found while parsing the object chunk earlier.
				if (obj.transform!=null) {
					mtx = new Matrix3D(obj.transform);
					mtx.invert();
					geom.applyTransformation(mtx);
				}
				
				// Final transform applied to geometry. Finalize the geometry,
				// which will no longer be modified after this point.
				finalizeAsset(geom, obj.name+'_geom');
				
				// Build mesh and return it
				mesh = new Mesh(geom, mat);
				mesh.transform = new Matrix3D(obj.transform);
				return mesh;
			}
			
			// If reached, unknown
			return null;
		}
		
		private function prepareData(vertices:Array<VertexVO>, faces:Array<FaceVO>, obj:ObjectVO):Void
		{
			// convert raw ObjectVO's data to structured VertexVO and FaceVO
			var i:Int;
			var j:Int;
			var k:Int;
			var len:Int = obj.verts.length;
			// For loop conversion - 			for (i = 0, j = 0, k = 0; i < len; )
			i=0;
			j=0;
			k=0;
			while (i<len) {
				var v:VertexVO = new VertexVO();
				v.x = obj.verts[i++];
				v.y = obj.verts[i++];
				v.z = obj.verts[i++];
				if (obj.uvs!=null) {
					v.u = obj.uvs[j++];
					v.v = obj.uvs[j++];
				}
				vertices[k++] = v;
			}
			len = obj.indices.length;
			// For loop conversion - 			for (i = 0, k = 0; i < len; )
			i=0;
			k=0;
			while (i<len) {
				var f:FaceVO = new FaceVO();
				f.a = obj.indices[i++];
				f.b = obj.indices[i++];
				f.c = obj.indices[i++];
				f.smoothGroup = obj.smoothingGroups[k];
				faces[k++] = f;
			}
		}
		
		private function applySmoothGroups(vertices:Array<VertexVO>, faces:Array<FaceVO>):Void
		{
			// clone vertices according to following rule:
			// clone if vertex's in faces from groups 1+2 and 3
			// don't clone if vertex's in faces from groups 1+2, 3 and 1+3
			
			var i:Int;
			var j:Int;
			var k:Int;
			var l:Int;
			var len:Int;
			var numVerts:UInt = vertices.length;
			var numFaces:UInt = faces.length;
			var face:FaceVO;
			var groups:Array<UInt>;
			var group:UInt;
			var clones:Array<UInt>;

			// extract groups data for vertices
			var vGroups:Array<Array<UInt>> = ArrayUtils.Prefill(new Array<Array<UInt>>(), numVerts);
			// For loop conversion - 			for (i = 0; i < numVerts; i++)
			for (i in 0...numVerts)
				vGroups[i] = new Array<UInt>();
			// For loop conversion - 			for (i = 0; i < numFaces; i++)
			for (i in 0...numFaces) {
				face = cast(faces[i], FaceVO);
				// For loop conversion - 				for (j = 0; j < 3; j++)
				for (j in 0...3) {
					groups = vGroups[(j == 0)? face.a : ((j == 1)? face.b : face.c)];
					group = face.smoothGroup;
					// For loop conversion - 					for (k = groups.length - 1; k >= 0; k--)
					k = groups.length - 1;
					while (k >= 0) {
						if ((group & groups[k]) > 0) {
							group = group!=0 ? group : groups[k];
							groups.splice(k, 1);
							k = groups.length - 1;
						}
						k--;
					}
					groups.push(group);
				}
			}
			// clone vertices
			var vClones:Array<Array<UInt>> = ArrayUtils.Prefill(new Array<Array<UInt>>(), numVerts);
			// For loop conversion - 			for (i = 0; i < numVerts; i++)
			for (i in 0...numVerts) {
				if ((len = vGroups[i].length) < 1)
					continue;
				clones = ArrayUtils.Prefill(new Array<UInt>(), len);
				vClones[i] = clones;
				clones[0] = i;
				var v0:VertexVO = vertices[i];
				// For loop conversion - 				for (j = 1; j < len; j++)
				for (j in 1...len) {
					var v1:VertexVO = new VertexVO();
					v1.x = v0.x;
					v1.y = v0.y;
					v1.z = v0.z;
					v1.u = v0.u;
					v1.v = v0.v;
					clones[j] = vertices.length;
					vertices.push(v1);
				}
			}
			numVerts = vertices.length;
			
			// For loop conversion - 						for (i = 0; i < numFaces; i++)
			
			for (i in 0...numFaces) {
				face = cast(faces[i], FaceVO);
				group = face.smoothGroup;
				// For loop conversion - 				for (j = 0; j < 3; j++)
				for (j in 0...3) {
					k = (j == 0)? face.a : ((j == 1)? face.b : face.c);
					groups = vGroups[k];
					len = groups.length;
					clones = vClones[k];
					// For loop conversion - 					for (l = 0; l < len; l++)
					l=0;
					while (l < len) {
						if (((group == 0) && (groups[l] == 0)) ||
							((group & groups[l]) > 0)) {
							var index:UInt = clones[l];
							if (group == 0) {
								// vertex is unique if no smoothGroup found
								groups.splice(l, 1);
								clones.splice(l, 1);
							}
							if (j == 0)
								face.a = index;
							else if (j == 1)
								face.b = index;
							else
								face.c = index;
							l = len;
						}
						l++;
					}
				}
			}
		}
		
		private function finalizeCurrentMaterial():Void
		{
			var mat:MaterialBase;
			if (materialMode < 2) {
				if (_cur_mat.colorMap!=null) {
					mat = new TextureMaterial(_cur_mat.colorMap.texture!=null ? _cur_mat.colorMap.texture : DefaultMaterialManager.getDefaultTexture());
				} else
					mat = new ColorMaterial(_cur_mat.diffuseColor);
				cast(mat, SinglePassMaterialBase).ambientColor = _cur_mat.ambientColor;
				cast(mat, SinglePassMaterialBase).specularColor = _cur_mat.specularColor;
			} else {
				if (_cur_mat.colorMap!=null)
					mat = new TextureMultiPassMaterial(_cur_mat.colorMap.texture!=null ? _cur_mat.colorMap.texture : DefaultMaterialManager.getDefaultTexture());
				else
					mat = new ColorMultiPassMaterial(_cur_mat.diffuseColor);
				cast(mat, MultiPassMaterialBase).ambientColor = _cur_mat.ambientColor;
				cast(mat, MultiPassMaterialBase).specularColor = _cur_mat.specularColor;
			}
			
			mat.bothSides = _cur_mat.twoSided;
			
			finalizeAsset(mat, _cur_mat.name);
			
			_materials.set(_cur_mat.name, _cur_mat);
			_cur_mat.material = mat;
			
			_cur_mat = null;
		}
		
		private function readNulTermString():String
		{
			var chr:UInt;
			var str:String = "";
			
			while ((chr = _byteData.readUnsignedByte()) > 0)
				str += String.fromCharCode(chr);
			
			return str;
		}
		
		private function readTransform():Array<Float>
		{
			var data:Array<Float>;
			
			data = new Array<Float>();
			
			// X axis
			data[0] = _byteData.readFloat(); // X
			data[2] = _byteData.readFloat(); // Z
			data[1] = _byteData.readFloat(); // Y
			data[3] = 0;
			
			// Z axis
			data[8] = _byteData.readFloat(); // X
			data[10] = _byteData.readFloat(); // Z
			data[9] = _byteData.readFloat(); // Y
			data[11] = 0;
			
			// Y Axis
			data[4] = _byteData.readFloat(); // X 
			data[6] = _byteData.readFloat(); // Z
			data[5] = _byteData.readFloat(); // Y
			data[7] = 0;
			
			// Translation
			data[12] = _byteData.readFloat(); // X
			data[14] = _byteData.readFloat(); // Z
			data[13] = _byteData.readFloat(); // Y
			data[15] = 1;
			
			return data;
		}
		
		private function readColor():UInt
		{
			var cid:UInt;
			var len:UInt;
			var r:UInt = 0, g:UInt = 0, b:UInt = 0;
			
			cid = _byteData.readUnsignedShort();
			len = _byteData.readUnsignedInt();
			
			switch (cid) {
				case 0x0010: // Floats
					r = Std.int(_byteData.readFloat()*255);
					g = Std.int(_byteData.readFloat()*255);
					b = Std.int(_byteData.readFloat()*255);
				case 0x0011: // 24-bit color
					r = _byteData.readUnsignedByte();
					g = _byteData.readUnsignedByte();
					b = _byteData.readUnsignedByte();
				default:
					_byteData.position += (len - 6);
			}
			
			return (r << 16) | (g << 8) | b;
		}
	}

class TextureVO
{
	public var url:String;
	public var texture:Texture2DBase;
	
	public function new()
	{
	}
}

class MaterialVO
{
	public var name:String;
	public var ambientColor:UInt;
	public var diffuseColor:UInt;
	public var specularColor:UInt;
	public var twoSided:Bool;
	public var colorMap:TextureVO;
	public var specularMap:TextureVO;
	public var material:MaterialBase;
	
	public function new()
	{
	}
}

class ObjectVO
{
	public var name:String;
	public var type:String;
	public var pivotX:Float;
	public var pivotY:Float;
	public var pivotZ:Float;
	public var transform:Array<Float>;
	public var verts:Array<Float>;
	public var indices:Array<UInt>;
	public var uvs:Array<Float>;
	public var materialFaces:StringMap<Array<UInt>>;
	public var materials:Array<String>;
	public var smoothingGroups:Array<UInt>;
	
	public function new()
	{
	}
}

class VertexVO
{
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var u:Float;
	public var v:Float;
	public var normal:Vector3D;
	public var tangent:Vector3D;
	
	public function new()
	{
	}
}

class FaceVO
{
	public var a:UInt;
	public var b:UInt;
	public var c:UInt;
	public var smoothGroup:UInt;
	
	public function new()
	{
	}
}
