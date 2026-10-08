package away3d.primitives;

import away3d.core.base.CompactSubGeometry;

import openfl.Vector;

/**
 * A Capsule primitive mesh.
 */
class CapsuleGeometry extends PrimitiveBase
{
	/**
	 * The radius of the capsule.
	 */
	public var radius(get, set):Float;
	/**
	 * The height of the capsule.
	 */
	public var height(get, set):Float;
	/**
	 * The number of sections the circumference is divided into. Defaults to 16.
	 */
	public var sectionsC(get, set):Int;
	/**
	 * The number of sections the height is divided into. Defaults to 15. Must be uneven.
	 */
	public var sectionsH(get, set):Int;
	@:noCompletion public var segmentsW(get, set):Int;
	@:noCompletion public var segmentsH(get, set):Int;
	/**
	 * Whether the capsule poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */
	public var yUp(get, set):Bool;
	
	private var _radius:Float;
	private var _height:Float;
	private var _sectionsC:Int;
	private var _sectionsH:Int;
	private var _yUp:Bool;
	
	/**
	 * Creates a new Capsule object.
	 * @param radius The radius of the capsule.
	 * @param height The height of the capsule.
	 * @param sectionsC The number of sections the circumference is divided
	 * into. Defaults to 16.
	 * @param sectionsH The number of sections the height is divided into.
	 * Defaults to 15. Must be uneven value.
	 * @param yUp Whether the capsule poles should lay on the Y-axis (true) or
	 * on the Z-axis (false).
	 */
	public function new(radius:Float = 50, height:Float = 100, sectionsC:Int = 16, sectionsH:Int = 15, yUp:Bool = true)
	{
		super();
		
		_radius = radius;
		_height = height;
		_sectionsC = sectionsC;
		_sectionsH = (sectionsH%2 == 0)? sectionsH + 1 : sectionsH;
		_yUp = yUp;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function buildGeometry(target:CompactSubGeometry):Void
	{
		var data:Vector<Float>;
		var indices:Vector<UInt>;
		var i:Int = 0, j:Int = 0, triIndex:Int = 0;
		var numVerts:Int = (_sectionsH + 1)*(_sectionsC + 1);
		var stride:Int = target.vertexStride;
		var skip:Int = stride - 9;
		var index:Int = 0;
		var startIndex:Int = 0;
		var comp1:Float = 0, comp2:Float = 0, t1:Float = 0, t2:Float = 0;
		
		if (numVerts == target.numVertices) {
			data = target.vertexData;
			indices = target.indexData;
			if (indices == null)
				indices = new Vector<UInt>((_sectionsH - 1)*_sectionsC*6, true);
		} else {
			data = new Vector<Float>(numVerts*stride, true);
			indices = new Vector<UInt>((_sectionsH - 1)*_sectionsC*6, true);
			invalidateUVs();
		}
		
		for (j in 0..._sectionsH + 1) {
			
			var horangle:Float = Math.PI*j/_sectionsH;
			var z:Float = -_radius*Math.cos(horangle);
			var ringradius:Float = _radius*Math.sin(horangle);
			startIndex = index;
			
			for (i in 0..._sectionsC + 1) {
				var verangle:Float = 2*Math.PI*i/_sectionsC;
				var x:Float = ringradius*Math.cos(verangle);
				var offset:Float = j > _sectionsH/2? _height/2 : -_height/2;
				var y:Float = ringradius*Math.sin(verangle);
				var normLen:Float = 1/Math.sqrt(x*x + y*y + z*z);
				var tanLen:Float = Math.sqrt(y*y + x*x);
				
				if (_yUp) {
					t1 = 0;
					t2 = tanLen > .007? x/tanLen : 0;
					comp1 = -z;
					comp2 = y;
					
				} else {
					t1 = tanLen > .007? x/tanLen : 0;
					t2 = 0;
					comp1 = y;
					comp2 = z;
				}
				
				if (i == _sectionsC) {
					
					data[index++] = data[startIndex];
					data[index++] = data[startIndex + 1];
					data[index++] = data[startIndex + 2];
					data[index++] = (data[startIndex + 3] + (x*normLen))*.5;
					data[index++] = (data[startIndex + 4] + ( comp1*normLen))*.5;
					data[index++] = (data[startIndex + 5] + (comp2*normLen))*.5;
					data[index++] = (data[startIndex + 6] + (tanLen > .007? -y/tanLen : 1))*.5;
					data[index++] = (data[startIndex + 7] + t1)*.5;
					data[index++] = (data[startIndex + 8] + t2)*.5;
					
				} else {
					// vertex
					data[index++] = x;
					data[index++] = (_yUp)? comp1 - offset : comp1;
					data[index++] = (_yUp)? comp2 : comp2 + offset;
					// normal
					data[index++] = x*normLen;
					data[index++] = comp1*normLen;
					data[index++] = comp2*normLen;
					// tangent
					data[index++] = tanLen > .007? -y/tanLen : 1;
					data[index++] = t1;
					data[index++] = t2;
				}
				
				if (i > 0 && j > 0) {
					var a:Int = (_sectionsC + 1)*j + i;
					var b:Int = (_sectionsC + 1)*j + i - 1;
					var c:Int = (_sectionsC + 1)*(j - 1) + i - 1;
					var d:Int = (_sectionsC + 1)*(j - 1) + i;
					
					if (j == _sectionsH) {
						data[index - 9] = data[startIndex];
						data[index - 8] = data[startIndex + 1];
						data[index - 7] = data[startIndex + 2];
						
						indices[triIndex++] = a;
						indices[triIndex++] = c;
						indices[triIndex++] = d;
						
					} else if (j == 1) {
						indices[triIndex++] = a;
						indices[triIndex++] = b;
						indices[triIndex++] = c;
						
					} else {
						indices[triIndex++] = a;
						indices[triIndex++] = b;
						indices[triIndex++] = c;
						indices[triIndex++] = a;
						indices[triIndex++] = c;
						indices[triIndex++] = d;
					}
				}
				
				index += skip;
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
		var i:Int, j:Int;
		var index:Int;
		var data:Vector<Float>;
		var stride:Int = target.UVStride;
		var UVlen:Int = (_sectionsH + 1)*(_sectionsC + 1)*stride;
		var skip:Int = stride - 2;
		
		if (target.UVData != null && UVlen == target.UVData.length)
			data = target.UVData;
		else {
			data = new Vector<Float>(UVlen, true);
			invalidateGeometry();
		}
		
		index = target.UVOffset;
		for (j in 0..._sectionsH + 1) {
			for (i in 0..._sectionsC + 1) {
				data[index++] = ( i/_sectionsC )*target.scaleU;
				data[index++] = ( j/_sectionsH )*target.scaleV;
				index += skip;
			}
		}
		
		target.updateData(data);
	}
	
	private function get_radius():Float
	{
		return _radius;
	}
	
	private function set_radius(value:Float):Float
	{
		_radius = value;
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
	
	private function get_sectionsC():Int
	{
		return _sectionsC;
	}
	
	private function set_sectionsC(value:Int):Int
	{
		_sectionsC = value;
		invalidateGeometry();
		invalidateUVs();
		return value;
	}
	
	private function get_segmentsW():Int
	{
		return sectionsC;
	}
	
	private function set_segmentsW(value:Int):Int
	{
		return sectionsC = value;
	}
	
	private function get_sectionsH():Int
	{
		return _sectionsH;
	}
	
	private function set_sectionsH(value:Int):Int
	{
		_sectionsH = (value%2 == 0)? value + 1 : value;
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
}