package away3d.core.pick;

import away3d.tools.utils.GeomUtil;
import away3d.core.base.SubGeometry;
import away3d.core.base.SubMesh;

import openfl.geom.Point;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * An abstract base class for all picking collider classes. It should not be instantiated directly.
 */
class PickingColliderBase
{
	private var rayPosition:Vector3D;
	private var rayDirection:Vector3D;
	
	public function new()
	{
	
	}
	
	private function getCollisionNormal(indexData:Vector<UInt>, vertexData:Vector<Float>, triangleIndex:Int, normal:Vector3D = null):Vector3D
	{
		var i0:Int = indexData[ triangleIndex ]*3;
		var i1:Int = indexData[ triangleIndex + 1 ]*3;
		var i2:Int = indexData[ triangleIndex + 2 ]*3;

		var side0x:Float = vertexData[ i1 ] - vertexData[ i0 ];
		var side0y:Float = vertexData[ i1 + 1] - vertexData[ i0 + 1];
		var side0z:Float = vertexData[ i1 + 2] - vertexData[ i0 + 2];
		var side1x:Float = vertexData[ i2 ] - vertexData[ i0 ];
		var side1y:Float = vertexData[ i2 + 1] - vertexData[ i0 + 1];
		var side1z:Float = vertexData[ i2 + 2] - vertexData[ i0 + 2];

		if(normal == null) normal = new Vector3D();
		normal.x = side0y*side1z - side0z*side1y;
		normal.y = side0z*side1x - side0x*side1z;
		normal.z = side0x*side1y - side0y*side1x;
		normal.w = 1;
		normal.normalize();
		return normal;
	}
	
	private function getCollisionUV(indexData:Vector<UInt>, uvData:Vector<Float>, triangleIndex:Int, v:Float, w:Float, u:Float, uvOffset:Int, uvStride:Int, uv:Point = null):Point
	{
		var uIndex:Int = indexData[ triangleIndex ]*uvStride + uvOffset;
		var uv0x:Float = uvData[ uIndex ];
		var uv0y:Float = uvData[ uIndex +1 ];
		uIndex = indexData[ triangleIndex + 1 ]*uvStride + uvOffset;
		var uv1x:Float = uvData[ uIndex ];
		var uv1y:Float = uvData[ uIndex +1 ];
		uIndex = indexData[ triangleIndex + 2 ]*uvStride + uvOffset;
		var uv2x:Float = uvData[ uIndex ];
		var uv2y:Float = uvData[ uIndex +1 ];
		if(uv == null) uv = new Point();
		uv.x = u*uv0x + v*uv1x + w*uv2x;
		uv.y = u*uv0y + v*uv1y + w*uv2y;
		return uv;
	}
	
	private function getMeshSubgeometryIndex(subGeometry:SubGeometry):Int
	{
		return GeomUtil.getMeshSubgeometryIndex(subGeometry);
	}
	
	private function getMeshSubMeshIndex(subMesh:SubMesh):Int
	{
		return GeomUtil.getMeshSubMeshIndex(subMesh);
	}
	
	/**
	 * @inheritDoc
	 */
	public function setLocalRay(localPosition:Vector3D, localDirection:Vector3D):Void
	{
		rayPosition = localPosition;
		rayDirection = localDirection;
	}
}