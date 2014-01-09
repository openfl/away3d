package away3d.animators.states;

	//import away3d.arcane;
	import away3d.animators.*;
	import away3d.animators.data.*;
	import away3d.animators.nodes.*;
	
	//use namespace arcane;
	
	class SpriteSheetAnimationState extends AnimationClipState implements ISpriteSheetAnimationState
	{
		var _frames:Array<SpriteSheetAnimationFrame>;
		var _clipNode:SpriteSheetClipNode;
		var _currentFrameID:UInt = 0;
		var _reverse:Bool;
		var _back:Bool;
		var _backAndForth:Bool;
		var _forcedFrame:Bool;
		
		function SpriteSheetAnimationState(animator:IAnimator, clipNode:SpriteSheetClipNode)
		{
			super(animator, clipNode);
			
			_clipNode = clipNode;
			_frames = _clipNode.frames;
		}
		
		public var reverse(null, set) : Void;
		
		public function set_reverse(b:Bool) : Void
		{
			_back = false;
			_reverse = b;
		}
		
		public var backAndForth(null, set) : Void;
		
		public function set_backAndForth(b:Bool) : Void
		{
			if (b)
				_reverse = false;
			_back = false;
			_backAndForth = b;
		}
		
		/**
		 * @inheritDoc
		 */
		public var currentFrameData(get, null) : SpriteSheetAnimationFrame;
		public function get_currentFrameData() : SpriteSheetAnimationFrame
		{
			if (_framesDirty)
				updateFrames();
			
			return _frames[_currentFrameID];
		}
		
		/**
		 * returns current frame index of the animation.
		 * The index is zero based and counts from first frame of the defined animation.
		 */
		public var currentFrameNumber(get, set) : UInt;
		public function get_currentFrameNumber() : UInt
		{
			return _currentFrameID;
		}
		
		public function set_currentFrameNumber(frameNumber:UInt) : UInt
		{
			_currentFrameID = (frameNumber > _frames.length - 1 )? _frames.length - 1 : frameNumber;
			_forcedFrame = true;
		}
		
		/**
		 * returns the total frames for the current animation.
		 */
		public var totalFrames(get, null) : UInt;
		public function get_totalFrames() : UInt
		{
			return (_frames==null)? 0 : _frames.length;
		}
		
		/**
		 * @inheritDoc
		 */
		override private function updateFrames():Void
		{
			if (_forcedFrame) {
				_forcedFrame = false;
				return;
			}
			
			super.updateFrames();
			
			if (_reverse) {
				
				if (_currentFrameID - 1 > -1)
					_currentFrameID--;
				
				else {
					
					if (_clipNode.looping) {
						
						if (_backAndForth) {
							_reverse = false;
							_currentFrameID++;
						} else
							_currentFrameID = _frames.length - 1;
					}
					
					SpriteSheetAnimator(_animator).dispatchCycleEvent();
				}
				
			} else {
				
				if (_currentFrameID < _frames.length - 1)
					_currentFrameID++;
				
				else {
					
					if (_clipNode.looping) {
						
						if (_backAndForth) {
							_reverse = true;
							_currentFrameID--;
						} else
							_currentFrameID = 0;
					}
					
					SpriteSheetAnimator(_animator).dispatchCycleEvent();
				}
			}
		
		}
	}

