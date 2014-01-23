package away3d.library.assets;

import flash.events.IEventDispatcher;

interface IAsset extends IEventDispatcher {
    var name(get_name, set_name):String;
    var id(get_id, set_id):String;
    var assetNamespace(get_assetNamespace, never):String;
    var assetType(get_assetType, never):String;
    var assetFullPath(get_assetFullPath, never):Array<Dynamic>;

/**
	 * The name of the asset.
	 */
    function get_name():String;
    function set_name(val:String):String;
/**
	 * The id of the asset.
	 */
    function get_id():String;
    function set_id(val:String):String;
/**
	 * The namespace of the asset. This allows several assets with the same name to coexist in different contexts.
	 */
    function get_assetNamespace():String;
/**
	 * The type of the asset.
	 */
    function get_assetType():String;
/**
	 * The full path of the asset.
	 */
    function get_assetFullPath():Array<Dynamic>;
    function assetPathEquals(name:String, ns:String):Bool;
    function resetAssetPath(name:String, ns:String = null, overrideOriginal:Bool = true):Void;
/**
	 * Cleans up resources used by this asset.
	 */
    function dispose():Void;
}

