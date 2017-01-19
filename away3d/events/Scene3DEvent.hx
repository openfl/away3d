package away3d.events;

import away3d.containers.ObjectContainer3D;

import openfl.events.Event;

class Scene3DEvent extends Event
{
	public static inline var ADDED_TO_SCENE:String = "addedToScene";
	public static inline var REMOVED_FROM_SCENE:String = "removedFromScene";
	public static inline var PARTITION_CHANGED:String = "partitionChanged";
	
	public var objectContainer3D:ObjectContainer3D;
	
	//@:getter(target)
	#if flash
	private function get_target():Dynamic {
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