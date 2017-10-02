package away3d.library;

import away3d.events.Asset3DEvent;
import away3d.events.LoaderEvent;
import away3d.events.ParserEvent;
import away3d.library.assets.IAsset;
import away3d.library.assets.NamedAssetBase;
import away3d.library.naming.ConflictPrecedence;
import away3d.library.naming.ConflictStrategy;
import away3d.library.naming.ConflictStrategyBase;
import away3d.library.utils.Asset3DLibraryIterator;
import away3d.library.utils.IDUtil;
import away3d.loaders.AssetLoader;
import away3d.loaders.misc.AssetLoaderContext;
import away3d.loaders.misc.AssetLoaderToken;
import away3d.loaders.misc.SingleFileLoader;
import away3d.loaders.parsers.ParserBase;

import openfl.errors.Error;
import openfl.events.EventDispatcher;
import openfl.net.URLRequest;
import openfl.Vector;

/**
 * Asset3DLibraryBundle enforces a multiton pattern and is not intended to be instanced directly.
 * Its purpose is to create a container for 3D data management, both before and after parsing.
 * If you are interested in creating multiple library bundles, please use the <code>getInstance()</code> method.
 */
class Asset3DLibraryBundle extends EventDispatcher
{
	/**
	 * Defines which strategy should be used for resolving naming conflicts, when two library
	 * assets are given the same name. By default, <code>ConflictStrategy.APPEND_NUM_SUFFIX</code>
	 * is used which means that a numeric suffix is appended to one of the assets. The
	 * <code>conflictPrecedence</code> property defines which of the two conflicting assets will
	 * be renamed.
	 *
	 * @see a3d.library.naming.ConflictStrategy
	 * @see a3d.library.Asset3DLibrary.conflictPrecedence
	*/
	public var conflictStrategy(get, set):ConflictStrategyBase;
	
	/**
	 * Defines which asset should have precedence when resolving a naming conflict between
	 * two assets of which one has just been renamed by the user or by a parser. By default
	 * <code>ConflictPrecedence.FAVOR_NEW</code> is used, meaning that the newly renamed
	 * asset will keep it's new name while the older asset gets renamed to not conflict.
	 *
	 * This property is ignored for conflict strategies that do not actually rename an
	 * asset automatically, such as ConflictStrategy.IGNORE and ConflictStrategy.THROW_ERROR.
	 *
	 * @see a3d.library.naming.ConflictPrecedence
	 * @see a3d.library.naming.ConflictStrategy
	*/
	public var conflictPrecedence(get, set):String;
	
	private var _loadingSessions:Vector<AssetLoader>;
	
	private var _strategy:ConflictStrategyBase;
	private var _strategyPreference:String;
	
	private var _assets:Vector<IAsset>;
	private var _assetDictionary:Map<String, Map<String, IAsset>>;
	private var _assetDictDirty:Bool;
	
	/**
	 * Creates a new <code>Asset3DLibraryBundle</code> object.
	 */
	private function new()
	{
		super();
		
		_assets = new Vector<IAsset>();
		_assetDictionary = new Map<String, Map<String, IAsset>>();
		_loadingSessions = new Vector<AssetLoader>();
		
		conflictStrategy = ConflictStrategy.IGNORE.create();
		conflictPrecedence = ConflictPrecedence.FAVOR_NEW;
	}
	
	/**
	 * Returns an Asset3DLibraryBundle instance. If no key is given, returns the default bundle instance (which is
	 * similar to using the Asset3DLibraryBundle as a singleton.) To keep several separated library bundles,
	 * pass a string key to this method to define which bundle should be returned. This is
	 * referred to as using the Asset3DLibrary as a multiton.
	 *
	 * @param key Defines which multiton instance should be returned.
	 * @return An instance of the asset library
	 */
	public static function getInstance(key:String = 'default'):Asset3DLibraryBundle
	{
		if (key == null)
			key = 'default';
		
		if (!Asset3DLibrary._instances.exists(key))
			Asset3DLibrary._instances[key] = new Asset3DLibraryBundle();
		
		return Asset3DLibrary._instances[key];
	}
	
