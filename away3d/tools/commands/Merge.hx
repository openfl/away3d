package away3d.tools.commands;

import away3d.containers.*;
import away3d.core.base.*;
import away3d.core.math.Matrix3DUtils;
import away3d.entities.*;
import away3d.materials.*;
import away3d.tools.utils.*;

import openfl.Vector;

/**
 *  Class Merge merges two or more static meshes into one.<code>Merge</code>
 */
class Merge
{
	public var disposeSources(get, set):Bool;
	public var keepMaterial(get, set):Bool;
	public var objectSpace(get, set):Bool;
	
	//private const LIMIT:uint = 196605;
	private var _objectSpace:Bool;
	private var _keepMaterial:Bool;
	private var _disposeSources:Bool;
	private var _geomVOs:Vector<GeometryVO>;
	private var _toDispose:Vector<Mesh>;
	
	/**
	 * @param    keepMaterial    [optional]    Determines if the merged object uses the recevier mesh material information or keeps its source material(s). Defaults to false.
	 * If false and receiver object has multiple materials, the last material found in receiver submeshes is applied to the merged submesh(es).
	 * @param    disposeSources  [optional]    Determines if the mesh and geometry source(s) used for the merging are disposed. Defaults to false.
	 * If true, only receiver geometry and resulting mesh are kept in  memory.
	 * @param    objectSpace     [optional]    Determines if source mesh(es) is/are merged using objectSpace or worldspace. Defaults to false.
	 */
	public function new (keepMaterial:Bool = false, disposeSources:Bool = false, objectSpace:Bool = false)
	{
		_keepMaterial = keepMaterial;
		_disposeSources = disposeSources;
		_objectSpace = objectSpace;
	}
	
	/**
	 * Determines if the mesh and geometry source(s) used for the merging are disposed. Defaults to false.
	 */
	private function set_disposeSources(b:Bool):Bool
	{
		_disposeSources = b;
		return b;
	}
	
	private function get_disposeSources():Bool
	{
		return _disposeSources;
	}
	
	/**
	 * Determines if the material source(s) used for the merging are disposed. Defaults to false.
	 */
	private function set_keepMaterial(b:Bool):Bool
	{
		_keepMaterial = b;
		return b;
	}
	
	private function get_keepMaterial():Bool
	{
		return _keepMaterial;
	}
	
	/**
	 * Determines if source mesh(es) is/are merged using objectSpace or worldspace. Defaults to false.
	 */
	private function set_objectSpace(b:Bool):Bool
	{
		_objectSpace = b;
		return b;
	}
	
