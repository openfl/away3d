package away3d.audio.drivers;

import openfl.geom.Vector3D;
import openfl.media.Sound;
import openfl.events.EventDispatcher;

class AbstractSound3DDriver extends EventDispatcher
{
	public var sourceSound(get, set):Sound;
	public var volume(get, set):Float;
	public var scale(get, set):Float;
	public var mute(get, set):Bool;
	
	private var _ref_v:Vector3D;
	private var _src:Sound;
	private var _volume:Float;
	private var _scale:Float;
	
	private var _mute:Bool;
	private var _paused:Bool;
	private var _playing:Bool;
	
	public function new()
	{
		_volume = 1;
		_scale = 1000;
		_playing = false;
		super();
	}
	
	private function get_sourceSound():Sound
	{
		return _src;
	}
	
	private function set_sourceSound(val:Sound):Sound
	{
		if (_src == val)
			return val;
		
		_src = val;
		return val;
	}
	
	private function get_volume():Float
	{
		return _volume;
	}
	
	private function set_volume(val:Float):Float
	{
		_volume = val;
		return val;
	}
	
	private function get_scale():Float
	{
		return _scale;
	}
	
	private function set_scale(val:Float):Float
	{
		_scale = val;
		return val;
	}
	
	private function get_mute():Bool
	{
		return _mute;
	}
	
	private function set_mute(val:Bool):Bool
	{
		if (_mute == val)
			return val;
		
		_mute = val;
		return val;
	}
	
	public function updateReferenceVector(v:Vector3D):Void
	{
		this._ref_v = v;
	}
}