	/**
	 *
	 */
	public function enableParser(parserClass:Class<ParserBase>):Void
	{
		SingleFileLoader.enableParser(parserClass);
	}
	
	/**
	 *
	 */
	public function enableParsers(parserClasses:Array<Dynamic>):Void
	{
		SingleFileLoader.enableParsers(parserClasses);
	}
	
	private function get_conflictStrategy():ConflictStrategyBase
	{
		return _strategy;
	}
	
	private function set_conflictStrategy(val:ConflictStrategyBase):ConflictStrategyBase
	{
		if (val == null)
			throw new Error('namingStrategy must not be null. To ignore naming, use Asset3DLibrary.IGNORE');
		
		return _strategy = val.create();
	}
	
	private function get_conflictPrecedence():String
	{
		return _strategyPreference;
	}
	
	private function set_conflictPrecedence(val:String):String
	{
		return _strategyPreference = val;
	}
	
	/**
	 * Create an Asset3DLibraryIterator instance that can be used to iterate over the assets
	 * in this asset library instance. The iterator can filter assets on asset type and/or
	 * namespace. A "null" filter value means no filter of that type is used.
	 *
	 * @param Asset3DTypeFilter Asset type to filter on (from the Asset3DType enum class.) Use
	 * null to not filter on asset type.
	 * @param namespaceFilter Namespace to filter on. Use null to not filter on namespace.
	 * @param filterFunc Callback function to use when deciding whether an asset should be
	 * included in the iteration or not. This needs to be a function that takes a single
	 * parameter of type IAsset and returns a Bool where true means it should be included.
	 *
	 * @see away3d.library.assets.Asset3DType
	 */
	public function createIterator(Asset3DTypeFilter:String = null, namespaceFilter:String = null, filterFunc:Dynamic = null):Asset3DLibraryIterator
	{
		return new Asset3DLibraryIterator(_assets, Asset3DTypeFilter, namespaceFilter, filterFunc);
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
		return loadResource(req, context, ns, parser);
	}
	
	/**
	 * Loads a resource from existing data in memory.
	 *
	 * @param data The data object containing all resource information.
	 * @param context An optional context object providing additional parameters for loading
	 * @param ns An optional namespace string under which the file is to be loaded, allowing the differentiation of two resources with identical assets
	 * @param parser An optional parser object for translating the loaded data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.
	 */
	public function loadData(data:Dynamic, context:AssetLoaderContext = null, ns:String = null, parser:ParserBase = null):AssetLoaderToken
	{
		return parseResource(data, context, ns, parser);
	}
	
	/**
	 *
	 */
	public function getAsset(name:String, ns:String = null):IAsset
	{
		//var asset : IAsset;
		
		if (_assetDictDirty)
			rehashAssetDict();
		
		if (ns == null)
			ns = NamedAssetBase.DEFAULT_NAMESPACE;
		
		if (!_assetDictionary.exists(ns))
			return null;
		
		return _assetDictionary[ns][name];
	}
	
	/**
	 * Adds an asset to the asset library, first making sure that it's name is unique
	 * using the method defined by the <code>conflictStrategy</code> and
	 * <code>conflictPrecedence</code> properties.
	 */
	public function addAsset(asset:IAsset):Void
	{
		var ns:String;
		var old:IAsset;
		
		// Bail if asset has already been added.
		if (_assets.indexOf(asset) >= 0)
			return;
		
		old = getAsset(asset.name, asset.assetNamespace);
		if (asset.assetNamespace != null) {
			ns = asset.assetNamespace;
		}
		else {
			ns = NamedAssetBase.DEFAULT_NAMESPACE;
		}
		
		if (old != null)
			_strategy.resolveConflict(asset, old, _assetDictionary.get(ns), _strategyPreference);
		
		//create unique-id (for now this is used in AwayBuilder only
		asset.id = IDUtil.createUID();
		
		// Add it
		_assets.push(asset);
		if (!_assetDictionary.exists(ns))
			_assetDictionary[ns] = new Map<String, IAsset>();
		_assetDictionary[ns][asset.name] = asset;
		
		asset.addEventListener(Asset3DEvent.ASSET_RENAME, onAssetRename);
		asset.addEventListener(Asset3DEvent.ASSET_CONFLICT_RESOLVED, onAssetConflictResolved);
	}
	
