
package aglsl;

class Destination {

	public var mask : Int;
	public var regnum : Int;
	public var regtype : UInt;
	public var dim : Int;
	public var indexoffset : Int;
	public var swizzle : Int;
	// sampler
	public var lodbiad : Int;
	// sampler
	public var readmode : Int;
	public var special : Int;
	public var wrap : Int;
	public var mipmap : Int;
	public var filter : Int;
	public var indexregtype : Int;
	public var indexselect : Int;
	public var indirectflag : Int;
	public function new() {
		mask = 0;
		regnum = 0;
		regtype = 0;
		dim = 0;
	}

}

