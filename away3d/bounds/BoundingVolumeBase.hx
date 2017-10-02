package away3d.bounds;

import away3d.core.base.*;
import away3d.core.math.Plane3D;
import away3d.errors.*;
import away3d.primitives.*;

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * An abstract base class for all bounding volume classes. It should not be instantiated directly.
 */
class BoundingVolumeBase
{
	public var max(get, never):Vector3D;
	public var min(get, never):Vector3D;
	public var aabbPoints(get, never):Vector<Float>;
	public var boundingRenderable(get, never):WireframePrimitiveBase;
	
	private var _min:Vector3D;
	private var _max:Vector3D;
	private var _aabbPoints:Vector<Float> = new Vector<Float>();
	private var _aabbPointsDirty:Bool = true;
	private var _boundingRenderable:WireframePrimitiveBase;
	
	/**
	 * The maximum extreme of the bounds
	 */
	private function get_max():Vector3D
	{
		return _max;
	}
	
	/**
	 * The minimum extreme of the bounds
	 */
	private function get_min():Vector3D
	{
		return _min;
	}
	
	/**
	 * Returns a vector of values representing the concatenated cartesian triplet of the 8 axial extremities of the bounding volume.
	 */
	private function get_aabbPoints():Vector<Float>
	{
		if (_aabbPointsDirty)
			updateAABBPoints();
		
		return _aabbPoints;
	}
	
	/**
	 * Returns the bounding renderable object for the bounding volume, in cases where the showBounds
	 * property of the entity is set to true.
	 *
	 * @see away3d.entities.Entity#showBounds
	 */
	private function get_boundingRenderable():WireframePrimitiveBase
	{
		if (_boundingRenderable == null) {
			_boundingRenderable = createBoundingRenderable();
			updateBoundingRenderable();
		}
		
		return _boundingRenderable;
	}
	
	/**
	 * Creates a new <code>BoundingVolumeBase</code> object
	 */
	public function new()
	{
		_min = new Vector3D();
		_max = new Vector3D();
	}
	
	/**
	 * Sets the bounds to zero size.
	 */
	public function nullify():Void
	{
		_min.x = _min.y = _min.z = 0;
		_max.x = _max.y = _max.z = 0;
		_aabbPointsDirty = true;
		if (_boundingRenderable != null)
			updateBoundingRenderable();
	}
	
	/**
	 * Disposes of the bounds renderable object. Used to clear memory after a bounds rendeable is no longer required.
	 */
	public function disposeRenderable():Void
	{
		if (_boundingRenderable != null)
			_boundingRenderable.dispose();
		_boundingRenderable = null;
	}
	
	/**
	 * Updates the bounds to fit a list of vertices
	 *
	 * @param vertices A Vector.&lt;Number&gt; of vertex data to be bounded.
	 */
	public function fromVertices(vertices:Vector<Float>):Void
	{
		var i:Int = 0;
		var len:Int = vertices.length;
		var minX:Float, minY:Float, minZ:Float;
		var maxX:Float, maxY:Float, maxZ:Float;
		
		if (len == 0) {
			nullify();
			return;
		}
		
		var v:Float;
		
		minX = maxX = vertices[(i++)];
		minY = maxY = vertices[(i++)];
		minZ = maxZ = vertices[(i++)];
		
		while (i < len) {
			v = vertices[i++];
			if (v < minX)
				minX = v;
			else if (v > maxX)
				maxX = v;
			v = vertices[i++];
			if (v < minY)
				minY = v;
			else if (v > maxY)
				maxY = v;
			v = vertices[i++];
			if (v < minZ)
				minZ = v;
			else if (v > maxZ)
				maxZ = v;
		}
		
		fromExtremes(minX, minY, minZ, maxX, maxY, maxZ);
	}
	
	/**
	 * Updates the bounds to fit a Geometry object.
	 *
	 * @param geometry The Geometry object to be bounded.
	 */
	public function fromGeometry(geometry:Geometry):Void
	{ 
		var subGeoms:Vector<ISubGeometry> = geometry.subGeometries;
		var numSubGeoms:Int = subGeoms.length;
		var minX:Float, minY:Float, minZ:Float;
		var maxX:Float, maxY:Float, maxZ:Float;
		
		if (numSubGeoms > 0) {
			var subGeom:ISubGeometry = subGeoms[0];
			var vertices:Vector<Float> = subGeom.vertexData;
			var i:Int = subGeom.vertexOffset;
			minX = maxX = vertices[i];
			minY = maxY = vertices[i + 1];
			minZ = maxZ = vertices[i + 2];
			
			var j:Int = 0;
			while (j < numSubGeoms) {
				subGeom = subGeoms[j++];
				vertices = subGeom.vertexData;
				var vertexDataLen:Int = vertices.length;
				i = subGeom.vertexOffset;
				var stride:Int = subGeom.vertexStride;
				
				while (i < vertexDataLen) {
					var v:Float = vertices[i];
					if (v < minX)
						minX = v;
					else if (v > maxX)
						maxX = v;
					v = vertices[i + 1];
					if (v < minY)
						minY = v;
					else if (v > maxY)
						maxY = v;
					v = vertices[i + 2];
					if (v < minZ)
						minZ = v;
					else if (v > maxZ)
						maxZ = v;
					i += stride;
				}
			}
			
			fromExtremes(minX, minY, minZ, maxX, maxY, maxZ);
		} else
			fromExtremes(0, 0, 0, 0, 0, 0);
	}
	
