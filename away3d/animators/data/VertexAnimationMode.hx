package away3d.animators.data;

/**
 * Options for setting the animation mode of a vertex animator object.
 *
 * @see away3d.animators.VertexAnimator
 */
@:enum abstract VertexAnimationMode(String) from String to String
{
	/**
	 * Animation mode that adds all outputs from active vertex animation state to form the current vertex animation pose.
	 */
	public var ADDITIVE = "additive";
	
	/**
	 * Animation mode that picks the output from a single vertex animation state to form the current vertex animation pose.
	 */
	public var ABSOLUTE = "absolute";
}
