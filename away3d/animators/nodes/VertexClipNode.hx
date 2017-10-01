package away3d.animators.nodes;

import away3d.animators.states.*;
import away3d.core.base.*;

import openfl.geom.*;
import openfl.Vector;

/**
 * A vertex animation node containing time-based animation data as individual geometry obejcts.
 */
class VertexClipNode extends AnimationClipNodeBase
{
	public var frames(get, never):Vector<Geometry>;
	
	private var _frames:Vector<Geometry> = new Vector<Geometry>();
	private var _translations:Vector<Vector3D> = new Vector<Vector3D>();
	
	/**
	 * Returns a vector of geometry frames representing the vertex values of each animation frame in the clip.
	 */
	private function get_frames():Vector<Geometry>
	{
		return _frames;
	}
	
	/**
	 * Creates a new <code>VertexClipNode</code> object.
	 */
	public function new()
	{
		_stateConstructor = cast VertexClipState.new;
		super();
	}
	
	/**
	 * Adds a geometry object to the internal timeline of the animation node.
	 *
	 * @param geometry The geometry object to add to the timeline of the node.
	 * @param duration The specified duration of the frame in milliseconds.
	 * @param translation The absolute translation of the frame, used in root delta calculations for mesh movement.
	 */
	public function addFrame(geometry:Geometry, duration:Int, translation:Vector3D = null):Void
	{
		_frames.push(geometry);
		_durations.push(duration);
		if (translation != null) {
			_translations.push(translation);
		} else {
			_translations.push(new Vector3D());
		}
		_numFrames = _durations.length;
		
		_stitchDirty = true;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateStitch():Void
	{
		super.updateStitch();
		
		var i:Int = _numFrames - 1;
		var p1:Vector3D, p2:Vector3D, delta:Vector3D;
		while (i-- > 0) {
			_totalDuration += _durations[i];
			p1 = _translations[i];
			p2 = _translations[i + 1];
			delta = p2.subtract(p1);
			_totalDelta.x += delta.x;
			_totalDelta.y += delta.y;
			_totalDelta.z += delta.z;
		}
		
		if (_stitchFinalFrame && _looping) {
			_totalDuration += _durations[_numFrames - 1];
			if (_numFrames > 1) {
				p1 = _translations[0];
				p2 = _translations[1];
				delta = p2.subtract(p1);
				_totalDelta.x += delta.x;
				_totalDelta.y += delta.y;
				_totalDelta.z += delta.z;
			}
		}
	}
}