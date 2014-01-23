
package aglsl;

class Context3D {

	static public var enableErrorChecking : Bool = false;
	static public var resources : Array<Dynamic> = [];
	static public var driverInfo : String = "Call getter function instead";
	static public var maxvertexconstants : Int = 128;
	static public var maxfragconstants : Int = 28;
	static public var maxtemp : Int = 8;
	static public var maxstreams : Int = 8;
	static public var maxtextures : Int = 8;
	static public var defaultsampler : Sampler = new Sampler();
	public function new() {
	}

}

