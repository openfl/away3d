package away3d.debug;

import openfl.errors.Error;

/**
 * Class for emmiting debuging messages, warnings and errors
 */
class Debug
{
	public static var active:Bool = false;
	public static var warningsAsErrors:Bool = false;
	
	public static function clear():Void
	{
	}
	
	public static function delimiter():Void
	{
	}
	
	public static function trace(message:Dynamic):Void
	{
		if (active)
			trace(message);
	}
	
	public static function warning(message:Dynamic):Void
	{
		if (warningsAsErrors) {
			error(message);
			return;
		}
		trace("WARNING: " + message);
	}
	
	public static function error(message:Dynamic):Void
	{
		trace("ERROR: " + message);
		throw new Error(message);
	}
}