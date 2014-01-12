package away3d.animators.transitions;

	import away3d.animators.*;
	import away3d.animators.states.*;
	import away3d.events.*;
	
	/**
	 *
	 */
	class CrossfadeTransitionState extends SkeletonBinaryLERPState
	{
		var _skeletonAnimationNode:CrossfadeTransitionNode;
		var _animationStateTransitionComplete:AnimationStateEvent;
		
		function CrossfadeTransitionState(animator:IAnimator, skeletonAnimationNode:CrossfadeTransitionNode)
		{
			super(animator, skeletonAnimationNode);
			
			_skeletonAnimationNode = skeletonAnimationNode;
		}
		
		/**
		 * @inheritDoc
		 */
		override private function updateTime(time:Int):Void
		{
			blendWeight = Math.abs(time - _skeletonAnimationNode.startBlend)/(1000*_skeletonAnimationNode.blendSpeed);
			
			if (blendWeight >= 1) {
				blendWeight = 1;
				if (!_animationStateTransitionComplete) _animationStateTransitionComplete = new AnimationStateEvent(AnimationStateEvent.TRANSITION_COMPLETE, _animator, this, _skeletonAnimationNode)
				_skeletonAnimationNode.dispatchEvent(_animationStateTransitionComplete);
			}
			
			super.updateTime(time);
		}
	}

