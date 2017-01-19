package away3d.events;

import away3d.animators.*;
import away3d.animators.states.*;
import away3d.animators.nodes.*;

import openfl.events.Event;

/**
 * Dispatched to notify changes in an animation state's state.
 */
class AnimationStateEvent extends Event
{
	public var animator(get, never):IAnimator;
	public var animationState(get, never):IAnimationState;
	public var animationNode(get, never):AnimationNodeBase;
	
	/**
	 * Dispatched when a non-looping clip node inside an animation state reaches the end of its timeline.
	 */
	public static inline var PLAYBACK_COMPLETE:String = "playbackComplete";
	
	public static inline var TRANSITION_COMPLETE:String = "transitionComplete";
	
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
	public function new(type:String, animator:IAnimator, animationState:IAnimationState, animationNode:AnimationNodeBase)
	{
		super(type, false, false);
		
		_animator = animator;
		_animationState = animationState;
		_animationNode = animationNode;
	}
	
	/**
	 * The animator object that is the subject of this event.
	 */
	private function get_animator():IAnimator
	{
		return _animator;
	}
	
	/**
	 * The animation state object that is the subject of this event.
	 */
	private function get_animationState():IAnimationState
	{
		return _animationState;
	}
	
	/**
	 * The animation node inside the animation state from which the event originated.
	 */
	private function get_animationNode():AnimationNodeBase
	{
		return _animationNode;
	}
	
	/**
	 * Clones the event.
	 *
	 * @return An exact duplicate of the current object.
	 */
	override public function clone():Event
	{
		return new AnimationStateEvent(type, _animator, _animationState, _animationNode);
	}
}