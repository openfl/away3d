package away3d.animators.nodes;

import away3d.animators.data.SpriteSheetAnimationFrame;

/**
 * Provides an interface for animation node classes that hold animation data for use in the SpriteSheetAnimator class.
 *
 * @see away3d.animators.SpriteSheetAnimator
 */
interface ISpriteSheetAnimationNode
{
	/**
	 * Returns the current SpriteSheetAnimationFrame of animation in the clip based on the internal playhead position.
	 */
	var currentFrameData(get, never):SpriteSheetAnimationFrame;
	
	/**
	 * Returns the current frame number.
	 */
	var currentFrameNumber(get, never):Int;
}
