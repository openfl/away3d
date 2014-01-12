package away3d.events;

	import away3d.animators.*;
	
	import flash.events.*;
	
	/**
	 * Dispatched to notify changes in an animator's state.
	 */
	class AnimatorEvent extends Event
	{
		/**
		 * Defines the value of the type property of a start event object.
		 */
		public static var START:String = "start";
		
		/**
		 * Defines the value of the type property of a stop event object.
		 */
		public static var STOP:String = "stop";
		
		/**
		 * Defines the value of the type property of a cycle complete event object.
		 */
		public static var CYCLE_COMPLETE:String = "cycle_complete";
		
		var _animator:AnimatorBase;
		
		/**
		 * Create a new <code>AnimatorEvent</code> object.
		 *
		 * @param type The event type.
		 * @param animator The animator object that is the subject of this event.
		 */
		public function new(type:String, animator:AnimatorBase):Void
		{
			super(type, false, false);
			_animator = animator;
		}
		
		public var animator(get, null) : AnimatorBase;
		
		public function get_animator() : AnimatorBase
		{
			return _animator;
		}
		
		/**
		 * Clones the event.
		 *
		 * @return An exact duplicate of the current event object.
		 */
		override public function clone():Event
		{
			return new AnimatorEvent(type, _animator);
		}
	}

