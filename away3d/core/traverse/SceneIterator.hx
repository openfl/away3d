package away3d.core.traverse;

	//import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	
	//use namespace arcane;
	
	class SceneIterator
	{
		private static var PRE:Int = 0;
		private static var IN:Int = 1;
		private static var POST:Int = 2;
		
		var _childIndex:Int;
		var _scene:Scene3D;
		var _node:ObjectContainer3D;
		var _traverseState:Int;
		var _childIndexStack:Array<Int>;
		var _stackPos:Int;
		
		public function new(scene:Scene3D)
		{
			_scene = scene;
			reset();
		}
		
		public function reset():Void
		{
			_childIndexStack = new Array<Int>();
			_node = _scene._sceneGraphRoot;
			_childIndex = 0;
			_stackPos = 0;
			_traverseState = PRE;
		}
		
		public function next():ObjectContainer3D
		{
			do {
				switch (_traverseState) {
					case PRE:
						// just entered a node
						_childIndexStack[_stackPos++] = _childIndex;
						_childIndex = 0;
						_traverseState = IN;
						return _node;
					case IN:
						if (_childIndex == _node.numChildren)
							_traverseState = POST;
						else {
							_node = _node.getChildAt(_childIndex);
							_traverseState = PRE;
						}
						break;
					case POST:
						_node = _node.parent;
						_childIndex = _childIndexStack[--_stackPos] + 1;
						_traverseState = IN;
						break;
				}
			} while (!(_node == _scene._sceneGraphRoot && _traverseState == POST));
			
			return null;
		}
	}

