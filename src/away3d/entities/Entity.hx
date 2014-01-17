/**
 * The Entity class provides an abstract base class for all scene graph objects that are considered having a
 * "presence" in the scene, in the sense that it can be considered an actual object with a position and a size (even
 * if infinite or idealised), rather than a grouping.
 * Entities can be partitioned in a space partitioning system and in turn collected by an EntityCollector.
 *
 * @see away3d.partition.Partition3D
 * @see away3d.core.traverse.EntityCollector
 */
package away3d.entities;

import away3d.bounds.AxisAlignedBoundingBox;
import away3d.errors.AbstractMethodError;
import flash.geom.Vector3D;
import away3d.library.assets.AssetType;
import away3d.core.partition.Partition3D;
import away3d.containers.Scene3D;
import away3d.containers.ObjectContainer3D;
import away3d.core.partition.EntityNode;
import away3d.core.pick.PickingCollisionVO;
import away3d.core.pick.IPickingCollider;
import away3d.bounds.BoundingVolumeBase;
class Entity extends ObjectContainer3D {
    public var shaderPickingDetails(get_shaderPickingDetails, set_shaderPickingDetails):Bool;
    public var staticNode(get_staticNode, set_staticNode):Bool;
    public var pickingCollisionVO(get_pickingCollisionVO, never):PickingCollisionVO;
    public var showBounds(get_showBounds, set_showBounds):Bool;
    public var bounds(get_bounds, set_bounds):BoundingVolumeBase;
    public var worldBounds(get_worldBounds, never):BoundingVolumeBase;
    public var pickingCollider(get_pickingCollider, set_pickingCollider):IPickingCollider;

    private var _showBounds:Bool;
    private var _partitionNode:EntityNode;
    private var _boundsIsShown:Bool;
    private var _shaderPickingDetails:Bool;
    public var _pickingCollisionVO:PickingCollisionVO;
    private var _pickingCollider:IPickingCollider;
    private var _staticNode:Bool;
    private var _bounds:BoundingVolumeBase;
    private var _boundsInvalid:Bool;
    private var _worldBounds:BoundingVolumeBase;
    private var _worldBoundsInvalid:Bool;

