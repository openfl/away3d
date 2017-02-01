package away3d.filters;

import away3d.filters.tasks.Filter3DRadialBlurTask;

class RadialBlurFilter3D extends Filter3DBase
{
	public var intensity(get, set):Float;
	public var glowGamma(get, set):Float;
	public var blurStart(get, set):Float;
	public var blurWidth(get, set):Float;
	public var cx(get, set):Float;
	public var cy(get, set):Float;
	
	private var _blurTask:Filter3DRadialBlurTask;
	
	public function new(intensity:Float = 8.0, glowGamma:Float = 1.6, blurStart:Float = 1.0, blurWidth:Float = -0.3, cx:Float = 0.5, cy:Float = 0.5)
	{
		super();
		_blurTask = new Filter3DRadialBlurTask(intensity, glowGamma, blurStart, blurWidth, cx, cy);
		addTask(_blurTask);
	}
	
	private function get_intensity():Float
	{
		return _blurTask.intensity;
	}
	
	private function set_intensity(intensity:Float):Float
	{
		_blurTask.intensity = intensity;
		return intensity;
	}
	
	private function get_glowGamma():Float
	{
		return _blurTask.glowGamma;
	}
	
	private function set_glowGamma(glowGamma:Float):Float
	{
		_blurTask.glowGamma = glowGamma;
		return glowGamma;
	}
	
	private function get_blurStart():Float
	{
		return _blurTask.blurStart;
	}
	
	private function set_blurStart(blurStart:Float):Float
	{
		_blurTask.blurStart = blurStart;
		return blurStart;
	}
	
	private function get_blurWidth():Float
	{
		return _blurTask.blurWidth;
	}
	
	private function set_blurWidth(blurWidth:Float):Float
	{
		_blurTask.blurWidth = blurWidth;
		return blurWidth;
	}
	
	private function get_cx():Float
	{
		return _blurTask.cx;
	}
	
	private function set_cx(cx:Float):Float
	{
		_blurTask.cx = cx;
		return cx;
	}
	
	private function get_cy():Float
	{
		return _blurTask.cy;
	}
	
	private function set_cy(cy:Float):Float
	{
		_blurTask.cy = cy;
		return cy;
	}
}