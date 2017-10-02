package away3d.primitives;

import openfl.errors.Error;
import openfl.geom.Vector3D;

/**
 * A WirefameCube primitive mesh.
 */
class WireframeCube extends WireframePrimitiveBase
{
	public var width(get, set):Float;
	public var height(get, set):Float;
	public var depth(get, set):Float;
	
	private var _width:Float;
	private var _height:Float;
	private var _depth:Float;
	
	/**
	 * Creates a new WireframeCube object.
	 * @param width The size of the cube along its X-axis.
	 * @param height The size of the cube along its Y-axis.
	 * @param depth The size of the cube along its Z-axis.
	 * @param color The colour of the wireframe lines
	 * @param thickness The thickness of the wireframe lines
	 */
	public function new(width:Float = 100, height:Float = 100, depth:Float = 100, color:Int = 0xFFFFFF, thickness:Float = 1)
	{
		super(color, thickness);
		
		_width = width;
		_height = height;
		_depth = depth;
	}
	
	/**
	 * The size of the cube along its X-axis.
	 */
	private function get_width():Float
	{
		return _width;
	}
	
	private function set_width(value:Float):Float
	{
		_width = value;
		invalidateGeometry();
		return value;
	}
	
	/**
	 * The size of the cube along its Y-axis.
	 */
	private function get_height():Float
	{
		return _height;
	}
	
	private function set_height(value:Float):Float
	{
		if (value <= 0)
			throw new Error("Value needs to be greater than 0");
		_height = value;
		invalidateGeometry();
		return value;
	}
	
	/**
	 * The size of the cube along its Z-axis.
	 */
	private function get_depth():Float
	{
		return _depth;
	}
	
	private function set_depth(value:Float):Float
	{
		_depth = value;
		invalidateGeometry();
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function buildGeometry():Void
	{
		var v0:Vector3D = new Vector3D();
		var v1:Vector3D = new Vector3D();
		var hw:Float = _width*.5;
		var hh:Float = _height*.5;
		var hd:Float = _depth*.5;
		
		v0.x = -hw;
		v0.y = hh;
		v0.z = -hd;
		v1.x = -hw;
		v1.y = -hh;
		v1.z = -hd;
		
		updateOrAddSegment(0, v0, v1);
		v0.z = hd;
		v1.z = hd;
		updateOrAddSegment(1, v0, v1);
		v0.x = hw;
		v1.x = hw;
		updateOrAddSegment(2, v0, v1);
		v0.z = -hd;
		v1.z = -hd;
		updateOrAddSegment(3, v0, v1);
		
		v0.x = -hw;
		v0.y = -hh;
		v0.z = -hd;
		v1.x = hw;
		v1.y = -hh;
		v1.z = -hd;
		updateOrAddSegment(4, v0, v1);
		v0.y = hh;
		v1.y = hh;
		updateOrAddSegment(5, v0, v1);
		v0.z = hd;
		v1.z = hd;
		updateOrAddSegment(6, v0, v1);
		v0.y = -hh;
		v1.y = -hh;
		updateOrAddSegment(7, v0, v1);
		
		v0.x = -hw;
		v0.y = -hh;
		v0.z = -hd;
		v1.x = -hw;
		v1.y = -hh;
		v1.z = hd;
		updateOrAddSegment(8, v0, v1);
		v0.y = hh;
		v1.y = hh;
		updateOrAddSegment(9, v0, v1);
		v0.x = hw;
		v1.x = hw;
		updateOrAddSegment(10, v0, v1);
		v0.y = -hh;
		v1.y = -hh;
		updateOrAddSegment(11, v0, v1);
	}
}