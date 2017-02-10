package away3d.textures;

import openfl.errors.Error;
import openfl.display3D.Context3DTextureFormat;
import openfl.utils.ByteArray;

class ATFData
{
	public static inline var TYPE_NORMAL:Int = 0x0;
	public static inline var TYPE_CUBE:Int = 0x1;
	
	public var type:Int;
	public var format:Context3DTextureFormat;
	public var width:Int;
	public var height:Int;
	public var numTextures:Int;
	public var data:ByteArray;
	
	/** Create a new instance by parsing the given byte array. */
	public function new(data:ByteArray)
	{
		var sign:String = data.readUTFBytes(3);
		if (sign != "ATF")
			throw new Error("ATF parsing error, unknown format " + sign);
		
		if (data[6] == 255)
			data.position = 12; // new file version
		else
			data.position = 6; // old file version
		
		var tdata:Int = data.readUnsignedByte();
		var _type:Int = tdata >> 7; // UB[1]
		var _format:Int = tdata & 0x7f; // UB[7]
		
		switch (_format) {
			case 0, 1:
				format = Context3DTextureFormat.BGRA;
			case 2, 3:
				format = Context3DTextureFormat.COMPRESSED;
			case 4, 5:
				format = Context3DTextureFormat.COMPRESSED_ALPHA;
				// explicit string to stay compatible
			// with older versions
			default:
				throw new Error("Invalid ATF format");
		}
		
		switch (_type) {
			case 0:
				type = ATFData.TYPE_NORMAL;
			case 1:
				type = ATFData.TYPE_CUBE;
			
			default:
				throw new Error("Invalid ATF type");
		}
		
		this.width = Std.int(Math.pow(2, data.readUnsignedByte()));
		this.height = Std.int(Math.pow(2, data.readUnsignedByte()));
		this.numTextures = data.readUnsignedByte();
		this.data = data;
	}
}