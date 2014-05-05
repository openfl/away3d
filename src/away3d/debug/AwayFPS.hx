package away3d.debug;

import flash.events.Event;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.Lib;

import haxe.Timer;

import away3d.containers.View3D;

class AwayFPS extends TextField {

	public var currentFPS (default, null):Float;
	
	var _view:View3D;
	var _showRes:Bool;
	
	var cacheCount:Int;
	var times:Array <Float>;
	
	public function new(?view:View3D = null, x:Float = 10, y:Float = 10, color:Int = 0x000000, scale:Float = 4, showRes:Bool = false) {
		super ();
		
		this.x = x;
		this.y = y;

		_view = view;
		_showRes = showRes;
		
		currentFPS = 0;
		selectable = false;
		defaultTextFormat = new TextFormat ("_sans", 12, color);
		text = "";
		
		cacheCount = 0;
		times = [];
		
		addEventListener (Event.ENTER_FRAME, this_onEnterFrame);

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
			if (_view != null)
				appendText("\nPLY: "+_view.renderedFacesCount);			
			if (_showRes)
				appendText("\n"+Lib.current.stage.stageWidth+"/"+Lib.current.stage.stageHeight);
		}
		
		cacheCount = currentCount;
	}
}