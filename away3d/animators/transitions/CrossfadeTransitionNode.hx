package away3d.animators.transitions;

import away3d.animators.nodes.*;

/**
 * A skeleton animation node that uses two animation node inputs to blend a lineraly interpolated output of a skeleton pose.
 */
class CrossfadeTransitionNode extends SkeletonBinaryLERPNode
{
	public var blendSpeed:Float;
	
	public var startBlend:Int;
	
	/**
	 * Creates a new <code>CrossfadeTransitionNode</code> object.
	 */
	public function new()
	{
		super();
		_stateConstructor = cast CrossfadeTransitionState.new;	
	}
}