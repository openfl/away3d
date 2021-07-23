package away3d.loaders;

import away3d.*;
import away3d.cameras.*;
import away3d.containers.*;
import away3d.entities.*;
import away3d.events.*;
import away3d.library.*;
import away3d.library.assets.*;
import away3d.lights.*;
import away3d.loaders.misc.*;
import away3d.loaders.parsers.*;
import away3d.primitives.*;

import openfl.events.*;
import openfl.net.*;
import openfl.Vector;

/**
 * Loader3D can load any file format that Away3D supports (or for which a third-party parser
 * has been plugged in) and be added directly to the scene. As assets are encountered
 * they are added to the Loader3D container. Assets that can not be displayed in the scene
 * graph (e.g. unused bitmaps/materials/skeletons etc) will be ignored.
 *
 * This provides a fast and easy way to load models (no need for event listeners) but is not
 * very versatile since many types of assets are ignored.
 *
 * Loader3D by default uses the Asset3DLibrary to load all assets, which means that they also
 * ends up in the library. To circumvent this, Loader3D can be configured to not use the
 * Asset3DLibrary in which case it will use the AssetLoader directly.
 *
 * @see away3d.loaders.AssetLoader
 * @see away3d.library.Asset3DLibrary
 */
class Loader3D extends ObjectContainer3D
{
	private var _loadingSessions:Vector<AssetLoader>;
	private var _useAssetLib:Bool;
	private var _assetLibId:String;
	
	public function new(useAsset3DLibrary:Bool = true, asset3DLibraryId:String = null)
	{
		super();
		
		_loadingSessions = new Vector<AssetLoader>();
		_useAssetLib = useAsset3DLibrary;
		_assetLibId = asset3DLibraryId;
	}
	
	/**
	 * Loads a file and (optionally) all of its dependencies.
	 *
	 * @param req The URLRequest object containing the URL of the file to be loaded.
	 * @param context An optional context object providing additional parameters for loading
	 * @param ns An optional namespace string under which the file is to be loaded, allowing the differentiation of two resources with identical assets
	 * @param parser An optional parser object for translating the loaded data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.
	 */
	public function load(req:URLRequest, context:AssetLoaderContext = null, ns:String = null, parser:ParserBase = null):AssetLoaderToken
	{
		var token:AssetLoaderToken;
		
		if (_useAssetLib) {
			var lib:Asset3DLibraryBundle;
			lib = Asset3DLibraryBundle.getInstance(_assetLibId);
			token = lib.load(req, context, ns, parser);
		} else {
			var loader:AssetLoader = new AssetLoader();
			_loadingSessions.push(loader);
			token = loader.load(req, context, ns, parser);
		}
		
		token.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
		token.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.TEXTURE_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.CONTAINER_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.GEOMETRY_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.MATERIAL_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.MESH_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.ENTITY_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.SKELETON_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
		
		// Error are handled separately (see documentation for addErrorHandler)
		token._loader.addErrorHandler(onLoadError);
		
		return token;
	}
	
	/**
	 * Loads a resource from already loaded data.
	 *
	 * @param data The data object containing all resource information.
	 * @param context An optional context object providing additional parameters for loading
	 * @param ns An optional namespace string under which the file is to be loaded, allowing the differentiation of two resources with identical assets
	 * @param parser An optional parser object for translating the loaded data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.
	 */
	public function loadData(data:Dynamic, context:AssetLoaderContext = null, ns:String = null, parser:ParserBase = null):AssetLoaderToken
	{
		var token:AssetLoaderToken;
		
		if (_useAssetLib) {
			var lib:Asset3DLibraryBundle;
			lib = Asset3DLibraryBundle.getInstance(_assetLibId);
			token = lib.loadData(data, context, ns, parser);
		} else {
			var loader:AssetLoader = new AssetLoader();
			_loadingSessions.push(loader);
			token = loader.loadData(data, '', context, ns, parser);
		}
		
		token.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
		token.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.TEXTURE_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.CONTAINER_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.GEOMETRY_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.MATERIAL_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.MESH_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.ENTITY_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.SKELETON_COMPLETE, onAssetComplete);
		token.addEventListener(Asset3DEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
		
		// Error are handled separately (see documentation for addErrorHandler)
		token._loader.addErrorHandler(onLoadError);
		
		return token;
	}
			
