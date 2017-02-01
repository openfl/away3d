package away3d.library.utils;

import away3d.library.assets.IAsset;

import openfl.Vector;

class Asset3DLibraryIterator
{
	public var currentAsset(get, never):IAsset;
	public var numAssets(get, never):Int;
	
	private var _assets:Vector<IAsset>;
	private var _filtered:Vector<IAsset>;
	private var _idx:Int;
	
	public function new(assets:Vector<IAsset>, assetTypeFilter:String, namespaceFilter:String, filterFunc:Dynamic -> Dynamic)
	{
		_assets = assets;
		filter(assetTypeFilter, namespaceFilter, filterFunc);
	}
	
	private function get_currentAsset():IAsset
	{
		// Return current, or null if no current
		return ((_idx < _filtered.length))?
			_filtered[_idx] : null;
	}
	
	private function get_numAssets():Int
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
	
	public function setIndex(index:Int):Void
	{
		_idx = index;
	}
	
	private function filter(assetTypeFilter:String, namespaceFilter:String, filterFunc:Dynamic -> Dynamic):Void
	{
		if (assetTypeFilter != null || namespaceFilter != null || filterFunc != null) {
			var idx:Int;
			var asset:IAsset;
			
			idx = 0;
			_filtered = new Vector<IAsset>();
			
			for (asset in _assets) {
				// Skip this assets if filtering on type and this is wrong type
				if (assetTypeFilter != null && asset.assetType != assetTypeFilter)
					continue;
				
				// Skip this asset if filtering on namespace and this is wrong namespace
				if (namespaceFilter != null && asset.assetNamespace != namespaceFilter)
					continue;
				
				if (filterFunc != null && filterFunc(asset) == null)
					continue;
				
				_filtered[idx++] = asset;
			}
		} else {
			_filtered = _assets;
		}
	}
}