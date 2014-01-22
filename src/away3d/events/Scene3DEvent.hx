package away3d.events;

	import away3d.containers.ObjectContainer3D;
	
	import flash.events.Event;
	
	class Scene3DEvent extends Event
	{
		public static var ADDED_TO_SCENE:String = "addedToScene";
		public static var REMOVED_FROM_SCENE:String = "removedFromScene";
		public static var PARTITION_CHANGED:String = "partitionChanged";
		
		public var objectContainer3D:ObjectContainer3D;
		
		#if html5
		public function get_target() : Dynamic
		#else
		public override function get_target() : Dynamic
		#end
		{
			return objectContainer3D;
		}
		
		public function new(type:String, objectContainer:ObjectContainer3D)
		{
			objectContainer3D = objectContainer;
			super(type);
		}
		
		public override function clone():Event
		{
			return new Scene3DEvent(type, objectContainer3D);
		}
	}

