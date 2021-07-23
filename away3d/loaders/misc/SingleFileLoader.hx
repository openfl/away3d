package away3d.loaders.misc;

import away3d.events.Asset3DEvent;
import away3d.events.LoaderEvent;
import away3d.events.ParserEvent;
import away3d.loaders.parsers.ImageParser;
import away3d.loaders.parsers.ParserBase;
import away3d.loaders.parsers.ParserDataFormat;

import openfl.errors.Error;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IOErrorEvent;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;
import openfl.Vector;

/**
 * The SingleFileLoader is used to load a single file, as part of a resource.
 *
 * While SingleFileLoader can be used directly, e.g. to create a third-party asset
 * management system, it's recommended to use any of the classes Loader3D, AssetLoader
 * and Asset3DLibrary instead in most cases.
 *
 * @see away3d.loading.Loader3D
 * @see away3d.loading.AssetLoader
 * @see away3d.loading.Asset3DLibrary
 */
class SingleFileLoader extends EventDispatcher
{
	private var _parser:ParserBase;
	private var _req:URLRequest;
	private var _fileExtension:String;
	private var _fileName:String;
	private var _loadAsRawData:Bool;
	private var _materialMode:UInt;
	private var _data:Dynamic;
	
	// Image parser only parser that is added by default, to save file size.
	private static var _parsers:Vector<Class<ParserBase>> = Vector.ofArray(cast [ ImageParser ]);
	
	/**
	 * Creates a new SingleFileLoader object.
	 */
	public function new(materialMode:UInt = 0)
	{
		super();
		_materialMode = materialMode;
	}
	
	public var url(get, null):String;
	
	private function get_url():String
	{
		return _req != null ? _req.url : '';
	}
	
	public var data(get, null):Dynamic;
	
	private function get_data():Dynamic
	{
		return _data;
	}
	
	public var loadAsRawData(get, null):Bool;
	
	private function get_loadAsRawData():Bool
	{
		return _loadAsRawData;
	}
	
	public static function enableParser(parser:Class<ParserBase>):Void
	{
		if (_parsers.indexOf(parser) < 0)
			_parsers.push(parser);
	}
	
	public static function enableParsers(parsers:Array<Dynamic>):Void
	{
		for (pc in parsers)
			enableParser(pc);
	}
	
	/**
	 * Load a resource from a file.
	 *
	 * @param urlRequest The URLRequest object containing the URL of the object to be loaded.
	 * @param parser An optional parser object that will translate the loaded data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.
	 */
	public function load(urlRequest:URLRequest, parser:ParserBase = null, loadAsRawData:Bool = false):Void
	{
		var urlLoader:URLLoader;
		var dataFormat:URLLoaderDataFormat = null;
		
		_loadAsRawData = loadAsRawData;
		_req = urlRequest;
		decomposeFilename(_req.url);
		
		if (_loadAsRawData) {
			// Always use binary for raw data loading
			dataFormat = URLLoaderDataFormat.BINARY;
		} else {
			if (parser != null)
				_parser = parser;
			
			if (_parser == null)
				_parser = getParserFromSuffix();
			
			if (_parser != null) {
				switch (_parser.dataFormat) {
					case ParserDataFormat.BINARY:
						dataFormat = URLLoaderDataFormat.BINARY;
					case ParserDataFormat.PLAIN_TEXT:
						dataFormat = URLLoaderDataFormat.TEXT;
				}
				
			} else {
				// Always use BINARY for unknown file formats. The thorough
				// file type check will determine format after load, and if
				// binary, a text load will have broken the file data.
				dataFormat = URLLoaderDataFormat.BINARY;
			}
		}
		
		urlLoader = new URLLoader();
		urlLoader.dataFormat = dataFormat;
		urlLoader.addEventListener(Event.COMPLETE, handleUrlLoaderComplete);
		urlLoader.addEventListener(IOErrorEvent.IO_ERROR, handleUrlLoaderError);
		urlLoader.load(urlRequest);
	}
	
	/**
	 * Loads a resource from already loaded data.
	 * @param data The data to be parsed. Depending on the parser type, this can be a ByteArray, String or XML.
	 * @param uri The identifier (url or id) of the object to be loaded, mainly used for resource management.
	 * @param parser An optional parser object that will translate the data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.
	 */
	public function parseData(data:Dynamic, parser:ParserBase = null, req:URLRequest = null):Void
	{
		if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(data, Class))
			data = Type.createInstance(data, []);
		
		if (parser != null)
			_parser = parser;
		
		_req = req;
		
