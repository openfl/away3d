package away3d.entities;

	//import away3d.arcane;
	import away3d.bounds.*;
	import away3d.containers.*;
	import away3d.core.partition.*;
	import away3d.core.pick.*;
	import away3d.errors.*;
	import away3d.library.assets.*;
	
	import away3d.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	//use namespace arcane;
	
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
		var _showBounds:Bool;
		var _partitionNode:EntityNode;
		var _boundsIsShown:Bool = false;
		var _shaderPickingDetails:Bool;
		
		/*arcane*/ public var _pickingCollisionVO:PickingCollisionVO;
		/*arcane*/ public var _pickingCollider:IPickingCollider;
		/*arcane*/ public var _staticNode:Bool;
		
		var _bounds:BoundingVolumeBase;
		var _boundsInvalid:Bool = true;
		var _worldBounds:BoundingVolumeBase;
		var _worldBoundsInvalid:Bool = true;
		
		override public function set_ignoreTransform(value:Bool) : Bool
		{
			if (_scene!=null)
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
		public var shaderPickingDetails(get, set) : Bool;
		public function get_shaderPickingDetails() : Bool
		{
			return _shaderPickingDetails;
		}
		
		public function set_shaderPickingDetails(value:Bool) : Bool
		{
			_shaderPickingDetails = value;
			return _shaderPickingDetails;
		}
		
		/**
		 * Defines whether or not the object will be moved or animated at runtime. This property is used by some partitioning systems to improve performance.
		 * Warning: if set to true, they may not be processed by certain partition systems using static visibility lists, unless they're specifically assigned to the visibility list.
		 */
		public var staticNode(get, set) : Bool;
		public function get_staticNode() : Bool
		{
			return _staticNode;
		}
		
		public function set_staticNode(value:Bool) : Bool
		{
			_staticNode = value;
			return _staticNode;
		}
		
		/**
		 * Returns a unique picking collision value object for the entity.
		 */
		public var pickingCollisionVO(get, null) : PickingCollisionVO;
		public function get_pickingCollisionVO() : PickingCollisionVO
		{
			if (_pickingCollisionVO==null)
				_pickingCollisionVO = new PickingCollisionVO(this);
			
			return _pickingCollisionVO;
		}
		
		/**
		 * Tests if a collision occurs before shortestCollisionDistance, using the data stored in PickingCollisionVO.
		 * @param shortestCollisionDistance
		 * @return
		 */
		public function collidesBefore(shortestCollisionDistance:Float, findClosest:Bool):Bool
		{
			//shortestCollisionDistance = shortestCollisionDistance;
			//findClosest = findClosest;
			return true;
		}
		
		/**
		 *
		 */
		public var showBounds(get, set) : Bool;
		public function get_showBounds() : Bool
		{
			return _showBounds;
		}
		
		public function set_showBounds(value:Bool) : Bool
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
		override public function get_minX() : Float
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.min.x;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get_minY() : Float
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.min.y;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get_minZ() : Float
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.min.z;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get_maxX() : Float
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.max.x;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get_maxY() : Float
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.max.y;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get_maxZ() : Float
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds.max.z;
		}
		
		/**
		 * The bounding volume approximating the volume occupied by the Entity.
		 */
		public var bounds(get, set) : BoundingVolumeBase;
		public function get_bounds() : BoundingVolumeBase
		{
			if (_boundsInvalid)
				updateBounds();
			
			return _bounds;
		}
		
		public function set_bounds(value:BoundingVolumeBase) : BoundingVolumeBase
		{
			removeBounds();
			_bounds = value;
			_worldBounds = value.clone();
			invalidateBounds();
			if (_showBounds)
				addBounds();
			return _bounds;
		}
		
		public var worldBounds(get, null) : BoundingVolumeBase;
		
		public function get_worldBounds() : BoundingVolumeBase
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
		override public function set_implicitPartition(value:Partition3D) : Partition3D
		{
			if (value == _implicitPartition)
				return _implicitPartition;
			
			if (_implicitPartition!=null)
				notifyPartitionUnassigned();
			
			super.implicitPartition = value;
			
			notifyPartitionAssigned();
			return _implicitPartition;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set_scene(value:Scene3D) : Scene3D
		{
			if (value == _scene)
				return _scene;
			
			if (_scene!=null)
				_scene.unregisterEntity(this);
			
			// callback to notify object has been spawned. Casts to please FDT
			if (value!=null)
				value.registerEntity(this);
			
			super.scene = value;
			return _scene;
		}
		
		override public function get_assetType() : String
		{
			return AssetType.ENTITY;
		}
		
		/**
		 * Used by the raycast-based picking system to determine how the geometric contents of an entity are processed
		 * in order to offer more details for the picking collision object, including local position, normal vector and uv value.
		 * Defaults to null.
		 *
		 * @see away3d.core.pick.RaycastPicker
		 */
		public var pickingCollider(get, set) : IPickingCollider;
		public function get_pickingCollider() : IPickingCollider
		{
			return _pickingCollider;
		}
		
		public function set_pickingCollider(value:IPickingCollider) : IPickingCollider
		{
			_pickingCollider = value;
			return _pickingCollider;
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
			if (_partitionNode==null) _partitionNode = createEntityPartitionNode();
			return _partitionNode;
		}
		
		public function isIntersectingRay(rayPosition:Vector3D, rayDirection:Vector3D):Bool
		{
			// convert ray to entity space
			var localRayPosition:Vector3D = inverseSceneTransform.transformVector(rayPosition);
			var localRayDirection:Vector3D = inverseSceneTransform.deltaTransformVector(rayDirection);
			
			// check for ray-bounds collision
			var v:Vector3D = pickingCollisionVO.localNormal;
			if (pickingCollisionVO.localNormal==null) v = new Vector3D();
			var rayEntryDistance:Float = bounds.rayIntersection(localRayPosition, localRayDirection, v);
			
			if (rayEntryDistance < 0)
				return false;
			
			// Store collision data.
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
		private function createEntityPartitionNode():EntityNode
		{
			return new EntityNode(this);
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
			if (_parent!=null && pickingCollider==null) {
				if (Std.is(_parent, Entity)) {
					var collider:IPickingCollider = cast(_parent, Entity).pickingCollider;
					if (collider!=null)
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
			if (_scene!=null)
				_scene.invalidateEntityBounds(this);
		}
		
		/**
		 * Notify the scene that a new partition was assigned.
		 */
		private function notifyPartitionAssigned():Void
		{
			if (_scene!=null)
				_scene.registerPartition(this); //_onAssignPartitionCallback(this);
		}
		
		/**
		 * Notify the scene that a partition was unassigned.
		 */
		private function notifyPartitionUnassigned():Void
		{
			if (_scene!=null)
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
			if (_controller!=null)
				_controller.update();
		}
	}

