package away3d.loaders.misc;


import haxe.ds.StringMap;
class AssetLoaderContext {
    public var includeDependencies(get_includeDependencies, set_includeDependencies):Bool;
    public var materialMode(get_materialMode, set_materialMode):Int;
    public var dependencyBaseUrl(get_dependencyBaseUrl, set_dependencyBaseUrl):String;
    public var overrideAbsolutePaths(get_overrideAbsolutePaths, set_overrideAbsolutePaths):Bool;
    public var overrideFullURLs(get_overrideFullURLs, set_overrideFullURLs):Bool;

    static public var UNDEFINED:Int = 0;
    static public var SINGLEPASS_MATERIALS:Int = 1;
    static public var MULTIPASS_MATERIALS:Int = 2;
    private var _includeDependencies:Bool;
    private var _dependencyBaseUrl:String;
    private var _embeddedDataByUrl:StringMap<Dynamic>;
    private var _remappedUrls:StringMap<String>;
    private var _materialMode:Int;
    private var _overrideAbsPath:Bool;
    private var _overrideFullUrls:Bool;
/**
	 * AssetLoaderContext provides configuration for the AssetLoader load() and parse() operations.
	 * Use it to configure how (and if) dependencies are loaded, or to map dependency URLs to
	 * embedded data.
	 *
	 * @see away3d.loading.AssetLoader
	 */

    public function new(includeDependencies:Bool = true, dependencyBaseUrl:String = null) {
        _includeDependencies = includeDependencies;
        _dependencyBaseUrl = dependencyBaseUrl ;
        if (_dependencyBaseUrl == null)_dependencyBaseUrl = "";
        _embeddedDataByUrl = new StringMap<Dynamic>();
        _remappedUrls = new StringMap<String>();
        _materialMode = UNDEFINED;
    }

/**
	 * Defines whether dependencies (all files except the one at the URL given to the load() or
	 * parseData() operations) should be automatically loaded. Defaults to true.
	 */

    public function get_includeDependencies():Bool {
        return _includeDependencies;
    }

    public function set_includeDependencies(val:Bool):Bool {
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

    public function get_materialMode():Int {
        return _materialMode;
    }

    public function set_materialMode(materialMode:Int):Int {
        _materialMode = materialMode;
        return materialMode;
    }

/**
	 * A base URL that will be prepended to all relative dependency URLs found in a loaded resource.
	 * Absolute paths will not be affected by the value of this property.
	 */

    public function get_dependencyBaseUrl():String {
        return _dependencyBaseUrl;
    }

    public function set_dependencyBaseUrl(val:String):String {
        _dependencyBaseUrl = val;
        return val;
    }

/**
	 * Defines whether absolute paths (defined as paths that begin with a "/") should be overridden
	 * with the dependencyBaseUrl defined in this context. If this is true, and the base path is
	 * "base", /path/to/asset.jpg will be resolved as base/path/to/asset.jpg.
	 */

    public function get_overrideAbsolutePaths():Bool {
        return _overrideAbsPath;
    }

    public function set_overrideAbsolutePaths(val:Bool):Bool {
        _overrideAbsPath = val;
        return val;
    }

/**
	 * Defines whether "full" URLs (defined as a URL that includes a scheme, e.g. http://) should be
	 * overridden with the dependencyBaseUrl defined in this context. If this is true, and the base
	 * path is "base", http://example.com/path/to/asset.jpg will be resolved as base/path/to/asset.jpg.
	 */

    public function get_overrideFullURLs():Bool {
        return _overrideFullUrls;
    }

    public function set_overrideFullURLs(val:Bool):Bool {
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

    public function mapUrl(originalUrl:String, newUrl:String):Void {
        _remappedUrls.set(originalUrl, newUrl);
    }

/**
	 * Map a URL to embedded data, so that instead of trying to load a dependency from the URL at
	 * which it's referenced, the dependency data will be retrieved straight from the memory instead.
	 *
	 * @param originalUrl The original URL which is referenced in the loaded resource.
	 * @param data The embedded data. Can be ByteArray or a class which can be used to create a bytearray.
	 */

    public function mapUrlToData(originalUrl:String, data:Dynamic):Void {
        _embeddedDataByUrl.set(originalUrl, data);
    }

/**
	 * @private
	 * Defines whether embedded data has been mapped to a particular URL.
	 */

    public function hasDataForUrl(url:String):Bool {
        return _embeddedDataByUrl.exists(url);
    }

/**
	 * @private
	 * Returns embedded data for a particular URL.
	 */

    public function getDataForUrl(url:String):Dynamic {
        return _embeddedDataByUrl.get(url);
    }

/**
	 * @private
	 * Defines whether a replacement URL has been mapped to a particular URL.
	 */

    public function hasMappingForUrl(url:String):Bool {
        return _remappedUrls.exists(url);
    }

/**
	 * @private
	 * Returns new (replacement) URL for a particular original URL.
	 */

    public function getRemappedUrl(originalUrl:String):String {
        return _remappedUrls.get(originalUrl);
    }

}

