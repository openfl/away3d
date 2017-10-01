package away3d.library.assets;

import openfl.display.BitmapData;

/**
 * BitmapDataResource is a wrapper for loaded BitmapData, allowing it to be used uniformly as a resource when
 * loading, parsing, and listing/resolving dependencies.
 */
class BitmapDataAsset extends NamedAssetBase implements IAsset
{
	public var bitmapData(get, set):BitmapData;
	public var assetType(get, never):String;
	
	private var _bitmapData:BitmapData;
	
	/**
	 * Creates a new BitmapDataResource object.
	 * @param bitmapData An optional BitmapData object to use as the resource data.
	 */
	public function new(bitmapData:BitmapData = null)
	{
		_bitmapData = bitmapData;
		super();
	}
	
	/**
	 * The bitmapData to be treated as a resource.
	 */
	private function get_bitmapData():BitmapData
	{
		return _bitmapData;
	}
	
	private function set_bitmapData(value:BitmapData):BitmapData
	{
		_bitmapData = value;
		return value;
	}
	
	private function get_assetType():String
	{
		return Asset3DType.TEXTURE;
	}
	
	/**
	 * Cleans up any resources used by the current object.
	 */
	public function dispose():Void
	{
		_bitmapData.dispose();
	}
}