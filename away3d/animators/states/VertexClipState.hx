package away3d.animators.states;

import away3d.core.base.Geometry;
import away3d.animators.*;
import away3d.animators.nodes.*;

import openfl.Vector;

/**
 *
 */
class VertexClipState extends AnimationClipState implements IVertexAnimationState
{
	public var currentGeometry(get, never):Geometry;
	public var nextGeometry(get, never):Geometry;
	
	private var _frames:Vector<Geometry>;
	private var _vertexClipNode:VertexClipNode;
	private var _currentGeometry:Geometry;
	private var _nextGeometry:Geometry;
	
	/**
	 * @inheritDoc
	 */
	private function get_currentGeometry():Geometry
	{
		if (_framesDirty)
			updateFrames();
		
		return _currentGeometry;
	}
	
	/**
	 * @inheritDoc
	 */
	private function get_nextGeometry():Geometry
	{
		if (_framesDirty)
			updateFrames();
		
		return _nextGeometry;
	}
	
	public function new(animator:IAnimator, vertexClipNode:VertexClipNode)
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
			cast(_animator, VertexAnimator).dispatchCycleEvent();
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