	/**
	 * Stop the current loading/parsing process.
	 */
	public function stopLoad():Void
	{
		if (_useAssetLib) {
			var lib:Asset3DLibraryBundle;
			lib = Asset3DLibraryBundle.getInstance(_assetLibId);
			lib.stopAllLoadingSessions();
			_loadingSessions = null;
			return;
		}
		var i:Int;
		var length:Int = _loadingSessions.length;
		for (i in 0...length) {
			removeListeners(_loadingSessions[i]);
			_loadingSessions[i].stop();
			_loadingSessions[i] = null;
		}
		_loadingSessions = null;
	}
			
	/**
	 * Enables a specific parser. 
	 * When no specific parser is set for a loading/parsing opperation, 
	 * loader3d can autoselect the correct parser to use.
	 * A parser must have been enabled, to be considered when autoselecting the parser.
	 *
	 * @param parserClass The parser class to enable.
	 * @see away3d.loaders.parsers.Parsers
	*/
	public static function enableParser(parserClass:Class<ParserBase>):Void
	{
		SingleFileLoader.enableParser(parserClass);
	}
	
	/**
	 * Enables a list of parsers. 
	 * When no specific parser is set for a loading/parsing opperation, 
	 * loader3d can autoselect the correct parser to use.
	 * A parser must have been enabled, to be considered when autoselecting the parser.
	 *
	 * @param parserClasses A Vector of parser classes to enable.
	 * @see away3d.loaders.parsers.Parsers
	 */
	public static function enableParsers(parserClasses:Array<Dynamic>):Void
	{
		SingleFileLoader.enableParsers(parserClasses);
	}
	
	private function removeListeners(dispatcher:EventDispatcher):Void
	{
		dispatcher.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
		dispatcher.removeEventListener(LoaderEvent.LOAD_ERROR, onLoadError);
		dispatcher.removeEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(Asset3DEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(Asset3DEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(Asset3DEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(Asset3DEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(Asset3DEvent.TEXTURE_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(Asset3DEvent.CONTAINER_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(Asset3DEvent.GEOMETRY_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(Asset3DEvent.MATERIAL_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(Asset3DEvent.MESH_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(Asset3DEvent.ENTITY_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(Asset3DEvent.SKELETON_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(Asset3DEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
	}
	
	private function onAssetComplete(ev:Asset3DEvent):Void
	{
		if (ev.type == Asset3DEvent.ASSET_COMPLETE) {
			// TODO: not used
			// var type : String = ev.asset.assetType;
			var obj:ObjectContainer3D = null;
			switch (ev.asset.assetType) {
				case Asset3DType.LIGHT:
					obj = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(ev.asset, LightBase) ? cast ev.asset : null;
				case Asset3DType.CONTAINER:
					obj = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(ev.asset, ObjectContainer3D) ? cast ev.asset : null;
				case Asset3DType.MESH:
					obj = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(ev.asset, Mesh) ? cast ev.asset : null;
				case Asset3DType.SKYBOX:
					obj = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(ev.asset, SkyBox) ? cast ev.asset : null;
				case Asset3DType.TEXTURE_PROJECTOR:
					obj = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(ev.asset, TextureProjector) ? cast ev.asset : null;
				case Asset3DType.CAMERA:
					obj = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(ev.asset, Camera3D) ? cast ev.asset : null;
				case Asset3DType.SEGMENT_SET:
					obj = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(ev.asset, SegmentSet) ? cast ev.asset : null;
			}
			
			// If asset was of fitting type, and doesn't
			// already have a parent, add to loader container
			if (obj != null && obj.parent == null)
				addChild(obj);
		}
		
		this.dispatchEvent(ev.clone());
	}
	
	private function onParseError(ev:ParserEvent):Bool
	{
		if (hasEventListener(ParserEvent.PARSE_ERROR)) {
			dispatchEvent(ev);
			return true;
		} else
			return false;
	}
	
	
	private function onLoadError(ev:LoaderEvent):Bool
	{
		if (hasEventListener(LoaderEvent.LOAD_ERROR)) {
			dispatchEvent(ev);
			return true;
		} else
			return false;
	}
	
	private function onResourceComplete(ev:Event):Void
	{
		removeListeners(cast(ev.currentTarget, EventDispatcher));
		this.dispatchEvent(ev.clone());
	}
}