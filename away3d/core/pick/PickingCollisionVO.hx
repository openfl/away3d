package away3d.core.pick;

import away3d.core.base.IRenderable;
import away3d.entities.Entity;

import openfl.geom.Point;
import openfl.geom.Vector3D;

/**
 * Value object for a picking collision returned by a picking collider. Created as unique objects on entities
 *
 * @see away3d.entities.Entity#pickingCollisionVO
 * @see away3d.core.pick.IPickingCollider
 */
class PickingCollisionVO
{
	/**
	 * The entity to which this collision object belongs.
	 */
	public var entity:Entity;
	
	/**
	 * The local position of the collision on the entity's surface.
	 */
	public var localPosition:Vector3D;
	
	/**
	 * The local normal vector at the position of the collision.
	 */
	public var localNormal:Vector3D;
	
	/**
	 * The uv coordinate at the position of the collision.
	 */
	public var uv:Point;
	
	/**
	 * The index of the face where the event took pl ace.
	 */
	public var index:Int;
	
	/**
	 * The index of the subGeometry where the event took place.
	 */
	public var subGeometryIndex:Int;
	
	/**
	 * The starting position of the colliding ray in local coordinates.
	 */
	public var localRayPosition:Vector3D;
	
	/**
	 * The direction of the colliding ray in local coordinates.
	 */
	public var localRayDirection:Vector3D;
	
	/**
	 * The starting position of the colliding ray in scene coordinates.
	 */
	public var rayPosition:Vector3D;
	
	/**
	 * The direction of the colliding ray in scene coordinates.
	 */
	public var rayDirection:Vector3D;
	
	/**
	 * Determines if the ray position is contained within the entity bounds.
	 *
	 * @see away3d.entities.Entity#bounds
	 */
	public var rayOriginIsInsideBounds:Bool;
	
	/**
	 * The distance along the ray from the starting position to the calculated intersection entry point with the entity.
	 */
	public var rayEntryDistance:Float;
	
	/**
	 * The IRenderable associated with a collision.
	 */
	public var renderable:IRenderable;
	
	/**
	 * Creates a new <code>PickingCollisionVO</code> object.
	 *
	 * @param entity The entity to which this collision object belongs.
	 */
	public function new(entity:Entity)
	{
		this.entity = entity;
	}
}