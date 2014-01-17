/**
 * Provides an interface for picking colliders that can be assigned to individual entities in a scene for specific picking behaviour.
 * Used with the <code>RaycastPicker</code> picking object.
 *
 * @see away3d.entities.Entity#pickingCollider
 * @see away3d.core.pick.RaycastPicker
 */
package away3d.core.pick;

import away3d.core.base.SubMesh;
import flash.geom.Vector3D;

interface IPickingCollider {

/**
	 * Sets the position and direction of a picking ray in local coordinates to the entity.
	 *
	 * @param localDirection The position vector in local coordinates
	 * @param localPosition The direction vector in local coordinates
	 */
    function setLocalRay(localPosition:Vector3D, localDirection:Vector3D):Void;
    function testSubMeshCollision(subMesh:SubMesh, pickingCollisionVO:PickingCollisionVO, shortestCollisionDistance:Float):Bool;
}

