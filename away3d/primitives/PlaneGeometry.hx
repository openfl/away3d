package away3d.primitives;

import away3d.core.base.CompactSubGeometry;

import openfl.Vector;

/**
 * A Plane primitive mesh.
 */
class PlaneGeometry extends PrimitiveBase
{
	/**
	 * The number of sections the plane's width is divided into.
	 */
	public var sectionsW(get, set):Int;
	/**
	 * The number of sections the plane's height is divided into.
	 */
	public var sectionsH(get, set):Int;
	@:noCompletion public var segmentsW(get, set):Int;
	@:noCompletion public var segmentsH(get, set):Int;
	/**
	 * Defines whether the normal vector of the plane should point along the Y-axis (true) or Z-axis (false). Defaults to true.
	 */
	public var yUp(get, set):Bool;
	/**
	 * Defines whether the plane will be visible from both sides, with correct vertex normals (as opposed to bothSides on Material). Defaults to false.
	 */
	public var doubleSided(get, set):Bool;
	/**
	 * The width of the plane.
	 */
	public var width(get, set):Float;
	/**
	 * The height of the plane, along the Y or Z-axis.
	 */
	public var height(get, set):Float;
	
	private var _sectionsW:Int;
	private var _sectionsH:Int;
	private var _yUp:Bool;
	private var _width:Float;
	private var _height:Float;
	private var _doubleSided:Bool;
	
	/**
	 * Creates a new Plane object.
	 * @param width The width of the plane.
	 * @param height The height of the plane, along the Y or Z-axis.
	 * @param sectionsW The number of sections the plane's width is divided into.
	 * @param sectionsH The number of sections the plane's height is divided into.
	 * @param yUp Defines whether the normal vector of the plane should point along the Y-axis (true) or Z-axis (false).
	 * @param doubleSided Defines whether the plane will be visible from both sides, with correct vertex normals.
	 */
	public function new(width:Float = 100, height:Float = 100, sectionsW:Int = 1, sectionsH:Int = 1, yUp:Bool = true, doubleSided:Bool = false)
	{
		super();
		
		_sectionsW = sectionsW;
		_sectionsH = sectionsH;
		_yUp = yUp;
		_width = width;
		_height = height;
		_doubleSided = doubleSided;
	}
	
	private function get_sectionsW():Int
	{
		return _sectionsW;
	}
	
	private function set_sectionsW(value:Int):Int
	{
		_sectionsW = value;
		invalidateGeometry();
		invalidateUVs();
		return value;
	}
	
	private function get_segmentsW():Int
	{
		return sectionsW;
	}
	
	private function set_segmentsW(value:Int):Int
	{
		return sectionsW = value;
	}
	
	private function get_sectionsH():Int
	{
		return _sectionsH;
	}
	
	private function set_sectionsH(value:Int):Int
	{
		_sectionsH = value;
		invalidateGeometry();
		invalidateUVs();
		return value;
	}
	
	private function get_segmentsH():Int
	{
		return sectionsH;
	}
	
	private function set_segmentsH(value:Int):Int
	{
		return sectionsH = value;
	}
	
	private function get_yUp():Bool
	{
		return _yUp;
	}
	
	private function set_yUp(value:Bool):Bool
	{
		_yUp = value;
		invalidateGeometry();
		return value;
	}
	
	private function get_doubleSided():Bool
	{
		return _doubleSided;
	}
	
	private function set_doubleSided(value:Bool):Bool
	{
		_doubleSided = value;
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
		_height = value;
		invalidateGeometry();
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function buildGeometry(target:CompactSubGeometry):Void
	{
		var data:Vector<Float>;
		var indices:Vector<UInt>;
		var x:Float, y:Float;
		var numIndices:Int;
		var base:Int;
		var tw:Int = _sectionsW + 1;
		var numVertices:Int = (_sectionsH + 1)*tw;
		var stride:Int = target.vertexStride;
		var skip:Int = stride - 9;
		if (_doubleSided)
			numVertices *= 2;
		
		numIndices = _sectionsH*_sectionsW*6;
		if (_doubleSided)
			numIndices <<= 1;
		
		if (numVertices == target.numVertices) {
			data = target.vertexData;
			indices = target.indexData;
			if (indices == null)
				indices = new Vector<UInt>(numIndices, true);
		} else {
			data = new Vector<Float>(numVertices*stride, true);
			indices = new Vector<UInt>(numIndices, true);
			invalidateUVs();
		}
		
		numIndices = 0;
		var index:Int = target.vertexOffset;
		for (yi in 0..._sectionsH + 1) {
			for (xi in 0..._sectionsW + 1) {
				x = (xi/_sectionsW - .5)*_width;
				y = (yi/_sectionsH - .5)*_height;
				
				data[index++] = x;
				if (_yUp) {
					data[index++] = 0;
					data[index++] = y;
				} else {
					data[index++] = y;
					data[index++] = 0;
				}
				
				data[index++] = 0;
				if (_yUp) {
					data[index++] = 1;
					data[index++] = 0;
				} else {
					data[index++] = 0;
					data[index++] = -1;
				}
				
				data[index++] = 1;
				data[index++] = 0;
				data[index++] = 0;
				
				index += skip;
				
				// add vertex with same position, but with inverted normal & tangent
				if (_doubleSided) {
					for (i in 0...3) {
						data[index] = data[index - stride];
						++index;
					}
					for (i in 0...3) {
						data[index] = -data[index - stride];
						++index;
					}
					for (i in 0...3) {
						data[index] = -data[index - stride];
						++index;
					}
					index += skip;
				}
				
				if (xi != _sectionsW && yi != _sectionsH) {
					base = xi + yi*tw;
					var mult:Int = _doubleSided? 2 : 1;
					
					indices[numIndices++] = base*mult;
					indices[numIndices++] = (base + tw)*mult;
					indices[numIndices++] = (base + tw + 1)*mult;
					indices[numIndices++] = base*mult;
					indices[numIndices++] = (base + tw + 1)*mult;
					indices[numIndices++] = (base + 1)*mult;
					
					if (_doubleSided) {
						indices[numIndices++] = (base + tw + 1)*mult + 1;
						indices[numIndices++] = (base + tw)*mult + 1;
						indices[numIndices++] = base*mult + 1;
						indices[numIndices++] = (base + 1)*mult + 1;
						indices[numIndices++] = (base + tw + 1)*mult + 1;
						indices[numIndices++] = base*mult + 1;
					}
				}
			}
		}
		
		target.updateData(data);
		target.updateIndexData(indices);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function buildUVs(target:CompactSubGeometry):Void
	{
		var data:Vector<Float>;
		var stride:Int = target.UVStride;
		var numUvs:Int = (_sectionsH + 1)*(_sectionsW + 1)*stride;
		var skip:Int = stride - 2;
		
		if (_doubleSided)
			numUvs *= 2;
		
		if (target.UVData != null && numUvs == target.UVData.length)
			data = target.UVData;
		else {
			data = new Vector<Float>(numUvs, true);
			invalidateGeometry();
		}
		
		var index:Int = target.UVOffset;
		
		for (yi in 0..._sectionsH + 1) {
			for (xi in 0..._sectionsW + 1) {
				data[index++] = (xi/_sectionsW)*target.scaleU;
				data[index++] = (1 - yi/_sectionsH)*target.scaleV;
				index += skip;
				
				if (_doubleSided) {
					data[index++] = (xi/_sectionsW)*target.scaleU;
					data[index++] = (1 - yi/_sectionsH)*target.scaleV;
					index += skip;
				}
			}
		}
		
		target.updateData(data);
	}
}