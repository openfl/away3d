package away3d.tools.utils;

	import away3d.containers.*;
	import away3d.core.base.*;
	import away3d.core.base.data.*;
	import away3d.entities.*;
	
	import flash.geom.*;
	
	class Projector
	{
		public static var FRONT:String = "front";
		public static var BACK:String = "back";
		public static var TOP:String = "top";
		public static var BOTTOM:String = "bottom";
		public static var LEFT:String = "left";
		public static var RIGHT:String = "right";
		public static var CYLINDRICAL_X:String = "cylindricalx";
		public static var CYLINDRICAL_Y:String = "cylindricaly";
		public static var CYLINDRICAL_Z:String = "cylindricalz";
		public static var SPHERICAL:String = "spherical";
		
		private static var _width:Float;
		private static var _height:Float;
		private static var _depth:Float;
		private static var _offsetW:Float;
		private static var _offsetH:Float;
		private static var _offsetD:Float;
		private static var _orientation:String;
		private static var _center:Vector3D;
		private static var _vn:Vector3D;
		private static var _ve:Vector3D;
		private static var _vp:Vector3D;
		private static var _dir:Vector3D;
		private static var _radius:Float;
		private static var _uv:UV;
		
		private static var PI:Float = Math.PI;
		private static var DOUBLEPI:Float = Math.PI << 1;
		
		/**
		 * Class remaps the uv data of a mesh
		 *
		 * @param     orientation    String. Defines the projection direction and methods.
		 * Note: As we use triangles, cylindrical and spherical projections might require correction,
		 * as some faces, may have vertices pointing at other side of the map, causing some faces to be rendered as a whole reverted map.
		 *
		 * @param     obj        ObjectContainer3D. The ObjectContainer3D to remap.
		 */
		public static project(orientation:String, obj:ObjectContainer3D):Void
		{
			_orientation = orientation.toLowerCase();
			parse(obj);
		}
		
		private static function parse(obj:ObjectContainer3D):Void
		{
			var child:ObjectContainer3D;
			if (obj is Mesh && obj.numChildren == 0)
				remapMesh(Mesh(obj));
			
			// For loop conversion - 						for (var i:UInt = 0; i < obj.numChildren; ++i)
			
			var i:UInt = 0;
			
			for (i in 0...obj.numChildren) {
				child = obj.getChildAt(i);
				parse(child);
			}
		}
		
		private static function remapMesh(mesh:Mesh):Void
		{
			var minX:Float = Infinity;
			var minY:Float = Infinity;
			var minZ:Float = Infinity;
			var maxX:Float = -Infinity;
			var maxY:Float = -Infinity;
			var maxZ:Float = -Infinity;
			
			Bounds.getMeshBounds(mesh);
			minX = Bounds.minX;
			minY = Bounds.minY;
			minZ = Bounds.minZ;
			maxX = Bounds.maxX;
			maxY = Bounds.maxY;
			maxZ = Bounds.maxZ;
			
			if (_orientation == FRONT || _orientation == BACK || _orientation == CYLINDRICAL_X) {
				_width = maxX - minX;
				_height = maxY - minY;
				_depth = maxZ - minZ;
				_offsetW = (minX > 0)? -minX : Math.abs(minX);
				_offsetH = (minY > 0)? -minY : Math.abs(minY);
				_offsetD = (minZ > 0)? -minZ : Math.abs(minZ);
				
			} else if (_orientation == LEFT || _orientation == RIGHT || _orientation == CYLINDRICAL_Z) {
				_width = maxZ - minZ;
				_height = maxY - minY;
				_depth = maxX - minX;
				_offsetW = (minZ > 0)? -minZ : Math.abs(minZ);
				_offsetH = (minY > 0)? -minY : Math.abs(minY);
				_offsetD = (minX > 0)? -minX : Math.abs(minX);
				
			} else if (_orientation == TOP || _orientation == BOTTOM || _orientation == CYLINDRICAL_Y) {
				_width = maxX - minX;
				_height = maxZ - minZ;
				_depth = maxY - minY;
				_offsetW = (minX > 0)? -minX : Math.abs(minX);
				_offsetH = (minZ > 0)? -minZ : Math.abs(minZ);
				_offsetD = (minY > 0)? -minY : Math.abs(minY);
			}
			
			var geometry:Geometry = mesh.geometry;
			var geometries:Array<ISubGeometry> = geometry.subGeometries;
			
			if (_orientation == SPHERICAL) {
				if (!_center)
					_center = new Vector3D();
				_width = maxX - minX;
				_height = maxZ - minZ;
				_depth = maxY - minY;
				_radius = Math.max(_width, _depth, _height) + 10;
				_center.x = _center.y = _center.z = .0001;
				
				remapSpherical(geometries, mesh.scenePosition);
				
			} else if (_orientation.indexOf("cylindrical") != -1)
				remapCylindrical(geometries, mesh.scenePosition);
			
			else
				remapLinear(geometries, mesh.scenePosition);
		}
		
		private static function remapLinear(geometries:Array<ISubGeometry>, position:Vector3D):Void
		{
			var numSubGeoms:UInt = geometries.length;
			var sub_geom:ISubGeometry;
			var vertices:Array<Float>;
			var vertexOffset:Int;
			var vertexStride:Int;
			var indices:Array<UInt>;
			var uvs:Array<Float>;
			var uvOffset:Int;
			var uvStride:Int;
			var i:UInt = 0;
			var j:UInt;
			var vIndex:UInt;
			var uvIndex:UInt;
			var numIndices:UInt;
			var offsetU:Float;
			var offsetV:Float;
			
			// For loop conversion - 						for (i = 0; i < numSubGeoms; ++i)
			
			for (i in 0...numSubGeoms) {
				sub_geom = geometries[i];
				
				vertices = sub_geom.vertexData
				vertexOffset = sub_geom.vertexOffset;
				vertexStride = sub_geom.vertexStride;
				
				uvs = sub_geom.UVData;
				uvOffset = sub_geom.UVOffset;
				uvStride = sub_geom.UVStride;
				
				indices = sub_geom.indexData;
				
				numIndices = indices.length;
				
				switch (_orientation) {
					case FRONT:
						offsetU = _offsetW + position.x;
						offsetV = _offsetH + position.y;
						// For loop conversion - 						for (j = 0; j < numIndices; ++j)
						for (j in 0...numIndices) {
							vIndex = vertexOffset + vertexStride*indices[j];
							uvIndex = uvOffset + uvStride*indices[j];
							uvs[uvIndex] = (vertices[vIndex] + offsetU)/_width;
							uvs[uvIndex + 1] = 1 - (vertices[vIndex + 1] + offsetV)/_height;
						}
						break;
					
					case BACK:
						offsetU = _offsetW + position.x;
						offsetV = _offsetH + position.y;
						// For loop conversion - 						for (j = 0; j < numIndices; ++j)
						for (j in 0...numIndices) {
							vIndex = vertexOffset + vertexStride*indices[j];
							uvIndex = uvOffset + uvStride*indices[j];
							uvs[uvIndex] = 1 - (vertices[vIndex] + offsetU)/_width;
							uvs[uvIndex + 1] = 1 - (vertices[vIndex + 1] + offsetV)/_height;
						}
						break;
					
					case RIGHT:
						offsetU = _offsetW + position.z;
						offsetV = _offsetH + position.y;
						// For loop conversion - 						for (j = 0; j < numIndices; ++j)
						for (j in 0...numIndices) {
							vIndex = vertexOffset + vertexStride*indices[j] + 1;
							uvIndex = uvOffset + uvStride*indices[j];
							uvs[uvIndex] = (vertices[vIndex + 1] + offsetU)/_width;
							uvs[uvIndex + 1] = 1 - (vertices[vIndex] + offsetV)/_height;
						}
						break;
					
					case LEFT:
						offsetU = _offsetW + position.z;
						offsetV = _offsetH + position.y;
						// For loop conversion - 						for (j = 0; j < numIndices; ++j)
						for (j in 0...numIndices) {
							vIndex = vertexOffset + vertexStride*indices[j] + 1;
							uvIndex = uvOffset + uvStride*indices[j];
							uvs[uvIndex] = 1 - (vertices[vIndex + 1] + offsetU)/_width;
							uvs[uvIndex + 1] = 1 - (vertices[vIndex] + offsetV)/_height;
						}
						break;
					
					case TOP:
						offsetU = _offsetW + position.x;
						offsetV = _offsetH + position.z;
						// For loop conversion - 						for (j = 0; j < numIndices; ++j)
						for (j in 0...numIndices) {
							vIndex = vertexOffset + vertexStride*indices[j];
							uvIndex = uvOffset + uvStride*indices[j];
							uvs[uvIndex] = (vertices[vIndex] + offsetU)/_width;
							uvs[uvIndex + 1] = 1 - (vertices[vIndex + 2] + offsetV)/_height;
						}
						break;
					
					case BOTTOM:
						offsetU = _offsetW + position.x;
						offsetV = _offsetH + position.z;
						// For loop conversion - 						for (j = 0; j < numIndices; ++j)
						for (j in 0...numIndices) {
							vIndex = vertexOffset + vertexStride*indices[j];
							uvIndex = uvOffset + uvStride*indices[j];
							uvs[uvIndex] = 1 - (vertices[vIndex] + offsetU)/_width;
							uvs[uvIndex + 1] = 1 - (vertices[vIndex + 2] + offsetV)/_height;
						}
				}
				
				if (sub_geom is CompactSubGeometry)
					CompactSubGeometry(sub_geom).updateData(uvs);
				else
					SubGeometry(sub_geom).updateUVData(uvs);
			}
		}
		
		private static function remapCylindrical(geometries:Array<ISubGeometry>, position:Vector3D):Void
		{
			var numSubGeoms:UInt = geometries.length;
			var sub_geom:ISubGeometry;
			var vertices:Array<Float>;
			var vertexOffset:Int;
			var vertexStride:Int;
			var indices:Array<UInt>;
			var uvs:Array<Float>;
			var uvOffset:Int;
			var uvStride:Int;
			var i:UInt = 0;
			var j:UInt;
			var vIndex:UInt;
			var uvIndex:UInt;
			var numIndices:UInt;
			var offset:Float;
			
			// For loop conversion - 						for (i = 0; i < numSubGeoms; ++i)
			
			for (i in 0...numSubGeoms) {
				sub_geom = geometries[i];
				
				vertices = sub_geom.vertexData
				vertexOffset = sub_geom.vertexOffset;
				vertexStride = sub_geom.vertexStride;
				
				uvs = sub_geom.UVData;
				uvOffset = sub_geom.UVOffset;
				uvStride = sub_geom.UVStride;
				
				indices = sub_geom.indexData;
				
				numIndices = indices.length;
				
				switch (_orientation) {
					
					case CYLINDRICAL_X:
						
						offset = _offsetW + position.x;
						// For loop conversion - 						for (j = 0; j < numIndices; ++j)
						for (j in 0...numIndices) {
							vIndex = vertexOffset + vertexStride*indices[j];
							uvIndex = uvOffset + uvStride*indices[j];
							uvs[uvIndex] = (vertices[vIndex] + offset)/_width;
							uvs[uvIndex + 1] = (PI + Math.atan2(vertices[vIndex + 1], vertices[vIndex + 2]))/DOUBLEPI;
						}
						break;
					
					case CYLINDRICAL_Y:
						offset = _offsetD + position.y;
						// For loop conversion - 						for (j = 0; j < numIndices; ++j)
						for (j in 0...numIndices) {
							vIndex = vertexOffset + vertexStride*indices[j];
							uvIndex = uvOffset + uvStride*indices[j];
							uvs[uvIndex] = (PI + Math.atan2(vertices[vIndex], vertices[vIndex + 2]))/DOUBLEPI;
							uvs[uvIndex + 1] = 1 - (vertices[vIndex + 1] + offset)/_depth;
						}
						break;
					
					case CYLINDRICAL_Z:
						offset = _offsetW + position.z;
						// For loop conversion - 						for (j = 0; j < numIndices; ++j)
						for (j in 0...numIndices) {
							vIndex = vertexOffset + vertexStride*indices[j];
							uvIndex = uvOffset + uvStride*indices[j];
							uvs[uvIndex + 1] = (vertices[vIndex + 2] + offset)/_width;
							uvs[uvIndex] = (PI + Math.atan2(vertices[vIndex + 1], vertices[vIndex]))/DOUBLEPI;
						}
					
				}
				
				if (sub_geom is CompactSubGeometry)
					CompactSubGeometry(sub_geom).updateData(uvs);
				else
					SubGeometry(sub_geom).updateUVData(uvs);
				
			}
		}
		
		private static function remapSpherical(geometries:Array<ISubGeometry>, position:Vector3D):Void
		{
			position = position;
			var numSubGeoms:UInt = geometries.length;
			var sub_geom:ISubGeometry;
			
			var vertices:Array<Float>;
			var vertexOffset:Int;
			var vertexStride:Int;
			var indices:Array<UInt>;
			var uvs:Array<Float>;
			var uvOffset:Int;
			var uvStride:Int;
			
			var i:UInt = 0;
			var j:UInt;
			var vIndex:UInt;
			var uvIndex:UInt;
			var numIndices:UInt;
			
			// For loop conversion - 						for (i = 0; i < numSubGeoms; ++i)
			
			for (i in 0...numSubGeoms) {
				sub_geom = geometries[i];
				
				vertices = sub_geom.vertexData
				vertexOffset = sub_geom.vertexOffset;
				vertexStride = sub_geom.vertexStride;
				
				uvs = sub_geom.UVData;
				uvOffset = sub_geom.UVOffset;
				uvStride = sub_geom.UVStride;
				
				indices = sub_geom.indexData;
				
				numIndices = indices.length;
				
				numIndices = indices.length;
				
				// For loop conversion - 								for (j = 0; j < numIndices; ++j)
				
				for (j in 0...numIndices) {
					vIndex = vertexOffset + vertexStride*indices[j];
					uvIndex = uvOffset + uvStride*indices[j];
					
					projectVertex(vertices[vIndex], vertices[vIndex + 1], vertices[vIndex + 2]);
					uvs[uvIndex] = _uv.u;
					uvs[uvIndex + 1] = _uv.v;
				}
				
				if (sub_geom is CompactSubGeometry)
					CompactSubGeometry(sub_geom).updateData(uvs);
				else
					SubGeometry(sub_geom).updateUVData(uvs);
			}
		}
		
		private static function projectVertex(x:Float, y:Float, z:Float):Void
		{
			if (!_dir) {
				_dir = new Vector3D(x, y, z);
				_uv = new UV();
				_vn = new Vector3D(0, -1, 0);
				_ve = new Vector3D(.1, 0, .9);
				_vp = new Vector3D();
			} else {
				_dir.x = x;
				_dir.y = y;
				_dir.z = z;
			}
			
			_dir.normalize();
			
			_vp.x = _dir.x*_radius;
			_vp.y = _dir.y*_radius;
			_vp.z = _dir.z*_radius;
			_vp.normalize();
			
			var phi:Float = Math.acos(-_vn.dotProduct(_vp));
			
			_uv.v = phi/PI;
			
			var theta:Float = Math.acos(_vp.dotProduct(_ve)/Math.sin(phi))/DOUBLEPI;
			
			var _crp:Vector3D = _vn.crossProduct(_ve);
			
			if (_crp.dotProduct(_vp) < 0)
				_uv.u = 1 - theta;
			else
				_uv.u = theta;
		
		}
	
	}

