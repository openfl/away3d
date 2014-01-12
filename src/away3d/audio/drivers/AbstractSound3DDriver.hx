package away3d.audio.drivers;

	import flash.events.EventDispatcher;
	import flash.geom.*;
	import flash.media.*;
	
	class AbstractSound3DDriver extends EventDispatcher
	{
		var _ref_v:Vector3D;
		var _src:Sound;
		var _volume:Float;
		var _scale:Float;
		
		var _mute:Bool;
		var _paused:Bool;
		var _playing:Bool;
		
		public function new()
		{
			_volume = 1;
			_scale = 1000;
			_playing = false;
		}
		
		public var sourceSound(get, set) : Sound;
		
		public function get_sourceSound() : Sound
		{
			return _src;
		}
		
		public function set_sourceSound(val:Sound) : Sound
		{
			if (_src == val)
				return;
			
			_src = val;
		}
		
		public var volume(get, set) : Float;
		
		public function get_volume() : Float
		{
			return _volume;
		}
		
		public function set_volume(val:Float) : Float
		{
			_volume = val;
		}
		
		public var scale(get, set) : Float;
		
		public function get_scale() : Float
		{
			return _scale;
		}
		
		public function set_scale(val:Float) : Float
		{
			_scale = val;
		}
		
		public var mute(get, set) : Bool;
		
		public function get_mute() : Bool
		{
			return _mute;
		}
		
		public function set_mute(val:Bool) : Bool
		{
			if (_mute == val)
				return;
			
			_mute = val;
		}
		
		public function updateReferenceVector(v:Vector3D):Void
		{
			this._ref_v = v;
		}
	}

