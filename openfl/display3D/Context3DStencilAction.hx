/****
* 
****/

package openfl.display3D;
#if display
@:fakeEnum(String) extern enum Context3DStencilAction {
	DECREMENT_SATURATE;
	DECREMENT_WRAP;
	INCREMENT_SATURATE;
	INCREMENT_WRAP;
	INVERT;
	KEEP;
	SET;
	ZERO;
}
#end