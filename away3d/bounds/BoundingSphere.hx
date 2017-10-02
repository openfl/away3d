package away3d.bounds;

import away3d.core.math.*;
import away3d.primitives.*;

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * BoundingSphere represents a spherical bounding volume defined by a center point and a radius.
 * This bounding volume is useful for point lights.
 */
class BoundingSphere extends BoundingVolumeBase
{
	public var radius(get, never):Float;
	
	private var _radius:Float = 0;
	private var _centerX:Float = 0;
	private var _centerY:Float = 0;
	private var _centerZ:Float = 0;
	
	/**
	 * The radius of the bounding sphere, calculated from the contents of the entity.
	 */
	private function get_radius():Float
	{
		return _radius;
	}
	
	/**
	 * Creates a new <code>BoundingSphere</code> object
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
		_radius = 0;
	}
	
	/**
	 * todo: pass planes?
	 * @inheritDoc
	 */
	override public function isInFrustum(planes:Vector<Plane3D>, numPlanes:Int):Bool
	{
		for (i in 0...numPlanes) {
			var plane:Plane3D = planes[i];
			var flippedExtentX:Float = plane.a < 0? -_radius : _radius;
			var flippedExtentY:Float = plane.b < 0? -_radius : _radius;
			var flippedExtentZ:Float = plane.c < 0? -_radius : _radius;
			var projDist:Float = plane.a*(_centerX + flippedExtentX) + plane.b*(_centerY + flippedExtentY) + plane.c*(_centerZ + flippedExtentZ) - plane.d;
			if (projDist < 0)
				return false;
		}
		
		return true;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function fromSphere(center:Vector3D, radius:Float):Void
	{
		_centerX = center.x;
		_centerY = center.y;
		_centerZ = center.z;
		_radius = radius;
		_max.x = _centerX + radius;
		_max.y = _centerY + radius;
		_max.z = _centerZ + radius;
		_min.x = _centerX - radius;
		_min.y = _centerY - radius;
		_min.z = _centerZ - radius;
		_aabbPointsDirty = true;
		if (_boundingRenderable != null)
			updateBoundingRenderable();
	}
	
	// TODO: fromGeometry can probably be updated a lot
	// find center from extremes, but radius from actual furthest distance from center
	
	/**
	 * @inheritDoc
	 */
	override public function fromExtremes(minX:Float, minY:Float, minZ:Float, maxX:Float, maxY:Float, maxZ:Float):Void
	{
		_centerX = (maxX + minX)*.5;
		_centerY = (maxY + minY)*.5;
		_centerZ = (maxZ + minZ)*.5;
		
		var d:Float = maxX - minX;
		var y:Float = maxY - minY;
		var z:Float = maxZ - minZ;
		if (y > d)
			d = y;
		if (z > d)
			d = z;
		
		_radius = d*Math.sqrt(.5);
		super.fromExtremes(minX, minY, minZ, maxX, maxY, maxZ);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function clone():BoundingVolumeBase
	{
		var clone:BoundingSphere = new BoundingSphere();
		clone.fromSphere(new Vector3D(_centerX, _centerY, _centerZ), _radius);
		return clone;
	}
	
	override public function rayIntersection(position:Vector3D, direction:Vector3D, targetNormal:Vector3D):Float
	{
		if (containsPoint(position))
			return 0;
		
		var px:Float = position.x - _centerX, py:Float = position.y - _centerY, pz:Float = position.z - _centerZ;
		var vx:Float = direction.x, vy:Float = direction.y, vz:Float = direction.z;
		var rayEntryDistance:Float;
		
		var a:Float = vx*vx + vy*vy + vz*vz;
		var b:Float = 2*( px*vx + py*vy + pz*vz );
		var c:Float = px*px + py*py + pz*pz - _radius*_radius;
		var det:Float = b*b - 4*a*c;
		
		if (det >= 0) { // ray goes through sphere
			var sqrtDet:Float = Math.sqrt(det);
			rayEntryDistance = ( -b - sqrtDet )/( 2*a );
			if (rayEntryDistance >= 0) {
				targetNormal.x = px + rayEntryDistance*vx;
				targetNormal.y = py + rayEntryDistance*vy;
				targetNormal.z = pz + rayEntryDistance*vz;
				targetNormal.normalize();
				
				return rayEntryDistance;
			}
		}
		
		// ray misses sphere
		return -1;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function containsPoint(position:Vector3D):Bool
	{
		var px:Float = position.x - _centerX, py:Float = position.y - _centerY, pz:Float = position.z - _centerZ;
		var distance:Float = Math.sqrt(px*px + py*py + pz*pz);
		return distance <= _radius;
	}
	
	override private function updateBoundingRenderable():Void
	{
		var sc:Float = _radius;
		if (sc == 0)
			sc = 0.001;
		_boundingRenderable.scaleX = sc;
		_boundingRenderable.scaleY = sc;
		_boundingRenderable.scaleZ = sc;
		_boundingRenderable.x = _centerX;
		_boundingRenderable.y = _centerY;
		_boundingRenderable.z = _centerZ;
	}
	
	override private function createBoundingRenderable():WireframePrimitiveBase
	{
		return new WireframeSphere(1, 16, 12, 0xffffff, 0.5);
	}
	
	override public function classifyToPlane(plane:Plane3D):Int
	{
		var a:Float = plane.a;
		var b:Float = plane.b;
		var c:Float = plane.c;
		var dd:Float = a*_centerX + b*_centerY + c*_centerZ - plane.d;
		if (a < 0)
			a = -a;
		if (b < 0)
			b = -b;
		if (c < 0)
			c = -c;
		var rr:Float = (a + b + c)*_radius;
		
		return dd > rr? PlaneClassification.FRONT :
			dd < -rr? PlaneClassification.BACK :
			PlaneClassification.INTERSECT;
	}
	
	override public function transformFrom(bounds:BoundingVolumeBase, matrix:Matrix3D):Void
	{
		var sphere:BoundingSphere = cast(bounds, BoundingSphere);
		var cx:Float = sphere._centerX;
		var cy:Float = sphere._centerY;
		var cz:Float = sphere._centerZ;
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
		var r:Float = sphere._radius;
		var rx:Float = m11 + m12 + m13;
		var ry:Float = m21 + m22 + m23;
		var rz:Float = m31 + m32 + m33;
		_radius = r*Math.sqrt(rx*rx + ry*ry + rz*rz);
		
		_min.x = _centerX - _radius;
		_min.y = _centerY - _radius;
		_min.z = _centerZ - _radius;
		
		_max.x = _centerX + _radius;
		_max.y = _centerY + _radius;
		_max.z = _centerZ + _radius;
	}
}