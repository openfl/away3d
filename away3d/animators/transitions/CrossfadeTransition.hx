package away3d.animators.transitions;

import away3d.animators.*;
import away3d.animators.nodes.*;

class CrossfadeTransition implements IAnimationTransition
{
	public var blendSpeed:Float = 0.5;
	
	public function new(blendSpeed:Float)
	{
		this.blendSpeed = blendSpeed;
	}
	
	public function getAnimationNode(animator:IAnimator, startNode:AnimationNodeBase, endNode:AnimationNodeBase, startBlend:Int):AnimationNodeBase
	{
		var crossFadeTransitionNode:CrossfadeTransitionNode = new CrossfadeTransitionNode();
		crossFadeTransitionNode.inputA = startNode;
		crossFadeTransitionNode.inputB = endNode;
		crossFadeTransitionNode.blendSpeed = blendSpeed;
		crossFadeTransitionNode.startBlend = startBlend;
		
		return crossFadeTransitionNode;
	}
}