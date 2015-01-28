package away3d.animators.transitions;


import away3d.animators.nodes.AnimationNodeBase;

interface IAnimationTransition {

    function getAnimationNode(animator:IAnimator, startNode:AnimationNodeBase, endNode:AnimationNodeBase, startTime:Int):AnimationNodeBase;
}

