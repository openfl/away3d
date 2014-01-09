package away3d.core.partition;

	//import away3d.arcane;
	import away3d.entities.Entity;
	
	//use namespace arcane;
	
	class ViewVolumePartition extends Partition3D
	{
		public function new()
		{
			super(new ViewVolumeRootNode());
		}
		
		override public function markForUpdate(entity:Entity):Void
		{
			// ignore if static, will be handled separately by visibility list
			if (!entity.staticNode)
				super.markForUpdate(entity);
		}
		
		/**
		 * Adds a view volume to provide visibility info for a given region.
		 */
		public function addViewVolume(viewVolume:ViewVolume):Void
		{
			ViewVolumeRootNode(_rootNode).addViewVolume(viewVolume);
		}
		
		public function removeViewVolume(viewVolume:ViewVolume):Void
		{
			ViewVolumeRootNode(_rootNode).removeViewVolume(viewVolume);
		}
		
		/**
		 * A dynamic grid to be able to determine visibility of dynamic objects. If none is provided, dynamic objects are only frustum-culled.
		 * If provided, ViewVolumes need to have visible grid cells assigned from the same DynamicGrid instance.
		 */
		public var dynamicGrid(get, set) : DynamicGrid;
		public function get_dynamicGrid() : DynamicGrid
		{
			return ViewVolumeRootNode(_rootNode).dynamicGrid;
		}
		
		public function set_dynamicGrid(value:DynamicGrid) : DynamicGrid
		{
			ViewVolumeRootNode(_rootNode).dynamicGrid = value;
		}
	}

