package away3d.primitives;

import openfl.errors.Error;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * Generates a wireframd cylinder primitive.
 */
class WireframeCylinder extends WireframePrimitiveBase
{
	public var topRadius(get, set):Float;
	public var bottomRadius(get, set):Float;
	public var height(get, set):Float;
	
	private static var TWO_PI:Float = 2*Math.PI;
	
	private var _topRadius:Float;
	private var _bottomRadius:Float;
	private var _height:Float;
	private var _segmentsW:Int;
	private var _segmentsH:Int;
	
	/**
	 * Creates a new WireframeCylinder instance
	 * @param topRadius Top radius of the cylinder
	 * @param bottomRadius Bottom radius of the cylinder
	 * @param height The height of the cylinder
	 * @param segmentsW Number of radial segments
	 * @param segmentsH Number of vertical segments
	 * @param color The color of the wireframe lines
	 * @param thickness The thickness of the wireframe lines
	 */
	public function new(topRadius:Float = 50, bottomRadius:Float = 50, height:Float = 100, segmentsW:Int = 16, segmentsH:Int = 1, color:Int = 0xFFFFFF, thickness:Float = 1)
	{
		super(color, thickness);
		_topRadius = topRadius;
		_bottomRadius = bottomRadius;
		_height = height;
		_segmentsW = segmentsW;
		_segmentsH = segmentsH;
	}
	
	override private function buildGeometry():Void
	{
		var i:Int = 0, j:Int;
		var radius:Float = _topRadius;
		var revolutionAngle:Float;
		var revolutionAngleDelta:Float = TWO_PI / _segmentsW;
		var nextVertexIndex:Int = 0;
		var x:Float = 0, y:Float = 0, z:Float = 0;
		var lastLayer:Vector<Vector<Vector3D>> = new Vector<Vector<Vector3D>>(_segmentsH + 1, true);
		
		for (j in 0..._segmentsH + 1) {
			lastLayer[j] = new Vector<Vector3D>(_segmentsW + 1, true);
			
			radius = _topRadius - ((j/_segmentsH)*(_topRadius - _bottomRadius));
			z = -(_height/2) + (j/_segmentsH*_height);
			
			var previousV:Vector3D = null;
			
			for (i in 0..._segmentsW + 1) {
				// revolution vertex
				revolutionAngle = i*revolutionAngleDelta;
				x = radius*Math.cos(revolutionAngle);
				y = radius*Math.sin(revolutionAngle);
				var vertex:Vector3D = null;
				if (previousV != null) {
					vertex = new Vector3D(x, -z, y);
					updateOrAddSegment(nextVertexIndex++, vertex, previousV);
					previousV = vertex;
				} else
					previousV = new Vector3D(x, -z, y);
				
				if (j > 0 && i > 0)
					updateOrAddSegment(nextVertexIndex++, vertex, lastLayer[j - 1][i]);
				lastLayer[j][i] = previousV;
			}
		}
	}
	
	/**
	 * Top radius of the cylinder
	 */
	private function get_topRadius():Float
	{
		return _topRadius;
	}
	
	private function set_topRadius(value:Float):Float
	{
		if (_topRadius == value)
			return value;
		_topRadius = value;
		invalidateGeometry();
		return value;
	}
	
	/**
	 * Bottom radius of the cylinder
	 */
	private function get_bottomRadius():Float
	{
		return _bottomRadius;
	}
	
	private function set_bottomRadius(value:Float):Float
	{
		if (_bottomRadius == value)
			return value;
		_bottomRadius = value;
		invalidateGeometry();
		return value;
	}
	
	/**
	 * The height of the cylinder
	 */
	private function get_height():Float
	{
		return _height;
	}
	
	private function set_height(value:Float):Float
	{
		if (height <= 0)
			throw new Error("Height must be a value greater than zero.");
		if (_height == value)
			return value;
		_height = value;
		invalidateGeometry();
		return value;
	}
}