/**
 * Dispatched to notify changes in an animation state's state.
 */
package away3d.events;

import away3d.animators.nodes.AnimationNodeBase;
import away3d.animators.states.IAnimationState;
import away3d.animators.IAnimator;
import flash.events.Event;

class AnimationStateEvent extends Event {
    public var animator(get_animator, never):IAnimator;
    public var animationState(get_animationState, never):IAnimationState;
    public var animationNode(get_animationNode, never):AnimationNodeBase;

/**
	 * Dispatched when a non-looping clip node inside an animation state reaches the end of its timeline.
	 */
    static public var PLAYBACK_COMPLETE:String = "playbackComplete";
    static public var TRANSITION_COMPLETE:String = "transitionComplete";
    private var _animator:IAnimator;
    private var _animationState:IAnimationState;
    private var _animationNode:AnimationNodeBase;
/**
	 * Create a new <code>AnimatonStateEvent</code>
	 *
	 * @param type The event type.
	 * @param animator The animation state object that is the subject of this event.
	 * @param animationNode The animation node inside the animation state from which the event originated.
	 */

    public function new(type:String, animator:IAnimator, animationState:IAnimationState, animationNode:AnimationNodeBase) {
        super(type, false, false);
        _animator = animator;
        _animationState = animationState;
        _animationNode = animationNode;
    }

/**
	 * The animator object that is the subject of this event.
	 */

    public function get_animator():IAnimator {
        return _animator;
    }

/**
	 * The animation state object that is the subject of this event.
	 */

    public function get_animationState():IAnimationState {
        return _animationState;
    }

/**
	 * The animation node inside the animation state from which the event originated.
	 */

    public function get_animationNode():AnimationNodeBase {
        return _animationNode;
    }

/**
	 * Clones the event.
	 *
	 * @return An exact duplicate of the current object.
	 */

    override public function clone():Event {
        return new AnimationStateEvent(type, _animator, _animationState, _animationNode);
    }

}

