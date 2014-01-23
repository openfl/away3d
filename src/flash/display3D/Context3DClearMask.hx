/****
* 
****/

package flash.display3D;
#if (flash || display)
extern class Context3DClearMask {
	static var ALL : Int;
	static var COLOR : Int;
	static var DEPTH : Int;
	static var STENCIL : Int;
}
#else
import openfl.gl.GL;

class Context3DClearMask {
    inline static public var ALL:Int = COLOR | DEPTH | STENCIL;
    inline static public var COLOR:Int = GL.COLOR_BUFFER_BIT;
    inline static public var DEPTH:Int = GL.DEPTH_BUFFER_BIT;
    inline static public var STENCIL:Int = GL.STENCIL_BUFFER_BIT;
}

#end