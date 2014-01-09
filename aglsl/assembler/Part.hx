package aglsl.assembler;

import flash.utils.ByteArray;
import flash.utils.Endian;

class Part
{
	public var name:String;
	public var version:Int;
	public var data:ByteArray;
	
	public function new( name:String = null, version:Int = null )
	{
		this.name = name;
		this.version = version;
		this.data = new ByteArray();
		this.data.endian = Endian.LITTLE_ENDIAN;
	}
}