	private function get_objectSpace():Bool
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
	public function applyToMeshes(receiver:Mesh, meshes:Vector<Mesh>):Void
	{
		reset();
		
		if (meshes.length == 0)
			return;
		
		//collect meshes in vector
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
	
	public function reset():Void
	{
		_toDispose = new Vector<Mesh>();
		_geomVOs = new Vector<GeometryVO>();
	}
	
	private function merge(destMesh:Mesh, dispose:Bool):Void
	{
		var i:Int = 0;
		var subIdx:Int;
		var oldGeom:Geometry;
		var destGeom:Geometry;
		var useSubMaterials:Bool;
		
		oldGeom = destMesh.geometry;
		destGeom = destMesh.geometry = new Geometry();
		subIdx = destMesh.subMeshes.length;
		
		// Only apply materials directly to sub-meshes if necessary,
		// i.e. if there is more than one material available.
		useSubMaterials = (_geomVOs.length > 1);
		
		for (i in 0..._geomVOs.length) {
			var s:Int;
			var data:GeometryVO;
			var subs:Vector<ISubGeometry>;
			
			data = _geomVOs[i];
			subs = GeomUtil.fromVectors(data.vertices, data.indices, data.uvs, data.normals, null, null, null);
			
			for (s in 0...subs.length) {
				destGeom.addSubGeometry(subs[s]);
				
				if (_keepMaterial && useSubMaterials)
					destMesh.subMeshes[subIdx].material = data.material;
				
				subIdx++;
			}
		}
		
		if (_keepMaterial && !useSubMaterials && _geomVOs.length > 0)
			destMesh.material = _geomVOs[0].material;
			
		if (dispose) {
			for (m in _toDispose) {
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
		if (mesh.geometry != null) {
			var subIdx:Int;
			var subGeometries:Vector<ISubGeometry> = mesh.geometry.subGeometries;
			var calc:Int;
			for (subIdx in 0...subGeometries.length) {
				var i:Int = 0;
				var len:Int;
				var iIdx:Int, vIdx:Int, nIdx:Int, uIdx:Int;
				var indexOffset:Int;
				var subGeom:ISubGeometry;
				var vo:GeometryVO;
				var vertices:Vector<Float>;
				var normals:Vector<Float>;
				var vStride:Int, nStride:Int, uStride:Int;
				var vOffs:Int, nOffs:Int, uOffs:Int;
				var vd:Vector<Float>, nd:Vector<Float>, ud:Vector<Float>;
				
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
				if (mesh.subMeshes[subIdx].material != null) 
					vo = getSubGeomData(mesh.subMeshes[subIdx].material);
				else 
					vo = getSubGeomData(mesh.material);
				
				// Vertices and normals are copied to temporary vectors, to be transformed
				// before concatenated onto those of the data. This is unnecessary if no
				// transformation will be performed, i.e. for object space merging.
				vertices = (_objectSpace)? vo.vertices : new Vector<Float>();
				normals = (_objectSpace)? vo.normals : new Vector<Float>();
				
				// Copy over vertex attributes
				vIdx = vertices.length;
				nIdx = normals.length;
				uIdx = vo.uvs.length;
				len = subGeom.numVertices;
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
				indexOffset = (!_objectSpace)? Std.int(vo.vertices.length/3) : 0;
				iIdx = vo.indices.length;
				len = subGeom.numTriangles;
				for (i in 0...len) {
					calc = i*3;
					vo.indices[iIdx++] = subGeom.indexData[calc] + indexOffset;
					vo.indices[iIdx++] = subGeom.indexData[calc + 1] + indexOffset;
					vo.indices[iIdx++] = subGeom.indexData[calc + 2] + indexOffset;
				}
				
				if (!_objectSpace) {
					mesh.sceneTransform.transformVectors(vertices, vertices);
					Matrix3DUtils.deltaTransformVectors(mesh.sceneTransform,normals, normals);
					
					// Copy vertex data from temporary (transformed) vectors
					vIdx = vo.vertices.length;
					nIdx = vo.normals.length;
					len = vertices.length;
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
		var data:GeometryVO = null;
		
		if (_keepMaterial) {
			var len:Int = _geomVOs.length;
			for (i in 0...len) {
				if (_geomVOs[i].material == material) {
					data = _geomVOs[i];
					break;
				}
			}
		} else if (_geomVOs.length > 0) {
			// If materials are not to be kept, all data can be
			// put into a single VO, so return that one.
			data = _geomVOs[0];
		}
		
		// No data (for this material) found, create new.
		if (data == null) {
			data = new GeometryVO();
			data.vertices = new Vector<Float>();
			data.normals = new Vector<Float>();
			data.uvs = new Vector<Float>();
			data.indices = new Vector<UInt>();
			data.material = material;
			
			_geomVOs.push(data);
		}
		
		return data;
	}
	
	private function parseContainer(receiver:Mesh, object:ObjectContainer3D):Void
	{
		var child:ObjectContainer3D;
		
		if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(object, Mesh) && object != receiver)
			collect(cast(object, Mesh), _disposeSources);
		
		for (i in 0...object.numChildren) {
			child = object.getChildAt(i);
			parseContainer(receiver, child);
		}
	}
}

class GeometryVO {

	public var uvs:Vector<Float>;
	public var vertices:Vector<Float>;
	public var normals:Vector<Float>;
	public var indices:Vector<UInt>;
	public var material:MaterialBase;
	
	public function new()
	{
	}
}