/****
* 
****/

package flash.display;

#if (flash || display)
@:require(flash11) extern class Stage3D extends flash.events.EventDispatcher {
	var context3D(default,null) : flash.display3D.Context3D;
	var visible : Bool;
	var x : Float;
	var y : Float;
	function requestContext3D(?context3DRenderMode : String, ?profile : flash.display3D.Context3DProfile) : Void;
}
#else
import flash.display3D.Context3D;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.EventDispatcher;
import openfl.display.OpenGLView;

class Stage3D extends EventDispatcher 
{
   public var context3D:Context3D;
   public var visible:Bool; // TODO
   public var x:Float; // TODO
   public var y:Float; // TODO

   public function new() 
   {
      super();
   }

   public function requestContext3D(context3DRenderMode:String = ""):Void 
   {
      if (OpenGLView.isSupported) 
      {
          context3D = new Context3D();
          dispatchEvent(new Event(Event.CONTEXT3D_CREATE));
      }else
      {
            dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));
      }
   }
}

#end