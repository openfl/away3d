package away3d.tools.commands;

	import away3d.containers.*;
	import away3d.core.base.*;
	import away3d.entities.*;
	import away3d.materials.*;
	import away3d.tools.utils.*;
	
	/**
	 *  Class Merge merges two or more static meshes into one.<code>Merge</code>
	 */
	class Merge
	{
		
		//private var LIMIT:UInt = 196605;
		var _objectSpace:Bool;
		var _keepMaterial:Bool;
		var _disposeSources:Bool;
		var _geomVOs:Array<GeometryVO>;
		var _toDispose:Array<Mesh>;
		
		/**
		 * @param    keepMaterial    [optional]    Determines if the merged object uses the recevier mesh material information or keeps its source material(s). Defaults to false.
		 * If false and receiver object has multiple materials, the last material found in receiver submeshes is applied to the merged submesh(es).
		 * @param    disposeSources  [optional]    Determines if the mesh and geometry source(s) used for the merging are disposed. Defaults to false.
		 * If true, only receiver geometry and resulting mesh are kept in  memory.
		 * @param    objectSpace     [optional]    Determines if source mesh(es) is/are merged using objectSpace or worldspace. Defaults to false.
		 */
		function Merge(keepMaterial:Bool = false, disposeSources:Bool = false, objectSpace:Bool = false):Void
		{
			_keepMaterial = keepMaterial;
			_disposeSources = disposeSources;
			_objectSpace = objectSpace;
		}
		
		/**
		 * Determines if the mesh and geometry source(s) used for the merging are disposed. Defaults to false.
		 */
		public function set_disposeSources(b:Bool) : Void
		{
			_disposeSources = b;
		}
		
		public var disposeSources(get, set) : Void;
		
		public function get_disposeSources() : Void
		{
			return _disposeSources;
		}
		
		/**
		 * Determines if the material source(s) used for the merging are disposed. Defaults to false.
		 */
		public function set_keepMaterial(b:Bool) : Void
		{
			_keepMaterial = b;
		}
		
		public var keepMaterial(get, set) : Void;
		
		public function get_keepMaterial() : Void
		{
			return _keepMaterial;
		}
		
		/**
		 * Determines if source mesh(es) is/are merged using objectSpace or worldspace. Defaults to false.
		 */
		public function set_objectSpace(b:Bool) : Void
		{
			_objectSpace = b;
		}
		
		public var objectSpace(get, set) : Void;
		
		public function get_objectSpace() : Void
		{
			return _objectSpace;
		}
		
		/**
		 * Merges all the children of a container into a single Mesh. If no Mesh object is found, method returns the receiver without modification.
		 *
		 * @param    receiver           The Mesh to receive the merged contents of the container.
		 * @param    objectContainer    The ObjectContainer3D holding the meshes to be mergd.
		 *
		 * @return The merged Mesh instance.
		 */
		public function applyToContainer(receiver:Mesh, objectContainer:ObjectContainer3D):Void
		{
			reset();
			
			//collect container meshes
			parseContainer(receiver, objectContainer);
			
			//collect receiver
			collect(receiver, false);
			
			//merge to receiver
			merge(receiver, _disposeSources);
		}
		
		/**
		 * Merges all the meshes found in the Vector.&lt;Mesh&gt; into a single Mesh.
		 *
		 * @param    receiver    The Mesh to receive the merged contents of the meshes.
		 * @param    meshes      A series of Meshes to be merged with the reciever mesh.
		 */
		public function applyToMeshes(receiver:Mesh, meshes:Array<Mesh>):Void
		{
			reset();
			
			if (!meshes.length)
				return;
			
			//collect meshes in vector
			// For loop conversion - 			for (var i:UInt = 0; i < meshes.length; i++)
			var i:UInt = 0;
			for (i in 0...meshes.length)
				if (meshes[i] != receiver)
					collect(meshes[i], _disposeSources);
			
			//collect receiver
			collect(receiver, false);
			
			//merge to receiver
			merge(receiver, _disposeSources);
		}
		
		/**
		 *  Merges 2 meshes into one. It is recommand to use apply when 2 meshes are to be merged. If more need to be merged, use either applyToMeshes or applyToContainer methods.
		 *
		 * @param    receiver    The Mesh to receive the merged contents of both meshes.
		 * @param    mesh        The Mesh to be merged with the receiver mesh
		 */
		public function apply(receiver:Mesh, mesh:Mesh):Void
		{
			reset();
			
			//collect mesh
			collect(mesh, _disposeSources);
			
			//collect receiver
			collect(receiver, false);
			
			//merge to receiver
			merge(receiver, _disposeSources);
		}
		
		private function reset():Void
		{
			_toDispose  = new Array<Mesh>();
			_geomVOs = new Array<GeometryVO>();
		}
		
		private function merge(destMesh:Mesh, dispose:Bool):Void
		{
			var i:UInt = 0;
			var subIdx:UInt;
			var oldGeom:Geometry
			var destGeom:Geometry;
			var useSubMaterials:Bool;
			
			oldGeom = destMesh.geometry;
			destGeom = destMesh.geometry = new Geometry();
			subIdx = destMesh.subMeshes.length;
			
			// Only apply materials directly to sub-meshes if necessary,
			// i.e. if there is more than one material available.
			useSubMaterials = (_geomVOs.length > 1);
			
			// For loop conversion - 						for (i = 0; i < _geomVOs.length; i++)
			
			for (i in 0..._geomVOs.length) {
				var s:UInt;
				var data:GeometryVO;
				var subs:Array<ISubGeometry>;
				
				data = _geomVOs[i];
				subs = GeomUtil.fromVectors(data.vertices, data.indices, data.uvs, data.normals, null, null, null);
				
				// For loop conversion - 								for (s = 0; s < subs.length; s++)
				
				for (s in 0...subs.length) {
					destGeom.addSubGeometry(subs[s]);
					
					if (_keepMaterial && useSubMaterials)
						destMesh.subMeshes[subIdx].material = data.material;
					
					subIdx++;
				}
			}
			
			if (_keepMaterial && !useSubMaterials && _geomVOs.length)
				destMesh.material = _geomVOs[0].material;
				
			if (dispose) {
				for each (var m:Mesh in _toDispose) {
					m.geometry.dispose();
					m.dispose();
				}
				
				//dispose of the original receiver geometry
				oldGeom.dispose();
			}
			
			_toDispose = null;
		}
		
		private function collect(mesh:Mesh, dispose:Bool):Void
		{
			if (mesh.geometry) {
				var subIdx:UInt;
				var subGeometries:Array<ISubGeometry> = mesh.geometry.subGeometries;
				var calc:UInt;
				// For loop conversion - 				for (subIdx = 0; subIdx < subGeometries.length; subIdx++)
				for (subIdx in 0...subGeometries.length) {
					var i:UInt = 0;
					var len:UInt;
					var iIdx:UInt, vIdx:UInt, nIdx:UInt, uIdx:UInt;
					var indexOffset:UInt;
					var subGeom:ISubGeometry;
					var vo:GeometryVO;
					var vertices:Array<Float>;
					var normals:Array<Float>;
					var vStride:UInt, nStride:UInt, uStride:UInt;
					var vOffs:UInt, nOffs:UInt, uOffs:UInt;
					var vd:Array<Float>, nd:Array<Float>, ud:Array<Float>;
					
					subGeom = subGeometries[subIdx];
					vd = subGeom.vertexData;
					vStride = subGeom.vertexStride;
					vOffs = subGeom.vertexOffset;
					nd = subGeom.vertexNormalData;
					nStride = subGeom.vertexNormalStride;
					nOffs = subGeom.vertexNormalOffset;
					ud = subGeom.UVData;
					uStride = subGeom.UVStride;
					uOffs = subGeom.UVOffset;
					
					// Get (or create) a VO for this material
					vo = getSubGeomData(mesh.subMeshes[subIdx].material || mesh.material);
					
					// Vertices and normals are copied to temporary vectors, to be transformed
					// before concatenated onto those of the data. This is unnecessary if no
					// transformation will be performed, i.e. for object space merging.
					vertices = (_objectSpace)? vo.vertices : new Array<Float>();
					normals = (_objectSpace)? vo.normals : new Array<Float>();
					
					// Copy over vertex attributes
					vIdx = vertices.length;
					nIdx = normals.length;
					uIdx = vo.uvs.length;
					len = subGeom.numVertices;
					// For loop conversion - 					for (i = 0; i < len; i++)
					for (i in 0...len) {
						// Position
						calc = vOffs + i*vStride;
						vertices[vIdx++] = vd[calc];
						vertices[vIdx++] = vd[calc + 1];
						vertices[vIdx++] = vd[calc + 2];
						
						// Normal
						calc = nOffs + i*nStride;
						normals[nIdx++] = nd[calc];
						normals[nIdx++] = nd[calc + 1];
						normals[nIdx++] = nd[calc + 2];
						
						// UV
						calc = uOffs + i*uStride;
						vo.uvs[uIdx++] = ud[calc];
						vo.uvs[uIdx++] = ud[calc + 1];
					}
					
					// Copy over triangle indices
					indexOffset = (!_objectSpace)? vo.vertices.length/3 :0;
					iIdx = vo.indices.length;
					len = subGeom.numTriangles;
					// For loop conversion - 					for (i = 0; i < len; i++)
					for (i in 0...len) {
						calc = i*3;
						vo.indices[iIdx++] = subGeom.indexData[calc] + indexOffset;
						vo.indices[iIdx++] = subGeom.indexData[calc + 1] + indexOffset;
						vo.indices[iIdx++] = subGeom.indexData[calc + 2] + indexOffset;
					}
					
					if (!_objectSpace) {
						mesh.sceneTransform.transformVectors(vertices, vertices);
						mesh.sceneTransform.transformVectors(normals, normals);
						
						// Copy vertex data from temporary (transformed) vectors
						vIdx = vo.vertices.length;
						nIdx = vo.normals.length;
						len = vertices.length;
						// For loop conversion - 						for (i = 0; i < len; i++)
						for (i in 0...len) {
							vo.vertices[vIdx++] = vertices[i];
							vo.normals[nIdx++] = normals[i];
						}
					}
				}
				
				if (dispose)
					_toDispose.push(mesh);
			}
		}
		
		private function getSubGeomData(material:MaterialBase):GeometryVO
		{
			var data:GeometryVO;
			
			if (_keepMaterial) {
				var i:UInt = 0;
				var len:UInt;
				
				len = _geomVOs.length;
				// For loop conversion - 				for (i = 0; i < len; i++)
				for (i in 0...len) {
					if (_geomVOs[i].material == material) {
						data = _geomVOs[i];
						break;
					}
				}
			} else if (_geomVOs.length) {
				// If materials are not to be kept, all data can be
				// put into a single VO, so return that one.
				data = _geomVOs[0];
			}
			
			// No data (for this material) found, create new.
			if (!data) {
				data = new GeometryVO();
				data.vertices = new Array<Float>();
				data.normals = new Array<Float>();
				data.uvs = new Array<Float>();
				data.indices = new Array<UInt>();
				data.material = material;
				
				_geomVOs.push(data);
			}
			
			return data;
		}
		
		private function parseContainer(receiver:Mesh, object:ObjectContainer3D):Void
		{
			var child:ObjectContainer3D;
			var i:UInt = 0;
			
			if (object is Mesh && object != receiver)
				collect(Mesh(object), _disposeSources);
			
			// For loop conversion - 						for (i = 0; i < object.numChildren; ++i)
			
			for (i in 0...object.numChildren) {
				child = object.getChildAt(i);
				parseContainer(receiver, child);
			}
		}
	}
}

import away3d.materials.MaterialBase;

class GeometryVO
{
	public var uvs:Array<Float>;
	public var vertices:Array<Float>;
	public var normals:Array<Float>;
	public var indices:Array<UInt>;
	public var material:MaterialBase;
	
	public function GeometryVO()
	{
	}

