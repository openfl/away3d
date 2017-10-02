package away3d.core.partition;

import away3d.entities.Entity;

class ViewVolumePartition extends Partition3D
{
	public var dynamicGrid(get, set):DynamicGrid;
	
	public function new()
	{
		super(new ViewVolumeRootNode());
	}
	
	override private function markForUpdate(entity:Entity):Void
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
		cast(_rootNode, ViewVolumeRootNode).addViewVolume(viewVolume);
	}
	
	public function removeViewVolume(viewVolume:ViewVolume):Void
	{
		cast(_rootNode, ViewVolumeRootNode).removeViewVolume(viewVolume);
	}
	
	/**
	 * A dynamic grid to be able to determine visibility of dynamic objects. If none is provided, dynamic objects are only frustum-culled.
	 * If provided, ViewVolumes need to have visible grid cells assigned from the same DynamicGrid instance.
	 */
	private function get_dynamicGrid():DynamicGrid
	{
		return cast(_rootNode, ViewVolumeRootNode).dynamicGrid;
	}
	
	private function set_dynamicGrid(value:DynamicGrid):DynamicGrid
	{
		cast(_rootNode, ViewVolumeRootNode).dynamicGrid = value;
		return value;
	}
}