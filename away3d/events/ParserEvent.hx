package away3d.events;

	import flash.events.Event;
	
	class ParserEvent extends Event
	{
		var _message:String;
		
		/**
		 * Dispatched when parsing of an asset completed.
		 */
		public static var PARSE_COMPLETE:String = 'parseComplete';
		
		/**
		 * Dispatched when an error occurs while parsing the data (e.g. because it's
		 * incorrectly formatted.)
		 */
		public static var PARSE_ERROR:String = 'parseError';
		
		/**
		 * Dispatched when a parser is ready to have dependencies retrieved and resolved.
		 * This is an internal event that should rarely (if ever) be listened for by
		 * external classes.
		 */
		public static var READY_FOR_DEPENDENCIES:String = 'readyForDependencies';
		
		public function new(type:String, message:String = '')
		{
			super(type);
			
			_message = message;
		}
		
		/**
		 * Additional human-readable message. Usually supplied for PARSE_ERROR events.
		 */
		public var message(get, null) : String;
		public function get_message() : String
		{
			return _message;
		}
		
		public override function clone():Event
		{
			return new ParserEvent(type, message);
		}
	}

