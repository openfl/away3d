/**
 * Picks a 3d object from a view or scene by 3D raycast calculations.
 * Performs an initial coarse boundary calculation to return a subset of entities whose bounding volumes intersect with the specified ray,
 * then triggers an optional picking collider on individual entity objects to further determine the precise values of the picking ray collision.
 */
package away3d.core.pick;

import away3d.core.math.MathConsts;
import flash.Vector;
import flash.geom.Vector3D;

import away3d.containers.Scene3D;
import away3d.containers.View3D;
import away3d.core.data.EntityListItem;
import away3d.core.traverse.EntityCollector;
import away3d.core.traverse.RaycastCollector;
import away3d.entities.Entity;

class RaycastPicker implements IPicker {
    public var onlyMouseEnabled(get_onlyMouseEnabled, set_onlyMouseEnabled):Bool;

// TODO: add option of finding best hit?
    private var _findClosestCollision:Bool;
    private var _raycastCollector:RaycastCollector;
    private var _ignoredEntities:Array<Dynamic>;
    private var _onlyMouseEnabled:Bool;
    private var _entities:Vector<Entity>;
    private var _numEntities:Int;
    private var _hasCollisions:Bool;
/**
	 * @inheritDoc
	 */

    public function get_onlyMouseEnabled():Bool {
        return _onlyMouseEnabled;
    }

    public function set_onlyMouseEnabled(value:Bool):Bool {
        _onlyMouseEnabled = value;
        return value;
    }

/**
	 * Creates a new <code>RaycastPicker</code> object.
	 *
	 * @param findClosestCollision Determines whether the picker searches for the closest bounds collision along the ray,
	 * or simply returns the first collision encountered Defaults to false.
	 */

    public function new(findClosestCollision:Bool) {
        _raycastCollector = new RaycastCollector();
        _ignoredEntities = new Array<Dynamic>();
        _onlyMouseEnabled = true;
        _findClosestCollision = findClosestCollision;
        _entities = new Vector<Entity>();
    }

/**
	 * @inheritDoc
	 */

    public function getViewCollision(x:Float, y:Float, view:View3D):PickingCollisionVO {
//cast ray through the collection of entities on the view
        var collector:EntityCollector = view.entityCollector;
//var i:uint;
        if (collector.numMouseEnableds == 0) return null;
        var rayPosition:Vector3D = view.unproject(x, y, 0);
        var rayDirection:Vector3D = view.unproject(x, y, 1);
        rayDirection = rayDirection.subtract(rayPosition);
// Perform ray-bounds collision checks.
        _numEntities = 0;
        var node:EntityListItem = collector.entityHead;
        var entity:Entity;
        while (node != null) {
            entity = node.entity;
            if (isIgnored(entity)) {
                node = node.next;
                continue;
            }
            if (entity.isVisible && entity.isIntersectingRay(rayPosition, rayDirection)) _entities[_numEntities++] = entity;
            node = node.next;
        }

//early out if no collisions detected
        if (_numEntities == 0) return null;
        return getPickingCollisionVO();
    }

/**
	 * @inheritDoc
	 */

    public function getSceneCollision(position:Vector3D, direction:Vector3D, scene:Scene3D):PickingCollisionVO {
//clear collector
        _raycastCollector.clear();
//setup ray vectors
        _raycastCollector.rayPosition = position;
        _raycastCollector.rayDirection = direction;
// collect entities to test
        scene.traversePartitions(_raycastCollector);
        _numEntities = 0;
        var node:EntityListItem = _raycastCollector.entityHead;
        var entity:Entity;
        while (node != null) {
            entity = node.entity;
            if (isIgnored(entity)) {
                node = node.next;
                continue;
            }
            _entities[_numEntities++] = entity;
            node = node.next;
        }

//early out if no collisions detected
        if (_numEntities == 0) return null;
        return getPickingCollisionVO();
    }

    public function getEntityCollision(position:Vector3D, direction:Vector3D, entities:Vector<Entity>):PickingCollisionVO {

        _numEntities = 0;
        var entity:Entity;
        for (entity in entities) {
            if (entity.isIntersectingRay(position, direction)) _entities[_numEntities++] = entity;
        }

        return getPickingCollisionVO();
    }

    public function setIgnoreList(entities:Array<Dynamic>):Void {
        _ignoredEntities = entities;
    }

    private function isIgnored(entity:Entity):Bool {
        if (_onlyMouseEnabled && (!entity._ancestorsAllowMouseEnabled || !entity.mouseEnabled)) return true;
        var ignoredEntity:Entity;
        for (ignoredEntity in _ignoredEntities) {
            if (ignoredEntity == entity) return true;
        }

        return false;
    }

    private function sortOnNearT(entity1:Entity, entity2:Entity):Int {
        return entity1.pickingCollisionVO.rayEntryDistance > (entity2.pickingCollisionVO.rayEntryDistance) ? 1 : -1;
    }

    private function getPickingCollisionVO():PickingCollisionVO {
// trim before sorting
        _entities.length = _numEntities;
// Sort entities from closest to furthest.
// _entities =
        _entities.sort(sortOnNearT);
// ---------------------------------------------------------------------
// Evaluate triangle collisions when needed.
// Replaces collision data provided by bounds collider with more precise data.
// ---------------------------------------------------------------------
        var shortestCollisionDistance:Float = MathConsts.MAX_VALUE;
        var bestCollisionVO:PickingCollisionVO = null;
        var pickingCollisionVO:PickingCollisionVO;
        var entity:Entity;
        var i:Int;
        i = 0;
        while (i < _numEntities) {
            entity = _entities[i];
            pickingCollisionVO = entity._pickingCollisionVO;
            if (entity.pickingCollider != null) {
// If a collision exists, update the collision data and stop all checks.
                if ((bestCollisionVO == null || pickingCollisionVO.rayEntryDistance < bestCollisionVO.rayEntryDistance) && entity.collidesBefore(shortestCollisionDistance, _findClosestCollision)) {
                    shortestCollisionDistance = pickingCollisionVO.rayEntryDistance;
                    bestCollisionVO = pickingCollisionVO;
                    if (!_findClosestCollision) {
                        updateLocalPosition(pickingCollisionVO);
                        return pickingCollisionVO;
                    }
                }
            }

            else if (bestCollisionVO == null || pickingCollisionVO.rayEntryDistance < bestCollisionVO.rayEntryDistance) {
// A bounds collision with no triangle collider stops all checks.
// Note: a bounds collision with a ray origin inside its bounds is ONLY ever used
// to enable the detection of a corresponsding triangle collision.
// Therefore, bounds collisions with a ray origin inside its bounds can be ignored
// if it has been established that there is NO triangle collider to test
                if (!pickingCollisionVO.rayOriginIsInsideBounds) {
                    updateLocalPosition(pickingCollisionVO);
                    return pickingCollisionVO;
                }
            }
            ++i;
        }
        return bestCollisionVO;
    }

    private function updateLocalPosition(pickingCollisionVO:PickingCollisionVO):Void {
        if (pickingCollisionVO.localPosition == null) pickingCollisionVO.localPosition = new Vector3D();
        var collisionPos:Vector3D = pickingCollisionVO.localPosition ;
        var rayDir:Vector3D = pickingCollisionVO.localRayDirection;
        var rayPos:Vector3D = pickingCollisionVO.localRayPosition;
        var t:Float = pickingCollisionVO.rayEntryDistance;
        collisionPos.x = rayPos.x + t * rayDir.x;
        collisionPos.y = rayPos.y + t * rayDir.y;
        collisionPos.z = rayPos.z + t * rayDir.z;
    }

    public function dispose():Void {
    }

}

