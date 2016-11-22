package away3d.core.pick;

import away3d.core.base.*;

import openfl.geom.*;
import openfl.Vector;

/**
 * Pure Haxe picking collider for entity objects. Used with the <code>RaycastPicker</code> picking object.
 *
 * @see away3d.entities.Entity#pickingCollider
 * @see away3d.core.pick.RaycastPicker
 */
class HaxePickingCollider extends PickingColliderBase implements IPickingCollider
{
	private var _findClosestCollision:Bool;
	
	/**
	 * Creates a new <code>HaxePickingCollider</code> object.
	 *
	 * @param findClosestCollision Determines whether the picking collider searches for the closest collision along the ray. Defaults to false.
	 */
	public function new(findClosestCollision:Bool = false)
	{
		super();
		_findClosestCollision = findClosestCollision;
	}
	
	/**
	 * @inheritDoc
	 */
	public function testSubMeshCollision(subMesh:SubMesh, pickingCollisionVO:PickingCollisionVO, shortestCollisionDistance:Float):Bool
	{
		var t:Float;
		var i0:Int, i1:Int, i2:Int;
		var rx:Float, ry:Float, rz:Float;
		var nx:Float, ny:Float, nz:Float;
		var cx:Float, cy:Float, cz:Float;
		var coeff:Float, u:Float, v:Float, w:Float;
		var p0x:Float, p0y:Float, p0z:Float;
		var p1x:Float, p1y:Float, p1z:Float;
		var p2x:Float, p2y:Float, p2z:Float;
		var s0x:Float, s0y:Float, s0z:Float;
		var s1x:Float, s1y:Float, s1z:Float;
		var nl:Float, nDotV:Float, D:Float, disToPlane:Float;
		var Q1Q2:Float, Q1Q1:Float, Q2Q2:Float, RQ1:Float, RQ2:Float;
		var indexData:Vector<UInt> = subMesh.indexData;
		var vertexData:Vector<Float> = subMesh.vertexData;
		var uvData:Vector<Float> = subMesh.UVData;
		var collisionTriangleIndex:Int = -1;
		var bothSides:Bool = (subMesh.material != null && subMesh.material.bothSides);
		
		var vertexStride:Int = subMesh.vertexStride;
		var vertexOffset:Int = subMesh.vertexOffset;
		var uvStride:Int = subMesh.UVStride;
		var uvOffset:Int = subMesh.UVOffset;
		var numIndices:Int = indexData.length;
		
		var index = 0;
		while (index < numIndices) { // sweep all triangles
			// evaluate triangle indices
			i0 = vertexOffset + indexData[ index ]*vertexStride;
			i1 = vertexOffset + indexData[ (index + 1) ]*vertexStride;
			i2 = vertexOffset + indexData[ (index + 2) ]*vertexStride;
			
			// evaluate triangle vertices
			p0x = vertexData[ i0 ];
			p0y = vertexData[ (i0 + 1) ];
			p0z = vertexData[ (i0 + 2) ];
			p1x = vertexData[ i1 ];
			p1y = vertexData[ (i1 + 1) ];
			p1z = vertexData[ (i1 + 2) ];
			p2x = vertexData[ i2 ];
			p2y = vertexData[ (i2 + 1) ];
			p2z = vertexData[ (i2 + 2) ];
			
			// evaluate sides and triangle normal
			s0x = p1x - p0x; // s0 = p1 - p0
			s0y = p1y - p0y;
			s0z = p1z - p0z;
			s1x = p2x - p0x; // s1 = p2 - p0
			s1y = p2y - p0y;
			s1z = p2z - p0z;
			nx = s0y*s1z - s0z*s1y; // n = s0 x s1
			ny = s0z*s1x - s0x*s1z;
			nz = s0x*s1y - s0y*s1x;
			nl = 1/Math.sqrt(nx*nx + ny*ny + nz*nz); // normalize n
			nx *= nl;
			ny *= nl;
			nz *= nl;
			
			// -- plane intersection test --
			nDotV = nx*rayDirection.x + ny*rayDirection.y + nz*rayDirection.z; // rayDirection . normal
			if (( !bothSides && nDotV < 0.0 ) || ( bothSides && nDotV != 0.0 )) { // an intersection must exist
				// find collision t
				D = -( nx*p0x + ny*p0y + nz*p0z );
				disToPlane = -( nx*rayPosition.x + ny*rayPosition.y + nz*rayPosition.z + D );
				t = disToPlane/nDotV;
				// find collision point
				cx = rayPosition.x + t*rayDirection.x;
				cy = rayPosition.y + t*rayDirection.y;
				cz = rayPosition.z + t*rayDirection.z;
				// collision point inside triangle? ( using barycentric coordinates )
				Q1Q2 = s0x*s1x + s0y*s1y + s0z*s1z;
				Q1Q1 = s0x*s0x + s0y*s0y + s0z*s0z;
				Q2Q2 = s1x*s1x + s1y*s1y + s1z*s1z;
				rx = cx - p0x;
				ry = cy - p0y;
				rz = cz - p0z;
				RQ1 = rx*s0x + ry*s0y + rz*s0z;
				RQ2 = rx*s1x + ry*s1y + rz*s1z;
				coeff = 1/( Q1Q1*Q2Q2 - Q1Q2*Q1Q2 );
				v = coeff*( Q2Q2*RQ1 - Q1Q2*RQ2 );
				w = coeff*( -Q1Q2*RQ1 + Q1Q1*RQ2 );
				if (v < 0 || w < 0) {
					index += 3;
					continue;
				}
				u = 1 - v - w;
				if (!( u < 0 ) && t > 0 && t < shortestCollisionDistance) { // all tests passed
					shortestCollisionDistance = t;
					collisionTriangleIndex = Std.int(index/3);
					pickingCollisionVO.rayEntryDistance = t;
					pickingCollisionVO.localPosition = new Vector3D(cx, cy, cz);
					pickingCollisionVO.localNormal = new Vector3D(nx, ny, nz);
					pickingCollisionVO.uv = getCollisionUV(indexData, uvData, index, v, w, u, uvOffset, uvStride);
					pickingCollisionVO.index = index;
					pickingCollisionVO.subGeometryIndex = getMeshSubMeshIndex(subMesh);
					
					// if not looking for best hit, first found will do...
					if (!_findClosestCollision)
						return true;
				}
			}
			index += 3;
		}
		
		if (collisionTriangleIndex >= 0)
			return true;
		
		return false;
	}
}