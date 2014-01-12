package away3d.core.data;

	
	class RenderableListItemPool
	{
		var _pool:Array<RenderableListItem>;
		var _index:Int;
		var _poolSize:Int;
		
		public function new()
		{
			_pool = new Array<RenderableListItem>();
		}
		
		public function getItem():RenderableListItem
		{
			if (_index == _poolSize) {
				var item:RenderableListItem = new RenderableListItem();
				_pool[_index++] = item;
				++_poolSize;
				return item;
			} else
				return _pool[_index++];
		}
		
		public function freeAll():Void
		{
			_index = 0;
		}
		
		public function dispose():Void
		{
			_pool = null;
		}
	}

