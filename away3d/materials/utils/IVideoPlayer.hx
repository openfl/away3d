package away3d.materials.utils;

	import flash.display.Sprite;
	import flash.media.SoundTransform;
	
	interface IVideoPlayer
	{
		
		/**
		 * The source, url, to the video file
		 */
		function get source():String;
		
		function set source(src:String):Void;
		
		/**
		 * Indicates whether the player should loop when video finishes
		 */
		function get loop():Bool;
		
		function set loop(val:Bool):Void;
		
		/**
		 * Master volume/gain
		 */
		function get volume():Float;
		
		function set volume(val:Float):Void;
		
		/**
		 * Panning
		 */
		function get pan():Float;
		
		function set pan(val:Float):Void;
		
		/**
		 * Mutes/unmutes the video's audio.
		 */
		function get mute():Bool;
		
		function set mute(val:Bool):Void;
		
		/**
		 * Provides access to the SoundTransform of the video stream
		 */
		function get soundTransform():SoundTransform;
		
		function set soundTransform(val:SoundTransform):Void;
		
		/**
		 * Get/Set access to the with of the video object
		 */
		function get width():Int;
		
		function set width(val:Int):Void;
		
		/**
		 * Get/Set access to the height of the video object
		 */
		function get height():Int;
		
		function set height(val:Int):Void;
		
		/**
		 * Provides access to the Video Object
		 */
		function get container():Sprite;
		
		/**
		 * Indicates whether the video is playing
		 */
		function get playing():Bool;
		
		/**
		 * Indicates whether the video is paused
		 */
		function get paused():Bool;
		
		/**
		 * Returns the actual time of the netStream
		 */
		function get time():Float;
		
		/**
		 * Start playing (or resume if paused) the video.
		 */
		function play():Void;
		
		/**
		 * Temporarily pause playback. Resume using play().
		 */
		function pause():Void;
		
		/**
		 *  Seeks to a given time in the video, specified in seconds, with a precision of three decimal places (milliseconds).
		 */
		function seek(val:Float):Void;
		
		/**
		 * Stop playback and reset playhead.
		 */
		function stop():Void;
		
		/**
		 * Called if the player is no longer needed
		 */
		function dispose():Void;
	
	}

