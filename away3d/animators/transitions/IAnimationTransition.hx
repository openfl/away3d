package away3d.animators.transitions;

import away3d.animators.*;
import away3d.animators.nodes.*;

interface IAnimationTransition
{
	function getAnimationNode(animator:IAnimator, startNode:AnimationNodeBase, endNode:AnimationNodeBase, startTime:Int):AnimationNodeBase;
}