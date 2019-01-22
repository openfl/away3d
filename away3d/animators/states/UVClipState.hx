package away3d.animators.states;

import away3d.animators.*;
import away3d.animators.data.*;
import away3d.animators.nodes.*;

import openfl.Vector;

class UVClipState extends AnimationClipState implements IUVAnimationState
{
	public var currentUVFrame(get, never):UVAnimationFrame;
	public var nextUVFrame(get, never):UVAnimationFrame;
	
	private var _frames:Vector<UVAnimationFrame>;
	private var _uvClipNode:UVClipNode;
	private var _currentUVFrame:UVAnimationFrame;
	private var _nextUVFrame:UVAnimationFrame;
	
	/**
	 * @inheritDoc
	 */
	private function get_currentUVFrame():UVAnimationFrame
	{
		if (_framesDirty)
			updateFrames();
		
		return _currentUVFrame;
	}
	
	/**
	 * @inheritDoc
	 */
	private function get_nextUVFrame():UVAnimationFrame
	{
		if (_framesDirty)
			updateFrames();
		
		return _nextUVFrame;
	}
	
	public function new(animator:IAnimator, uvClipNode:UVClipNode)
	{
		super(animator, uvClipNode);
		
		_uvClipNode = uvClipNode;
		_frames = _uvClipNode.frames;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateFrames():Void
	{
		super.updateFrames();
		
		if (_frames.length > 0) {
			
			if (_frames.length == 2 && _currentFrame == 0) {
				
				_currentUVFrame = _frames[1];
				_nextUVFrame = _frames[0];
				
			} else {
				
				_currentUVFrame = _frames[_currentFrame];
				
				if (_uvClipNode.looping && _nextFrame >= _uvClipNode.lastFrame)
					_nextUVFrame = _frames[0];
				else
					_nextUVFrame = _frames[_nextFrame];
				
			}
			
		}
	}
}