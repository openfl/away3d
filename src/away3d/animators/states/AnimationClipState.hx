package away3d.animators.states;

	import away3d.animators.*;
	import away3d.animators.nodes.*;
	import away3d.events.*;
	
	/**
	 *
	 */
	class AnimationClipState extends AnimationStateBase
	{
		var _animationClipNode:AnimationClipNodeBase;
		var _animationStatePlaybackComplete:AnimationStateEvent;
		var _blendWeight:Float;
		var _currentFrame:UInt;
		var _nextFrame:UInt;
		
		var _oldFrame:UInt;
		var _timeDir:Int;
		var _framesDirty:Bool = true;
		
		/**
		 * Returns a fractional value between 0 and 1 representing the blending ratio of the current playhead position
		 * between the current frame (0) and next frame (1) of the animation.
		 *
		 * @see #currentFrame
		 * @see #nextFrame
		 */
		public var blendWeight(get, null) : Float;
		public function get_blendWeight() : Float
		{
			if (_framesDirty)
				updateFrames();
			
			return _blendWeight;
		}
		
		/**
		 * Returns the current frame of animation in the clip based on the internal playhead position.
		 */
		public var currentFrame(get, null) : UInt;
		public function get_currentFrame() : UInt
		{
			if (_framesDirty)
				updateFrames();
			
			return _currentFrame;
		}
		
		/**
		 * Returns the next frame of animation in the clip based on the internal playhead position.
		 */
		public var nextFrame(get, null) : UInt;
		public function get_nextFrame() : UInt
		{
			if (_framesDirty)
				updateFrames();
			
			return _nextFrame;
		}
		
		function AnimationClipState(animator:IAnimator, animationClipNode:AnimationClipNodeBase)
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
			var time:Int = value*_animationClipNode.totalDuration + _startTime;
			
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
			var totalDuration:UInt = _animationClipNode.totalDuration;
			var lastFrame:UInt = _animationClipNode.lastFrame;
			var time:Int = _time;
			
			//trace("time", time, totalDuration)
			if (looping && (time >= totalDuration || time < 0)) {
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
				var t:Float = time/totalDuration*lastFrame;
				_currentFrame = t;
				_blendWeight = t - _currentFrame;
				_nextFrame = _currentFrame + 1;
			} else {
				_currentFrame = 0;
				_nextFrame = 0;
				
				var dur:UInt = 0, frameTime:UInt;
				var durations:Array<UInt> = _animationClipNode.durations;
				
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
			if (!_animationStatePlaybackComplete) _animationStatePlaybackComplete = new AnimationStateEvent(AnimationStateEvent.PLAYBACK_COMPLETE, _animator, this, _animationClipNode));
			_animationClipNode.dispatchEvent(_animationStatePlaybackComplete);
		}
	}

