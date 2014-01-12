package away3d.audio;

	import away3d.containers.ObjectContainer3D;
	
	import away3d.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.media.SoundTransform;
	
	/**
	 * SoundTransform3D is a convinience class that helps adjust a Soundtransform's volume and pan according
	 * position and distance of a listener and emitter object. See SimplePanVolumeDriver for the limitations
	 * of this method.
	 */
	class SoundTransform3D
	{
		
		var _scale:Float;
		var _volume:Float;
		var _soundTransform:SoundTransform;
		
		var _emitter:ObjectContainer3D;
		var _listener:ObjectContainer3D;
		
		var _refv:Vector3D;
		var _inv_ref_mtx:Matrix3D;
		var _r:Float;
		var _r2:Float;
		var _azimuth:Float;
		
		/**
		 * Creates a new SoundTransform3D.
		 * @param emitter the ObjectContainer3D from which the sound originates.
		 * @param listener the ObjectContainer3D considered to be to position of the listener (usually, the camera)
		 * @param volume the maximum volume used.
		 * @param scale the distance that the sound covers.
		 *
		 */
		public function new(emitter:ObjectContainer3D = null, listener:ObjectContainer3D = null, volume:Float = 1, scale:Float = 1000)
		{
			
			_emitter = emitter;
			_listener = listener;
			_volume = volume;
			_scale = scale;
			
			_inv_ref_mtx = new Matrix3D();
			_refv = new Vector3D();
			_soundTransform = new SoundTransform(volume);
			
			_r = 0;
			_r2 = 0;
			_azimuth = 0;
		
		}
		
		/**
		 * updates the SoundTransform based on the emitter and listener.
		 */
		public function update():Void
		{
			
			if (_emitter && _listener) {
				_inv_ref_mtx.rawData = _listener.sceneTransform.rawData;
				_inv_ref_mtx.invert();
				_refv = _inv_ref_mtx.deltaTransformVector(_listener.position);
				_refv = _emitter.scenePosition.subtract(_refv);
			}
			
			updateFromVector3D(_refv);
		}
		
		/**
		 * udpates the SoundTransform based on the vector representing the distance and
		 * angle between the emitter and listener.
		 *
		 * @param v Vector3D
		 *
		 */
		public function updateFromVector3D(v:Vector3D):Void
		{
			
			_azimuth = Math.atan2(v.x, v.z);
			if (_azimuth < -1.5707963)
				_azimuth = -(1.5707963 + (_azimuth%1.5707963));
			else if (_azimuth > 1.5707963)
				_azimuth = 1.5707963 - (_azimuth%1.5707963);
			
			// Divide by a number larger than pi/2, to make sure
			// that pan is never full +/-1.0, muting one channel
			// completely, which feels very unnatural. 
			_soundTransform.pan = (_azimuth/1.7);
			
			// Offset radius so that max value for volume curve is 1,
			// (i.e. y~=1 for r=0.) Also scale according to configured
			// driver scale value.
			_r = (v.length/_scale) + 0.28209479;
			_r2 = _r*_r;
			
			// Volume is calculated according to the formula for
			// sound intensity, I = P / (4 * pi * r^2)
			// Avoid division by zero.
			if (_r2 > 0)
				_soundTransform.volume = (1/(12.566*_r2)); // 1 / 4pi * r^2
			else
				_soundTransform.volume = 1;
			
			// Alter according to user-specified volume
			_soundTransform.volume *= _volume;
		
		}
		
		public var soundTransform(get, set) : SoundTransform;
		
		public function get_soundTransform() : SoundTransform
		{
			
			return _soundTransform;
		}
		
		public function set_soundTransform(value:SoundTransform) : SoundTransform
		{
			_soundTransform = value;
			update();
		}
		
		public var scale(get, set) : Float;
		
		public function get_scale() : Float
		{
			return _scale;
		}
		
		public function set_scale(value:Float) : Float
		{
			_scale = value;
			update();
		}
		
		public var volume(get, set) : Float;
		
		public function get_volume() : Float
		{
			return _volume;
		}
		
		public function set_volume(value:Float) : Float
		{
			_volume = value;
			update();
		}
		
		public var emitter(get, set) : ObjectContainer3D;
		
		public function get_emitter() : ObjectContainer3D
		{
			return _emitter;
		}
		
		public function set_emitter(value:ObjectContainer3D) : ObjectContainer3D
		{
			_emitter = value;
			update();
		}
		
		public var listener(get, set) : ObjectContainer3D;
		
		public function get_listener() : ObjectContainer3D
		{
			return _listener;
		}
		
		public function set_listener(value:ObjectContainer3D) : ObjectContainer3D
		{
			_listener = value;
			update();
		}
	
	}

