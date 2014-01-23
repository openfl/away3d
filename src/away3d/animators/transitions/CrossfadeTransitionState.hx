/**
 *
 */
package away3d.animators.transitions;

import away3d.animators.states.SkeletonBinaryLERPState;
import away3d.events.AnimationStateEvent;

class CrossfadeTransitionState extends SkeletonBinaryLERPState {

    private var __skeletonAnimationNode:CrossfadeTransitionNode;
    private var _animationStateTransitionComplete:AnimationStateEvent;

    function new(animator:IAnimator, skeletonAnimationNode:CrossfadeTransitionNode) {
        super(animator, skeletonAnimationNode);
        __skeletonAnimationNode = skeletonAnimationNode;
    }

/**
	 * @inheritDoc
	 */

    override private function updateTime(time:Int):Void {
        blendWeight = Math.abs(time - __skeletonAnimationNode.startBlend) / (1000 * __skeletonAnimationNode.blendSpeed);
        if (blendWeight >= 1) {
            blendWeight = 1;
            if (_animationStateTransitionComplete == null) {
                _animationStateTransitionComplete = new AnimationStateEvent(AnimationStateEvent.TRANSITION_COMPLETE, _animator, this, __skeletonAnimationNode);
            }
            _skeletonAnimationNode.dispatchEvent(_animationStateTransitionComplete);
        }
        super.updateTime(time);
    }

}

