/****
* 
****/

package flash.display3D;
#if (flash || display)
@:fakeEnum(String) extern enum Context3DRenderMode {
	AUTO;
	SOFTWARE;
}
#else
enum Context3DRenderMode {
    AUTO;
    SOFTWARE;
}

#end