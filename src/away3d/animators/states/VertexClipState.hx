/**
 *
 */
package away3d.animators.states;

import flash.Vector;
import away3d.animators.nodes.VertexClipNode;
import away3d.core.base.Geometry;

class VertexClipState extends AnimationClipState implements IVertexAnimationState {
    public var currentGeometry(get_currentGeometry, never):Geometry;
    public var nextGeometry(get_nextGeometry, never):Geometry;

    private var _frames:Vector<Geometry>;
    private var _vertexClipNode:VertexClipNode;
    private var _currentGeometry:Geometry;
    private var _nextGeometry:Geometry;
/**
	 * @inheritDoc
	 */

    public function get_currentGeometry():Geometry {
        if (_framesDirty) updateFrames();
        return _currentGeometry;
    }

/**
	 * @inheritDoc
	 */

    public function get_nextGeometry():Geometry {
        if (_framesDirty) updateFrames();
        return _nextGeometry;
    }

    function new(animator:IAnimator, vertexClipNode:VertexClipNode) {
        super(animator, vertexClipNode);
        _vertexClipNode = vertexClipNode;
        _frames = _vertexClipNode.frames;
    }

/**
	 * @inheritDoc
	 */

    override private function updateFrames():Void {
        super.updateFrames();
        _currentGeometry = _frames[_currentFrame];
        if (_vertexClipNode.looping && _nextFrame >= _vertexClipNode.lastFrame) {
            _nextGeometry = _frames[0];
            cast((_animator), VertexAnimator).dispatchCycleEvent();
        }

        else _nextGeometry = _frames[_nextFrame];
    }

/**
	 * @inheritDoc
	 */

    override private function updatePositionDelta():Void {
//TODO:implement positiondelta functionality for vertex animations
    }

}

