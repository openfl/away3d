package away3d.bounds;

import away3d.core.math.*;
import away3d.primitives.*;

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * AxisAlignedBoundingBox represents a bounding box volume that has its planes aligned to the local coordinate axes of the bounded object.
 * This is useful for most meshes.
 */
class AxisAlignedBoundingBox extends BoundingVolumeBase
{
	public var halfExtentsX(get, never):Float;
	public var halfExtentsY(get, never):Float;
	public var halfExtentsZ(get, never):Float;
	
	private var _centerX:Float = 0;
	private var _centerY:Float = 0;
	private var _centerZ:Float = 0;
	private var _halfExtentsX:Float = 0;
	private var _halfExtentsY:Float = 0;
	private var _halfExtentsZ:Float = 0;
	
	/**
	 * Creates a new <code>AxisAlignedBoundingBox</code> object.
	 */
	public function new()
	{
		super();
	}
	
	/**
	 * @inheritDoc
	 */
	override public function nullify():Void
	{
		super.nullify();
		_centerX = _centerY = _centerZ = 0;
		_halfExtentsX = _halfExtentsY = _halfExtentsZ = 0;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function isInFrustum(planes:Vector<Plane3D>, numPlanes:Int):Bool
	{
		for (i in 0...numPlanes) {
			var plane:Plane3D = planes[i];
			var a:Float = plane.a;
			var b:Float = plane.b;
			var c:Float = plane.c;
			var flippedExtentX:Float = a < 0? -_halfExtentsX : _halfExtentsX;
			var flippedExtentY:Float = b < 0? -_halfExtentsY : _halfExtentsY;
			var flippedExtentZ:Float = c < 0? -_halfExtentsZ : _halfExtentsZ;
			var projDist:Float = a*(_centerX + flippedExtentX) + b*(_centerY + flippedExtentY) + c*(_centerZ + flippedExtentZ) - plane.d;
			if (projDist < 0)
				return false;
		}
		
		return true;
	}
	
	override public function rayIntersection(position:Vector3D, direction:Vector3D, targetNormal:Vector3D):Float
	{
		if (containsPoint(position))
			return 0;
		
		var px:Float = position.x - _centerX, py:Float = position.y - _centerY, pz:Float = position.z - _centerZ;
		var vx:Float = direction.x, vy:Float = direction.y, vz:Float = direction.z;
		var ix:Float, iy:Float, iz:Float;
		var rayEntryDistance:Float = 0;
		
		// ray-plane tests
		var intersects:Bool = false;
		if (vx < 0) {
			rayEntryDistance = ( _halfExtentsX - px )/vx;
			if (rayEntryDistance > 0) {
				iy = py + rayEntryDistance*vy;
				iz = pz + rayEntryDistance*vz;
				if (iy > -_halfExtentsY && iy < _halfExtentsY && iz > -_halfExtentsZ && iz < _halfExtentsZ) {
					targetNormal.x = 1;
					targetNormal.y = 0;
					targetNormal.z = 0;
					
					intersects = true;
				}
			}
		}
		if (!intersects && vx > 0) {
			rayEntryDistance = ( -_halfExtentsX - px )/vx;
			if (rayEntryDistance > 0) {
				iy = py + rayEntryDistance*vy;
				iz = pz + rayEntryDistance*vz;
				if (iy > -_halfExtentsY && iy < _halfExtentsY && iz > -_halfExtentsZ && iz < _halfExtentsZ) {
					targetNormal.x = -1;
					targetNormal.y = 0;
					targetNormal.z = 0;
					intersects = true;
				}
			}
		}
		if (!intersects && vy < 0) {
			rayEntryDistance = ( _halfExtentsY - py )/vy;
			if (rayEntryDistance > 0) {
				ix = px + rayEntryDistance*vx;
				iz = pz + rayEntryDistance*vz;
				if (ix > -_halfExtentsX && ix < _halfExtentsX && iz > -_halfExtentsZ && iz < _halfExtentsZ) {
					targetNormal.x = 0;
					targetNormal.y = 1;
					targetNormal.z = 0;
					intersects = true;
				}
			}
		}
		if (!intersects && vy > 0) {
			rayEntryDistance = ( -_halfExtentsY - py )/vy;
			if (rayEntryDistance > 0) {
				ix = px + rayEntryDistance*vx;
				iz = pz + rayEntryDistance*vz;
				if (ix > -_halfExtentsX && ix < _halfExtentsX && iz > -_halfExtentsZ && iz < _halfExtentsZ) {
					targetNormal.x = 0;
					targetNormal.y = -1;
					targetNormal.z = 0;
					intersects = true;
				}
			}
		}
		if (!intersects && vz < 0) {
			rayEntryDistance = ( _halfExtentsZ - pz )/vz;
			if (rayEntryDistance > 0) {
				ix = px + rayEntryDistance*vx;
				iy = py + rayEntryDistance*vy;
				if (iy > -_halfExtentsY && iy < _halfExtentsY && ix > -_halfExtentsX && ix < _halfExtentsX) {
					targetNormal.x = 0;
					targetNormal.y = 0;
					targetNormal.z = 1;
					intersects = true;
				}
			}
		}
		if (!intersects && vz > 0) {
			rayEntryDistance = ( -_halfExtentsZ - pz )/vz;
			if (rayEntryDistance > 0) {
				ix = px + rayEntryDistance*vx;
				iy = py + rayEntryDistance*vy;
				if (iy > -_halfExtentsY && iy < _halfExtentsY && ix > -_halfExtentsX && ix < _halfExtentsX) {
					targetNormal.x = 0;
					targetNormal.y = 0;
					targetNormal.z = -1;
					intersects = true;
				}
			}
		}
		
		return intersects? rayEntryDistance : -1;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function containsPoint(position:Vector3D):Bool
	{
		var px:Float = position.x - _centerX, py:Float = position.y - _centerY, pz:Float = position.z - _centerZ;
		return px <= _halfExtentsX && px >= -_halfExtentsX &&
			py <= _halfExtentsY && py >= -_halfExtentsY &&
			pz <= _halfExtentsZ && pz >= -_halfExtentsZ;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function fromExtremes(minX:Float, minY:Float, minZ:Float, maxX:Float, maxY:Float, maxZ:Float):Void
	{
		_centerX = (maxX + minX)*.5;
		_centerY = (maxY + minY)*.5;
		_centerZ = (maxZ + minZ)*.5;
		_halfExtentsX = (maxX - minX)*.5;
		_halfExtentsY = (maxY - minY)*.5;
		_halfExtentsZ = (maxZ - minZ)*.5;
		super.fromExtremes(minX, minY, minZ, maxX, maxY, maxZ);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function clone():BoundingVolumeBase
	{
		var clone:AxisAlignedBoundingBox = new AxisAlignedBoundingBox();
		clone.fromExtremes(_min.x, _min.y, _min.z, _max.x, _max.y, _max.z);
		return clone;
	}
	
	private function get_halfExtentsX():Float
	{
		return _halfExtentsX;
	}
	
	private function get_halfExtentsY():Float
	{
		return _halfExtentsY;
	}
	
	private function get_halfExtentsZ():Float
	{
		return _halfExtentsZ;
	}
	
	/**
	 * Finds the closest point on the bounding volume to another given point. This can be used for maximum error calculations for content within a given bound.
	 * @param point The point for which to find the closest point on the bounding volume
	 * @param target An optional Vector3D to store the result to prevent creating a new object.
	 * @return
	 */
	public function closestPointToPoint(point:Vector3D, target:Vector3D = null):Vector3D
	{
		var p:Float;
		if (target == null)
			target = new Vector3D();
		
		p = point.x;
		if (p < _min.x)
			p = _min.x;
		if (p > _max.x)
			p = _max.x;
		target.x = p;
		
		p = point.y;
		if (p < _min.y)
			p = _min.y;
		if (p > _max.y)
			p = _max.y;
		target.y = p;
		
		p = point.z;
		if (p < _min.z)
			p = _min.z;
		if (p > _max.z)
			p = _max.z;
		target.z = p;
		
		return target;
	}
	
	override private function updateBoundingRenderable():Void
	{
		_boundingRenderable.scaleX = Math.max(_halfExtentsX*2, 0.001);
		_boundingRenderable.scaleY = Math.max(_halfExtentsY*2, 0.001);
		_boundingRenderable.scaleZ = Math.max(_halfExtentsZ*2, 0.001);
		_boundingRenderable.x = _centerX;
		_boundingRenderable.y = _centerY;
		_boundingRenderable.z = _centerZ;
	}
	
	override private function createBoundingRenderable():WireframePrimitiveBase
	{
		return new WireframeCube(1, 1, 1, 0xffffff, 0.5);
	}

	override public function classifyToPlane(plane:Plane3D):Int
	{
		var a:Float = plane.a;
		var b:Float = plane.b;
		var c:Float = plane.c;
		var centerDistance:Float = a*_centerX + b*_centerY + c*_centerZ - plane.d;
		if (a < 0)
			a = -a;
		if (b < 0)
			b = -b;
		if (c < 0)
			c = -c;
		var boundOffset:Float = a*_halfExtentsX + b*_halfExtentsY + c*_halfExtentsZ;
		
		return centerDistance > boundOffset? PlaneClassification.FRONT :
			centerDistance < -boundOffset? PlaneClassification.BACK :
			PlaneClassification.INTERSECT;
	}
	
	override public function transformFrom(bounds:BoundingVolumeBase, matrix:Matrix3D):Void
	{
		var aabb:AxisAlignedBoundingBox = cast(bounds, AxisAlignedBoundingBox);
		var cx:Float = aabb._centerX;
		var cy:Float = aabb._centerY;
		var cz:Float = aabb._centerZ;
		var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
		matrix.copyRawDataTo(raw);
		var m11:Float = raw[0], m12:Float = raw[4], m13:Float = raw[8], m14:Float = raw[12];
		var m21:Float = raw[1], m22:Float = raw[5], m23:Float = raw[9], m24:Float = raw[13];
		var m31:Float = raw[2], m32:Float = raw[6], m33:Float = raw[10], m34:Float = raw[14];
		
		_centerX = cx*m11 + cy*m12 + cz*m13 + m14;
		_centerY = cx*m21 + cy*m22 + cz*m23 + m24;
		_centerZ = cx*m31 + cy*m32 + cz*m33 + m34;
		
		if (m11 < 0)
			m11 = -m11;
		if (m12 < 0)
			m12 = -m12;
		if (m13 < 0)
			m13 = -m13;
		if (m21 < 0)
			m21 = -m21;
		if (m22 < 0)
			m22 = -m22;
		if (m23 < 0)
			m23 = -m23;
		if (m31 < 0)
			m31 = -m31;
		if (m32 < 0)
			m32 = -m32;
		if (m33 < 0)
			m33 = -m33;
		var hx:Float = aabb._halfExtentsX;
		var hy:Float = aabb._halfExtentsY;
		var hz:Float = aabb._halfExtentsZ;
		_halfExtentsX = hx*m11 + hy*m12 + hz*m13;
		_halfExtentsY = hx*m21 + hy*m22 + hz*m23;
		_halfExtentsZ = hx*m31 + hy*m32 + hz*m33;
		
		_min.x = _centerX - _halfExtentsX;
		_min.y = _centerY - _halfExtentsY;
		_min.z = _centerZ - _halfExtentsZ;
		_max.x = _centerX + _halfExtentsX;
		_max.y = _centerY + _halfExtentsY;
		_max.z = _centerZ + _halfExtentsZ;

		_aabbPointsDirty = true;
	}
}