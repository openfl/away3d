package away3d.animators.states;

import away3d.core.base.*;

/**
 * Provides an interface for animation node classes that hold animation data for use in the Vertex animator class.
 *
 * @see away3d.animators.VertexAnimator
 */
interface IVertexAnimationState extends IAnimationState
{
	/**
	 * Returns the current geometry frame of animation in the clip based on the internal playhead position.
	 */
	var currentGeometry(get, never):Geometry;
	
	/**
	 * Returns the current geometry frame of animation in the clip based on the internal playhead position.
	 */
	var nextGeometry(get, never):Geometry;
	
	/**
	 * Returns a fractional value between 0 and 1 representing the blending ratio of the current playhead position
	 * between the current geometry frame (0) and next geometry frame (1) of the animation.
	 */
	var blendWeight(get, never):Float;
}