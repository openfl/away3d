package away3d.core.partition;

	//import away3d.arcane;
	import away3d.core.traverse.PartitionTraverser;
	import away3d.entities.Entity;
	
	import flash.geom.Vector3D;
	
	//use namespace arcane;
	
	class ViewVolumeRootNode extends NodeBase
	{
		// todo: provide a better data structure to find the containing view volume faster
		var _viewVolumes:Array<ViewVolume>;
		var _activeVolume:ViewVolume;
		var _dynamicGrid:DynamicGrid;
		
		public function new()
		{
			_viewVolumes = new Array<ViewVolume>();
		}
		
		public var showDebugBounds(null, set) : Void;
		
		override public function set_showDebugBounds(value:Bool) : Void
		{
			super.showDebugBounds = value;
			if (_dynamicGrid)
				_dynamicGrid.showDebugBounds = true;
		}
		
		override public function findPartitionForEntity(entity:Entity):NodeBase
		{
			return _dynamicGrid? _dynamicGrid.findPartitionForEntity(entity) : this;
		}
		
		public var dynamicGrid(get, set) : DynamicGrid;
		
		public function get_dynamicGrid() : DynamicGrid
		{
			return _dynamicGrid;
		}
		
		public function set_dynamicGrid(value:DynamicGrid) : DynamicGrid
		{
			_dynamicGrid = value;
			_dynamicGrid.showDebugBounds = showDebugBounds;
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
			if (!(_activeVolume && _activeVolume.contains(traverser.entryPoint))) {
				var volume:ViewVolume = getVolumeContaining(traverser.entryPoint);
				
				if (!volume)
					trace("WARNING: No view volume found for the current position.");
				
				// keep the active one if no volume is found (it may be just be a small error)
				else if (volume != _activeVolume) {
					if (_activeVolume)
						_activeVolume._active = false;
					_activeVolume = volume;
					if (_activeVolume)
						_activeVolume._active = true;
				}
			}
			
			super.acceptTraverser(traverser);
		}
		
		private function getVolumeContaining(entryPoint:Vector3D):ViewVolume
		{
			var numVolumes:UInt = _viewVolumes.length;
			// For loop conversion - 			for (var i:UInt = 0; i < numVolumes; ++i)
			var i:UInt = 0;
			for (i in 0...numVolumes) {
				if (_viewVolumes[i].contains(entryPoint))
					return _viewVolumes[i];
			}
			
			return null;
		}
	}

