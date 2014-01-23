/**
 * Auto-selecting picking collider for entity objects. Used with the <code>RaycastPicker</code> picking object.
 * Chooses between pure AS3 picking and PixelBender picking based on a threshold property representing
 * the number of triangles encountered in a <code>SubMesh</code> object over which PixelBender is used.
 *
 * @see away3d.entities.Entity#pickingCollider
 * @see away3d.core.pick.RaycastPicker
 */
package away3d.core.pick;


import away3d.core.base.SubMesh;
import flash.geom.Vector3D;
class AutoPickingCollider implements IPickingCollider {

    private var _as3PickingCollider:AS3PickingCollider;
    private var _activePickingCollider:IPickingCollider;
/**
	 * Represents the number of triangles encountered in a <code>SubMesh</code> object over which PixelBender is used.
	 */
    public var triangleThreshold:Int;
/**
	 * Creates a new <code>AutoPickingCollider</code> object.
	 *
	 * @param findClosestCollision Determines whether the picking collider searches for the closest collision along the ray. Defaults to false.
	 */

    public function new(findClosestCollision:Bool = false) {
        triangleThreshold = 1024;
        _as3PickingCollider = new AS3PickingCollider(findClosestCollision);

    }

/**
	 * @inheritDoc
	 */

    public function setLocalRay(localPosition:Vector3D, localDirection:Vector3D):Void {
        _as3PickingCollider.setLocalRay(localPosition, localDirection);

    }

/**
	 * @inheritDoc
	 */

    public function testSubMeshCollision(subMesh:SubMesh, pickingCollisionVO:PickingCollisionVO, shortestCollisionDistance:Float):Bool {
        _activePickingCollider = _as3PickingCollider;
        return _activePickingCollider.testSubMeshCollision(subMesh, pickingCollisionVO, shortestCollisionDistance);
    }

}

