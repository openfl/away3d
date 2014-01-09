package away3d.materials.utils;

	import flash.display.Sprite;
	import flash.events.AsyncErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	class SimpleVideoPlayer implements IVideoPlayer
	{
		
		var _src:String;
		var _video:Video;
		var _ns:NetStream;
		var _nc:NetConnection;
		var _nsClient:Object;
		var _soundTransform:SoundTransform;
		var _loop:Bool;
		var _playing:Bool;
		var _paused:Bool;
		var _lastVolume:Float;
		var _container:Sprite;
		
		public function new()
		{
			
			// default values
			_soundTransform = new SoundTransform();
			_loop = false;
			_playing = false;
			_paused = false;
			_lastVolume = 1;
			
			// client object that'll redirect various calls from the video stream
			_nsClient = {};
			_nsClient["onCuePoint"] = metaDataHandler;
			_nsClient["onMetaData"] = metaDataHandler;
			_nsClient["onBWDone"] = onBWDone;
			_nsClient["close"] = streamClose;
			
			// NetConnection
			_nc = new NetConnection();
			_nc.client = _nsClient;
			_nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
			_nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler, false, 0, true);
			_nc.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler, false, 0, true);
			_nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler, false, 0, true);
			_nc.connect(null);
			
			// NetStream
			_ns = new NetStream(_nc);
			_ns.checkPolicyFile = true;
			_ns.client = _nsClient;
			_ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler, false, 0, true);
			_ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler, false, 0, true);
			_ns.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler, false, 0, true);
			
			// video
			_video = new Video();
			_video.attachNetStream(_ns);
			
			// container
			_container = new Sprite();
			_container.addChild(_video);
		}
		
		//////////////////////////////////////////////////////
		// public methods
		//////////////////////////////////////////////////////
		
		public function play():Void
		{
			
			if (!_src) {
				trace("Video source not set.");
				return;
			}
			
			if (_paused) {
				_ns.resume();
				_paused = false;
				_playing = true;
			} else if (!_playing) {
				_ns.play(_src);
				_playing = true;
				_paused = false;
			}
		}
		
		public function pause():Void
		{
			if (!_paused) {
				_ns.pause();
				_paused = true;
			}
		}
		
		public function seek(val:Float):Void
		{
			pause();
			_ns.seek(val);
			_ns.resume();
		}
		
		public function stop():Void
		{
			_ns.close();
			_playing = false;
			_paused = false;
		}
		
		public function dispose():Void
		{
			
			_ns.close();
			
			_video.attachNetStream(null);
			
			_ns.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			_ns.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
			_ns.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			
			_nc.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			_nc.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			_nc.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			_nc.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
			
			_nsClient["onCuePoint"] = null;
			_nsClient["onMetaData"] = null;
			_nsClient["onBWDone"] = null;
			_nsClient["close"] = null;
			
			_container.removeChild(_video);
			_container = null;
			
			_src = null;
			_ns = null;
			_nc = null;
			_nsClient = null;
			_video = null;
			_soundTransform = null;
			
			_playing = false;
			_paused = false;
		
		}
		
		//////////////////////////////////////////////////////
		// event handlers
		//////////////////////////////////////////////////////
		
		private function asyncErrorHandler(event:AsyncErrorEvent):Void
		{
			// Must be present to prevent errors, but won't do anything
		}
		
		private function metaDataHandler(oData:Object = null):Void
		{
			// Offers info such as oData.duration, oData.width, oData.height, oData.framerate and more (if encoded into the FLV)
			//this.dispatchEvent( new VideoEvent(VideoEvent.METADATA,_netStream,file,oData) );
		}
		
		private function ioErrorHandler(e:IOErrorEvent):Void
		{
			trace("An IOerror occured: " + e.text);
		}
		
		private function securityErrorHandler(e:SecurityErrorEvent):Void
		{
			trace("A security error occured: " + e.text + " Remember that the FLV must be in the same security sandbox as your SWF.");
		}
		
		private function onBWDone():Void
		{
			// Must be present to prevent errors for RTMP, but won't do anything
		}
		
		private function streamClose():Void
		{
			trace("The stream was closed. Incorrect URL?");
		}
		
		private function netStatusHandler(e:NetStatusEvent):Void
		{
			switch (e.info["code"]) {
				case "NetStream.Play.Stop":
					//this.dispatchEvent( new VideoEvent(VideoEvent.STOP,_netStream, file) ); 
					if (loop)
						_ns.play(_src);
					
					break;
				case "NetStream.Play.Play":
					//this.dispatchEvent( new VideoEvent(VideoEvent.PLAY,_netStream, file) );
					break;
				case "NetStream.Play.StreamNotFound":
					trace("The file " + _src + " was not found", e);
					break;
				case "NetConnection.Connect.Success":
					trace("Connected to stream", e);
					break;
			}
		}
		
		//////////////////////////////////////////////////////
		// get / set functions
		//////////////////////////////////////////////////////
		
		public var source(get, set) : String;
		
		public function get_source() : String
		{
			return _src;
		}
		
		public function set_source(src:String) : String
		{
			_src = src;
			if (_playing)
				_ns.play(_src);
		}
		
		public var loop(get, set) : Bool;
		
		public function get_loop() : Bool
		{
			return _loop;
		}
		
		public function set_loop(val:Bool) : Bool
		{
			_loop = val;
		}
		
		public var volume(get, set) : Float;
		
		public function get_volume() : Float
		{
			return _ns.soundTransform.volume;
		}
		
		public function set_volume(val:Float) : Float
		{
			_soundTransform.volume = val;
			_ns.soundTransform = _soundTransform;
			_lastVolume = val;
		}
		
		public var pan(get, set) : Float;
		
		public function get_pan() : Float
		{
			return _ns.soundTransform.pan;
		}
		
		public function set_pan(val:Float) : Float
		{
			_soundTransform.pan = pan;
			_ns.soundTransform = _soundTransform;
		}
		
		public var mute(get, set) : Bool;
		
		public function get_mute() : Bool
		{
			return _ns.soundTransform.volume == 0;
		}
		
		public function set_mute(val:Bool) : Bool
		{
			_soundTransform.volume = (val)? 0 : _lastVolume;
			_ns.soundTransform = _soundTransform;
		}
		
		public var soundTransform(get, set) : SoundTransform;
		
		public function get_soundTransform() : SoundTransform
		{
			return _ns.soundTransform;
		}
		
		public function set_soundTransform(val:SoundTransform) : SoundTransform
		{
			_ns.soundTransform = val;
		}
		
		public var width(get, set) : Int;
		
		public function get_width() : Int
		{
			return _video.width;
		}
		
		public function set_width(val:Int) : Int
		{
			_video.width = val;
		}
		
		public var height(get, set) : Int;
		
		public function get_height() : Int
		{
			return _video.height;
		}
		
		public function set_height(val:Int) : Int
		{
			_video.height = val;
		}
		
		//////////////////////////////////////////////////////
		// read-only vars
		//////////////////////////////////////////////////////
		
		public var container(get, null) : Sprite;
		
		public function get_container() : Sprite
		{
			return _container;
		}
		
		public var time(get, null) : Float;
		
		public function get_time() : Float
		{
			return _ns.time;
		}
		
		public var playing(get, null) : Bool;
		
		public function get_playing() : Bool
		{
			return _playing;
		}
		
		public var paused(get, null) : Bool;
		
		public function get_paused() : Bool
		{
			return _paused;
		}
	
	}

