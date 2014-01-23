/**
 * Class Explode make all vertices and uv's of a mesh unic<code>Explode</code>
 */
package away3d.tools.commands;


import away3d.utils.ArrayUtils;
import flash.Vector;
import away3d.containers.ObjectContainer3D;
import away3d.core.base.Geometry;
import away3d.core.base.ISubGeometry;
import away3d.entities.Mesh;
import away3d.tools.utils.GeomUtil;

class Explode {

    private var _keepNormals:Bool;

    public function new() {
    }

/**
	 *  Apply the explode code to a given ObjectContainer3D.
	 * @param     object                ObjectContainer3D. The target Object3d object.
	 * @param     keepNormals        Boolean. If the vertexNormals of the object are preserved. Default is true.
	 */

    public function applyToContainer(ctr:ObjectContainer3D, keepNormals:Bool = true):Void {
        _keepNormals = keepNormals;
        parse(ctr);
    }

    public function apply(geom:Geometry, keepNormals:Bool = true):Void {
        var i:Int = 0;
        _keepNormals = keepNormals;
        i = 0;
        while (i < geom.subGeometries.length) {
            explodeSubGeom(geom.subGeometries[i], geom);
            i++;
        }
    }

/**
	 * recursive parsing of a container.
	 */

    private function parse(object:ObjectContainer3D):Void {
        var child:ObjectContainer3D;
        if (Std.is(object, Mesh) && object.numChildren == 0)apply(cast((object), Mesh).geometry, _keepNormals);
        var i:Int = 0;
        while (i < object.numChildren) {
            child = object.getChildAt(i);
            parse(child);
            ++i;
        }
    }

    private function explodeSubGeom(subGeom:ISubGeometry, geom:Geometry):Void {
        var i:Int = 0;
        var len:Int;
        var inIndices:Vector<UInt>;
        var outIndices:Vector<UInt>;
        var vertices:Vector<Float>;
        var normals:Vector<Float>;
        var uvs:Vector<Float>;
        var vIdx:Int;
        var uIdx:Int;
        var outSubGeoms:Vector<ISubGeometry>;
        var vStride:Int;
        var nStride:Int;
        var uStride:Int;
        var vOffs:Int;
        var nOffs:Int;
        var uOffs:Int;
        var vd:Vector<Float>;
        var nd:Vector<Float>;
        var ud:Vector<Float>;
        vd = subGeom.vertexData;
        vStride = subGeom.vertexStride;
        vOffs = subGeom.vertexOffset;
        nd = subGeom.vertexNormalData;
        nStride = subGeom.vertexNormalStride;
        nOffs = subGeom.vertexNormalOffset;
        ud = subGeom.UVData;
        uStride = subGeom.UVStride;
        uOffs = subGeom.UVOffset;
        inIndices = subGeom.indexData;
        outIndices = new Vector<UInt>(inIndices.length, true);
        vertices = new Vector<Float>(inIndices.length * 3, true);
        normals = new Vector<Float>(inIndices.length * 3, true);
        uvs = new Vector<Float>(inIndices.length * 2, true);
        ArrayUtils.Prefill(outIndices,inIndices.length,0);
        ArrayUtils.Prefill(vertices,inIndices.length,0);
        ArrayUtils.Prefill(normals,inIndices.length,0);
        ArrayUtils.Prefill(uvs,inIndices.length,0);
        vIdx = 0;
        uIdx = 0;
        len = inIndices.length;
        i = 0;
        while (i < len) {
            var index:Int;
            index = inIndices[i];
            vertices[vIdx + 0] = vd[vOffs + index * vStride + 0];
            vertices[vIdx + 1] = vd[vOffs + index * vStride + 1];
            vertices[vIdx + 2] = vd[vOffs + index * vStride + 2];
            if (_keepNormals) {
                normals[vIdx + 0] = vd[nOffs + index * nStride + 0];
                normals[vIdx + 1] = vd[nOffs + index * nStride + 1];
                normals[vIdx + 2] = vd[nOffs + index * nStride + 2];
            }

            else normals[vIdx + 0] = normals[vIdx + 1] = normals[vIdx + 2] = 0;
            uvs[uIdx++] = ud[uOffs + index * uStride + 0];
            uvs[uIdx++] = ud[uOffs + index * uStride + 1];
            vIdx += 3;
            outIndices[i] = i;
            i++;
        }
        outSubGeoms = GeomUtil.fromVectors(vertices, outIndices, uvs, normals, null, null, null);
        geom.removeSubGeometry(subGeom);
        i = 0;
        while (i < outSubGeoms.length) {
            outSubGeoms[i].autoDeriveVertexNormals = !_keepNormals;
            geom.addSubGeometry(outSubGeoms[i]);
            i++;
        }
    }

}

