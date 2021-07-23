package away3d.entities;

import away3d.bounds.*;
import away3d.containers.*;
import away3d.core.math.Matrix3DUtils;
import away3d.core.partition.*;
import away3d.core.pick.*;
import away3d.errors.*;
import away3d.library.assets.*;

import openfl.geom.Vector3D;

/**
 * The Entity class provides an abstract base class for all scene graph objects that are considered having a
 * "presence" in the scene, in the sense that it can be considered an actual object with a position and a size (even
 * if infinite or idealised), rather than a grouping.
 * Entities can be partitioned in a space partitioning system and in turn collected by an EntityCollector.
 *
 * @see away3d.partition.Partition3D
 * @see away3d.core.traverse.EntityCollector
 */
class Entity extends ObjectContainer3D
{
	public var shaderPickingDetails(get, set):Bool;
	public var staticNode(get, set):Bool;
	public var pickingCollisionVO(get, never):PickingCollisionVO;
	public var showBounds(get, set):Bool;
	public var bounds(get, set):BoundingVolumeBase;
	public var worldBounds(get, never):BoundingVolumeBase;
	public var pickingCollider(get, set):IPickingCollider;
	
	private var _showBounds:Bool;
	private var _partitionNode:EntityNode;
	private var _boundsIsShown:Bool = false;
	private var _shaderPickingDetails:Bool;
	
	@:allow(away3d) private var _pickingCollisionVO:PickingCollisionVO;
	@:allow(away3d) private var _pickingCollider:IPickingCollider;
	@:allow(away3d) private var _staticNode:Bool;
	
	private var _bounds:BoundingVolumeBase;
	private var _boundsInvalid:Bool = true;
	private var _worldBounds:BoundingVolumeBase;
	private var _worldBoundsInvalid:Bool = true;

	override private function set_ignoreTransform(value:Bool):Bool
	{
		if (_scene != null)
			_scene.invalidateEntityBounds(this);
		super.ignoreTransform = value;
		return value;
	}
	
	/**
	 * Used by the shader-based picking system to determine whether a separate render pass is made in order
	 * to offer more details for the picking collision object, including local position, normal vector and uv value.
	 * Defaults to false.
	 *
	 * @see away3d.core.pick.ShaderPicker
	 */
	private function get_shaderPickingDetails():Bool
	{
		return _shaderPickingDetails;
	}
	
	private function set_shaderPickingDetails(value:Bool):Bool
	{
		_shaderPickingDetails = value;
		return value;
	}
	
	/**
	 * Defines whether or not the object will be moved or animated at runtime. This property is used by some partitioning systems to improve performance.
	 * Warning: if set to true, they may not be processed by certain partition systems using static visibility lists, unless they're specifically assigned to the visibility list.
	 */
	private function get_staticNode():Bool
	{
		return _staticNode;
	}
	
	private function set_staticNode(value:Bool):Bool
	{
		_staticNode = value;
		return value;
	}
	
	/**
	 * Returns a unique picking collision value object for the entity.
	 */
	private function get_pickingCollisionVO():PickingCollisionVO
	{
		if (_pickingCollisionVO == null)
			_pickingCollisionVO = new PickingCollisionVO(this);
		
		return _pickingCollisionVO;
	}
	
	/**
	 * Tests if a collision occurs before shortestCollisionDistance, using the data stored in PickingCollisionVO.
	 * @param shortestCollisionDistance
	 * @return
	 */
	@:allow(away3d) private function collidesBefore(shortestCollisionDistance:Float, findClosest:Bool):Bool
	{
		return true;
	}
	
	/**
	 *
	 */
	private function get_showBounds():Bool
	{
		return _showBounds;
	}
	
