/****
* 
****/

package flash.display3D;
#if (flash || display)
@:fakeEnum(String) extern enum Context3DTriangleFace {
	BACK;
	FRONT;
	FRONT_AND_BACK;
	NONE;
}
#else
import openfl.gl.GL;
 
	
@:coreType abstract    Context3DTriangleFace( Int )   {
	inline function new(a:Int)
    {
		this = a;
	}
	@:from static public inline function fromInt(s:Int) {
		return  new Context3DTriangleFace(s);
	}
	@:to public inline function toInt():Int { 
        return this;
	}
    inline public static var BACK = GL.FRONT;
    inline public static var FRONT = GL.BACK;
    inline public static var FRONT_AND_BACK = GL.FRONT_AND_BACK;
    inline public static var NONE = 0;
}

#end