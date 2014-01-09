package away3d.library.utils;

	import away3d.library.assets.IAsset;
	
	class AssetLibraryIterator
	{
		var _assets:Array<IAsset>;
		var _filtered:Array<IAsset>;
		
		var _idx:UInt;
		
		public function new(assets:Array<IAsset>, assetTypeFilter:String, namespaceFilter:String, filterFunc:IAsset->Bool)
		{
			_assets = assets;
			filter(assetTypeFilter, namespaceFilter, filterFunc);
		}
		
		public var currentAsset(get, null) : IAsset;
		
		public function get_currentAsset() : IAsset
		{
			// Return current, or null if no current
			return (_idx < _filtered.length)?
				_filtered[_idx] : null;
		}
		
		public var numAssets(get, null) : UInt;
		
		public function get_numAssets() : UInt
		{
			return _filtered.length;
		}
		
		public function next():IAsset
		{
			var next:IAsset = null;
			
			if (_idx < _filtered.length)
				next = _filtered[_idx];
			
			_idx++;
			
			return next;
		}
		
		public function reset():Void
		{
			_idx = 0;
		}
		
		public function setIndex(index:UInt):Void
		{
			_idx = index;
		}
		
		private function filter(assetTypeFilter:String, namespaceFilter:String, filterFunc:IAsset->Bool):Void
		{
			if (assetTypeFilter!="" || namespaceFilter!="") {
				var idx:UInt;
				var asset:IAsset;
				
				idx = 0;
				_filtered = new Array<IAsset>();
				
				for (asset in _assets) {
					// Skip this assets if filtering on type and this is wrong type
					if (assetTypeFilter!="" && asset.assetType != assetTypeFilter)
						continue;
					
					// Skip this asset if filtering on namespace and this is wrong namespace
					if (namespaceFilter!="" && asset.assetNamespace != namespaceFilter)
						continue;
					
					// Skip this asset if a filter func has been provided and it returns false
					if (filterFunc != null && !filterFunc(asset))
						continue;
					
					_filtered[idx++] = asset;
				}
			} else
				_filtered = _assets;
		}
	}

