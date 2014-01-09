package away3d.core.traverse;

	//import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.data.EntityListItem;
	import away3d.core.data.EntityListItemPool;
	import away3d.core.data.RenderableListItem;
	import away3d.core.data.RenderableListItemPool;
	import away3d.core.math.Plane3D;
	import away3d.core.partition.NodeBase;
	import away3d.entities.Entity;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightBase;
	import away3d.lights.LightProbe;
	import away3d.lights.PointLight;
	import away3d.materials.MaterialBase;
	
	import flash.geom.Vector3D;
	
	//use namespace arcane;
	
	/**
	 * The EntityCollector class is a traverser for scene partitions that collects all scene graph entities that are
	 * considered potientially visible.
	 *
	 * @see away3d.partition.Partition3D
	 * @see away3d.partition.Entity
	 */
	class EntityCollector extends PartitionTraverser
	{
		var _skyBox:IRenderable;
		var _opaqueRenderableHead:RenderableListItem;
		var _blendedRenderableHead:RenderableListItem;
		var _entityHead:EntityListItem;
		var _renderableListItemPool:RenderableListItemPool;
		var _entityListItemPool:EntityListItemPool;
		var _lights:Array<LightBase>;
		var _directionalLights:Array<DirectionalLight>;
		var _pointLights:Array<PointLight>;
		var _lightProbes:Array<LightProbe>;
		var _numEntities:UInt;
		var _numLights:UInt;
		var _numTriangles:UInt;
		var _numMouseEnableds:UInt;
		var _camera:Camera3D;
		var _numDirectionalLights:UInt;
		var _numPointLights:UInt;
		var _numLightProbes:UInt;
		var _cameraForward:Vector3D;
		var _customCullPlanes:Array<Plane3D>;
		var _cullPlanes:Array<Plane3D>;
		var _numCullPlanes:UInt;
		
		/**
		 * Creates a new EntityCollector object.
		 */
		public function new()
		{
			super();
			init();
		}
		
		private function init():Void
		{
			_lights = new Array<LightBase>();
			_directionalLights = new Array<DirectionalLight>();
			_pointLights = new Array<PointLight>();
			_lightProbes = new Array<LightProbe>();
			_renderableListItemPool = new RenderableListItemPool();
			_entityListItemPool = new EntityListItemPool();
		}
		
		/**
		 * The camera that provides the visible frustum.
		 */
		public var camera(get, set) : Camera3D;
		public function get_camera() : Camera3D
		{
			return _camera;
		}
		
		public function set_camera(value:Camera3D) : Camera3D
		{
			_camera = value;
			_entryPoint = _camera.scenePosition;
			_cameraForward = _camera.forwardVector;
			_cullPlanes = _camera.frustumPlanes;
			return value;
		}
		
		public var cullPlanes(get, set) : Array<Plane3D>;
		public function get_cullPlanes() : Array<Plane3D>
		{
			return _customCullPlanes;
		}
		
		public function set_cullPlanes(value:Array<Plane3D>) : Array<Plane3D>
		{
			_customCullPlanes = value;
			return value;
		}
		
		/**
		 * The amount of IRenderable objects that are mouse-enabled.
		 */
		public var numMouseEnableds(get, null) : UInt;
		public function get_numMouseEnableds() : UInt
		{
			return _numMouseEnableds;
		}
		
		/**
		 * The sky box object if encountered.
		 */
		public var skyBox(get, null) : IRenderable;
		public function get_skyBox() : IRenderable
		{
			return _skyBox;
		}
		
		/**
		 * The list of opaque IRenderable objects that are considered potentially visible.
		 * @param value
		 */
		public var opaqueRenderableHead(get, set) : RenderableListItem;
		public function get_opaqueRenderableHead() : RenderableListItem
		{
			return _opaqueRenderableHead;
		}
		
		public function set_opaqueRenderableHead(value:RenderableListItem) : RenderableListItem
		{
			_opaqueRenderableHead = value;
			return value;
		}
		
		/**
		 * The list of IRenderable objects that require blending and are considered potentially visible.
		 * @param value
		 */
		public var blendedRenderableHead(get, set) : RenderableListItem;
		public function get_blendedRenderableHead() : RenderableListItem
		{
			return _blendedRenderableHead;
		}
		
		public function set_blendedRenderableHead(value:RenderableListItem) : RenderableListItem
		{
			_blendedRenderableHead = value;
			return value;
		}
		
		public var entityHead(get, null) : EntityListItem;
		
		public function get_entityHead() : EntityListItem
		{
			return _entityHead;
		}
		
		/**
		 * The lights of which the affecting area intersects the camera's frustum.
		 */
		public var lights(get, null) : Array<LightBase>;
		public function get_lights() : Array<LightBase>
		{
			return _lights;
		}
		
		public var directionalLights(get, null) : Array<DirectionalLight>;
		public function get_directionalLights() : Array<DirectionalLight>
		{
			return _directionalLights;
		}
		
		public var pointLights(get, null) : Array<PointLight>;
		public function get_pointLights() : Array<PointLight>
		{
			return _pointLights;
		}
		
		public var lightProbes(get, null) : Array<LightProbe>;	
		public function get_lightProbes() : Array<LightProbe>
		{
			return _lightProbes;
		}
		
		/**
		 * Clears all objects in the entity collector.
		 */
		public function clear():Void
		{
			_entryPoint = _camera.scenePosition;
			_cameraForward = _camera.forwardVector;
			_cullPlanes = _customCullPlanes!=null ? _customCullPlanes : (_camera!=null ? _camera.frustumPlanes : null);
			_numCullPlanes = _cullPlanes!=null ? _cullPlanes.length : 0;
			_numTriangles = _numMouseEnableds = 0;
			_blendedRenderableHead = null;
			_opaqueRenderableHead = null;
			_entityHead = null;
			_renderableListItemPool.freeAll();
			_entityListItemPool.freeAll();
			_skyBox = null;
			if (_numLights > 0) {
				_lights = []; _numLights = 0; }
			if (_numDirectionalLights > 0) {
				_directionalLights = []; _numDirectionalLights = 0; }
			if (_numPointLights > 0) {
				_pointLights = []; _numPointLights = 0; }
			if (_numLightProbes > 0) {
				_lightProbes = []; _numLightProbes = 0; }
		}
		
		/**
		 * Returns true if the current node is at least partly in the frustum. If so, the partition node knows to pass on the traverser to its children.
		 *
		 * @param node The Partition3DNode object to frustum-test.
		 */
		override public function enterNode(node:NodeBase):Bool
		{
			var enter:Bool = PartitionTraverser._collectionMark != node._collectionMark && node.isInFrustum(_cullPlanes, _numCullPlanes);
			node._collectionMark = PartitionTraverser._collectionMark;
			return enter;
		}
		
		/**
		 * Adds a skybox to the potentially visible objects.
		 * @param renderable The skybox to add.
		 */
		override public function applySkyBox(renderable:IRenderable):Void
		{
			_skyBox = renderable;
		}
		
		/**
		 * Adds an IRenderable object to the potentially visible objects.
		 * @param renderable The IRenderable object to add.
		 */
		override public function applyRenderable(renderable:IRenderable):Void
		{
			var material:MaterialBase;
			var entity:Entity = renderable.sourceEntity;
			if (renderable.mouseEnabled)
				++_numMouseEnableds;
			_numTriangles += renderable.numTriangles;
			material = renderable.material;

			if (material!=null) {
				var item:RenderableListItem = _renderableListItemPool.getItem();
				item.renderable = renderable;
				item.materialId = material._uniqueId;
				item.renderOrderId = material._renderOrderId;
				item.cascaded = false;
				var dx:Float = _entryPoint.x - entity.x;
				var dy:Float = _entryPoint.y - entity.y;
				var dz:Float = _entryPoint.z - entity.z;
				// project onto camera's z-axis
				item.zIndex = dx*_cameraForward.x + dy*_cameraForward.y + dz*_cameraForward.z + entity.zOffset;
				item.renderSceneTransform = renderable.getRenderSceneTransform(_camera);
				if (material.requiresBlending) {
					item.next = _blendedRenderableHead;
					_blendedRenderableHead = item;
				} else {
					item.next = _opaqueRenderableHead;
					_opaqueRenderableHead = item;
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function applyEntity(entity:Entity):Void
		{
			++_numEntities;
			
			var item:EntityListItem = _entityListItemPool.getItem();
			item.entity = entity;
			
			item.next = _entityHead;
			_entityHead = item;
		}
		
		/**
		 * Adds a light to the potentially visible objects.
		 * @param light The light to add.
		 */
		override public function applyUnknownLight(light:LightBase):Void
		{
			_lights[_numLights++] = light;
		}
		
		override public function applyDirectionalLight(light:DirectionalLight):Void
		{
			_lights[_numLights++] = light;
			_directionalLights[_numDirectionalLights++] = light;
		}
		
		override public function applyPointLight(light:PointLight):Void
		{
			_lights[_numLights++] = light;
			_pointLights[_numPointLights++] = light;
		}
		
		override public function applyLightProbe(light:LightProbe):Void
		{
			_lights[_numLights++] = light;
			_lightProbes[_numLightProbes++] = light;
		}
		
		/**
		 * The total number of triangles collected, and which will be pushed to the render engine.
		 */
		public var numTriangles(get, null) : UInt;
		public function get_numTriangles() : UInt
		{
			return _numTriangles;
		}
		
		/**
		 * Cleans up any data at the end of a frame.
		 */
		public function cleanUp():Void
		{
		}
	}

