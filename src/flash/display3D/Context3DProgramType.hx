/****
* 
****/

package flash.display3D;
#if (flash || display)
@:fakeEnum(String) extern enum Context3DProgramType {
	FRAGMENT;
	VERTEX;
}
#else
import openfl.gl.GL;

enum Context3DProgramType {
    VERTEX;
    FRAGMENT;
}

#end