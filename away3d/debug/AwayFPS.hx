package away3d.debug;

import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.Lib;
import haxe.Timer;


import away3d.containers.View3D;

class AwayFPS extends Sprite {

	var _fps:FPS;
	var _ply:TextField;
	var _view:View3D;

	public function new(view:View3D = null, xOff:Float = 10, yOff:Float = 10, color:Int = 0x000000, scale:Float = 4) {
		super();

		addChild(new FPS(0, 0, color));

		x = xOff;
		y = yOff;
		
		scaleX = scaleY = scale;

		_view = view;
		if (_view != null) {
			_ply = new TextField();
			_ply.defaultTextFormat = new TextFormat ("_sans", 12, color);
			_ply.y = 12;
			addChild(_ply);

			var timer = new haxe.Timer(500);
			timer.run = function() {
				_ply.text = "PLY:"+_view.renderedFacesCount;
			}
		}
	}	
}