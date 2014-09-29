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
	 * Picking collider that returns the first encountered hit on an Entity. Useful for low poly meshes and applying to many mesh instances.
	 *
	 * @see away3d.core.pick.PickingCollider
	 */
    static public var FIRST_ENCOUNTERED:IPickingCollider = new PickingCollider(false);
    
    /**
	 * Picking collider that returns the best (closest) hit on an Entity. Useful for low poly meshes and applying to many mesh instances.
	 *
	 * @see away3d.core.pick.PickingCollider
	 */
    static public var BEST_HIT:IPickingCollider = new PickingCollider(true);
}

