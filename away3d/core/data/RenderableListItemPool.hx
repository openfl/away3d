package away3d.core.data;

class RenderableListItemPool {

    private var _pool:Array<RenderableListItem>;
    private var _index:Int;
    private var _poolSize:Int;

    public function new() {
		_index = 0;
		_poolSize = 0;
        _pool = new Array<RenderableListItem>();
    }

    public function getItem():RenderableListItem {
        if (_index == _poolSize) {
            var item:RenderableListItem = new RenderableListItem();
            _pool[_index++] = item;
            ++_poolSize;
            return item;
        }

        else return _pool[_index++];
    }

    public function freeAll():Void {
        _index = 0;
    }

    public function dispose():Void {
        _pool = [];
    }
}

