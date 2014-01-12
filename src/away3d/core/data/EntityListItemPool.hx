package away3d.core.data;

	
	class EntityListItemPool
	{
		var _pool:Array<EntityListItem>;
		var _index:Int;
		var _poolSize:Int;
		
		public function new()
		{
			_pool = new Array<EntityListItem>();
		}
		
		public function getItem():EntityListItem
		{
			var item:EntityListItem;
			if (_index == _poolSize) {
				item = new EntityListItem();
				_pool[_index++] = item;
				++_poolSize;
			} else
				item = _pool[_index++];
			return item;
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

