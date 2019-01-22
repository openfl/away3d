package away3d.animators.states;

import away3d.animators.*;
import away3d.animators.nodes.*;
import away3d.events.*;

import openfl.Vector;

/**
 *
 */
class AnimationClipState extends AnimationStateBase
{
	public var blendWeight(get, never):Float;
	public var currentFrame(get, never):Int;
	public var nextFrame(get, never):Int;
	
	private var _animationClipNode:AnimationClipNodeBase;
	private var _animationStatePlaybackComplete:AnimationStateEvent;
	private var _blendWeight:Float = 0;
	private var _currentFrame:Int;
	private var _nextFrame:Int;
	
	private var _oldFrame:Int;
	private var _timeDir:Int;
	private var _framesDirty:Bool = true;
	
	/**
	 * Returns a fractional value between 0 and 1 representing the blending ratio of the current playhead position
	 * between the current frame (0) and next frame (1) of the animation.
	 *
	 * @see #currentFrame
	 * @see #nextFrame
	 */
	private function get_blendWeight():Float
	{
		if (_framesDirty)
			updateFrames();
		
		return _blendWeight;
	}
	
	/**
	 * Returns the current frame of animation in the clip based on the internal playhead position.
	 */
	private function get_currentFrame():Int
	{
		if (_framesDirty)
			updateFrames();
		
		return _currentFrame;
	}
	
	/**
	 * Returns the next frame of animation in the clip based on the internal playhead position.
	 */
	private function get_nextFrame():Int
	{
		if (_framesDirty)
			updateFrames();
		
		return _nextFrame;
	}
	
	public function new(animator:IAnimator, animationClipNode:AnimationClipNodeBase)
	{
		super(animator, animationClipNode);
		
		_animationClipNode = animationClipNode;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function update(time:Int):Void
	{
		if (!_animationClipNode.looping) {
			if (time > _startTime + _animationClipNode.totalDuration)
				time = _startTime + _animationClipNode.totalDuration;
			else if (time < _startTime)
				time = _startTime;
		}
		
		if (_time == time - _startTime)
			return;
		
		updateTime(time);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function phase(value:Float):Void
	{
		var time:Int = Std.int(value*_animationClipNode.totalDuration + _startTime);
		
		if (_time == time - _startTime)
			return;
		
		updateTime(time);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateTime(time:Int):Void
	{
		_framesDirty = true;
		
		_timeDir = (time - _startTime > _time)? 1 : -1;
		
		super.updateTime(time);
	}
	
	/**
	 * Updates the nodes internal playhead to determine the current and next animation frame, and the blendWeight between the two.
	 *
	 * @see #currentFrame
	 * @see #nextFrame
	 * @see #blendWeight
	 */
	private function updateFrames():Void
	{
		_framesDirty = false;
		
		var looping:Bool = _animationClipNode.looping;
		var totalDuration:Int = _animationClipNode.totalDuration;
		var lastFrame:Int = _animationClipNode.lastFrame;
		var time:Int = _time;
		
		//trace("time", time, totalDuration)
		if (looping && (time >= totalDuration || time < 0) && totalDuration > 0) {
			time %= totalDuration;
			if (time < 0)
				time += totalDuration;
		}
		
		if (!looping && time >= totalDuration) {
			notifyPlaybackComplete();
			_currentFrame = lastFrame;
			_nextFrame = lastFrame;
			_blendWeight = 0;
		} else if (!looping && time <= 0) {
			_currentFrame = 0;
			_nextFrame = 0;
			_blendWeight = 0;
		} else if (_animationClipNode.fixedFrameRate) {
			var t:Float = totalDuration > 0 ? time/totalDuration*lastFrame : 0;
			_currentFrame = Std.int(t);
			_blendWeight = t - _currentFrame;
			_nextFrame = _currentFrame + 1;
		} else {
			_currentFrame = 0;
			_nextFrame = 0;
			
			var dur:Int = 0, frameTime:Int;
			var durations:Vector<UInt> = _animationClipNode.durations;
			
			do {
				frameTime = dur;
				dur += durations[nextFrame];
				_currentFrame = _nextFrame++;
			} while (time > dur);
			
			if (_currentFrame == lastFrame) {
				_currentFrame = 0;
				_nextFrame = 1;
			}
			
			_blendWeight = (time - frameTime)/durations[_currentFrame];
		}
	}

	private function notifyPlaybackComplete():Void
	{
		if (_animationStatePlaybackComplete == null)
			_animationStatePlaybackComplete = new AnimationStateEvent(AnimationStateEvent.PLAYBACK_COMPLETE, _animator, this, _animationClipNode);
		_animationClipNode.dispatchEvent(_animationStatePlaybackComplete);
	}
}