	/**
	 * Removes an asset from the library, and optionally disposes that asset by calling
	 * it's disposeAsset() method (which for most assets is implemented as a default
	 * version of that type's dispose() method.
	 *
	 * @param asset The asset which should be removed from this library.
	 * @param dispose Defines whether the assets should also be disposed.
	 */
	public function removeAsset(asset:IAsset, dispose:Bool = true):Void
	{
		var idx:Int;
		
		removeAssetFromDict(asset);
		
		asset.removeEventListener(Asset3DEvent.ASSET_RENAME, onAssetRename);
		asset.removeEventListener(Asset3DEvent.ASSET_CONFLICT_RESOLVED, onAssetConflictResolved);
		
		idx = _assets.indexOf(asset);
		if (idx >= 0)
			_assets.splice(idx, 1);
		
		if (dispose)
			asset.dispose();
	}
	
	/**
	 * Removes an asset which is specified using name and namespace.
	 *
	 * @param name The name of the asset to be removed.
	 * @param ns The namespace to which the desired asset belongs.
	 * @param dispose Defines whether the assets should also be disposed.
	 *
	 * @see away3d.library.Asset3DLibrary.removeAsset()
	 */
	public function removeAssetByName(name:String, ns:String = null, dispose:Bool = true):IAsset
	{
		var asset:IAsset = getAsset(name, ns);
		if (asset != null)
			removeAsset(asset, dispose);
		
		return asset;
	}
	
	/**
	 * Removes all assets from the asset library, optionally disposing them as they
	 * are removed.
	 *
	 * @param dispose Defines whether the assets should also be disposed.
	 */
	public function removeAllAssets(dispose:Bool = true):Void
	{
		if (dispose) {
			var asset:IAsset;
			for (asset in _assets)
				asset.dispose();
		}
		
		_assets.length = 0;
		rehashAssetDict();
	}
	
	/**
	 * Removes all assets belonging to a particular namespace (null for default)
	 * from the asset library, and optionall disposes them by calling their
	 * disposeAsset() method.
	 *
	 * @param ns The namespace from which all assets should be removed.
	 * @param dispose Defines whether the assets should also be disposed.
	 *
	 * @see away3d.library.Asset3DLibrary.removeAsset()
	 */
	public function removeNamespaceAssets(ns:String = null, dispose:Bool = true):Void
	{
		var idx:Int = 0;
		var asset:IAsset;
		var old_assets:Vector<IAsset>;
		
		// Empty the assets vector after having stored a copy of it.
		// The copy will be filled with all assets which weren't removed.
		old_assets = _assets.concat();
		_assets.length = 0;
		
		if (ns == null)
			ns = NamedAssetBase.DEFAULT_NAMESPACE;
		for (asset in old_assets) {  
			// Remove from dict if in the supplied namespace. If not,
			// transfer over to the new vector.
			if (asset.assetNamespace == ns) {
				if (dispose)
					asset.dispose();
				
				// Remove asset from dictionary, but don't try to auto-remove
				// the namespace, which will trigger an unnecessarily expensive
				// test that is not needed since we know that the namespace
				// will be empty when loop finishes.
				removeAssetFromDict(asset, false);
			} else
				_assets[idx++] = asset;
		}
		
		// Remove empty namespace
		if (_assetDictionary.exists(ns))
			_assetDictionary.remove(ns);
	}
	
	private function removeAssetFromDict(asset:IAsset, autoRemoveEmptyNamespace:Bool = true):Void
	{
		if (_assetDictDirty)
			rehashAssetDict();
		
		if (_assetDictionary.exists(asset.assetNamespace)) {
			if (_assetDictionary[asset.assetNamespace].exists(asset.name))
				_assetDictionary[asset.assetNamespace].remove(asset.name);
			
			if (autoRemoveEmptyNamespace) {
				var key:String;
				var empty:Bool = true;
				
				var map:Map<String, IAsset> = _assetDictionary[asset.assetNamespace];
				if (map.keys().hasNext()) {
					empty = false;
				}
				
				if (empty)
					_assetDictionary.remove(asset.assetNamespace);
			}
		}
	}
	
