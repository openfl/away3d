/**
 *  Class Merge merges two or more static meshes into one.<code>Merge</code>
 */
package away3d.tools.commands;

import away3d.tools.utils.GeomUtil;
import away3d.core.base.ISubGeometry;
import away3d.core.base.Geometry;
import away3d.containers.ObjectContainer3D;
import flash.Vector;
import away3d.entities.Mesh;
import away3d.materials.MaterialBase;

class Merge {
    public var disposeSources(get_disposeSources, set_disposeSources):Bool;
    public var keepMaterial(get_keepMaterial, set_keepMaterial):Bool;
    public var objectSpace(get_objectSpace, set_objectSpace):Bool;

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

    function new(keepMaterial:Bool = false, disposeSources:Bool = false, objectSpace:Bool = false) {
        _keepMaterial = keepMaterial;
        _disposeSources = disposeSources;
        _objectSpace = objectSpace;
    }

/**
	 * Determines if the mesh and geometry source(s) used for the merging are disposed. Defaults to false.
	 */

    public function set_disposeSources(b:Bool):Bool {
        _disposeSources = b;
        return b;
    }

    public function get_disposeSources():Bool {
        return _disposeSources;
    }

/**
	 * Determines if the material source(s) used for the merging are disposed. Defaults to false.
	 */

    public function set_keepMaterial(b:Bool):Bool {
        _keepMaterial = b;
        return b;
    }

    public function get_keepMaterial():Bool {
        return _keepMaterial;
    }

/**
	 * Determines if source mesh(es) is/are merged using objectSpace or worldspace. Defaults to false.
	 */

    public function set_objectSpace(b:Bool):Bool {
        _objectSpace = b;
        return b;
    }

    public function get_objectSpace():Bool {
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

    public function applyToContainer(receiver:Mesh, objectContainer:ObjectContainer3D):Void {
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

    public function applyToMeshes(receiver:Mesh, meshes:Vector<Mesh>):Void {
        reset();
        if (!meshes.length) return;
        var i:Int = 0;
        while (i < meshes.length) {
            if (meshes[i] != receiver) collect(meshes[i], _disposeSources);
            i++;
        }
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

    public function apply(receiver:Mesh, mesh:Mesh):Void {
        reset();
//collect mesh
        collect(mesh, _disposeSources);
//collect receiver
        collect(receiver, false);
//merge to receiver
        merge(receiver, _disposeSources);
    }

    public function reset():Void {
        _toDispose = new Vector<Mesh>();
        _geomVOs = new Vector<GeometryVO>();
    }

    private function merge(destMesh:Mesh, dispose:Bool):Void {
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
        i = 0;
        while (i < _geomVOs.length) {
            var s:Int;
            var data:GeometryVO;
            var subs:Vector<ISubGeometry>;
            data = _geomVOs[i];
            subs = GeomUtil.fromVectors(data.vertices, data.indices, data.uvs, data.normals, null, null, null);
            s = 0;
            while (s < subs.length) {
                destGeom.addSubGeometry(subs[s]);
                if (_keepMaterial && useSubMaterials) destMesh.subMeshes[subIdx].material = data.material;
                subIdx++;
                s++;
            }
            i++;
        }
        if (_keepMaterial && !useSubMaterials && _geomVOs.length) destMesh.material = _geomVOs[0].material;
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

    private function collect(mesh:Mesh, dispose:Bool):Void {
        if (mesh.geometry) {
            var subIdx:Int;
            var subGeometries:Vector<ISubGeometry> = mesh.geometry.subGeometries;
            var calc:Int;
            subIdx = 0;
            while (subIdx < subGeometries.length) {
                var i:Int = 0;
                var len:Int;
                var iIdx:Int;
                var vIdx:Int;
                var nIdx:Int;
                var uIdx:Int;
                var indexOffset:Int;
                var subGeom:ISubGeometry;
                var vo:GeometryVO;
                var vertices:Vector<Float>;
                var normals:Vector<Float>;
                var vStride:Int;
                var nStride:Int;
                var uStride:Int;
                var vOffs:Int;
                var nOffs:Int;
                var uOffs:Int;
                var vd:Vector<Float>;
                var nd:Vector<Float>;
                var ud:Vector<Float>;
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
                vertices = ((_objectSpace)) ? vo.vertices : new Vector<Float>();
                normals = ((_objectSpace)) ? vo.normals : new Vector<Float>();
// Copy over vertex attributes
                vIdx = vertices.length;
                nIdx = normals.length;
                uIdx = vo.uvs.length;
                len = subGeom.numVertices;
                i = 0;
                while (i < len) {
// Position
                    calc = vOffs + i * vStride;
                    vertices[vIdx++] = vd[calc];
                    vertices[vIdx++] = vd[calc + 1];
                    vertices[vIdx++] = vd[calc + 2];
// Normal
                    calc = nOffs + i * nStride;
                    normals[nIdx++] = nd[calc];
                    normals[nIdx++] = nd[calc + 1];
                    normals[nIdx++] = nd[calc + 2];
// UV
                    calc = uOffs + i * uStride;
                    vo.uvs[uIdx++] = ud[calc];
                    vo.uvs[uIdx++] = ud[calc + 1];
                    i++;
                }
// Copy over triangle indices
                indexOffset = ((!_objectSpace)) ? vo.vertices.length / 3 : 0;
                iIdx = vo.indices.length;
                len = subGeom.numTriangles;
                i = 0;
                while (i < len) {
                    calc = i * 3;
                    vo.indices[iIdx++] = subGeom.indexData[calc] + indexOffset;
                    vo.indices[iIdx++] = subGeom.indexData[calc + 1] + indexOffset;
                    vo.indices[iIdx++] = subGeom.indexData[calc + 2] + indexOffset;
                    i++;
                }
                if (!_objectSpace) {
                    mesh.sceneTransform.transformVectors(vertices, vertices);
                    mesh.sceneTransform.transformVectors(normals, normals);
// Copy vertex data from temporary (transformed) vectors
                    vIdx = vo.vertices.length;
                    nIdx = vo.normals.length;
                    len = vertices.length;
                    i = 0;
                    while (i < len) {
                        vo.vertices[vIdx++] = vertices[i];
                        vo.normals[nIdx++] = normals[i];
                        i++;
                    }
                }
                subIdx++;
            }
            if (dispose) _toDispose.push(mesh);
        }
    }

    private function getSubGeomData(material:MaterialBase):GeometryVO {
        var data:GeometryVO;
        if (_keepMaterial) {
            var i:Int = 0;
            var len:Int;
            len = _geomVOs.length;
            i = 0;
            while (i < len) {
                if (_geomVOs[i].material == material) {
                    data = _geomVOs[i];
                    break;
                }
                i++;
            }
        }

        else if (_geomVOs.length) {
// If materials are not to be kept, all data can be
// put into a single VO, so return that one.
            data = _geomVOs[0];
        }
        if (!data) {
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

    private function parseContainer(receiver:Mesh, object:ObjectContainer3D):Void {
        var child:ObjectContainer3D;
        var i:Int = 0;
        if (Std.is(object, Mesh && object != receiver)) collect(cast((object), Mesh), _disposeSources);
        i = 0;
        while (i < object.numChildren) {
            child = object.getChildAt(i);
            parseContainer(receiver, child);
            ++i;
        }
    }

}

class GeometryVO {

    public var uvs:Vector<Float>;
    public var vertices:Vector<Float>;
    public var normals:Vector<Float>;
    public var indices:Vector<UInt>;
    public var material:MaterialBase;

    public function new() {
    }

}

