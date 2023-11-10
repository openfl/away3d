package away3d.events;

import away3d.containers.ObjectContainer3D;

import openfl.events.Event;
import openfl.utils.Object;

class Scene3DEvent extends Event
{
	public static inline var ADDED_TO_SCENE:String = "addedToScene";
	public static inline var REMOVED_FROM_SCENE:String = "removedFromScene";
	public static inline var PARTITION_CHANGED:String = "partitionChanged";
	
	public var objectContainer3D:ObjectContainer3D;
	
	#if flash
	#if (haxe_ver < 4.3) @:getter(target) #else override #end private function get_target(): #if (openfl >= "9.2.0") Object #else Dynamic #end {
		return objectContainer3D;
	}
	#end
	
	public function new(type:String, objectContainer:ObjectContainer3D)
	{
		objectContainer3D = objectContainer;
		super(type);
	}
	
	override public function clone():Event
	{
		return new Scene3DEvent(type, objectContainer3D);
	}
}