/****
* 
****/

package flash.display3D;
#if (flash || display)
@:fakeEnum(String) extern enum Context3DWrapMode {
	CLAMP;
	REPEAT;
}
#else
enum Context3DWrapMode {
    CLAMP;
    REPEAT;
}

#end