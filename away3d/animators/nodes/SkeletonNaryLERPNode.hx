package away3d.animators.nodes;

import away3d.animators.*;
import away3d.animators.states.*;

import openfl.Vector;

/**
 * A skeleton animation node that uses an n-dimensional array of animation node inputs to blend a lineraly interpolated output of a skeleton pose.
 */
class SkeletonNaryLERPNode extends AnimationNodeBase
{
	public var numInputs(get, never):Int;
	
	public var _inputs:Vector<AnimationNodeBase> = new Vector<AnimationNodeBase>();
	private var _numInputs:Int;
	
	private function get_numInputs():Int
	{
		return _numInputs;
	}
	
	/**
	 * Creates a new <code>SkeletonNaryLERPNode</code> object.
	 */
	public function new()
	{
		_stateConstructor = cast SkeletonNaryLERPState.new;
		super();
	}
	
	/**
	 * Returns an integer representing the input index of the given skeleton animation node.
	 *
	 * @param input The skeleton animation node for with the input index is requested.
	 */
	public function getInputIndex(input:AnimationNodeBase):Int
	{
		return _inputs.indexOf(input);
	}
	
	/**
	 * Returns the skeleton animation node object that resides at the given input index.
	 *
	 * @param index The input index for which the skeleton animation node is requested.
	 */
	public function getInputAt(index:Int):AnimationNodeBase
	{
		return _inputs[index];
	}
	
	/**
	 * Adds a new skeleton animation node input to the animation node.
	 */
	public function addInput(input:AnimationNodeBase):Void
	{
		_inputs[_numInputs++] = input;
	}
	
	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):SkeletonNaryLERPState
	{
		return cast(animator.getAnimationState(this), SkeletonNaryLERPState);
	}
}