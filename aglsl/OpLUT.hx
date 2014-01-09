package aglsl;

class OpLUT
{
	
	public var s:String;
	public var flags:UInt;
	public var dest:Bool;
	public var a:Bool;
	public var b:Bool;
	public var matrixwidth:UInt;
	public var matrixheight:UInt;
	public var ndwm:Bool;
	public var scalar:Bool;
	public var dm:Bool;
	public var lod:Bool;
	
	public function new ( ?s:String, ?flags:UInt, ?dest:Bool, ?a:Bool, ?b:Bool,
				 ?matrixwidth:UInt, ?matrixheight:UInt, ?ndwm:Bool,
				 ?scaler:Bool, ?dm:Bool, ?lod:Bool )
	{
		this.s = s;
		this.flags = flags;
		this.dest = dest;
		this.a = a;
		this.b = b;
		this.matrixwidth = matrixwidth;
		this.matrixheight = matrixheight;
		this.ndwm = ndwm;
		this.scalar = scaler;
		this.dm = dm;
		this.lod = lod;
	}
}