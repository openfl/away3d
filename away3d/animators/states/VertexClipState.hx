package away3d.animators.states;

	import away3d.core.base.Geometry;
	import away3d.animators.*;
	import away3d.animators.nodes.*;
	
	/**
	 *
	 */
	class VertexClipState extends AnimationClipState implements IVertexAnimationState
	{
		var _frames:Array<Geometry>;
		var _vertexClipNode:VertexClipNode;
		var _currentGeometry:Geometry;
		var _nextGeometry:Geometry;
		
		/**
		 * @inheritDoc
		 */
		public var currentGeometry(get, null) : Geometry;
		public function get_currentGeometry() : Geometry
		{
			if (_framesDirty)
				updateFrames();
			
			return _currentGeometry;
		}
		
		/**
		 * @inheritDoc
		 */
		public var nextGeometry(get, null) : Geometry;
		public function get_nextGeometry() : Geometry
		{
			if (_framesDirty)
				updateFrames();
			
			return _nextGeometry;
		}
		
		function VertexClipState(animator:IAnimator, vertexClipNode:VertexClipNode)
		{
			super(animator, vertexClipNode);
			
			_vertexClipNode = vertexClipNode;
			_frames = _vertexClipNode.frames;
		}
		
		/**
		 * @inheritDoc
		 */
		override private function updateFrames():Void
		{
			super.updateFrames();
			
			_currentGeometry = _frames[_currentFrame];
			
			if (_vertexClipNode.looping && _nextFrame >= _vertexClipNode.lastFrame) {
				_nextGeometry = _frames[0];
				VertexAnimator(_animator).dispatchCycleEvent();
			} else
				_nextGeometry = _frames[_nextFrame];
		}
		
		/**
		 * @inheritDoc
		 */
		override private function updatePositionDelta():Void
		{
			//TODO:implement positiondelta functionality for vertex animations
		}
	}

