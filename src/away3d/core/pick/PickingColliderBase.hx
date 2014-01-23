/**
 * An abstract base class for all picking collider classes. It should not be instantiated directly.
 */
package away3d.core.pick;

import flash.geom.Point;
import flash.Vector;
import flash.geom.Vector3D;
import away3d.tools.utils.GeomUtil;
import away3d.core.base.SubGeometry;
import away3d.core.base.SubMesh;

class PickingColliderBase {

    private var rayPosition:Vector3D;
    private var rayDirection:Vector3D;

    public function new() {
    }

    private function getCollisionNormal(indexData:Vector<UInt>, vertexData:Vector<Float>, triangleIndex:Int):Vector3D {
        var normal:Vector3D = new Vector3D();
        var i0:Int = indexData[triangleIndex] * 3;
        var i1:Int = indexData[triangleIndex + 1] * 3;
        var i2:Int = indexData[triangleIndex + 2] * 3;
        var p0:Vector3D = new Vector3D(vertexData[i0], vertexData[i0 + 1], vertexData[i0 + 2]);
        var p1:Vector3D = new Vector3D(vertexData[i1], vertexData[i1 + 1], vertexData[i1 + 2]);
        var p2:Vector3D = new Vector3D(vertexData[i2], vertexData[i2 + 1], vertexData[i2 + 2]);
        var side0:Vector3D = p1.subtract(p0);
        var side1:Vector3D = p2.subtract(p0);
        normal = side0.crossProduct(side1);
        normal.normalize();
        return normal;
    }

    private function getCollisionUV(indexData:Vector<UInt>, uvData:Vector<Float>, triangleIndex:Int, v:Float, w:Float, u:Float, uvOffset:Int, uvStride:Int):Point {
        var uv:Point = new Point();
        var uIndex:Int = indexData[triangleIndex] * uvStride + uvOffset;
        var uv0:Vector3D = new Vector3D(uvData[uIndex], uvData[uIndex + 1]);
        uIndex = indexData[triangleIndex + 1] * uvStride + uvOffset;
        var uv1:Vector3D = new Vector3D(uvData[uIndex], uvData[uIndex + 1]);
        uIndex = indexData[triangleIndex + 2] * uvStride + uvOffset;
        var uv2:Vector3D = new Vector3D(uvData[uIndex], uvData[uIndex + 1]);
        uv.x = u * uv0.x + v * uv1.x + w * uv2.x;
        uv.y = u * uv0.y + v * uv1.y + w * uv2.y;
        return uv;
    }

    private function getMeshSubgeometryIndex(subGeometry:SubGeometry):Int {
        return GeomUtil.getMeshSubgeometryIndex(subGeometry);
    }

    private function getMeshSubMeshIndex(subMesh:SubMesh):Int {
        return GeomUtil.getMeshSubMeshIndex(subMesh);
    }

/**
	 * @inheritDoc
	 */

    public function setLocalRay(localPosition:Vector3D, localDirection:Vector3D):Void {
        rayPosition = localPosition;
        rayDirection = localDirection;
    }

}

