package away3d.audio.drivers;

	import away3d.audio.SoundTransform3D;
	
	import flash.events.Event;
	import flash.geom.*;
	import flash.media.*;
	
	/**
	 * The Simple pan/volume Sound3D driver will alter the pan and volume properties on the
	 * sound transform object of a regular flash.media.Sound3D representation of the sound. This
	 * is very efficient, but has the drawback that it can only reflect azimuth and distance,
	 * and will disregard elevation. You'll be able to hear whether a
	 */
	class SimplePanVolumeDriver extends AbstractSound3DDriver implements ISound3DDriver
	{
		var _sound_chan:SoundChannel;
		var _pause_position:Float;
		var _st3D:SoundTransform3D;
		
		public function new()
		{
			super();
			
			_ref_v = new Vector3D();
			_st3D = new SoundTransform3D();
		}
		
		public function play():Void
		{
			var pos:Float;
			
			if (_src==null)
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
		
		public var volume(null, set) : Void;
		
		public override function set_volume(val:Float) : Void
		{
			_volume = val;
			_st3D.volume = val;
		}
		
		public var scale(null, set) : Void;
		
		public override function set_scale(val:Float) : Void
		{
			_scale = val;
			_st3D.scale = scale;
		}
		
		public override function updateReferenceVector(v:Vector3D):Void
		{
			super.updateReferenceVector(v);
			
			// Only update sound transform while playing
			if (_playing)
				_updateSoundTransform();
		}
		
		private function _updateSoundTransform():Void
		{
			
			_st3D.updateFromVector3D(_ref_v);
			
			if (_sound_chan)
				_sound_chan.soundTransform = _st3D.soundTransform;
		}
		
		private function onSoundComplete(ev:Event):Void
		{
			this.dispatchEvent(ev.clone());
		}
	}

