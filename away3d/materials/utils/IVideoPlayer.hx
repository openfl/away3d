package away3d.materials.utils;

import openfl.display.Sprite;
import openfl.media.SoundTransform;

interface IVideoPlayer
{
	
	/**
	 * The source, url, to the video file
	 */
	public var source(get, set):String;
	
	/**
	 * Indicates whether the player should loop when video finishes
	 */
	public var loop(get, set):Bool;
	
	/**
	 * Master volume/gain
	 */
	public var volume(get, set):Float;
	
	/**
	 * Panning
	 */
	public var pan(get, set):Float;
	
	/**
	 * Mutes/unmutes the video's audio.
	 */
	public var mute(get, set):Bool;
	
	/**
	 * Provides access to the SoundTransform of the video stream
	 */
	public var soundTransform(get, set):SoundTransform;
	
	/**
	 * Get/Set access to the with of the video object
	 */
	public var width(get, set):Int;
	
	/**
	 * Get/Set access to the height of the video object
	 */
	public var height(get, set):Int;
	
	/**
	 * Provides access to the Video Object
	 */
	public var container(get, never):Sprite;
	
	/**
	 * Indicates whether the video is playing
	 */
	public var playing(get, never):Bool;
	
	/**
	 * Indicates whether the video is paused
	 */
	public var paused(get, never):Bool;
	
	/**
	 * Returns the actual time of the netStream
	 */
	public var time(get, never):Float;
	
	/**
	 * Start playing (or resume if paused) the video.
	 */
	public function play():Void;
	
	/**
	 * Temporarily pause playback. Resume using play().
	 */
	public function pause():Void;
	
	/**
	 *  Seeks to a given time in the video, specified in seconds, with a precision of three decimal places (milliseconds).
	 */
	public function seek(val:Float):Void;
	
	/**
	 * Stop playback and reset playhead.
	 */
	public function stop():Void;
	
	/**
	 * Called if the player is no longer needed
	 */
	public function dispose():Void;
}