		parse(data);
	}
	
	/**
	 * A reference to the parser that will translate the loaded data into a usable resource.
	 */
	public var parser(get, null):ParserBase;
	
	private function get_parser():ParserBase
	{
		return _parser;
	}
	
	/**
	 * A list of dependencies that need to be loaded and resolved for the loaded object.
	 */
	public var dependencies(get, never):Vector<ResourceDependency>;
	
	private function get_dependencies():Vector<ResourceDependency>
	{
		return _parser != null? _parser.dependencies : new Vector<ResourceDependency>();
	}
	
	/**
	 * Splits a url string into base and extension.
	 * @param url The url to be decomposed.
	 */
	private function decomposeFilename(url:String):Void
	{
		
		// Get rid of query string if any and extract suffix
		var base:String = (url.indexOf('?') > 0)? url.split('?')[0] : url;
		var i:Int = base.lastIndexOf('.');
		_fileExtension = base.substr(i + 1).toLowerCase();
		_fileName = base.substr(0, i);
	}
	
	/**
	 * Guesses the parser to be used based on the file extension.
	 * @return An instance of the guessed parser.
	 */
	private function getParserFromSuffix():ParserBase
	{
		var len:UInt = _parsers.length;
		
		// go in reverse order to allow application override of default parser added in Away3D proper
		var i:Int = len - 1;
		while (i >= 0) {
			if (Reflect.callMethod(_parsers[i], Reflect.field(_parsers[i], "supportsType"), [_fileExtension]))
				return Type.createInstance(_parsers[i], []);
			i--;
		}
		
		return null;
	}
	
	/**
	 * Guesses the parser to be used based on the file contents.
	 * @param data The data to be parsed.
	 * @param uri The url or id of the object to be parsed.
	 * @return An instance of the guessed parser.
	 */
	private function getParserFromData(data:Dynamic):ParserBase
	{
		var len:UInt = _parsers.length;
		
		// go in reverse order to allow application override of default parser added in Away3D proper
		var i:Int = len - 1;
		while (i >= 0) {
			if (Reflect.callMethod(_parsers[i], Reflect.field(_parsers[i], "supportsData"), [data]))
				return Type.createInstance(_parsers[i],[]);
			i--;
		}
		
		return null;
	}
	
	/**
	 * Cleanups
	 */
	private function removeListeners(urlLoader:URLLoader):Void
	{
		urlLoader.removeEventListener(Event.COMPLETE, handleUrlLoaderComplete);
		urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, handleUrlLoaderError);
	}
	
	/**
	 * Called when loading of a file has failed
	 */
	private function handleUrlLoaderError(event:IOErrorEvent):Void
	{
		var urlLoader:URLLoader = cast(event.currentTarget, URLLoader);
		removeListeners(urlLoader);
		
		if (hasEventListener(LoaderEvent.LOAD_ERROR))
			dispatchEvent(new LoaderEvent(LoaderEvent.LOAD_ERROR, _req.url, true, event.text));
	}
	
	/**
	 * Called when loading of a file is complete
	 */
	private function handleUrlLoaderComplete(event:Event):Void
	{
		var urlLoader:URLLoader = cast(event.currentTarget, URLLoader);
		removeListeners(urlLoader);
		
		_data = urlLoader.data;
		
		if (_loadAsRawData) {
			// No need to parse this data, which should be returned as is
			dispatchEvent(new LoaderEvent(LoaderEvent.DEPENDENCY_COMPLETE));
		} else
			parse(_data);
	}
	
	/**
	 * Initiates parsing of the loaded data.
	 * @param data The data to be parsed.
	 */
	private function parse(data:Dynamic):Void
	{
		// If no parser has been defined, try to find one by letting
		// all plugged in parsers inspect the actual data.
		if (_parser == null)
			_parser = getParserFromData(data);
		
		if (_parser != null) {
			_parser.addEventListener(ParserEvent.READY_FOR_DEPENDENCIES, onReadyForDependencies);
			_parser.addEventListener(ParserEvent.PARSE_ERROR, onParseError);
			_parser.addEventListener(ParserEvent.PARSE_COMPLETE, onParseComplete);
			_parser.addEventListener(Asset3DEvent.TEXTURE_SIZE_ERROR, onTextureSizeError);
			_parser.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.TEXTURE_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.CONTAINER_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.GEOMETRY_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.MATERIAL_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.MESH_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.ENTITY_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.SKELETON_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
			
			if (_req != null && _req.url != null)
				_parser._fileName = _req.url;
			_parser.materialMode = _materialMode;
			_parser.parseAsync(data);
		} else {
			var msg:String = "No parser defined. To enable all parsers for auto-detection, use Parsers.enableAllBundled()";
			if (hasEventListener(LoaderEvent.LOAD_ERROR))
				this.dispatchEvent(new LoaderEvent(LoaderEvent.LOAD_ERROR, "", true, msg));
			else
				throw new Error(msg);
		}
	}
	
	private function onParseError(event:ParserEvent):Void
	{
		if (hasEventListener(ParserEvent.PARSE_ERROR))
			dispatchEvent(event.clone());
	}
	
	private function onReadyForDependencies(event:ParserEvent):Void
	{
		dispatchEvent(event.clone());
	}
	
	private function onAssetComplete(event:Asset3DEvent):Void
	{
		this.dispatchEvent(event.clone());
	}
	
	private function onTextureSizeError(event:Asset3DEvent):Void
	{
		this.dispatchEvent(event.clone());
	}
	
	/**
	 * Called when parsing is complete.
	 */
	private function onParseComplete(event:ParserEvent):Void
	{
		this.dispatchEvent(new LoaderEvent(LoaderEvent.DEPENDENCY_COMPLETE, this.url)); //dispatch in front of removing listeners to allow any remaining asset events to propagate
		
		_parser.removeEventListener(ParserEvent.READY_FOR_DEPENDENCIES, onReadyForDependencies);
		_parser.removeEventListener(ParserEvent.PARSE_COMPLETE, onParseComplete);
		_parser.removeEventListener(ParserEvent.PARSE_ERROR, onParseError);
		_parser.removeEventListener(Asset3DEvent.TEXTURE_SIZE_ERROR, onTextureSizeError);
		_parser.removeEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.TEXTURE_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.CONTAINER_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.GEOMETRY_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.MATERIAL_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.MESH_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.ENTITY_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.SKELETON_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
	}
}