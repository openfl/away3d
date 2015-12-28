package away3d.materials.utils;

import openfl.display.Sprite;
import openfl.media.SoundTransform;

interface IVideoPlayer {
    var source(get, set):String;
    var loop(get, set):Bool;
    var volume(get, set):Float;
    var pan(get, set):Float;
    var mute(get, set):Bool;
    var soundTransform(get, set):SoundTransform;
    var width(get, set):Int;
    var height(get, set):Int;
    var container(get, never):Sprite;
    var playing(get, never):Bool;
    var paused(get, never):Bool;
    var time(get, never):Float;

    /**
	 * The source, url, to the video file
	 */
    private function get_source():String;
    private function set_source(src:String):String;
    /**
	 * Indicates whether the player should loop when video finishes
	 */
    private function get_loop():Bool;
    private function set_loop(val:Bool):Bool;
    /**
	 * Master volume/gain
	 */
    private function get_volume():Float;
    private function set_volume(val:Float):Float;
    /**
	 * Panning
	 */
    private function get_pan():Float;
    private function set_pan(val:Float):Float;
    /**
	 * Mutes/unmutes the video's audio.
	 */
    private function get_mute():Bool;
    private function set_mute(val:Bool):Bool;
    /**
	 * Provides access to the SoundTransform of the video stream
	 */
    private function get_soundTransform():SoundTransform;
    private function set_soundTransform(val:SoundTransform):SoundTransform;
    /**
	 * Get/Set access to the with of the video object
	 */
    private function get_width():Int;
    private function set_width(val:Int):Int;
    /**
	 * Get/Set access to the height of the video object
	 */
    private function get_height():Int;
    private function set_height(val:Int):Int;
    /**
	 * Provides access to the Video Object
	 */
    private function get_container():Sprite;
    /**
	 * Indicates whether the video is playing
	 */
    private function get_playing():Bool;
    /**
	 * Indicates whether the video is paused
	 */
    private function get_paused():Bool;
    /**
	 * Returns the actual time of the netStream
	 */
    private function get_time():Float;
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

