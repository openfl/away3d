package away3d.loaders.misc;

class AssetLoaderContext
{
	public static inline var UNDEFINED:UInt = 0;
	public static inline var SINGLEPASS_MATERIALS:UInt = 1;
	public static inline var MULTIPASS_MATERIALS:UInt = 2;
	private var _includeDependencies:Bool;
	private var _dependencyBaseUrl:String;
	private var _embeddedDataByUrl:Map<String, Dynamic>;
	private var _remappedUrls:Map<String, String>;
	private var _materialMode:UInt;
	
	private var _overrideAbsPath:Bool;
	private var _overrideFullUrls:Bool;
	
	/**
	 * AssetLoaderContext provides configuration for the AssetLoader load() and parse() operations.
	 * Use it to configure how (and if) dependencies are loaded, or to map dependency URLs to
	 * embedded data.
	 *
	 * @see away3d.loading.AssetLoader
	 */
	public function new(includeDependencies:Bool = true, dependencyBaseUrl:String = null)
	{
		_overrideAbsPath = false;
		_overrideFullUrls = false;
		_includeDependencies = includeDependencies;
		_dependencyBaseUrl = dependencyBaseUrl != null ? dependencyBaseUrl : '';
		_embeddedDataByUrl = new Map<String, Dynamic>();
		_remappedUrls = new Map<String, String>();
		_materialMode = UNDEFINED;
	}
	
	/**
	 * Defines whether dependencies (all files except the one at the URL given to the load() or
	 * parseData() operations) should be automatically loaded. Defaults to true.
	 */
	public var includeDependencies(get, set):Bool;
	private function get_includeDependencies():Bool
	{
		return _includeDependencies;
	}
	
	private function set_includeDependencies(val:Bool):Bool
	{
		_includeDependencies = val;
		return val;
	}
	
	/**
	 * MaterialMode defines, if the Parser should create SinglePass or MultiPass Materials
	 * Options:
	 * 0 (Default / undefined) - All Parsers will create SinglePassMaterials, but the AWD2.1parser will create Materials as they are defined in the file
	 * 1 (Force SinglePass) - All Parsers create SinglePassMaterials
	 * 2 (Force MultiPass) - All Parsers will create MultiPassMaterials
	 * 
	 */
	public var materialMode(get, set):UInt;
	private function get_materialMode():UInt
	{
		return _materialMode;
	}
	
	private function set_materialMode(materialMode:UInt):UInt
	{
		_materialMode = materialMode;
		return _materialMode;
	}
	
	/**
	 * A base URL that will be prepended to all relative dependency URLs found in a loaded resource.
	 * Absolute paths will not be affected by the value of this property.
	 */
	public var dependencyBaseUrl(get, set):String;
	private function get_dependencyBaseUrl():String
	{
		return _dependencyBaseUrl;
	}
	
	private function set_dependencyBaseUrl(val:String):String
	{
		_dependencyBaseUrl = val;
		return val;
	}
	
	/**
	 * Defines whether absolute paths (defined as paths that begin with a "/") should be overridden
	 * with the dependencyBaseUrl defined in this context. If this is true, and the base path is
	 * "base", /path/to/asset.jpg will be resolved as base/path/to/asset.jpg.
	 */
	public var overrideAbsolutePaths(get, set):Bool;
	private function get_overrideAbsolutePaths():Bool
	{
		return _overrideAbsPath;
	}
	
	private function set_overrideAbsolutePaths(val:Bool):Bool
	{
		_overrideAbsPath = val;
		return val;
	}
	
	/**
	 * Defines whether "full" URLs (defined as a URL that includes a scheme, e.g. http://) should be
	 * overridden with the dependencyBaseUrl defined in this context. If this is true, and the base
	 * path is "base", http://example.com/path/to/asset.jpg will be resolved as base/path/to/asset.jpg.
	 */
	public var overrideFullURLs(get, set):Bool;
	private function get_overrideFullURLs():Bool
	{
		return _overrideFullUrls;
	}
	
	private function set_overrideFullURLs(val:Bool):Bool
	{
		_overrideFullUrls = val;
		return val;
	}
	
	/**
	 * Map a URL to another URL, so that files that are referred to by the original URL will instead
	 * be loaded from the new URL. Use this when your file structure does not match the one that is
	 * expected by the loaded file.
	 *
	 * @param originalUrl The original URL which is referenced in the loaded resource.
	 * @param newUrl The URL from which Away3D should load the resource instead.
	 *
	 * @see mapUrlToData()
	 */
	public function mapUrl(originalUrl:String, newUrl:String):Void
	{
		_remappedUrls[originalUrl] = newUrl;
	}
	
	/**
	 * Map a URL to embedded data, so that instead of trying to load a dependency from the URL at
	 * which it's referenced, the dependency data will be retrieved straight from the memory instead.
	 *
	 * @param originalUrl The original URL which is referenced in the loaded resource.
	 * @param data The embedded data. Can be ByteArray or a class which can be used to create a bytearray.
	 */
	public function mapUrlToData(originalUrl:String, data:Dynamic):Void
	{
		_embeddedDataByUrl[originalUrl] = data;
	}
	
	/**
	 * @private
	 * Defines whether embedded data has been mapped to a particular URL.
	 */
	@:allow(away3d) private function hasDataForUrl(url:String):Bool
	{
		return _embeddedDataByUrl.exists(url);
	}
	
	/**
	 * @private
	 * Returns embedded data for a particular URL.
	 */
	@:allow(away3d) private function getDataForUrl(url:String):Dynamic
	{
		return _embeddedDataByUrl[url];
	}
	
	/**
	 * @private
	 * Defines whether a replacement URL has been mapped to a particular URL.
	 */
	@:allow(away3d) private function hasMappingForUrl(url:String):Bool
	{
		return _remappedUrls.exists(url);
	}
	
	/**
	 * @private
	 * Returns new (replacement) URL for a particular original URL.
	 */
	@:allow(away3d) private function getRemappedUrl(originalUrl:String):String
	{
		return _remappedUrls[originalUrl];
	}
}