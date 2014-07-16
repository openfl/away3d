package openfl.display;

import openfl.display3D.Context3D;
import openfl.events.ErrorEvent;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.display.OpenGLView;

class Stage3D extends EventDispatcher 
{
   public var context3D:Context3D;
   public var visible:Bool; // TODO
   public var x:Float; // TODO
   public var y:Float; // TODO

   public function new() {
      super();
   }

   public function requestContext3D(context3DRenderMode:String = "") {
      if (OpenGLView.isSupported) {
          context3D = new Context3D();
          dispatchEvent(new Event(Event.CONTEXT3D_CREATE));
      } else {
          dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));
      }
   }
}
