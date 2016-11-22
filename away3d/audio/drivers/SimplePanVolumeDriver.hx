package away3d.audio.drivers;

import away3d.audio.SoundTransform3D;

import openfl.errors.Error;
import openfl.events.Event;
import openfl.geom.Vector3D;
import openfl.media.SoundChannel;

/**
 * The Simple pan/volume Sound3D driver will alter the pan and volume properties on the
 * sound transform object of a regular openfl.media.Sound3D representation of the sound. This
 * is very efficient, but has the drawback that it can only reflect azimuth and distance,
 * and will disregard elevation. You'll be able to hear whether a
 */
class SimplePanVolumeDriver extends AbstractSound3DDriver implements ISound3DDriver
{
	private var _sound_chan:SoundChannel;
	private var _pause_position:Float;
	private var _st3D:SoundTransform3D;
	
	public function new()
	{
		super();
		
		_ref_v = new Vector3D();
		_st3D = new SoundTransform3D();
	}
	
	public function play():Void
	{
		var pos:Float;
		
		if (_src == null)
			throw new Error('SimplePanVolumeDriver.play(): No sound source to play.');
		
		_playing = true;
		
		// Update sound transform first. This has not happened while
		// the sound was not playing, so needs to be done now.
		_updateSoundTransform();
		
		// Start playing. If paused, resume from pause position. Else,
		// start from beginning of file.
		pos = _paused? _pause_position : 0;
		_sound_chan = _src.play(pos, 0, _st3D.soundTransform);
		_sound_chan.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
	}
	
	public function pause():Void
	{
		_paused = true;
		_pause_position = _sound_chan.position;
		_sound_chan.stop();
		_sound_chan.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
	}
	
	public function stop():Void
	{
		_sound_chan.stop();
		_sound_chan.removeEventListener(Event.SOUND_COMPLETE, onSoundComplete);
	}
	
	override private function set_volume(val:Float):Float
	{
		_volume = val;
		_st3D.volume = val;
		return val;
	}
	
	override private function set_scale(val:Float):Float
	{
		_scale = val;
		_st3D.scale = scale;
		return val;
	}
	
	override public function updateReferenceVector(v:Vector3D):Void
	{
		super.updateReferenceVector(v);
		
		// Only update sound transform while playing
		if (_playing)
			_updateSoundTransform();
	}
	
	private function _updateSoundTransform():Void
	{
		
		_st3D.updateFromVector3D(_ref_v);
		
		if (_sound_chan != null)
			_sound_chan.soundTransform = _st3D.soundTransform;
	}
	
	private function onSoundComplete(ev:Event):Void
	{
		this.dispatchEvent(ev.clone());
	}
}