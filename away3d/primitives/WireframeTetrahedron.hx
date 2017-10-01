package away3d.primitives;

import away3d.primitives.WireframePrimitiveBase;

import openfl.errors.Error;
import openfl.geom.Vector3D;

/**
 * A WireframeTetrahedron primitive mesh
 */
class WireframeTetrahedron extends WireframePrimitiveBase
{
	public var orientation(get, set):String;
	public var width(get, set):Float;
	public var height(get, set):Float;
	
	public static inline var ORIENTATION_YZ:String = "yz";
	public static inline var ORIENTATION_XY:String = "xy";
	public static inline var ORIENTATION_XZ:String = "xz";
	
	private var _width:Float;
	private var _height:Float;
	private var _orientation:String;
	
	/**
	 * Creates a new WireframeTetrahedron object.
	 * @param width The size of the tetrahedron buttom size.
	 * @param height The size of the tetranhedron height.
	 * @param color The color of the wireframe lines.
	 * @param thickness The thickness of the wireframe lines.
	 */
	public function new(width:Float, height:Float, color:Int = 0xffffff, thickness:Float = 1, orientation:String = "yz")
	{
		super(color, thickness);
		
		_width = width;
		_height = height;
		
		_orientation = orientation;
	}
	
	/**
	 * The orientation in which the plane lies
	 */
	private function get_orientation():String
	{
		return _orientation;
	}
	
	private function set_orientation(value:String):String
	{
		_orientation = value;
		invalidateGeometry();
		return value;
	}
	
	/**
	 * The size of the tetrahedron bottom.
	 */
	private function get_width():Float
	{
		return _width;
	}
	
	private function set_width(value:Float):Float
	{
		if (value <= 0)
			throw new Error("Value needs to be greater than 0");
		_width = value;
		invalidateGeometry();
		return value;
	}
	
	/**
	 * The size of the tetrahedron height.
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
	 * @inheritDoc
	 */
	override private function buildGeometry():Void
	{
		var bv0:Vector3D = null;
		var bv1:Vector3D = null;
		var bv2:Vector3D = null;
		var bv3:Vector3D = null;
		var top:Vector3D = null;
		var hw:Float = _width*0.5;
		
		switch(_orientation) {
			case WireframeTetrahedron.ORIENTATION_XY:
				bv0 = new Vector3D(-hw, hw, 0);
				bv1 = new Vector3D(hw, hw, 0);
				bv2 = new Vector3D(hw, -hw, 0);
				bv3 = new Vector3D(-hw, -hw, 0);
				top = new Vector3D(0, 0, _height);
			case WireframeTetrahedron.ORIENTATION_XZ:
				bv0 = new Vector3D(-hw, 0, hw);
				bv1 = new Vector3D(hw, 0, hw);
				bv2 = new Vector3D(hw, 0, -hw);
				bv3 = new Vector3D(-hw, 0, -hw);
				top = new Vector3D(0, _height, 0);
			case WireframeTetrahedron.ORIENTATION_YZ:
				bv0 = new Vector3D(0, -hw, hw);
				bv1 = new Vector3D(0, hw, hw);
				bv2 = new Vector3D(0, hw, -hw);
				bv3 = new Vector3D(0, -hw, -hw);
				top = new Vector3D(_height, 0, 0);
		}
		//bottom
		updateOrAddSegment(0, bv0, bv1);
		updateOrAddSegment(1, bv1, bv2);
		updateOrAddSegment(2, bv2, bv3);
		updateOrAddSegment(3, bv3, bv0);
		//bottom to top
		updateOrAddSegment(4, bv0, top);
		updateOrAddSegment(5, bv1, top);
		updateOrAddSegment(6, bv2, top);
		updateOrAddSegment(7, bv3, top);
	}
}