package away3d.animators.nodes;

import away3d.animators.*;
import away3d.animators.states.*;

/**
 * A skeleton animation node that uses two animation node inputs to blend a lineraly interpolated output of a skeleton pose.
 */
class SkeletonBinaryLERPNode extends AnimationNodeBase
{
	/**
	 * Defines input node A to use for the blended output.
	 */
	public var inputA:AnimationNodeBase;
	
	/**
	 * Defines input node B to use for the blended output.
	 */
	public var inputB:AnimationNodeBase;
	
	/**
	 * Creates a new <code>SkeletonBinaryLERPNode</code> object.
	 */
	public function new()
	{
		super();
		_stateConstructor = cast SkeletonBinaryLERPState.new;
	}
	
	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):SkeletonBinaryLERPState
	{
		return cast(animator.getAnimationState(this), SkeletonBinaryLERPState);
	}
}