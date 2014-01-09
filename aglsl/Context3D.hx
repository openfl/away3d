package aglsl;

import aglsl.Sampler;

class Context3D
{
	
	public var enableErrorChecking:Bool;    
	public var resources:Array<Dynamic>;
	public var driverInfo:String;
	
	public static var maxvertexconstants:UInt = 128; 
	public static var maxfragconstants:UInt = 28; 
	public static var maxtemp:UInt = 8;
	public static var maxstreams:UInt = 8; 
	public static var maxtextures:UInt = 8;   
	public static var defaultsampler:Sampler = new Sampler();
	
	public function new()
	{
		enableErrorChecking = false;    
		resources = [];
		driverInfo = "Call getter function instead";
	}
}
