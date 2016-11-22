package away3d.core.data;

import openfl.Vector;

class RenderableListItemPool
{
	private var _pool:Vector<RenderableListItem>;
	private var _index:Int;
	private var _poolSize:Int;
	
	public function new()
	{
		_index = 0;
		_poolSize = 0;
		_pool = new Vector<RenderableListItem>();
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
		_pool.length = 0;
	}
}