package away3d.animators.transitions;

import away3d.animators.nodes.AnimationNodeBase;

class CrossfadeTransition implements IAnimationTransition {

    public var blendSpeed:Float;

    public function new(blendSpeed:Float) {
        blendSpeed = 0.5;
        this.blendSpeed = blendSpeed;
    }

    public function getAnimationNode(animator:IAnimator, startNode:AnimationNodeBase, endNode:AnimationNodeBase, startBlend:Int):AnimationNodeBase {
        var crossFadeTransitionNode:CrossfadeTransitionNode = new CrossfadeTransitionNode();
        crossFadeTransitionNode.inputA = startNode;
        crossFadeTransitionNode.inputB = endNode;
        crossFadeTransitionNode.blendSpeed = blendSpeed;
        crossFadeTransitionNode.startBlend = startBlend;
        return crossFadeTransitionNode;
    }

}

