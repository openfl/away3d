package away3d.animators.transitions;

import away3d.animators.states.SkeletonBinaryLERPState;
import away3d.events.AnimationStateEvent;

class CrossfadeTransitionState extends SkeletonBinaryLERPState {

    private var _crossfadeTransitionNode:CrossfadeTransitionNode;
    private var _animationStateTransitionComplete:AnimationStateEvent;

    function new(animator:IAnimator, crossfadeTransitionNode:CrossfadeTransitionNode) {
        super(animator, crossfadeTransitionNode);
        _crossfadeTransitionNode = crossfadeTransitionNode;
    }

    /**
	 * @inheritDoc
	 */
    override private function updateTime(time:Int):Void {
        blendWeight = Math.abs(time - _crossfadeTransitionNode.startBlend) / (1000 * _crossfadeTransitionNode.blendSpeed);
        if (blendWeight >= 1) {
            blendWeight = 1;
            if (_animationStateTransitionComplete == null) {
                _animationStateTransitionComplete = new AnimationStateEvent(AnimationStateEvent.TRANSITION_COMPLETE, _animator, this, _crossfadeTransitionNode);
            }
            _crossfadeTransitionNode.dispatchEvent(_animationStateTransitionComplete);
        }
        super.updateTime(time);
    }
}

