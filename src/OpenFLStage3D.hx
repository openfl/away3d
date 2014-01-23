/****
* 
****/

package;

import flash.display.Stage;
import flash.display.Stage3D;
import flash.errors.Error;
import flash.events.ErrorEvent;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
    #if !flash
import flash.display3D.AGLSLContext3D;
import openfl.display.OpenGLView;
import openfl.gl.GL;
import openfl.gl.GLUniformLocation;
    #end
import flash.display3D.IndexBuffer3D;
import flash.geom.Rectangle;
import flash.events.Event;
import flash.Vector;
import flash.display3D.Context3D;



class OpenFLStage3D {   

    #if !flash
    static private var stage3Ds:Vector<Stage3D> = []; 
    #end
	static public function requestAGLSLContext3D(stage3D : Stage3D,?context3DRenderMode:String =  "auto"):Void 
   {
	 #if !flash
      if (OpenGLView.isSupported)   
      {
          stage3D.context3D = new AGLSLContext3D();   
          stage3D.dispatchEvent(new Event(Event.CONTEXT3D_CREATE));
      }else
      {
		  stage3D.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));  
	  }
	#end
	 #if flash
           stage3D.requestContext3D(context3DRenderMode);
	#end
      
   }
    static public function getStage3D(stage : Stage, index : Int) : Stage3D{
        #if flash
        return stage.stage3Ds[index];
        #else
        if(stage3Ds.length > index){
            return stage3Ds[index];
        }else{
            if(index > 0){
                throw "Only 1 Stage3D supported for now";
            }
            var stage3D = new Stage3D();
            stage3Ds[index] = stage3D;
            return stage3D;
        }
        #end
    }

   /**
    * Common API for both cpp and flash to set the render callback
    **/
    inline static public function setRenderCallback(context3D : Context3D, func : Event -> Void) : Void{
        #if flash
        flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, func);
        #elseif (cpp || neko || js)
        context3D.setRenderMethod(func);
        #end
    }

    /**
    * Common API for both cpp and flash to remove the render callback
    **/
    inline static public function removeRenderCallback(context3D : Context3D, func : Event -> Void) : Void{
        #if flash
        flash.Lib.current.removeEventListener(flash.events.Event.ENTER_FRAME, func);
        #elseif (cpp || neko || js)
        context3D.removeRenderMethod(func);
        #end
    }


}
