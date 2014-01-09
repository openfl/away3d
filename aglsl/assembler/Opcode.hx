package aglsl.assembler;

class Opcode
{
	
	public var dest:String;
	public var a:FS;
	public var b:FS;
	public var opcode:Int;
	public var flags:Flags;
	
	public function new( ?dest:String, ?aformat:String, ?asize:Int, ?bformat:String, ?bsize:Int, ?opcode:Int, ?simple:Bool, ?horizontal:Bool, ?fragonly:Bool, ?matrix:Bool )
	{
		this.a = new FS();
		this.b = new FS();
		this.flags = new Flags();
		
		this.dest = dest;
		this.a.format = aformat;
		this.a.size = asize;
		this.b.format = bformat;
		this.b.size = bsize;
		this.opcode = opcode;
		this.flags.simple = simple;
		this.flags.horizontal = horizontal;
		this.flags.fragonly = fragonly;
		this.flags.matrix = matrix;
	}
}

class FS
{
	public function new() {}
	
	public var format:String;
	public var size:Int;
}

class Flags
{
	public function new() {}

	public var simple:Bool;
	public var horizontal:Bool;
	public var fragonly:Bool;
	public var matrix:Bool;
}