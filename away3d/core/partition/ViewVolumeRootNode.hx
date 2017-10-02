package away3d.core.partition;

import away3d.core.traverse.PartitionTraverser;
import away3d.entities.Entity;

import openfl.geom.Vector3D;
import openfl.Vector;

class ViewVolumeRootNode extends NodeBase
{
	public var dynamicGrid(get, set):DynamicGrid;
	
	// todo: provide a better data structure to find the containing view volume faster
	private var _viewVolumes:Vector<ViewVolume>;
	private var _activeVolume:ViewVolume;
	private var _dynamicGrid:DynamicGrid;
	
	public function new()
	{
		_viewVolumes = new Vector<ViewVolume>();
		super();
	}
	
	override private function set_showDebugBounds(value:Bool):Bool
	{
		super.showDebugBounds = value;
		if (_dynamicGrid != null)
			_dynamicGrid.showDebugBounds = true;
		return value;
	}
	
	override public function findPartitionForEntity(entity:Entity):NodeBase
	{
		return (_dynamicGrid != null)? _dynamicGrid.findPartitionForEntity(entity) : this;
	}
	
	private function get_dynamicGrid():DynamicGrid
	{
		return _dynamicGrid;
	}
	
	private function set_dynamicGrid(value:DynamicGrid):DynamicGrid
	{
		_dynamicGrid = value;
		_dynamicGrid.showDebugBounds = showDebugBounds;
		return value;
	}
	
	public function addViewVolume(viewVolume:ViewVolume):Void
	{
		if (_viewVolumes.indexOf(viewVolume) == -1)
			_viewVolumes.push(viewVolume);
		
		addNode(viewVolume);
	}
	
	public function removeViewVolume(viewVolume:ViewVolume):Void
	{
		var index:Int = _viewVolumes.indexOf(viewVolume);
		if (index >= 0)
			_viewVolumes.splice(index, 1);
	}
	
	override public function acceptTraverser(traverser:PartitionTraverser):Void
	{
		if (!(_activeVolume != null && _activeVolume.contains(traverser.entryPoint))) {
			var volume:ViewVolume = getVolumeContaining(traverser.entryPoint);
			
			if (volume == null)
				trace("WARNING: No view volume found for the current position.");
			
			// keep the active one if no volume is found (it may be just be a small error)
			else if (volume != _activeVolume) {
				if (_activeVolume != null)
					_activeVolume._active = false;
				_activeVolume = volume;
				if (_activeVolume != null)
					_activeVolume._active = true;
			}
		}
		
		super.acceptTraverser(traverser);
	}
	
	private function getVolumeContaining(entryPoint:Vector3D):ViewVolume
	{
		var numVolumes:Int = _viewVolumes.length;
		for (i in 0...numVolumes) {
			if (_viewVolumes[i].contains(entryPoint))
				return _viewVolumes[i];
		}
		
		return null;
	}
}