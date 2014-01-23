package away3d.audio.drivers;

import flash.geom.Vector3D;
import flash.media.Sound;
import flash.events.IEventDispatcher;

interface ISound3DDriver extends IEventDispatcher {
    var sourceSound(get_sourceSound, set_sourceSound):Sound;
    var scale(get_scale, set_scale):Float;
    var volume(get_volume, set_volume):Float;
    var mute(get_mute, set_mute):Bool;

/**
	 * The sound object (flash.media.Sound) to play at the point of the sound
	 * source. The output of this sound is modified by the driver before actual
	 * sound output.
	 */
    function get_sourceSound():Sound;
    function set_sourceSound(val:Sound):Sound;
/**
	 * Arbitrary value by which all distances are divided. The default value of
	 * 1000 is usually suitable for scenes with a scale that roughly matches the
	 * standard Away3D scale, i.e. that look good from the default camera position.
	 */
    function get_scale():Float;
    function set_scale(val:Float):Float;
/**
	 * Master volume/gain after 3D modifications to pan/volume have been applied.
	 * Modify this to raise or lower the overall volume regardless of where the
	 * sound source is located.
	 */
    function get_volume():Float;
    function set_volume(val:Float):Float;
/**
	 * Mutes/unmutes the driver completely, which is typically only done (internally
	 * by Sound3D) whenever the sound source is removed from the scene. When true,
	 * any values set to the volume property will be ignored.
	 */
    function get_mute():Bool;
    function set_mute(val:Bool):Bool;
/**
	 * Start playing (or resume if paused) the audio. This is NOT The same thing
	 * as invoking play() on the flash.media.Sound object used as the source sound
	 * for the driver.
	 */
    function play():Void;
/**
	 * Temporarily pause playback. Resume using play().
	 */
    function pause():Void;
/**
	 * Stop playback and reset playhead. Subsequent play() calls will restart the
	 * playback from the beginning of the sound file.
	 */
    function stop():Void;
/**
	 * Change the position of the sound source relative to the listener, known as
	 * the reference vector. This is invoked by the Sound3D object when it's position
	 * changes, and should typically not be called by any other code.
	 *
	 * @param v Sound source position vector relative to the listener.
	 */
    function updateReferenceVector(v:Vector3D):Void;
}

