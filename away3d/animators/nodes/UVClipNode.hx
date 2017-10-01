package away3d.animators.nodes;

import away3d.animators.states.*;
import away3d.animators.data.*;

import openfl.Vector;

/**
 * A uv animation node containing time-based animation data as individual uv animation frames.
 */
class UVClipNode extends AnimationClipNodeBase
{
	public var frames(get, never):Vector<UVAnimationFrame>;

	private var _frames:Vector<UVAnimationFrame> = new Vector<UVAnimationFrame>();
	
	/**
	 * Returns a vector of UV frames representing the uv values of each animation frame in the clip.
	 */
	private function get_frames():Vector<UVAnimationFrame>
	{
		return _frames;
	}
	
	/**
	 * Creates a new <code>UVClipNode</code> object.
	 */
	public function new()
	{
		_stateConstructor = cast UVClipState.new;
		super();
	}
	
	/**
	 * Adds a UV frame object to the internal timeline of the animation node.
	 *
	 * @param uvFrame The uv frame object to add to the timeline of the node.
	 * @param duration The specified duration of the frame in milliseconds.
	 */
	public function addFrame(uvFrame:UVAnimationFrame, duration:Int):Void
	{
		_frames.push(uvFrame);
		_durations.push(duration);
		_numFrames = _durations.length;
		
		_stitchDirty = true;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateStitch():Void
	{
		super.updateStitch();
		var i:Int;
		
		if (_durations.length > 0) {
			
			i = _numFrames - 1;
			while (i-- > 0)
				_totalDuration += _durations[i];
			
			if (_stitchFinalFrame || !_looping)
				_totalDuration += _durations[_numFrames - 1];
		}
		
	}
}