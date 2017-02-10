package away3d.library;

import away3d.library.assets.IAsset;
import away3d.library.naming.ConflictStrategyBase;
import away3d.library.utils.Asset3DLibraryIterator;
import away3d.loaders.misc.AssetLoaderContext;
import away3d.loaders.misc.AssetLoaderToken;
import away3d.loaders.misc.SingleFileLoader;
import away3d.loaders.parsers.ParserBase;

import openfl.net.URLRequest;
import openfl.Vector;

/**
 * Asset3DLibrary enforces a singleton pattern and is not intended to be instanced.
 * It's purpose is to allow access to the default library bundle through a set of static shortcut methods.
 * If you are interested in creating multiple library bundles, please use the <code>getBundle()</code> method.
 */
class Asset3DLibrary
{
	@:allow(away3d) private static var _instances:Map<String, Asset3DLibraryBundle> = new Map<String, Asset3DLibraryBundle>();
	
	/**
	 * Short-hand for conflictStrategy property on default asset library bundle.
	 *
	 * @see away3d.library.Asset3DLibraryBundle.conflictStrategy
	 */
	public static var conflictStrategy(get, set):ConflictStrategyBase;
	
	/**
	 * Short-hand for conflictPrecedence property on default asset library bundle.
	 *
	 * @see away3d.library.Asset3DLibraryBundle.conflictPrecedence
	 */
	public static var conflictPrecedence(get, set):String;

	
	/**
	 * Creates a new <code>Asset3DLibrary</code> object.
	 */
	private function new()
	{
		
	}
	
	/**
	 * Returns an Asset3DLibrary bundle instance. If no key is given, returns the default bundle (which is
	 * similar to using the Asset3DLibraryBundle as a singleton). To keep several separated library bundles,
	 * pass a string key to this method to define which bundle should be returned. This is
	 * referred to as using the Asset3DLibraryBundle as a multiton.
	 *
	 * @param key Defines which multiton instance should be returned.
	 * @return An instance of the asset library
	 */
	public static function getBundle(key:String = 'default'):Asset3DLibraryBundle
	{
		return Asset3DLibraryBundle.getInstance(key);
	}
	
	/**
	 *
	 */
	public static function enableParser(parserClass:Class<ParserBase>):Void
	{
		SingleFileLoader.enableParser(parserClass);
	}
	
	/**
	 *
	 */
	public static function enableParsers(parserClasses:Array<Dynamic>):Void
	{
		SingleFileLoader.enableParsers(parserClasses);
	}
	
	private static function get_conflictStrategy():ConflictStrategyBase
	{
		return getBundle().conflictStrategy;
	}
	
	private static function set_conflictStrategy(val:ConflictStrategyBase):ConflictStrategyBase
	{
		return getBundle().conflictStrategy = val;
	}
	
	private static function get_conflictPrecedence():String
	{
		return getBundle().conflictPrecedence;
	}
	
	private static function set_conflictPrecedence(val:String):String
	{
		return getBundle().conflictPrecedence = val;
	}
	
	/**
	 * Short-hand for createIterator() method on default asset library bundle.
	 *
	 * @see away3d.library.Asset3DLibraryBundle.createIterator()
	 */
	public static function createIterator(Asset3DTypeFilter:String = null, namespaceFilter:String = null, filterFunc:Dynamic = null):Asset3DLibraryIterator
	{
		return getBundle().createIterator(Asset3DTypeFilter, namespaceFilter, filterFunc);
	}
	
	/**
	 * Short-hand for load() method on default asset library bundle.
	 *
	 * @see away3d.library.Asset3DLibraryBundle.load()
	 */
	public static function load(req:URLRequest, context:AssetLoaderContext = null, ns:String = null, parser:ParserBase = null):AssetLoaderToken
	{
		return getBundle().load(req, context, ns, parser);
	}
	
	/**
	 * Short-hand for loadData() method on default asset library bundle.
	 *
	 * @see away3d.library.Asset3DLibraryBundle.loadData()
	 */
	public static function loadData(data:Dynamic, context:AssetLoaderContext = null, ns:String = null, parser:ParserBase = null):AssetLoaderToken
	{
		return getBundle().loadData(data, context, ns, parser);
	}
	
	public static function stopLoad():Void
	{
		getBundle().stopAllLoadingSessions();
	}
	
	/**
	 * Short-hand for getAsset() method on default asset library bundle.
	 *
	 * @see away3d.library.Asset3DLibraryBundle.getAsset()
	 */
	public static function getAsset(name:String, ns:String = null):IAsset
	{
		return getBundle().getAsset(name, ns);
	}
	
	/**
	 * Short-hand for addEventListener() method on default asset library bundle.
	 */
	public static function addEventListener(type:String, listener:Dynamic, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void
	{
		getBundle().addEventListener(type, listener, useCapture, priority, useWeakReference);
	}
	
	/**
	 * Short-hand for removeEventListener() method on default asset library bundle.
	 */
	public static function removeEventListener(type:String, listener:Dynamic, useCapture:Bool = false):Void
	{
		getBundle().removeEventListener(type, listener, useCapture);
	}
	
	/**
	 * Short-hand for hasEventListener() method on default asset library bundle.
	 */
	public static function hasEventListener(type:String):Bool
	{
		return getBundle().hasEventListener(type);
	}
	
	public static function willTrigger(type:String):Bool
	{
		return getBundle().willTrigger(type);
	}
	
	/**
	 * Short-hand for addAsset() method on default asset library bundle.
	 *
	 * @see away3d.library.Asset3DLibraryBundle.addAsset()
	 */
	public static function addAsset(asset:IAsset):Void
	{
		getBundle().addAsset(asset);
	}
	
	/**
	 * Short-hand for removeAsset() method on default asset library bundle.
	 *
	 * @param asset The asset which should be removed from the library.
	 * @param dispose Defines whether the assets should also be disposed.
	 *
	 * @see away3d.library.Asset3DLibraryBundle.removeAsset()
	 */
	public static function removeAsset(asset:IAsset, dispose:Bool = true):Void
	{
		getBundle().removeAsset(asset, dispose);
	}
	
	/**
	 * Short-hand for removeAssetByName() method on default asset library bundle.
	 *
	 * @param name The name of the asset to be removed.
	 * @param ns The namespace to which the desired asset belongs.
	 * @param dispose Defines whether the assets should also be disposed.
	 *
	 * @see away3d.library.Asset3DLibraryBundle.removeAssetByName()
	 */
	public static function removeAssetByName(name:String, ns:String = null, dispose:Bool = true):IAsset
	{
		return getBundle().removeAssetByName(name, ns, dispose);
	}
	
	/**
	 * Short-hand for removeAllAssets() method on default asset library bundle.
	 *
	 * @param dispose Defines whether the assets should also be disposed.
	 *
	 * @see away3d.library.Asset3DLibraryBundle.removeAllAssets()
	 */
	public static function removeAllAssets(dispose:Bool = true):Void
	{
		getBundle().removeAllAssets(dispose);
	}
	
	/**
	 * Short-hand for removeNamespaceAssets() method on default asset library bundle.
	 *
	 * @see away3d.library.Asset3DLibraryBundle.removeNamespaceAssets()
	 */
	public static function removeNamespaceAssets(ns:String = null, dispose:Bool = true):Void
	{
		getBundle().removeNamespaceAssets(ns, dispose);
	}
}