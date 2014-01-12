package away3d.tools.commands;

	//import away3d.arcane;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.ISubGeometry;
	import away3d.entities.Mesh;
	import away3d.tools.utils.GeomUtil;
	
	import away3d.geom.Matrix3D;
	
	//use namespace arcane;
	
	class Mirror
	{
		public static var X_AXIS:Int = 1; // 001
		public static var Y_AXIS:Int = 2; // 010
		public static var Z_AXIS:Int = 4; // 100
		
		public static var MIN_BOUND:String = 'min';
		public static var MAX_BOUND:String = 'max';
		public static var CENTER:String = 'center';
		
		var _recenter:Bool;
		var _duplicate:Bool;
		var _axis:Int;
		var _offset:String;
		var _additionalOffset:Float;
		var _scaleTransform:Matrix3D;
		var _fullTransform:Matrix3D;
		var _centerTransform:Matrix3D;
		var _flipWinding:Bool;
		
		public function new(recenter:Bool = false, duplicate:Bool = true):Void
		{
			_recenter = recenter;
			_duplicate = duplicate;
		}
		
		public function set_recenter(b:Bool) : Void
		{
			_recenter = b;
		}
		
		public var recenter(get, set) : Void;
		
		public function get_recenter() : Void
		{
			return _recenter;
		}
		
		public function set_duplicate(b:Bool) : Void
		{
			_duplicate = b;
		}
		
		public var duplicate(get, set) : Void;
		
		public function get_duplicate() : Void
		{
			return _duplicate;
		}
		
		/**
		 * Clones a Mesh and mirrors the cloned mesh. returns the cloned (and mirrored) mesh.
		 * @param mesh the mesh to clone and mirror.
		 * @param axis the axis to mirror the mesh.
		 * @param offset can be MIN_BOUND, MAX_BOUND or CENTER.
		 * @param additionalOffset if MIN_BOUND or MAX_BOUND is selected as offset, this addional offset can be added.
		 */
		public function getMirroredClone(mesh:Mesh, axis:Int, offset:String = CENTER, additionalOffset:Float = 0):Mesh
		{
			_axis = axis;
			_offset = offset;
			_additionalOffset = additionalOffset;
			
			//var originalDuplicateMode:Bool = _duplicate;
			_duplicate = false;
			
			var newMesh:Mesh = Mesh(mesh.clone());
			initTransforms(newMesh.bounds);
			applyToMesh(newMesh, true);
			_duplicate = false;
			
			return newMesh;
		}
		
		/**
		 * Clones a ObjectContainer3D and all its children and mirrors the cloned Objects. returns the cloned (and mirrored) ObjectContainer3D.
		 * @param mesh the ObjectContainer3D to clone and mirror.
		 * @param axis the axis to mirror the ObjectContainer3D.
		 * @param offset can be MIN_BOUND, MAX_BOUND or CENTER.
		 * @param additionalOffset if MIN_BOUND or MAX_BOUND is selected as offset, this additional offset can be added.
		 */
		public function getMirroredCloneContainer(ctr:ObjectContainer3D, axis:Int, offset:String = CENTER, additionalOffset:Float = 0):ObjectContainer3D
		{
			var meshes:Array<Mesh> = new Array<Mesh>();
			_axis = axis;
			_offset = offset;
			_additionalOffset = additionalOffset;
			
			//var originalDuplicateMode:Bool = _duplicate; //store the _duplicateMode, because for this function we want to set it to false, but want to restore it later
			_duplicate = false;
			
			var newObjectContainer:ObjectContainer3D = ObjectContainer3D(ctr.clone());
			
			// Collect ctr (if it's a mesh) and all it's
			// mesh children to a flat list.
			if (newObjectContainer is Mesh)
				meshes.push(Mesh(newObjectContainer));
			
			collectMeshChildren(newObjectContainer, meshes);
			
			var len:UInt = meshes.length;
			// For loop conversion - 			for (var i:UInt = 0; i < len; i++)
			var i:UInt = 0;
			for (i in 0...len) {
				initTransforms(meshes[i].bounds);
				applyToMesh(meshes[i], true);
			}
			_duplicate = false;
			
			return newObjectContainer;
		}
		
		/**
		 * Mirror a Mesh along a given Axis.
		 * @param mesh the mesh to mirror.
		 * @param axis the axis to mirror the mesh.
		 * @param offset can be MIN_BOUND, MAX_BOUND or CENTER.
		 * @param additionalOffset if MIN_BOUND or MAX_BOUND is selected as offset, this addional offset can be added.
		 */
		public function apply(mesh:Mesh, axis:Int, offset:String = CENTER, additionalOffset:Float = 0):Void
		{
			_axis = axis;
			_offset = offset;
			_additionalOffset = additionalOffset;
			
			initTransforms(mesh.bounds);
			applyToMesh(mesh);
		}
		
		/**
		 * Mirror a ObjectContainer3d, and all its children along a given Axis.
		 * @param ctr the ObjectContainer3d to mirror.
		 * @param axis the axis to mirror the ObjectContainer3d.
		 * @param offset can be MIN_BOUND, MAX_BOUND or CENTER.
		 * @param additionalOffset if MIN_BOUND or MAX_BOUND is selected as offset, this addional offset can be added.
		 */
		public function applyToContainer(ctr:ObjectContainer3D, axis:Int, offset:String = CENTER, additionalOffset:Float = 0):Void
		{
			var len:UInt;
			_axis = axis;
			_offset = offset;
			_additionalOffset = additionalOffset;
			
			// Collect ctr (if it's a mesh) and all it's
			// mesh children to a flat list.
			var meshes:Array<Mesh> = new Array<Mesh>();
			
			if (ctr is Mesh)
				meshes.push(Mesh(ctr));
			
			collectMeshChildren(ctr, meshes);
			len = meshes.length;
			
			// For loop conversion - 						for (var i:UInt = 0; i < len; i++)
			
			var i:UInt = 0;
			
			for (i in 0...len) {
				initTransforms(meshes[i].bounds);
				applyToMesh(meshes[i]);
			}
		}
		
		private function applyToMesh(mesh:Mesh, keepOld:Bool = false):Void
		{
			var geom:Geometry = mesh.geometry;
			var newGeom:Geometry = new Geometry();
			var len:UInt = geom.subGeometries.length;
			
			// For loop conversion - 						for (var i:UInt = 0; i < len; i++)
			
			var i:UInt = 0;
			
			for (i in 0...len)
				applyToSubGeom(geom.subGeometries[i], newGeom, keepOld);
			
			mesh.geometry = newGeom;
		}
		
		private function applyToSubGeom(subGeom:ISubGeometry, geometry:Geometry, keepOld:Bool):Void
		{
			var i:UInt = 0;
			var len:UInt;
			var indices:Array<UInt>;
			var vertices:Array<Float>;
			var normals:Array<Float>;
			var uvs:Array<Float>;
			var newSubGeoms:Array<ISubGeometry>;
			
			var vIdx:UInt, nIdx:UInt, uIdx:UInt;
			var vd:Array<Float>, nd:Array<Float>, ud:Array<Float>;
			var vStride:UInt, nStride:UInt, uStride:UInt;
			var vOffs:UInt, nOffs:UInt, uOffs:UInt;
			
			vertices = new Array<Float>();
			normals = new Array<Float>();
			uvs = new Array<Float>();
			
			if (keepOld) {
				indices = Lambda.array(subGeom.indexData);
				
				vd = Lambda.array(subGeom.vertexData);
				nd = Lambda.array(subGeom.vertexNormalData);
				ud = Lambda.array(subGeom.UVData);
				
			} else {
				indices = subGeom.indexData;
				vd = subGeom.vertexData;
				nd = subGeom.vertexNormalData;
				ud = subGeom.UVData;
			}
			
			indices.fixed = false;
			vOffs = subGeom.vertexOffset;
			nOffs = subGeom.vertexNormalOffset;
			uOffs = subGeom.UVOffset;
			vStride = subGeom.vertexStride;
			nStride = subGeom.vertexNormalStride;
			uStride = subGeom.UVStride;
			
			vIdx = nIdx = uIdx = 0;
			len = subGeom.numVertices;
			
			// For loop conversion - 						for (i = 0; i < len; i++)
			
			for (i in 0...len) {
				vertices[vIdx++] = vd[vOffs + i*vStride + 0];
				vertices[vIdx++] = vd[vOffs + i*vStride + 1];
				vertices[vIdx++] = vd[vOffs + i*vStride + 2];
				
				normals[nIdx++] = nd[nOffs + i*nStride + 0];
				normals[nIdx++] = nd[nOffs + i*nStride + 1];
				normals[nIdx++] = nd[nOffs + i*nStride + 2];
				
				uvs[uIdx++] = ud[uOffs + i*uStride + 0];
				uvs[uIdx++] = ud[uOffs + i*uStride + 1];
			}
			
			var indexOffset:UInt = 0;
			
			if (_duplicate) {
				//var indexOffset : UInt;
				var flippedVertices:Array<Float> = new Array<Float>();
				var flippedNormals:Array<Float> = new Array<Float>();
				
				_fullTransform.transformVectors(vertices, flippedVertices);
				_scaleTransform.transformVectors(normals, flippedNormals);
				
				// Copy vertex attributes
				len = subGeom.numVertices;
				// For loop conversion - 				for (i = 0; i < len; i++)
				for (i in 0...len) {
					vertices[len*3 + i*3 + 0] = flippedVertices[i*3 + 0];
					vertices[len*3 + i*3 + 1] = flippedVertices[i*3 + 1];
					vertices[len*3 + i*3 + 2] = flippedVertices[i*3 + 2];
					
					normals[len*3 + i*3 + 0] = flippedNormals[i*3 + 0];
					normals[len*3 + i*3 + 1] = flippedNormals[i*3 + 1];
					normals[len*3 + i*3 + 2] = flippedNormals[i*3 + 2];
					
					uvs[len*2 + i*2 + 0] = uvs[i*2 + 0];
					uvs[len*2 + i*2 + 1] = uvs[i*2 + 1];
				}
				// Copy indices
				len = indices.length;
				indexOffset = subGeom.numVertices;
				
				if (_flipWinding) {
					// For loop conversion - 					for (i = 0; i < len; i += 3)
					for (i in 0...len) {
						indices[len + i + 0] = indices[i + 2] + indexOffset;
						indices[len + i + 1] = indices[i + 1] + indexOffset;
						indices[len + i + 2] = indices[i + 0] + indexOffset;
					}
					
				} else {
					// For loop conversion - 					for (i = 0; i < len; i += 3)
					for (i in 0...len) {
						indices[len + i + 0] = indices[i + 0] + indexOffset;
						indices[len + i + 1] = indices[i + 1] + indexOffset;
						indices[len + i + 2] = indices[i + 2] + indexOffset;
					}
				}
				
			} else {
				
				len = indices.length;
				var oldindicies:Array<UInt> = Lambda.array(indices);
				
				if (_flipWinding) {
					// For loop conversion - 					for (i = 0; i < len; i += 3)
					for (i in 0...len) {
						indices[i + 0] = oldindicies[i + 2];
						indices[i + 1] = oldindicies[i + 1];
						indices[i + 2] = oldindicies[i + 0];
					}
				}
				
				_fullTransform.transformVectors(vertices, vertices);
				_scaleTransform.transformVectors(normals, normals);
			}
			
			if (_recenter)
				_centerTransform.transformVectors(vertices, vertices);
			
			newSubGeoms = GeomUtil.fromVectors(vertices, indices, uvs, normals, null, null, null);
			len = newSubGeoms.length;
			
			// For loop conversion - 						for (i = 0; i < len; i++)
			
			for (i in 0...len)
				geometry.addSubGeometry(newSubGeoms[i]);
		}
		
		private function initTransforms(bounds:BoundingVolumeBase):Void
		{
			var ox:Float, oy:Float, oz:Float;
			var sx:Float, sy:Float, sz:Float;
			//var addx : Float, addy : Float, addz : Float;
			
			if (!_scaleTransform) {
				_scaleTransform = new Matrix3D();
				_fullTransform = new Matrix3D();
			}
			
			// Scale factors
			_fullTransform.identity();
			_scaleTransform.identity();
			sx = (_axis & X_AXIS)? -1 : 1;
			sy = (_axis & Y_AXIS)? -1 : 1;
			sz = (_axis & Z_AXIS)? -1 : 1;
			
			_fullTransform.appendScale(sx, sy, sz);
			_scaleTransform.appendScale(sx, sy, sz);
			switch (_offset) {
				
				case MIN_BOUND:
					ox = (_axis & X_AXIS)? 2*bounds.min.x : 0;
					oy = (_axis & Y_AXIS)? 2*bounds.min.y : 0;
					oz = (_axis & Z_AXIS)? 2*bounds.min.z : 0;
					break;
				
				case MAX_BOUND:
					ox = (_axis & X_AXIS)? 2*bounds.max.x : 0;
					oy = (_axis & Y_AXIS)? 2*bounds.max.y : 0;
					oz = (_axis & Z_AXIS)? 2*bounds.max.z : 0;
					break;
				
				default:
					ox = oy = oz = 0;
			}
			
			if (_additionalOffset > 0) {
				
				if (ox > 0)
					ox += (_axis & X_AXIS)? _additionalOffset : 0;
				
				if (ox < 0)
					ox -= (_axis & X_AXIS)? _additionalOffset : 0;
				
				if (oy > 0)
					oy += (_axis & Y_AXIS)? _additionalOffset : 0;
				
				if (oy < 0)
					oy -= (_axis & Y_AXIS)? _additionalOffset : 0;
				
				if (oz > 0)
					oz += (_axis & Z_AXIS)? _additionalOffset : 0;
				
				if (oz < 0)
					oz -= (_axis & Z_AXIS)? _additionalOffset : 0;
				
			}
			// Full transform contains both offset and scale, and is the one
			// to use for vertices. Normals should not be affected the same
			// way (i.e. not be offset) which is why these are separate.
			_fullTransform.appendTranslation(ox, oy, oz);
			
			if (_recenter) {
				if (!_centerTransform)
					_centerTransform = new Matrix3D();
				
				var recenterX:Float = 0;
				var recenterY:Float = 0;
				var recenterZ:Float = 0;
				
				if (ox == 0)
					recenterX = ((bounds.min.x + bounds.max.x)/2)* -1;
				if (oy == 0)
					recenterY = ((bounds.min.y + bounds.max.y)/2)* -1;
				if (oz == 0)
					recenterZ = ((bounds.min.z + bounds.max.z)/2)* -1;
				
				_centerTransform.identity();
				_centerTransform.appendTranslation(-ox*.5 + recenterX, -oy*.5 + recenterY, -oz*.5 + recenterZ);
				
			}
			
			_flipWinding = !((sx*sy*sz) > 0);
		}
		
		private function collectMeshChildren(ctr:ObjectContainer3D, meshes:Array<Mesh>):Void
		{
			// For loop conversion - 			for (var i:UInt = 0; i < ctr.numChildren; i++)
			var i:UInt = 0;
			for (i in 0...ctr.numChildren) {
				var child:ObjectContainer3D = ctr.getChildAt(i);
				if (child is Mesh)
					meshes.push(Mesh(child));
				
				collectMeshChildren(child, meshes);
			}
		}
	}

