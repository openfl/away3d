package away3d.audio.drivers;

import openfl.geom.Vector3D;
import openfl.media.Sound;
import openfl.events.IEventDispatcher;

interface ISound3DDriver extends IEventDispatcher {
    var sourceSound(get, set):Sound;
    var scale(get, set):Float;
    var volume(get, set):Float;
    var mute(get, set):Bool;

    /**
	 * The sound object (flash.media.Sound) to play at the point of the sound
	 * source. The output of this sound is modified by the driver before actual
	 * sound output.
	 */
    private function get_sourceSound():Sound;
    private function set_sourceSound(val:Sound):Sound;
    /**
	 * Arbitrary value by which all distances are divided. The default value of
	 * 1000 is usually suitable for scenes with a scale that roughly matches the
	 * standard Away3D scale, i.e. that look good from the default camera position.
	 */
    private function get_scale():Float;
    private function set_scale(val:Float):Float;
    /**
	 * Master volume/gain after 3D modifications to pan/volume have been applied.
	 * Modify this to raise or lower the overall volume regardless of where the
	 * sound source is located.
	 */
    private function get_volume():Float;
    private function set_volume(val:Float):Float;
    /**
	 * Mutes/unmutes the driver completely, which is typically only done (internally
	 * by Sound3D) whenever the sound source is removed from the scene. When true,
	 * any values set to the volume property will be ignored.
	 */
    private function get_mute():Bool;
    private function set_mute(val:Bool):Bool;
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

