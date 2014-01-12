package away3d.animators.nodes;

	import away3d.animators.states.*;
	import away3d.animators.data.*;
	
	/**
	 * A SpriteSheetClipNode containing time-based animation data as individual sprite sheet animation frames.
	 */
	class SpriteSheetClipNode extends AnimationClipNodeBase
	{
		var _frames:Array<SpriteSheetAnimationFrame> = new Array<SpriteSheetAnimationFrame>();
		
		/**
		 * Creates a new <code>SpriteSheetClipNode</code> object.
		 */
		public function new()
		{
			_stateClass = SpriteSheetAnimationState;
		}
		
		/**
		 * Returns a vector of SpriteSheetAnimationFrame representing the uv values of each animation frame in the clip.
		 */
		public var frames(get, null) : Array<SpriteSheetAnimationFrame>;
		public function get_frames() : Array<SpriteSheetAnimationFrame>
		{
			return _frames;
		}
		
		/**
		 * Adds a SpriteSheetAnimationFrame object to the internal timeline of the animation node.
		 *
		 * @param spriteSheetAnimationFrame The frame object to add to the timeline of the node.
		 * @param duration The specified duration of the frame in milliseconds.
		 */
		public function addFrame(spriteSheetAnimationFrame:SpriteSheetAnimationFrame, duration:UInt):Void
		{
			_frames.push(spriteSheetAnimationFrame);
			_durations.push(duration);
			_numFrames = _durations.length;
			
			_stitchDirty = false;
		}
	}

