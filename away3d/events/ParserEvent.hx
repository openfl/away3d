package away3d.events;

import openfl.events.Event;

class ParserEvent extends Event
{
	public var message(get, never):String;
	
	private var _message:String;
	
	/**
	 * Dispatched when parsing of an asset completed.
	 */
	public static inline var PARSE_COMPLETE:String = "parseComplete";
	
	/**
	 * Dispatched when an error occurs while parsing the data (e.g. because it's
	 * incorrectly formatted.)
	 */
	public static inline var PARSE_ERROR:String = "parseError";
	
	/**
	 * Dispatched when a parser is ready to have dependencies retrieved and resolved.
	 * This is an internal event that should rarely (if ever) be listened for by
	 * external classes.
	 */
	public static inline var READY_FOR_DEPENDENCIES:String = "readyForDependencies";
	
	public function new(type:String, message:String = "")
	{
		super(type);
		
		_message = message;
	}
	
	/**
	 * Additional human-readable message. Usually supplied for PARSE_ERROR events.
	 */
	private function get_message():String
	{
		return _message;
	}
	
	override public function clone():Event
	{
		return new ParserEvent(type, message);
	}
}