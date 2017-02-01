package away3d.filters;

import away3d.filters.tasks.Filter3DVBlurTask;

class VBlurFilter3D extends Filter3DBase
{
	public var amount(get, set):Int;
	public var stepSize(get, set):Int;
	
	private var _blurTask:Filter3DVBlurTask;
	
	/**
	 * Creates a new VBlurFilter3D object
	 * @param amount The amount of blur in pixels
	 * @param stepSize The distance between two blur samples. Set to -1 to autodetect with acceptable quality (default value).
	 */
	public function new(amount:Int, stepSize:Int = -1)
	{
		super();
		_blurTask = new Filter3DVBlurTask(amount, stepSize);
		addTask(_blurTask);
	}
	
	private function get_amount():Int
	{
		return _blurTask.amount;
	}
	
	private function set_amount(value:Int):Int
	{
		_blurTask.amount = value;
		return value;
	}
	
	/**
	 * The distance between two blur samples. Set to -1 to autodetect with acceptable quality (default value).
	 * Higher values provide better performance at the cost of reduces quality.
	 */
	private function get_stepSize():Int
	{
		return _blurTask.stepSize;
	}
	
	private function set_stepSize(value:Int):Int
	{
		_blurTask.stepSize = value;
		return value;
	}
}