    override public function set_ignoreTransform(value:Bool):Bool {
        if (_scene != null) _scene.invalidateEntityBounds(this);
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

    public function get_shaderPickingDetails():Bool {
        return _shaderPickingDetails;
    }

    public function set_shaderPickingDetails(value:Bool):Bool {
        _shaderPickingDetails = value;
        return value;
    }

/**
	 * Defines whether or not the object will be moved or animated at runtime. This property is used by some partitioning systems to improve performance.
	 * Warning: if set to true, they may not be processed by certain partition systems using static visibility lists, unless they're specifically assigned to the visibility list.
	 */

    public function get_staticNode():Bool {
        return _staticNode;
    }

    public function set_staticNode(value:Bool):Bool {
        _staticNode = value;
        return value;
    }

/**
	 * Returns a unique picking collision value object for the entity.
	 */

    public function get_pickingCollisionVO():PickingCollisionVO {
        if (_pickingCollisionVO == null) _pickingCollisionVO = new PickingCollisionVO(this);
        return _pickingCollisionVO;
    }

/**
	 * Tests if a collision occurs before shortestCollisionDistance, using the data stored in PickingCollisionVO.
	 * @param shortestCollisionDistance
	 * @return
	 */

    public function collidesBefore(shortestCollisionDistance:Float, findClosest:Bool):Bool {

        return true;
    }

/**
	 *
	 */

    public function get_showBounds():Bool {
        return _showBounds;
    }

    public function set_showBounds(value:Bool):Bool {
        if (value == _showBounds) return value;
        _showBounds = value;
        if (_showBounds) addBounds()
        else removeBounds();
        return value;
    }

/**
	 * @inheritDoc
	 */

    override public function get_minX():Float {
        if (_boundsInvalid) updateBounds();
        return _bounds.min.x;
    }

/**
	 * @inheritDoc
	 */

    override public function get_minY():Float {
        if (_boundsInvalid) updateBounds();
        return _bounds.min.y;
    }

/**
	 * @inheritDoc
	 */

    override public function get_minZ():Float {
        if (_boundsInvalid) updateBounds();
        return _bounds.min.z;
    }

/**
	 * @inheritDoc
	 */

    override public function get_maxX():Float {
        if (_boundsInvalid) updateBounds();
        return _bounds.max.x;
    }

/**
	 * @inheritDoc
	 */

    override public function get_maxY():Float {
        if (_boundsInvalid) updateBounds();
        return _bounds.max.y;
    }

/**
	 * @inheritDoc
	 */

    override public function get_maxZ():Float {
        if (_boundsInvalid) updateBounds();
        return _bounds.max.z;
    }

/**
	 * The bounding volume approximating the volume occupied by the Entity.
	 */

    public function get_bounds():BoundingVolumeBase {
        if (_boundsInvalid) updateBounds();
        return _bounds;
    }

    public function set_bounds(value:BoundingVolumeBase):BoundingVolumeBase {
        removeBounds();
        _bounds = value;
        _worldBounds = value.clone();
        invalidateBounds();
        if (_showBounds) addBounds();
        return value;
    }

    public function get_worldBounds():BoundingVolumeBase {
		//why
        if (_worldBoundsInvalid) {
			updateWorldBounds();
		}
	
        return _worldBounds;
    }

    private function updateWorldBounds():Void {
        _worldBounds.transformFrom(bounds, sceneTransform);
        _worldBoundsInvalid = false;
    }

/**
	 * @inheritDoc
	 */

    override private function set_implicitPartition(value:Partition3D):Partition3D {
        if (value == _implicitPartition) return value;
        if (_implicitPartition != null) notifyPartitionUnassigned();
        super.implicitPartition = value;
        notifyPartitionAssigned();
        return value;
    }

/**
	 * @inheritDoc
	 */

    override public function set_scene(value:Scene3D):Scene3D {
        if (value == _scene) return value;
        if (_scene != null) _scene.unregisterEntity(this);
        if (value != null) value.registerEntity(this);
        super.scene = value;
        return value;
    }

    override public function get_assetType():String {
        return AssetType.ENTITY;
    }

/**
	 * Used by the raycast-based picking system to determine how the geometric contents of an entity are processed
	 * in order to offer more details for the picking collision object, including local position, normal vector and uv value.
	 * Defaults to null.
	 *
	 * @see away3d.core.pick.RaycastPicker
	 */

    public function get_pickingCollider():IPickingCollider {
        return _pickingCollider;
    }

    public function set_pickingCollider(value:IPickingCollider):IPickingCollider {
        _pickingCollider = value;
        return value;
    }

/**
	 * Creates a new Entity object.
	 */

    public function new() {
        _boundsIsShown = false;
        _boundsInvalid = true;
        _worldBoundsInvalid = true;
        super();
        _bounds = getDefaultBoundingVolume();
        _worldBounds = getDefaultBoundingVolume();
    }

/**
	 * Gets a concrete EntityPartition3DNode subclass that is associated with this Entity instance
	 */

    public function getEntityPartitionNode():EntityNode {
        if (_partitionNode == null) _partitionNode = createEntityPartitionNode();
        return _partitionNode;
    }

    public function isIntersectingRay(rayPosition:Vector3D, rayDirection:Vector3D):Bool {
// convert ray to entity space
        var localRayPosition:Vector3D = inverseSceneTransform.transformVector(rayPosition);
        var localRayDirection:Vector3D = inverseSceneTransform.deltaTransformVector(rayDirection);
// check for ray-bounds collision
        if (pickingCollisionVO.localNormal == null)pickingCollisionVO.localNormal = new Vector3D();
        var rayEntryDistance:Float = bounds.rayIntersection(localRayPosition, localRayDirection, pickingCollisionVO.localNormal);
        if (rayEntryDistance < 0) return false;
        pickingCollisionVO.rayEntryDistance = rayEntryDistance;
        pickingCollisionVO.localRayPosition = localRayPosition;
        pickingCollisionVO.localRayDirection = localRayDirection;
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

    private function createEntityPartitionNode():EntityNode {
        throw new AbstractMethodError();
        return null;
    }

/**
	 * Creates the default bounding box to be used by this type of Entity.
	 * @return
	 */

    private function getDefaultBoundingVolume():BoundingVolumeBase {
// point lights should be using sphere bounds
// directional lights should be using null bounds
        return new AxisAlignedBoundingBox();
    }

/**
	 * Updates the bounding volume for the object. Overriding methods need to set invalid flag to false!
	 */

    private function updateBounds():Void {
        throw new AbstractMethodError();
        return null;
    }

/**
	 * @inheritDoc
	 */

    override private function invalidateSceneTransform():Void {
        if (!_ignoreTransform) {
            super.invalidateSceneTransform();
            _worldBoundsInvalid = true;
            notifySceneBoundsInvalid();
        }
    }

/**
	 * Invalidates the bounding volume, causing to be updated when requested.
	 */

    private function invalidateBounds():Void {
        _boundsInvalid = true;
        _worldBoundsInvalid = true;
        notifySceneBoundsInvalid();
    }

    override private function updateMouseChildren():Void {
// If there is a parent and this child does not have a triangle collider, use its parent's triangle collider.

        if (_parent == null && pickingCollider != null) {
            if (Std.is(_parent, Entity)) {
                var collider:IPickingCollider = cast((_parent), Entity).pickingCollider;
                if (collider != null) pickingCollider = collider;
            }
        }
        super.updateMouseChildren();
    }

/**
	 * Notify the scene that the global scene bounds have changed, so it can be repartitioned.
	 */

    private function notifySceneBoundsInvalid():Void {
        if (_scene != null) _scene.invalidateEntityBounds(this);

    }

/**
	 * Notify the scene that a new partition was assigned.
	 */

    private function notifyPartitionAssigned():Void {
        if (_scene != null) _scene.registerPartition(this);
    }

/**
	 * Notify the scene that a partition was unassigned.
	 */

    private function notifyPartitionUnassigned():Void {
        if (_scene != null) _scene.unregisterPartition(this);
    }

    private function addBounds():Void {
        if (!_boundsIsShown) {
            _boundsIsShown = true;
            addChild(_bounds.boundingRenderable);
        }
    }

    private function removeBounds():Void {
        if (_boundsIsShown) {
            _boundsIsShown = false;
            removeChild(_bounds.boundingRenderable);
            _bounds.disposeRenderable();
        }
    }

    public function internalUpdate():Void {
        if (_controller != null) _controller.update();
    }

}

