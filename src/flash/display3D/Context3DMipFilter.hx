/****
* 
****/

package flash.display3D;

#if (flash || display)
@:fakeEnum(String) extern enum Context3DMipFilter {
	MIPLINEAR;
	MIPNEAREST;
	MIPNONE;
}
#else

enum Context3DMipFilter {
    MIPLINEAR;
    MIPNEAREST;
    MIPNONE;
}

#end