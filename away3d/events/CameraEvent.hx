/**
 *
 */
package away3d.events;

	import flash.events.Event;
	import away3d.events.Object3DEvent;
	
	import away3d.cameras.Camera3D;
	
	class CameraEvent extends Object3DEvent
	{
		public static var LENS_CHANGED:String = "lensChanged";
		
		var _camera:Camera3D;
		
		public function new(type:String, camera:Camera3D, bubbles:Bool = false, cancelable:Bool = false)
		{
			super(type, camera);
			_camera = camera;
		}
		
		public var camera(get, null) : Camera3D;
		
		public function get_camera() : Camera3D
		{
			return _camera;
		}
		
		override public function clone():Event
		{
			return new CameraEvent(type, _camera, bubbles, cancelable);
		}
	}