	private function set_showBounds(value:Bool):Bool
	{
		if (value == _showBounds)
			return value;
		
		_showBounds = value;
		
		if (_showBounds)
			addBounds();
		else
			removeBounds();
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function get_minX():Float
	{
		if (_boundsInvalid)
			updateBounds();
		
		return _bounds.min.x;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function get_minY():Float
	{
		if (_boundsInvalid)
			updateBounds();
		
		return _bounds.min.y;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function get_minZ():Float
	{
		if (_boundsInvalid)
			updateBounds();
		
		return _bounds.min.z;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function get_maxX():Float
	{
		if (_boundsInvalid)
			updateBounds();
		
		return _bounds.max.x;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function get_maxY():Float
	{
		if (_boundsInvalid)
			updateBounds();
		
		return _bounds.max.y;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function get_maxZ():Float
	{
		if (_boundsInvalid)
			updateBounds();
		
		return _bounds.max.z;
	}
	
	/**
	 * The bounding volume approximating the volume occupied by the Entity.
	 */
	private function get_bounds():BoundingVolumeBase
	{
		if (_boundsInvalid)
			updateBounds();
		
		return _bounds;
	}
	
	private function set_bounds(value:BoundingVolumeBase):BoundingVolumeBase
	{
		removeBounds();
		_bounds = value;
		_worldBounds = value.clone();
		invalidateBounds();
		if (_showBounds)
			addBounds();
		return value;
	}
	
	private function get_worldBounds():BoundingVolumeBase
	{
		if (_worldBoundsInvalid)
			updateWorldBounds();
		
		return _worldBounds;
	}
	
	private function updateWorldBounds():Void
	{
		_worldBounds.transformFrom(bounds, sceneTransform);
		_worldBoundsInvalid = false;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function set_implicitPartition(value:Partition3D):Partition3D
	{
		if (value == _implicitPartition)
			return value;
		
		if (_implicitPartition != null)
			notifyPartitionUnassigned();
		
		super.implicitPartition = value;
		
		notifyPartitionAssigned();
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function set_scene(value:Scene3D):Scene3D
	{
		if (value == _scene)
			return value;
		
		if (_scene != null)
			_scene.unregisterEntity(this);
		
		// callback to notify object has been spawned. Casts to please FDT
		if (value != null)
			value.registerEntity(this);
		
		super.scene = value;
		return value;
	}
	
	override private function get_assetType():String
	{
		return Asset3DType.ENTITY;
	}
	
	/**
	 * Used by the raycast-based picking system to determine how the geometric contents of an entity are processed
	 * in order to offer more details for the picking collision object, including local position, normal vector and uv value.
	 * Defaults to null.
	 *
	 * @see away3d.core.pick.RaycastPicker
	 */
	private function get_pickingCollider():IPickingCollider
	{
		return _pickingCollider;
	}
	
	private function set_pickingCollider(value:IPickingCollider):IPickingCollider
	{
		_pickingCollider = value;
		return value;
	}
	
	/**
	 * Creates a new Entity object.
	 */
	public function new()
	{
		super();
		
		_bounds = getDefaultBoundingVolume();
		_worldBounds = getDefaultBoundingVolume();
	}
	
	/**
	 * Gets a concrete EntityPartition3DNode subclass that is associated with this Entity instance
	 */
	public function getEntityPartitionNode():EntityNode
	{
		if (_partitionNode == null) 
			_partitionNode = createEntityPartitionNode();
		
		return _partitionNode;
	}

	public function isIntersectingRay(rayPosition:Vector3D, rayDirection:Vector3D):Bool
	{
		if (pickingCollisionVO.localRayPosition == null) pickingCollisionVO.localRayPosition = new Vector3D();
		if (pickingCollisionVO.localRayDirection == null) pickingCollisionVO.localRayDirection = new Vector3D();
		if (pickingCollisionVO.localNormal == null) pickingCollisionVO.localNormal = new Vector3D();

		// convert ray to entity space
		var localRayPosition:Vector3D = pickingCollisionVO.localRayPosition;
		var localRayDirection:Vector3D = pickingCollisionVO.localRayDirection;
		Matrix3DUtils.transformVector(inverseSceneTransform, rayPosition, localRayPosition);
		Matrix3DUtils.deltaTransformVector(inverseSceneTransform, rayDirection, localRayDirection);

		// check for ray-bounds collision
		var rayEntryDistance:Float = bounds.rayIntersection(localRayPosition, localRayDirection, pickingCollisionVO.localNormal);
		if (rayEntryDistance < 0)
			return false;
		
		// Store collision data.
		pickingCollisionVO.rayEntryDistance = rayEntryDistance;
		pickingCollisionVO.rayPosition = rayPosition;
		pickingCollisionVO.rayDirection = rayDirection;
		pickingCollisionVO.rayOriginIsInsideBounds = rayEntryDistance == 0;
		
		return true;
	}
	
	/**
	 * Factory method that returns the current partition node. Needs to be overridden by concrete subclasses
	 * such as Mesh to return the correct concrete subtype of EntityPartition3DNode (for Mesh = MeshPartition3DNode,
	 * most IRenderables (particles fe) would return RenderablePartition3DNode, I suppose)
	 */
	private function createEntityPartitionNode():EntityNode
	{
		throw new AbstractMethodError();
		return null;
	}
	
	/**
	 * Creates the default bounding box to be used by this type of Entity.
	 * @return
	 */
	private function getDefaultBoundingVolume():BoundingVolumeBase
	{
		// point lights should be using sphere bounds
		// directional lights should be using null bounds
		return new AxisAlignedBoundingBox();
	}
	
	/**
	 * Updates the bounding volume for the object. Overriding methods need to set invalid flag to false!
	 */
	private function updateBounds():Void
	{
		throw new AbstractMethodError();
	}
	
	/**
	 * @inheritDoc
	 */
	override private function invalidateSceneTransform():Void
	{
		if (!_ignoreTransform) {
			super.invalidateSceneTransform();
			_worldBoundsInvalid = true;
			notifySceneBoundsInvalid();
		}
	}
	
	/**
	 * Invalidates the bounding volume, causing to be updated when requested.
	 */
	private function invalidateBounds():Void
	{
		_boundsInvalid = true;
		_worldBoundsInvalid = true;
		notifySceneBoundsInvalid();
	}
	
	override private function updateMouseChildren():Void
	{
		// If there is a parent and this child does not have a triangle collider, use its parent's triangle collider.
		if (_parent == null && pickingCollider != null) {
			if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(_parent, Entity)) {
				var collider:IPickingCollider = cast(_parent, Entity).pickingCollider;
				if (collider != null)
					pickingCollider = collider;
			}
		}
		
		super.updateMouseChildren();
	}
	
	/**
	 * Notify the scene that the global scene bounds have changed, so it can be repartitioned.
	 */
	private function notifySceneBoundsInvalid():Void
	{
		if (_scene != null)
			_scene.invalidateEntityBounds(this);
	}
	
	/**
	 * Notify the scene that a new partition was assigned.
	 */
	private function notifyPartitionAssigned():Void
	{
		if (_scene != null)
			_scene.registerPartition(this); //_onAssignPartitionCallback(this);
	}
	
	/**
	 * Notify the scene that a partition was unassigned.
	 */
	private function notifyPartitionUnassigned():Void
	{
		if (_scene != null)
			_scene.unregisterPartition(this);
	}
	
	private function addBounds():Void
	{
		if (!_boundsIsShown) {
			_boundsIsShown = true;
			addChild(_bounds.boundingRenderable);
		}
	}
	
	private function removeBounds():Void
	{
		if (_boundsIsShown) {
			_boundsIsShown = false;
			removeChild(_bounds.boundingRenderable);
			_bounds.disposeRenderable();
		}
	}
	
	public function internalUpdate():Void
	{
		if (_controller != null)
			_controller.update();
	}
}