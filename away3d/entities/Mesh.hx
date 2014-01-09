package away3d.entities;

	import away3d.materials.utils.DefaultMaterialManager;
	import away3d.animators.IAnimator;
	//import away3d.arcane;
	import away3d.containers.*;
	import away3d.core.base.*;
	import away3d.core.partition.*;
	import away3d.events.*;
	import away3d.library.assets.*;
	import away3d.materials.*;
	
	//use namespace arcane;
	
	/**
	 * Mesh is an instance of a Geometry, augmenting it with a presence in the scene graph, a material, and an animation
	 * state. It consists out of SubMeshes, which in turn correspond to SubGeometries. SubMeshes allow different parts
	 * of the geometry to be assigned different materials.
	 */
	class Mesh extends Entity implements IMaterialOwner implements IAsset
	{
		var _subMeshes:Array<SubMesh>;
		var _geometry:Geometry;
		var _material:MaterialBase;
		var _animator:IAnimator;
		var _castsShadows:Bool = true;
		var _shareAnimationGeometry:Bool = true;
		
		/**
		 * Create a new Mesh object.
		 *
		 * @param geometry                    The geometry used by the mesh that provides it with its shape.
		 * @param material    [optional]        The material with which to render the Mesh.
		 */
		public function new(geometry:Geometry, material:MaterialBase = null)
		{
			super();
			_subMeshes = new Array<SubMesh>();
			
			this.geometry = geometry!=null ? geometry : new Geometry(); //this should never happen, but if people insist on trying to create their meshes before they have geometry to fill it, it becomes necessary
			
			this.material = material!=null ? material : DefaultMaterialManager.getDefaultMaterial(this);
		}
		
		public function bakeTransformations():Void
		{
			geometry.applyTransformation(transform);
			transform.identity();
		}
		
		public override function get_assetType() : String
		{
			return AssetType.MESH;
		}
		
		private function onGeometryBoundsInvalid(event:GeometryEvent):Void
		{
			invalidateBounds();
		}
		
		/**
		 * Indicates whether or not the Mesh can cast shadows. Default value is <code>true</code>.
		 */
		public var castsShadows(get, set) : Bool;
		public function get_castsShadows() : Bool
		{
			return _castsShadows;
		}
		
		public function set_castsShadows(value:Bool) : Bool
		{
			_castsShadows = value;
			return _castsShadows;
		}
		
		/**
		 * Defines the animator of the mesh. Act on the mesh's geometry.  Default value is <code>null</code>.
		 */
		public var animator(get, set) : IAnimator;
		public function get_animator() : IAnimator
		{
			return _animator;
		}
		
		public function set_animator(value:IAnimator) : IAnimator
		{
			if (_animator!=null)
				_animator.removeOwner(this);
			
			_animator = value;
			
			// cause material to be unregistered and registered again to work with the new animation type (if possible)
			var oldMaterial:MaterialBase = material;
			material = null;
			material = oldMaterial;
			
			var len:UInt = _subMeshes.length;
			var subMesh:SubMesh;
			
			// reassign for each SubMesh
			// For loop conversion - 			for (var i:Int = 0; i < len; ++i)
			var i:Int;
			for (i in 0...len) {
				subMesh = _subMeshes[i];
				oldMaterial = subMesh._material;
				if (oldMaterial!=null) {
					subMesh.material = null;
					subMesh.material = oldMaterial;
				}
			}
			
			if (_animator!=null)
				_animator.addOwner(this);

			return _animator;
		}
		
		/**
		 * The geometry used by the mesh that provides it with its shape.
		 */
		public var geometry(get, set) : Geometry;
		public function get_geometry() : Geometry
		{
			return _geometry;
		}
		
		public function set_geometry(value:Geometry) : Geometry
		{
			var i:UInt = 0;
			
			if (_geometry!=null) {
				_geometry.removeEventListener(GeometryEvent.BOUNDS_INVALID, onGeometryBoundsInvalid);
				_geometry.removeEventListener(GeometryEvent.SUB_GEOMETRY_ADDED, onSubGeometryAdded);
				_geometry.removeEventListener(GeometryEvent.SUB_GEOMETRY_REMOVED, onSubGeometryRemoved);
				
				// For loop conversion - 								for (i = 0; i < _subMeshes.length; ++i)
				
				for (i in 0..._subMeshes.length)
					_subMeshes[i].dispose();
				_subMeshes = new Array<SubMesh>();
			}
			
			_geometry = value;
			if (_geometry!=null) {
				_geometry.addEventListener(GeometryEvent.BOUNDS_INVALID, onGeometryBoundsInvalid);
				_geometry.addEventListener(GeometryEvent.SUB_GEOMETRY_ADDED, onSubGeometryAdded);
				_geometry.addEventListener(GeometryEvent.SUB_GEOMETRY_REMOVED, onSubGeometryRemoved);
				
				var subGeoms:Array<ISubGeometry> = _geometry.subGeometries;
				
				// For loop conversion - 								for (i = 0; i < subGeoms.length; ++i)
				
				for (i in 0...subGeoms.length)
					addSubMesh(subGeoms[i]);
			}
			
			if (_material!=null) {
				// reregister material in case geometry has a different animation
				_material.removeOwner(this);
				_material.addOwner(this);
			}
			return _geometry;
		}
		
		/**
		 * The material with which to render the Mesh.
		 */
		public var material(get, set) : MaterialBase;
		public function get_material() : MaterialBase
		{
			return _material;
		}
		
		public function set_material(value:MaterialBase) : MaterialBase
		{
			if (value == _material)
				return _material;
			if (_material!=null)
				_material.removeOwner(this);
			_material = value;
			if (_material!=null)
				_material.addOwner(this);
			return _material;
		}
		
		/**
		 * The SubMeshes out of which the Mesh consists. Every SubMesh can be assigned a material to override the Mesh's
		 * material.
		 */
		public var subMeshes(get, null) : Array<SubMesh>;
		public function get_subMeshes() : Array<SubMesh>
		{
			// Since this getter is invoked every iteration of the render loop, and
			// the geometry construct could affect the sub-meshes, the geometry is
			// validated here to give it a chance to rebuild.
			_geometry.validate();
			
			return _subMeshes;
		}
		
		/**
		 * Indicates whether or not the mesh share the same animation geometry.
		 */
		public var shareAnimationGeometry(get, set) : Bool;
		public function get_shareAnimationGeometry() : Bool
		{
			return _shareAnimationGeometry;
		}
		
		public function set_shareAnimationGeometry(value:Bool) : Bool
		{
			_shareAnimationGeometry = value;
			return _shareAnimationGeometry;
		}
		
		/**
		 * Clears the animation geometry of this mesh. It will cause animation to generate a new animation geometry. Work only when shareAnimationGeometry is false.
		 */
		public function clearAnimationGeometry():Void
		{
			var len:Int = _subMeshes.length;
			// For loop conversion - 			for (var i:Int = 0; i < len; ++i)
			var i:Int;
			for (i in 0...len)
				_subMeshes[i].animationSubGeometry = null;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():Void
		{
			super.dispose();
			
			material = null;
			geometry = null;
		}
		
		/**
		 * Disposes mesh including the animator and children. This is a merely a convenience method.
		 * @return
		 */
		public function disposeWithAnimatorAndChildren():Void
		{
			disposeWithChildren();
			
			if (_animator!=null)
				_animator.dispose();
		}
		
		/**
		 * Clones this Mesh instance along with all it's children, while re-using the same
		 * material, geometry and animation set. The returned result will be a copy of this mesh,
		 * containing copies of all of it's children.
		 *
		 * Properties that are re-used (i.e. not cloned) by the new copy include name,
		 * geometry, and material. Properties that are cloned or created anew for the copy
		 * include subMeshes, children of the mesh, and the animator.
		 *
		 * If you want to copy just the mesh, reusing it's geometry and material while not
		 * cloning it's children, the simplest way is to create a new mesh manually:
		 *
		 * <code>
		 * var clone : Mesh = new Mesh(original.geometry, original.material);
		 * </code>
		 */
		override public function clone():Object3D
		{
			var clone:Mesh = new Mesh(_geometry, _material);
			clone.transform = transform;
			clone.pivotPoint = pivotPoint;
			clone.partition = partition;
			clone.bounds = _bounds.clone();
			clone.name = name;
			clone.castsShadows = castsShadows;
			clone.shareAnimationGeometry = shareAnimationGeometry;
			clone.mouseEnabled = this.mouseEnabled;
			clone.mouseChildren = this.mouseChildren;
			//this is of course no proper cloning
			//maybe use this instead?: http://blog.another-d-mention.ro/programming/how-to-clone-duplicate-an-object-in-actionscript-3/
			clone.extra = this.extra;
			
			var len:Int = _subMeshes.length;
			// For loop conversion - 			for (var i:Int = 0; i < len; ++i)
			var i:Int;
			for (i in 0...len)
				clone._subMeshes[i]._material = _subMeshes[i]._material;
			
			len = numChildren;
			// For loop conversion - 			for (i = 0; i < len; ++i)
			for (i in 0...len)
				clone.addChild(cast(getChildAt(i).clone(), ObjectContainer3D));
			
			if (_animator!=null)
				clone.animator = _animator.clone();
			
			return clone;
		}
		
		/**
		 * @inheritDoc
		 */
		override private function updateBounds():Void
		{
			_bounds.fromGeometry(_geometry);
			_boundsInvalid = false;
		}
		
		/**
		 * @inheritDoc
		 */
		override private function createEntityPartitionNode():EntityNode
		{
			return new MeshNode(this);
		}
		
		/**
		 * Called when a SubGeometry was added to the Geometry.
		 */
		private function onSubGeometryAdded(event:GeometryEvent):Void
		{
			addSubMesh(event.subGeometry);
		}
		
		/**
		 * Called when a SubGeometry was removed from the Geometry.
		 */
		private function onSubGeometryRemoved(event:GeometryEvent):Void
		{
			var subMesh:SubMesh;
			var subGeom:ISubGeometry = event.subGeometry;
			var len:Int = _subMeshes.length;
			var i:UInt = 0;
			
			// Important! This has to be done here, and not delayed until the
			// next render loop, since this may be caused by the geometry being
			// rebuilt IN THE RENDER LOOP. Invalidating and waiting will delay
			// it until the NEXT RENDER FRAME which is probably not desirable.
			
			// For loop conversion - 						for (i = 0; i < len; ++i)
			
			for (i in 0...len) {
				subMesh = _subMeshes[i];
				if (subMesh.subGeometry == subGeom) {
					subMesh.dispose();
					_subMeshes.splice(i, 1);
					break;
				}
			}
			
			--len;
			for (i in 0...len)
				_subMeshes[i]._index = i;
		}
		
		/**
		 * Adds a SubMesh wrapping a SubGeometry.
		 */
		private function addSubMesh(subGeometry:ISubGeometry):Void
		{
			var subMesh:SubMesh = new SubMesh(subGeometry, this, null);
			var len:UInt = _subMeshes.length;
			subMesh._index = len;
			_subMeshes[len] = subMesh;
			invalidateBounds();
		}
		
		public function getSubMeshForSubGeometry(subGeometry:SubGeometry):SubMesh
		{
			return _subMeshes[Lambda.indexOf(_geometry.subGeometries, subGeometry)];
		}
		
		override public function collidesBefore(shortestCollisionDistance:Float, findClosest:Bool):Bool
		{
			_pickingCollider.setLocalRay(_pickingCollisionVO.localRayPosition, _pickingCollisionVO.localRayDirection);
			_pickingCollisionVO.renderable = null;
			var len:Int = _subMeshes.length;
			// For loop conversion - 			for (var i:Int = 0; i < len; ++i)
			var i:Int;
			for (i in 0...len) {
				var subMesh:SubMesh = _subMeshes[i];
				
				//var ignoreFacesLookingAway:Bool = _material ? !_material.bothSides : true;
				if (_pickingCollider.testSubMeshCollision(subMesh, _pickingCollisionVO, shortestCollisionDistance)) {
					shortestCollisionDistance = _pickingCollisionVO.rayEntryDistance;
					_pickingCollisionVO.renderable = subMesh;
					if (!findClosest)
						return true;
				}
			}
			
			return _pickingCollisionVO.renderable != null;
		}
	}

