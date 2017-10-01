package away3d.filters;

import away3d.filters.tasks.Filter3DHueSaturationTask;

class HueSaturationFilter3D extends Filter3DBase
{
	public var saturation(get, set):Float;
	public var r(get, set):Float;
	public var b(get, set):Float;
	public var g(get, set):Float;
	
	private var _hslTask:Filter3DHueSaturationTask;
	
	public function new(saturation:Float = 1, r:Float = 1, g:Float = 1, b:Float = 1)
	{
		super();
		
		_hslTask = new Filter3DHueSaturationTask();
		this.saturation = saturation;
		this.r = r;
		this.g = g;
		this.b = b;
		addTask(_hslTask);
	}
	
	private function get_saturation():Float
	{
		return _hslTask.saturation;
	}
	
	private function set_saturation(value:Float):Float
	{
		if (_hslTask.saturation == value)
			return value;
		_hslTask.saturation = value;
		return value;
	}
	
	private function get_r():Float
	{
		return _hslTask.r;
	}
	
	private function set_r(value:Float):Float
	{
		if (_hslTask.r == value)
			return value;
		_hslTask.r = value;
		return value;
	}
	
	private function get_b():Float
	{
		return _hslTask.b;
	}
	
	private function set_b(value:Float):Float
	{
		if (_hslTask.b == value)
			return value;
		_hslTask.b = value;
		return value;
	}
	
	private function get_g():Float
	{
		return _hslTask.g;
	}
	
	private function set_g(value:Float):Float
	{
		if (_hslTask.g == value)
			return value;
		_hslTask.g = value;
		return value;
	}
}