package away3d.debug;

import flash.events.Event;
import flash.text.TextField;
import flash.text.TextFormat;
import haxe.Timer;

import away3d.containers.View3D;

class AwayFPS extends TextField {

	public var currentFPS (default, null):Float;
	
	var _view:View3D;
	
	var cacheCount:Int;
	var times:Array <Float>;
	
	public function new(?view:View3D = null, x:Float = 10, y:Float = 10, color:Int = 0x000000, scale:Float = 4) {
		super ();
		
		this.x = x;
		this.y = y;
		
		currentFPS = 0;
		selectable = false;
		defaultTextFormat = new TextFormat ("_sans", 12, color);
		text = "";
		
		cacheCount = 0;
		times = [];
		
		addEventListener (Event.ENTER_FRAME, this_onEnterFrame);
		
		_view = view;

		this.scaleX = this.scaleY = scale;
	}

	private function this_onEnterFrame (event:Event):Void {
		var currentTime = Timer.stamp ();
		times.push (currentTime);
		
		while (times[0] < currentTime - 1) {
			times.shift ();			
		}
		
		var currentCount = times.length;
		currentFPS = Math.round ((currentCount + cacheCount) / 2);
		
		if (currentCount != cacheCount && visible) {			
			text = "FPS: " + currentFPS;
			if (_view != null) {
				appendText("\nPLY: "+_view.renderedFacesCount);
			}			
		}
		
		cacheCount = currentCount;
	}
}