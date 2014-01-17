/**
 * Options for setting a picking collider for entity objects. Used with the <code>RaycastPicker</code> picking object.
 *
 * @see away3d.entities.Entity#pickingCollider
 * @see away3d.core.pick.RaycastPicker
 */
package away3d.core.pick;

class PickingColliderType {

/**
	 * Default null collider that forces picker to only use entity bounds for hit calculations on an Entity
	 */
    static public var BOUNDS_ONLY:IPickingCollider = null;
/**
	 * Pure AS3 picking collider that returns the first encountered hit on an Entity. Useful for low poly meshes and applying to many mesh instances.
	 *
	 * @see away3d.core.pick.AS3PickingCollider
	 */
    static public var AS3_FIRST_ENCOUNTERED:IPickingCollider = new AS3PickingCollider(false);
/**
	 * Pure AS3 picking collider that returns the best (closest) hit on an Entity. Useful for low poly meshes and applying to many mesh instances.
	 *
	 * @see away3d.core.pick.AS3PickingCollider
	 */
    static public var AS3_BEST_HIT:IPickingCollider = new AS3PickingCollider(true);

/**
	 * Auto-selecting picking collider that returns the first encountered hit on an Entity.
	 * Chooses between pure AS3 picking and PixelBender picking based on a threshold property representing
	 * the number of triangles encountered in a <code>SubMesh</code> object over which PixelBender is used.
	 * Useful for picking meshes with a mixture of polycounts.
	 *
	 * @see away3d.core.pick.AutoPickingCollider
	 * @see away3d.core.pick.AutoPickingCollider#triangleThreshold
	 */
    static public var AUTO_FIRST_ENCOUNTERED:IPickingCollider = new AutoPickingCollider(false);
/**
	 * Auto-selecting picking collider that returns the best (closest) hit on an Entity
	 * Chooses between pure AS3 picking and PixelBender picking based on a threshold property representing
	 * the number of triangles encountered in a <code>SubMesh</code> object over which PixelBender is used.
	 * Useful for picking meshes with a mixture of polycounts.
	 *
	 * @see away3d.core.pick.AutoPickingCollider
	 * @see away3d.core.pick.AutoPickingCollider#triangleThreshold
	 */
    static public var AUTO_BEST_HIT:IPickingCollider = new AutoPickingCollider(true);
}

