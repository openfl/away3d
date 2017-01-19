package away3d.errors;

import openfl.errors.Error;

class DeprecationError extends Error
{
	public var since(get, never):String;
	public var source(get, never):String;
	public var info(get, never):String;
	
	private var _since:String;
	private var _source:String;
	private var _info:String;
	
	public function new(source:String, since:String, info:String)
	{
		super(source + " has been marked as deprecated since version " + since + " and has been slated for removal. " + info);
		_since = since;
		_source = source;
		_info = info;
	}
	
	private function get_since():String
	{
		return _since;
	}
	
	private function get_source():String
	{
		return _source;
	}
	
	private function get_info():String
	{
		return _info;
	}
}