	/**
	 * Sets the bound to fit a given sphere.
	 *
	 * @param center The center of the sphere to be bounded
	 * @param radius The radius of the sphere to be bounded
	 */
	public function fromSphere(center:Vector3D, radius:Float):Void
	{
		// this is BETTER overridden, because most volumes will have shortcuts for this
		// but then again, sphere already overrides it, and if we'd call "fromSphere", it'd probably need a sphere bound anyway
		fromExtremes(center.x - radius, center.y - radius, center.z - radius, center.x + radius, center.y + radius, center.z + radius);
	}
	
	/**
	 * Sets the bounds to the given extrema.
	 *
	 * @param minX The minimum x value of the bounds
	 * @param minY The minimum y value of the bounds
	 * @param minZ The minimum z value of the bounds
	 * @param maxX The maximum x value of the bounds
	 * @param maxY The maximum y value of the bounds
	 * @param maxZ The maximum z value of the bounds
	 */
	public function fromExtremes(minX:Float, minY:Float, minZ:Float, maxX:Float, maxY:Float, maxZ:Float):Void
	{
		_min.x = minX;
		_min.y = minY;
		_min.z = minZ;
		_max.x = maxX;
		_max.y = maxY;
		_max.z = maxZ;
		_aabbPointsDirty = true;
		if (_boundingRenderable != null)
			updateBoundingRenderable();
	}
	
	/**
	 * Tests if the bounds are in the camera frustum.
	 *
	 * @param mvpMatrix The model view projection matrix for the object to which this bounding box belongs.
	 * @return True if the bounding box is at least partially inside the frustum
	 */
	public function isInFrustum(planes:Vector<Plane3D>, numPlanes:Int):Bool
	{
		throw new AbstractMethodError();
		return false;
	}
	
	/**
	 * Tests if the bounds overlap other bounds, treating both bounds as AABBs.
	 */
	public function overlaps(bounds:BoundingVolumeBase):Bool
	{
		var min:Vector3D = bounds._min;
		var max:Vector3D = bounds._max;
		return _max.x > min.x &&
			_min.x < max.x &&
			_max.y > min.y &&
			_min.y < max.y &&
			_max.z > min.z &&
			_min.z < max.z;
	}
	
	/*public function classifyAgainstPlane(plane : Plane3D) : int
	 {
	 throw new AbstractMethodError();
	 return -1;
	 }*/
	
	/**
	 * Clones the current BoundingVolume object
	 * @return An exact duplicate of this object
	 */
	public function clone():BoundingVolumeBase
	{
		throw new AbstractMethodError();
		return null;
	}
	
	/**
	 * Method for calculating whether an intersection of the given ray occurs with the bounding volume.
	 *
	 * @param position The starting position of the casting ray in local coordinates.
	 * @param direction A unit vector representing the direction of the casting ray in local coordinates.
	 * @param targetNormal The vector to store the bounds' normal at the point of collision
	 * @return A Boolean value representing the detection of an intersection.
	 */
	public function rayIntersection(position:Vector3D, direction:Vector3D, targetNormal:Vector3D):Float
	{
		return -1;
	}
	
	/**
	 * Method for calculating whether the given position is contained within the bounding volume.
	 *
	 * @param position The position in local coordinates to be checked.
	 * @return A Boolean value representing the detection of a contained position.
	 */
	public function containsPoint(position:Vector3D):Bool
	{
		return false;
	}
	
	private function updateAABBPoints():Void
	{
		var maxX:Float = _max.x, maxY:Float = _max.y, maxZ:Float = _max.z;
		var minX:Float = _min.x, minY:Float = _min.y, minZ:Float = _min.z;
		_aabbPoints[0] = minX;
		_aabbPoints[1] = minY;
		_aabbPoints[2] = minZ;
		_aabbPoints[3] = maxX;
		_aabbPoints[4] = minY;
		_aabbPoints[5] = minZ;
		_aabbPoints[6] = minX;
		_aabbPoints[7] = maxY;
		_aabbPoints[8] = minZ;
		_aabbPoints[9] = maxX;
		_aabbPoints[10] = maxY;
		_aabbPoints[11] = minZ;
		_aabbPoints[12] = minX;
		_aabbPoints[13] = minY;
		_aabbPoints[14] = maxZ;
		_aabbPoints[15] = maxX;
		_aabbPoints[16] = minY;
		_aabbPoints[17] = maxZ;
		_aabbPoints[18] = minX;
		_aabbPoints[19] = maxY;
		_aabbPoints[20] = maxZ;
		_aabbPoints[21] = maxX;
		_aabbPoints[22] = maxY;
		_aabbPoints[23] = maxZ;
		_aabbPointsDirty = false;
	}
	
	private function updateBoundingRenderable():Void
	{
		throw new AbstractMethodError();
	}
	
	private function createBoundingRenderable():WireframePrimitiveBase
	{
		throw new AbstractMethodError();
		return null;
	}
	
	public function classifyToPlane(plane:Plane3D):Int
	{
		throw new AbstractMethodError();
		return 0;
	}
	
	public function transformFrom(bounds:BoundingVolumeBase, matrix:Matrix3D):Void
	{
		throw new AbstractMethodError();
	}
}