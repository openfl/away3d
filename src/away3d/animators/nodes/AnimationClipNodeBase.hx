package away3d.animators.nodes;

	//import away3d.arcane;
	import away3d.animators.nodes.*;
	
	import flash.geom.*;
	
	//use namespace arcane;
	
	/**
	 * Provides an abstract base class for nodes with time-based animation data in an animation blend tree.
	 */
	class AnimationClipNodeBase extends AnimationNodeBase
	{
		var _looping:Bool = true;
		var _totalDuration:UInt = 0;
		var _lastFrame:UInt;
		
		var _stitchDirty:Bool = true;
		var _stitchFinalFrame:Bool = false;
		var _numFrames:UInt = 0;
		
		var _durations:Array<UInt> = new Array<UInt>();
		var _totalDelta:Vector3D = new Vector3D();
		
		public var fixedFrameRate:Bool = true;
		
		/**
		 * Determines whether the contents of the animation node have looping characteristics enabled.
		 */
		public var looping(get, set) : Bool;
		public function get_looping() : Bool
		{
			return _looping;
		}
		
		public function set_looping(value:Bool) : Bool
		{
			if (_looping == value)
				return;
			
			_looping = value;
			
			_stitchDirty = true;
		}
		
		/**
		 * Defines if looping content blends the final frame of animation data with the first (true) or works on the
		 * assumption that both first and last frames are identical (false). Defaults to false.
		 */
		public var stitchFinalFrame(get, set) : Bool;
		public function get_stitchFinalFrame() : Bool
		{
			return _stitchFinalFrame;
		}
		
		public function set_stitchFinalFrame(value:Bool) : Bool
		{
			if (_stitchFinalFrame == value)
				return;
			
			_stitchFinalFrame = value;
			
			_stitchDirty = true;
		}
		
		public var totalDuration(get, null) : UInt;
		
		public function get_totalDuration() : UInt
		{
			if (_stitchDirty)
				updateStitch();
			
			return _totalDuration;
		}
		
		public var totalDelta(get, null) : Vector3D;
		
		public function get_totalDelta() : Vector3D
		{
			if (_stitchDirty)
				updateStitch();
			
			return _totalDelta;
		}
		
		public var lastFrame(get, null) : UInt;
		
		public function get_lastFrame() : UInt
		{
			if (_stitchDirty)
				updateStitch();
			
			return _lastFrame;
		}
		
		/**
		 * Returns a vector of time values representing the duration (in milliseconds) of each animation frame in the clip.
		 */
		public var durations(get, null) : Array<UInt>;
		public function get_durations() : Array<UInt>
		{
			return _durations;
		}
		
		/**
		 * Creates a new <code>AnimationClipNodeBase</code> object.
		 */
		public function new()
		{
			super();
		}
		
		/**
		 * Updates the node's final frame stitch state.
		 *
		 * @see #stitchFinalFrame
		 */
		private function updateStitch():Void
		{
			_stitchDirty = false;
			
			_lastFrame = (_stitchFinalFrame)? _numFrames : _numFrames - 1;
			
			_totalDuration = 0;
			_totalDelta.x = 0;
			_totalDelta.y = 0;
			_totalDelta.z = 0;
		}
	}

