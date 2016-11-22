package away3d.core.pick;

import away3d.core.base.*;

import openfl.geom.*;

/**
 * Auto-selecting picking collider for entity objects. Used with the <code>RaycastPicker</code> picking object.
 * Chooses between pure AS3 picking and PixelBender picking based on a threshold property representing
 * the number of triangles encountered in a <code>SubMesh</code> object over which PixelBender is used.
 *
 * @see away3d.entities.Entity#pickingCollider
 * @see away3d.core.pick.RaycastPicker
 */
class AutoPickingCollider implements IPickingCollider
{
	private var _pbPickingCollider:PBPickingCollider;
	private var _haxePickingCollider:HaxePickingCollider;
	private var _activePickingCollider:IPickingCollider;
	
	/**
	 * Represents the number of triangles encountered in a <code>SubMesh</code> object over which PixelBender is used.
	 */
	public var triangleThreshold:Int = 1024;
	
	/**
	 * Creates a new <code>AutoPickingCollider</code> object.
	 *
	 * @param findClosestCollision Determines whether the picking collider searches for the closest collision along the ray. Defaults to false.
	 */
	public function new(findClosestCollision:Bool = false)
	{
		_haxePickingCollider = new HaxePickingCollider(findClosestCollision);
		//_pbPickingCollider = new PBPickingCollider(findClosestCollision);
	}
	
	/**
	 * @inheritDoc
	 */
	public function setLocalRay(localPosition:Vector3D, localDirection:Vector3D):Void
	{
		_haxePickingCollider.setLocalRay(localPosition, localDirection);
		//_pbPickingCollider.setLocalRay(localPosition, localDirection);
	}
	
	/**
	 * @inheritDoc
	 */
	public function testSubMeshCollision(subMesh:SubMesh, pickingCollisionVO:PickingCollisionVO, shortestCollisionDistance:Float):Bool
	{
		_activePickingCollider = _haxePickingCollider;
		//_activePickingCollider = (subMesh.numTriangles > triangleThreshold)? _pbPickingCollider : _haxePickingCollider;
		return _activePickingCollider.testSubMeshCollision(subMesh, pickingCollisionVO, shortestCollisionDistance);
	}
}