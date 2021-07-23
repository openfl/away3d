package away3d.loaders.parsers.utils;

import openfl.utils.ByteArray;

class ParserUtil
{
	
	/**
	 * Returns a object as ByteArray, if possible.
	 * 
	 * @param data The object to return as ByteArray
	 * 
	 * @return The ByteArray or null
	 *
	 */
	public static function toByteArray(data:Dynamic):ByteArray
	{
		if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(data, Class))
			data = Type.createInstance(data,[]);
		
		if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(data, ByteArrayData))
			return data;
		else
			return null;
	}
	
	/**
	 * Returns a object as String, if possible.
	 * 
	 * @param data The object to return as String
	 * @param length The length of the returned String
	 * 
	 * @return The String or null
	 *
	 */
	public static function toString(data:Dynamic, length:UInt = 0):String
	{
		var ba:ByteArray;
		
		if (length==0) length = 0xffffffff;
		
		if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(data, String)) {
			var dS:String = cast data;
			return dS.substr(0, Std.int(Math.min(length, dS.length)));
		}
		
		ba = toByteArray(data);
		if (ba != null) {
			ba.position = 0;
			return ba.readUTFBytes(Std.int(Math.min(ba.bytesAvailable, length)));
		}
		
		return null;
	}
}