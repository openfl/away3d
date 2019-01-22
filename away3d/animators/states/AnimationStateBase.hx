package away3d.animators.states;

import away3d.animators.*;
import away3d.animators.nodes.*;

import openfl.geom.Vector3D;

class AnimationStateBase implements IAnimationState
{
	public var positionDelta(get, never):Vector3D;

	private var _animationNode:AnimationNodeBase;
	private var _rootDelta:Vector3D = new Vector3D();
	private var _positionDeltaDirty:Bool = true;
	
	private var _time:Int = 0;
	private var _startTime:Int = 0;
	private var _animator:IAnimator;
	
	/**
	 * Returns a 3d vector representing the translation delta of the animating entity for the current timestep of animation
	 */
	private function get_positionDelta():Vector3D
	{
		if (_positionDeltaDirty)
			updatePositionDelta();
		
		return _rootDelta;
	}
	
	public function new(animator:IAnimator, animationNode:AnimationNodeBase)
	{
		_animator = animator;
		_animationNode = animationNode;
	}
	
	/**
	 * Resets the start time of the node to a  new value.
	 *
	 * @param startTime The absolute start time (in milliseconds) of the node's starting time.
	 */
	public function offset(startTime:Int):Void
	{
		_startTime = startTime;
		
		_positionDeltaDirty = true;
	}
	
	/**
	 * Updates the configuration of the node to its current state.
	 *
	 * @param time The absolute time (in milliseconds) of the animator's play head position.
	 *
	 * @see away3d.animators.AnimatorBase#update()
	 */
	public function update(time:Int):Void
	{
		if (_time == time - _startTime)
			return;
		
		updateTime(time);
	}
	
	/**
	 * Sets the animation phase of the node.
	 *
	 * @param value The phase value to use. 0 represents the beginning of an animation clip, 1 represents the end.
	 */
	public function phase(value:Float):Void
	{
	}
	
	/**
	 * Updates the node's internal playhead position.
	 *
	 * @param time The local time (in milliseconds) of the node's playhead position.
	 */
	private function updateTime(time:Int):Void
	{
		_time = time - _startTime;
		
		_positionDeltaDirty = true;
	}
	
	/**
	 * Updates the node's root delta position
	 */
	private function updatePositionDelta():Void
	{
	}
}