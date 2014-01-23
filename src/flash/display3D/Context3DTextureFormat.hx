/****
* 
****/

package flash.display3D;
#if (flash || display)
@:fakeEnum(String) extern enum Context3DTextureFormat {
	BGRA;
	BGRA_PACKED;
	BGR_PACKED;
	COMPRESSED;
	COMPRESSED_ALPHA;
}
#else
enum Context3DTextureFormat {
    BGRA;
    COMPRESSED;
    COMPRESSED_ALPHA;
}

#end