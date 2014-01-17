/**
 * Provides an interface for animation node classes that hold animation data for use in the SpriteSheetAnimator class.
 *
 * @see away3d.animators.SpriteSheetAnimator
 */
package away3d.animators.states;


import away3d.animators.data.SpriteSheetAnimationFrame;
interface ISpriteSheetAnimationState extends IAnimationState {
    var currentFrameData(get_currentFrameData, never):SpriteSheetAnimationFrame;
    var currentFrameNumber(get_currentFrameNumber, never):Int;

/**
	 * Returns the current SpriteSheetAnimationFrame of animation in the clip based on the internal playhead position.
	 */
    function get_currentFrameData():SpriteSheetAnimationFrame;
/**
	 * Returns the current frame number.
	 */
    function get_currentFrameNumber():Int;
}

