/****
* 
****/

package flash.display3D;
#if (flash || display)
@:fakeEnum(String) extern enum Context3DProfile {
	BASELINE;
	BASELINE_CONSTRAINED;
}
#else
enum Context3DProfile {
    BASELINE;
    BASELINE_CONSTRAINED;
    BASELINE_EXTENDED;
}

#end