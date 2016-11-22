package away3d.core.data;

import openfl.Vector;

class EntityListItemPool
{
	private var _pool:Vector<EntityListItem>;
	private var _index:Int;
	private var _poolSize:Int;
	
	public function new()
	{
		_index = 0;
		_poolSize = 0;
		_pool = new Vector<EntityListItem>();
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
		_pool.length = 0;
	}
}