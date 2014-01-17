/**
 * ResourceDependency represents the data required to load, parse and resolve additional files ("dependencies")
 * required by a parser, used by ResourceLoadSession.
 *
 */
package away3d.loaders.misc;


import flash.Vector;
import away3d.library.assets.IAsset;
import away3d.loaders.parsers.ParserBase;
import flash.net.URLRequest;

class ResourceDependency {
    public var id(get_id, never):String;
    public var assets(get_assets, never):Vector<IAsset>;
    public var dependencies(get_dependencies, never):Vector<ResourceDependency>;
    public var request(get_request, never):URLRequest;
    public var retrieveAsRawData(get_retrieveAsRawData, never):Bool;
    public var suppresAssetEvents(get_suppresAssetEvents, never):Bool;
    public var data(get_data, never):Dynamic;
    public var parentParser(get_parentParser, never):ParserBase;

    private var _id:String;
    private var _req:URLRequest;
    private var _assets:Vector<IAsset>;
    private var _parentParser:ParserBase;
    private var _data:Dynamic;
    private var _retrieveAsRawData:Bool;
    private var _suppressAssetEvents:Bool;
    private var _dependencies:Vector<ResourceDependency>;
    public var loader:SingleFileLoader;
    public var success:Bool;

    public function new(id:String, req:URLRequest, data:Dynamic, parentParser:ParserBase, retrieveAsRawData:Bool = false, suppressAssetEvents:Bool = false) {
        _id = id;
        _req = req;
        _parentParser = parentParser;
        _data = data;
        _retrieveAsRawData = retrieveAsRawData;
        _suppressAssetEvents = suppressAssetEvents;
        _assets = new Vector<IAsset>();
        _dependencies = new Vector<ResourceDependency>();
    }

    public function get_id():String {
        return _id;
    }

    public function get_assets():Vector<IAsset> {
        return _assets;
    }

    public function get_dependencies():Vector<ResourceDependency> {
        return _dependencies;
    }

    public function get_request():URLRequest {
        return _req;
    }

    public function get_retrieveAsRawData():Bool {
        return _retrieveAsRawData;
    }

    public function get_suppresAssetEvents():Bool {
        return _suppressAssetEvents;
    }

/**
	 * The data containing the dependency to be parsed, if the resource was already loaded.
	 */

    public function get_data():Dynamic {
        return _data;
    }

/**
	 * @private
	 * Method to set data after having already created the dependency object, e.g. after load.
	 */

    public function setData(data:Dynamic):Void {
        _data = data;
    }

/**
	 * The parser which is dependent on this ResourceDependency object.
	 */

    public function get_parentParser():ParserBase {
        return _parentParser;
    }

/**
	 * Resolve the dependency when it's loaded with the parent parser. For example, a dependency containing an
	 * ImageResource would be assigned to a Mesh instance as a BitmapMaterial, a scene graph object would be added
	 * to its intended parent. The dependency should be a member of the dependencies property.
	 */

    public function resolve():Void {
        if (_parentParser != null) _parentParser.resolveDependency(this);
    }

/**
	 * Resolve a dependency failure. For example, map loading failure from a 3d file
	 */

    public function resolveFailure():Void {
        if (_parentParser != null) _parentParser.resolveDependencyFailure(this);
    }

/**
	 * Resolve the dependencies name
	 */

    public function resolveName(asset:IAsset):String {
        if (_parentParser != null) return _parentParser.resolveDependencyName(this, asset);
        return asset.name;
    }

}

