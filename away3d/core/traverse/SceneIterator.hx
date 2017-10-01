package away3d.core.traverse;

import away3d.containers.ObjectContainer3D;
import away3d.containers.Scene3D;

import openfl.Vector;

class SceneIterator
{
	private static inline var PRE:Int = 0;
	private static inline var IN:Int = 1;
	private static inline var POST:Int = 2;
	
	private var _childIndex:Int;
	private var _scene:Scene3D;
	private var _node:ObjectContainer3D;
	private var _traverseState:Int;
	private var _childIndexStack:Vector<Int>;
	private var _stackPos:Int;
	
	public function new(scene:Scene3D)
	{
		_scene = scene;
		reset();
	}
	
	public function reset():Void
	{
		_childIndexStack = new Vector<Int>();
		_node = _scene._sceneGraphRoot;
		_childIndex = 0;
		_stackPos = 0;
		_traverseState = PRE;
	}
	
	public function next():ObjectContainer3D
	{
		do {
			switch (_traverseState) {
				case SceneIterator.PRE: // just entered a node
					_childIndexStack[_stackPos++] = _childIndex;
					_childIndex = 0;
					_traverseState = SceneIterator.IN;
					return _node;
				case SceneIterator.IN:
					if (_childIndex == _node.numChildren)
						_traverseState = SceneIterator.POST;
					else {
						_node = _node.getChildAt(_childIndex);
						_traverseState = SceneIterator.PRE;
					}
				case SceneIterator.POST:
					_node = _node.parent;
					_childIndex = _childIndexStack[--_stackPos] + 1;
					_traverseState = SceneIterator.IN;
			}
		} while (!(_node == _scene._sceneGraphRoot && _traverseState == POST));
		
		return null;
	}
}