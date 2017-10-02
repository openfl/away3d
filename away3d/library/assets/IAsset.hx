package away3d.library.assets;

import openfl.events.IEventDispatcher;
import openfl.Vector;

interface IAsset extends IEventDispatcher
{
	var name(get, set):String;
	var id(get, set):String;
	var assetNamespace(get, never):String;
	var assetType(get, never):String;
	var assetFullPath(get, never):Array<Dynamic>;
	
	/**
	 * The name of the asset.
	 */
	private function get_name():String;
	
	private function set_name(val:String):String;
	
	/**
	 * The id of the asset.
	 */
	private function get_id():String;
	
	private function set_id(val:String):String;
	
	/**
	 * The namespace of the asset. This allows several assets with the same name to coexist in different contexts.
	 */
	private function get_assetNamespace():String;
	
	/**
	 * The type of the asset.
	 */
	private function get_assetType():String;
	
	/**
	 * The full path of the asset.
	 */
	private function get_assetFullPath():Array<Dynamic>;
	
	function assetPathEquals(name:String, ns:String):Bool;
	
	function resetAssetPath(name:String, ns:String = null, ?overrideOriginal:Bool = true):Void;
	
	/**
	 * Cleans up resources used by this asset.
	 */
	function dispose():Void;
}