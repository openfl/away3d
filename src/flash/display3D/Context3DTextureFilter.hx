/****
* 
****/

package flash.display3D;
#if (flash || display)
@:fakeEnum(String) extern enum Context3DTextureFilter {
	LINEAR;
	NEAREST;
}
#else
enum Context3DTextureFilter {
    LINEAR;
    NEAREST;
}

#end