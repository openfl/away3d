package away3d.loaders.misc;

import away3d.library.assets.IAsset;
import away3d.loaders.parsers.ParserBase;

import openfl.net.URLRequest;
import openfl.Vector;

/**
 * ResourceDependency represents the data required to load, parse and resolve additional files ("dependencies")
 * required by a parser, used by ResourceLoadSession.
 *
 */
class ResourceDependency
{
	private var _id:String;
	private var _req:URLRequest;
	private var _assets:Vector<IAsset>;
	private var _parentParser:ParserBase;
	private var _data:Dynamic;
	private var _retrieveAsRawData:Bool;
	private var _suppressAsset3DEvents:Bool;
	private var _dependencies:Vector<ResourceDependency>;
	
	@:allow(away3d) private var loader:SingleFileLoader;
	@:allow(away3d) private var success:Bool;
	
	public function new(id:String, req:URLRequest, data:Dynamic, parentParser:ParserBase, retrieveAsRawData:Bool = false, suppressAsset3DEvents:Bool = false)
	{
		_id = id;
		_req = req;
		_parentParser = parentParser;
		_data = data;
		_retrieveAsRawData = retrieveAsRawData;
		_suppressAsset3DEvents = suppressAsset3DEvents;
		
		_assets = new Vector<IAsset>();
		_dependencies = new Vector<ResourceDependency>();
	}
	
	public var id(get, null):String;		
	private function get_id():String
	{
		return _id;
	}
	
	public var assets(get, null):Vector<IAsset>;		
	private function get_assets():Vector<IAsset>
	{
		return _assets;
	}
	
	public var dependencies(get, null):Vector<ResourceDependency>;		
	private function get_dependencies():Vector<ResourceDependency>
	{
		return _dependencies;
	}
	
	public var request(get, null):URLRequest;	
	private function get_request():URLRequest
	{
		return _req;
	}
	
	public var retrieveAsRawData(get, null):Bool;		
	private function get_retrieveAsRawData():Bool
	{
		return _retrieveAsRawData;
	}
	
	public var suppresAsset3DEvents(get, null):Bool;		
	private function get_suppresAsset3DEvents():Bool
	{
		return _suppressAsset3DEvents;
	}
	
	/**
	 * The data containing the dependency to be parsed, if the resource was already loaded.
	 */
	public var data(get, null):Dynamic;
	private function get_data():Dynamic
	{
		return _data;
	}
	
	/**
	 * @private
	 * Method to set data after having already created the dependency object, e.g. after load.
	 */
	@:allow(away3d) private function setData(data:Dynamic):Void
	{
		_data = data;
	}
	
	/**
	 * The parser which is dependent on this ResourceDependency object.
	 */
	public var parentParser(get, null):ParserBase;
	private function get_parentParser():ParserBase
	{
		return _parentParser;
	}
	
	/**
	 * Resolve the dependency when it's loaded with the parent parser. For example, a dependency containing an
	 * ImageResource would be assigned to a Mesh instance as a BitmapMaterial, a scene graph object would be added
	 * to its intended parent. The dependency should be a member of the dependencies property.
	 */
	public function resolve():Void
	{
		if (_parentParser != null)
			_parentParser.resolveDependency(this);
	}
	
	/**
	 * Resolve a dependency failure. For example, map loading failure from a 3d file
	 */
	public function resolveFailure():Void
	{
		if (_parentParser != null)
			_parentParser.resolveDependencyFailure(this);
	}
	
	/**
	 * Resolve the dependencies name
	 */
	public function resolveName(asset:IAsset):String
	{
		if (_parentParser != null)
			return _parentParser.resolveDependencyName(this, asset);
		return asset.name;
	}

}