	/**
	 * Loads a yet unloaded resource file from the given url.
	 */
	private function loadResource(req:URLRequest, context:AssetLoaderContext = null, ns:String = null, parser:ParserBase = null):AssetLoaderToken
	{
		var loader:AssetLoader = new AssetLoader();
		if (_loadingSessions == null)
			_loadingSessions = new Vector<AssetLoader>();
		_loadingSessions.push(loader);
		loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceRetrieved);
		loader.addEventListener(LoaderEvent.DEPENDENCY_COMPLETE, onDependencyRetrieved);
		loader.addEventListener(Asset3DEvent.TEXTURE_SIZE_ERROR, onTextureSizeError);
		loader.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.TEXTURE_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.CONTAINER_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.GEOMETRY_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.MATERIAL_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.MESH_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.ENTITY_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.SKELETON_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
		
		// Error are handled separately (see documentation for addErrorHandler)
		loader.addErrorHandler(onDependencyRetrievingError);
		loader.addParseErrorHandler(onDependencyRetrievingParseError);
		
		return loader.load(req, context, ns, parser);
	}
	
	public function stopAllLoadingSessions():Void
	{
		if (_loadingSessions == null)
			_loadingSessions = new Vector<AssetLoader>();
		var length:Int = _loadingSessions.length;
		for (i in 0...length)
			killLoadingSession(_loadingSessions[i]);
		_loadingSessions = null;
	}
	
	/**
	 * Retrieves an unloaded resource parsed from the given data.
	 * @param data The data to be parsed.
	 * @param id The id that will be assigned to the resource. This can later also be used by the getResource method.
	 * @param ignoreDependencies Indicates whether or not dependencies should be ignored or loaded.
	 * @param parser An optional parser object that will translate the data into a usable resource.
	 * @return A handle to the retrieved resource.
	 */
	private function parseResource(data:Dynamic, context:AssetLoaderContext = null, ns:String = null, parser:ParserBase = null):AssetLoaderToken
	{
		var loader:AssetLoader = new AssetLoader();
		if (_loadingSessions == null)
			_loadingSessions = new Vector<AssetLoader>();
		_loadingSessions.push(loader);
		loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceRetrieved);
		loader.addEventListener(LoaderEvent.DEPENDENCY_COMPLETE, onDependencyRetrieved);
		loader.addEventListener(Asset3DEvent.TEXTURE_SIZE_ERROR, onTextureSizeError);
		loader.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.TEXTURE_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.CONTAINER_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.GEOMETRY_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.MATERIAL_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.MESH_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.ENTITY_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.SKELETON_COMPLETE, onAssetComplete);
		loader.addEventListener(Asset3DEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
		
		// Error are handled separately (see documentation for addErrorHandler)
		loader.addErrorHandler(onDependencyRetrievingError);
		loader.addParseErrorHandler(onDependencyRetrievingParseError);
		
		return loader.loadData(data, '', context, ns, parser);
	}
	
	private function rehashAssetDict():Void
	{
		var asset:IAsset;
		
		_assetDictionary = new Map<String, Map<String, IAsset>>();
		
		_assets.fixed = true;
		for (asset in _assets) {
			if (!_assetDictionary.exists(asset.assetNamespace))
				_assetDictionary[asset.assetNamespace] = new Map<String, IAsset>();
			
			_assetDictionary[asset.assetNamespace][asset.name] = asset;
		}
		_assets.fixed = false;
		
		_assetDictDirty = false;
	}
	
	/**
	 * Called when a dependency was retrieved.
	 */
	private function onDependencyRetrieved(event:LoaderEvent):Void
	{
		if (hasEventListener(LoaderEvent.DEPENDENCY_COMPLETE))
			dispatchEvent(event);
	}
	
	/**
	 * Called when a an error occurs during dependency retrieving.
	 */
	private function onDependencyRetrievingError(event:LoaderEvent):Bool
	{
		if (hasEventListener(LoaderEvent.LOAD_ERROR)) {
			dispatchEvent(event);
			return true;
		} else
			return false;
	}
	
	/**
	 * Called when a an error occurs during parsing.
	 */
	private function onDependencyRetrievingParseError(event:ParserEvent):Bool
	{
		if (hasEventListener(ParserEvent.PARSE_ERROR)) {
			dispatchEvent(event);
			return true;
		} else
			return false;
	}
	
	private function onAssetComplete(event:Asset3DEvent):Void
	{
		// Only add asset to library the first time.
		if (event.type == Asset3DEvent.ASSET_COMPLETE)
			addAsset(event.asset);
		
		dispatchEvent(event.clone());
	}
	
	private function onTextureSizeError(event:Asset3DEvent):Void
	{
		this.dispatchEvent(event.clone());
	}
	
	/**
	 * Called when the resource and all of its dependencies was retrieved.
	 */
	private function onResourceRetrieved(event:LoaderEvent):Void
	{
		var loader:AssetLoader = cast(event.target, AssetLoader);
		killLoadingSession(loader);
		var index:Int = _loadingSessions.indexOf(loader);
		_loadingSessions.splice(index, 1);
		
		/*
		if(session.handle){
			dispatchEvent(event);
		}else{
			onResourceError((session is IResource)? IResource(session) : null);
		}
		*/
		
		dispatchEvent(event.clone());
	}
	
	private function killLoadingSession(loader:AssetLoader):Void
	{
		
		loader.removeEventListener(LoaderEvent.LOAD_ERROR, onDependencyRetrievingError);
		loader.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceRetrieved);
		loader.removeEventListener(LoaderEvent.DEPENDENCY_COMPLETE, onDependencyRetrieved);
		loader.removeEventListener(Asset3DEvent.TEXTURE_SIZE_ERROR, onTextureSizeError);
		loader.removeEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		loader.removeEventListener(Asset3DEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
		loader.removeEventListener(Asset3DEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
		loader.removeEventListener(Asset3DEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
		loader.removeEventListener(Asset3DEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
		loader.removeEventListener(Asset3DEvent.TEXTURE_COMPLETE, onAssetComplete);
		loader.removeEventListener(Asset3DEvent.CONTAINER_COMPLETE, onAssetComplete);
		loader.removeEventListener(Asset3DEvent.GEOMETRY_COMPLETE, onAssetComplete);
		loader.removeEventListener(Asset3DEvent.MATERIAL_COMPLETE, onAssetComplete);
		loader.removeEventListener(Asset3DEvent.MESH_COMPLETE, onAssetComplete);
		loader.removeEventListener(Asset3DEvent.ENTITY_COMPLETE, onAssetComplete);
		loader.removeEventListener(Asset3DEvent.SKELETON_COMPLETE, onAssetComplete);
		loader.removeEventListener(Asset3DEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
		loader.stop();
		
	}
	
	/**
	 * Called when unespected error occurs
	 */
	/*
	private function onResourceError():Void
	{
		var msg:String = "Unexpected parser error";
		if(hasEventListener(LoaderEvent.DEPENDENCY_ERROR)){
			var re:LoaderEvent = new LoaderEvent(LoaderEvent.DEPENDENCY_ERROR, "");
			dispatchEvent(re);
		} else{
			throw new Error(msg);
		}
	}
	*/
	
	private function onAssetRename(ev:Asset3DEvent):Void
	{
		var asset:IAsset = cast(ev.currentTarget, IAsset);
		var old:IAsset = getAsset(asset.assetNamespace, asset.name);
		
		if (old != null)
			_strategy.resolveConflict(asset, old, _assetDictionary[asset.assetNamespace], _strategyPreference);
		else {
			var dict:Map<String, IAsset> = _assetDictionary[ev.asset.assetNamespace];
			if (dict == null)
				return;
			
			dict.remove(ev.assetPrevName);
			dict[ev.asset.name] = ev.asset;
		}
	}
	
	private function onAssetConflictResolved(ev:Asset3DEvent):Void
	{
		dispatchEvent(ev.clone());
	}
}