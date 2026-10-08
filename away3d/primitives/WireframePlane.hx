package away3d.primitives;

import openfl.errors.Error;
import openfl.geom.Vector3D;

/**
 * A WireframePlane primitive mesh.
 */
class WireframePlane extends WireframePrimitiveBase
{
	/**
	 * The orientation in which the plane lies.
	 */
	public var orientation(get, set):String;
	/**
	 * The size of the plane along its X-axis.
	 */
	public var width(get, set):Float;
	/**
	 * The size of the plane along its Y-axis.
	 */
	public var height(get, set):Float;
	/**
	 * The number of sections the plane's width is divided into.
	 */
	public var sectionsW(get, set):Int;
	/**
	 * The number of sections the plane's height is divided into.
	 */
	public var sectionsH(get, set):Int;
	
	public static inline var ORIENTATION_YZ:String = "yz";
	public static inline var ORIENTATION_XY:String = "xy";
	public static inline var ORIENTATION_XZ:String = "xz";
	
	private var _width:Float;
	private var _height:Float;
	private var _sectionsW:Int;
	private var _sectionsH:Int;
	private var _orientation:String;
	
	/**
	 * Creates a new WireframePlane object.
	 * @param width The size of the plane along its X-axis.
	 * @param height The size of the plane along its Y-axis.
	 * @param sectionsW The number of sections the plane's width is divided into.
	 * @param sectionsH The number of sections the plane's height is divided into.
	 * @param color The colour of the wireframe lines
	 * @param thickness The thickness of the wireframe lines
	 * @param orientation The orientation in which the plane lies.
	 */
	public function new(width:Float, height:Float, sectionsW:Int = 10, sectionsH:Int = 10, color:Int = 0xFFFFFF, thickness:Float = 1, orientation:String = "yz")
	{
		super(color, thickness);
		
		_width = width;
		_height = height;
		_sectionsW = sectionsW;
		_sectionsH = sectionsH;
		_orientation = orientation;
	}
	
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
	
	private function get_sectionsW():Int
	{
		return _sectionsW;
	}
	
	private function set_sectionsW(value:Int):Int
	{
		_sectionsW = value;
		removeAllSegments();
		invalidateGeometry();
		return value;
	}
	
	private function get_sectionsH():Int
	{
		return _sectionsH;
	}
	
	private function set_sectionsH(value:Int):Int
	{
		_sectionsH = value;
		removeAllSegments();
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
		var index:Int = 0;
		var ws:Int = 0, hs:Int = 0;
		
		if (_orientation == ORIENTATION_XY) {
			v0.y = hh;
			v0.z = 0;
			v1.y = -hh;
			v1.z = 0;
			
			for (ws in 0..._sectionsW + 1) {
				v0.x = v1.x = (ws/_sectionsW - .5)*_width;
				updateOrAddSegment(index++, v0, v1);
			}
			
			v0.x = -hw;
			v1.x = hw;
			
			for (hs in 0..._sectionsH + 1) {
				v0.y = v1.y = (hs/_sectionsH - .5)*_height;
				updateOrAddSegment(index++, v0, v1);
			}
		}
		
		else if (_orientation == ORIENTATION_XZ) {
			v0.z = hh;
			v0.y = 0;
			v1.z = -hh;
			v1.y = 0;
			
			for (ws in 0..._sectionsW + 1) {
				v0.x = v1.x = (ws/_sectionsW - .5)*_width;
				updateOrAddSegment(index++, v0, v1);
			}
			
			v0.x = -hw;
			v1.x = hw;
			
			for (hs in 0..._sectionsH + 1) {
				v0.z = v1.z = (hs/_sectionsH - .5)*_height;
				updateOrAddSegment(index++, v0, v1);
			}
		}
		
		else if (_orientation == ORIENTATION_YZ) {
			v0.y = hh;
			v0.x = 0;
			v1.y = -hh;
			v1.x = 0;
			
			for (ws in 0..._sectionsW + 1) {
				v0.z = v1.z = (ws/_sectionsW - .5)*_width;
				updateOrAddSegment(index++, v0, v1);
			}
			
			v0.z = hw;
			v1.z = -hw;
			
			for (hs in 0..._sectionsH + 1) {
				v0.y = v1.y = (hs/_sectionsH - .5)*_height;
				updateOrAddSegment(index++, v0, v1);
			}
		}
	}
}