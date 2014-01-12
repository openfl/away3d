package away3d.events;

	import flash.events.Event;
	
	/**
	 * LoaderEvent is an Event dispatched to notify changes in loading state.
	 */
	class LoaderEvent extends Event
	{
		/**
		 * Dispatched when loading of a asset failed.
		 * Such as wrong parser type, unsupported extensions, parsing errors, malformated or unsupported 3d file etc..
		 */
		public static var LOAD_ERROR:String = "loadError";
		
		/**
		 * Dispatched when a resource and all of its dependencies is retrieved.
		 */
		public static var RESOURCE_COMPLETE:String = "resourceComplete";
		
		/**
		 * Dispatched when a resource's dependency is retrieved and resolved.
		 */
		public static var DEPENDENCY_COMPLETE:String = "dependencyComplete";
		
		var _url:String;
		var _message:String;
		var _isDependency:Bool;
		var _isDefaultPrevented:Bool;
		
		/**
		 * Create a new LoaderEvent object.
		 * @param type The event type.
		 * @param resource The loaded or parsed resource.
		 * @param url The url of the loaded resource.
		 */
		public function new(type:String, url:String = null, isDependency:Bool = false, errmsg:String = null)
		{
			super(type);
			_url = url;
			_message = errmsg;
			_isDependency = isDependency;
		}
		
		/**
		 * The url of the loaded resource.
		 */
		public var url(get, null) : String;
		public function get_url() : String
		{
			return _url;
		}
		
		/**
		 * The error string on loadError.
		 */
		public var message(get, null) : String;
		public function get_message() : String
		{
			return _message;
		}
		
		/**
		 * Indicates whether the event occurred while loading a dependency, as opposed
		 * to the base file. Dependencies can be textures or other files that are
		 * referenced by the base file.
		 */
		public var isDependency(get, null) : Bool;
		public function get_isDependency() : Bool
		{
			return _isDependency;
		}
		
		/**
		 * @inheritDoc
		 */
		public function preventDefault():Void
		{
			_isDefaultPrevented = true;
		}
		
		/**
		 * @inheritDoc
		 */
		public function isDefaultPrevented():Bool
		{
			return _isDefaultPrevented;
		}
		
		/**
		 * Clones the current event.
		 * @return An exact duplicate of the current event.
		 */
		public override function clone():Event
		{
			return new LoaderEvent(type, _url, _isDependency, _message);
		}
	
	}

