package away3d.primitives;

import away3d.core.base.CompactSubGeometry;

import openfl.Vector;

/**
 * A UV Cylinder primitive mesh.
 */
class TorusGeometry extends PrimitiveBase
{
	/**
	 * The major radius of the torus.
	 */
	public var radius(get, set):Float;
	/**
	 * The minor radius of the torus, or the radius of the inner tube.
	 */
	public var tubeRadius(get, set):Float;
	/**
	 * The number of sections the major circumference is divided into.
	 */
	public var sectionsR(get, set):Int;
	/**
	 * The number of sections the minor circumference (the circumference of the
	 * inner tube) is divided into.
	 */
	public var sectionsT(get, set):Int;
	@:noCompletion public var segmentsR(get, set):Int;
	@:noCompletion public var segmentsT(get, set):Int;
	/**
	 * Whether the torus poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */
	public var yUp(get, set):Bool;
	
	private var _radius:Float;
	private var _tubeRadius:Float;
	private var _sectionsR:Int;
	private var _sectionsT:Int;
	private var _yUp:Bool;
	private var _rawVertexData:Vector<Float>;
	private var _rawIndices:Vector<UInt>;
	private var _nextVertexIndex:Int;
	private var _currentIndex:Int;
	private var _currentTriangleIndex:Int;
	private var _numVertices:Int;
	private var _vertexStride:Int;
	private var _vertexOffset:Int;
	
	private function addVertex(px:Float, py:Float, pz:Float, nx:Float, ny:Float, nz:Float, tx:Float, ty:Float, tz:Float):Void
	{
		var compVertInd:Int = _vertexOffset + _nextVertexIndex*_vertexStride; // current component vertex index
		_rawVertexData[compVertInd++] = px;
		_rawVertexData[compVertInd++] = py;
		_rawVertexData[compVertInd++] = pz;
		_rawVertexData[compVertInd++] = nx;
		_rawVertexData[compVertInd++] = ny;
		_rawVertexData[compVertInd++] = nz;
		_rawVertexData[compVertInd++] = tx;
		_rawVertexData[compVertInd++] = ty;
		_rawVertexData[compVertInd] = tz;
		_nextVertexIndex++;
	}
	
	private function addTriangleClockWise(cwVertexIndex0:Int, cwVertexIndex1:Int, cwVertexIndex2:Int):Void
	{
		_rawIndices[_currentIndex++] = cwVertexIndex0;
		_rawIndices[_currentIndex++] = cwVertexIndex1;
		_rawIndices[_currentIndex++] = cwVertexIndex2;
		_currentTriangleIndex++;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function buildGeometry(target:CompactSubGeometry):Void
	{
		var i:Int = 0, j:Int;
		var x:Float, y:Float, z:Float, nx:Float, ny:Float, nz:Float, revolutionAngleR:Float, revolutionAngleT:Float;
		var numTriangles:Int;
		// reset utility variables
		_numVertices = 0;
		_nextVertexIndex = 0;
		_currentIndex = 0;
		_currentTriangleIndex = 0;
		_vertexStride = target.vertexStride;
		_vertexOffset = target.vertexOffset;
		
		// evaluate target number of vertices, triangles and indices
		_numVertices = (_sectionsT + 1)*(_sectionsR + 1); // sectionsT + 1 because of closure, sectionsR + 1 because of closure
		numTriangles = _sectionsT*_sectionsR*2; // each level has segmentR quads, each of 2 triangles
		
		// need to initialize raw arrays or can be reused?
		if (_numVertices == target.numVertices) {
			_rawVertexData = target.vertexData;
			_rawIndices = target.indexData;
			if (_rawIndices == null)
				_rawIndices = new Vector<UInt>(numTriangles*3, true);
		} else {
			var numVertComponents:Int = _numVertices*_vertexStride;
			_rawVertexData = new Vector<Float>(numVertComponents, true);
			_rawIndices = new Vector<UInt>(numTriangles*3, true);
			invalidateUVs();
		}
		
		// evaluate revolution steps
		var revolutionAngleDeltaR:Float = 2*Math.PI/_sectionsR;
		var revolutionAngleDeltaT:Float = 2*Math.PI/_sectionsT;
		
		var comp1:Float, comp2:Float;
		var t1:Float, t2:Float, n1:Float, n2:Float;
		var startIndex:Int;
		
		// surface
		var a:Int, b:Int, c:Int, d:Int, length:Float;
		
		for (j in 0..._sectionsT + 1) {
			
			startIndex = _vertexOffset + _nextVertexIndex*_vertexStride;
			
			for (i in 0..._sectionsR + 1) {
				// revolution vertex
				revolutionAngleR = i*revolutionAngleDeltaR;
				revolutionAngleT = j*revolutionAngleDeltaT;
				
				length = Math.cos(revolutionAngleT);
				nx = length*Math.cos(revolutionAngleR);
				ny = length*Math.sin(revolutionAngleR);
				nz = Math.sin(revolutionAngleT);
				
				x = _radius*Math.cos(revolutionAngleR) + _tubeRadius*nx;
				y = _radius*Math.sin(revolutionAngleR) + _tubeRadius*ny;
				z = (j == _sectionsT)? 0 : _tubeRadius*nz;
				
				if (_yUp) {
					n1 = -nz;
					n2 = ny;
					t1 = 0;
					t2 = ((length != 0)? nx/length : x/_radius);
					comp1 = -z;
					comp2 = y;
					
				} else {
					n1 = ny;
					n2 = nz;
					t1 = ((length != 0)? nx/length : x/_radius);
					t2 = 0;
					comp1 = y;
					comp2 = z;
				}
				
				if (i == _sectionsR) {
					addVertex(x, _rawVertexData[startIndex + 1], _rawVertexData[startIndex + 2],
						nx, n1, n2,
						-((length != 0)? ny/length : y/_radius), t1, t2);
				} else {
					addVertex(x, comp1, comp2,
						nx, n1, n2,
						-((length != 0)? ny/length : y/_radius), t1, t2);
				}
				
				// close triangle
				if (i > 0 && j > 0) {
					a = _nextVertexIndex - 1; // current
					b = _nextVertexIndex - 2; // previous
					c = b - _sectionsR - 1; // previous of last level
					d = a - _sectionsR - 1; // current of last level
					addTriangleClockWise(a, b, c);
					addTriangleClockWise(a, c, d);
				}
			}
		}
		
		// build real data from raw data
		target.updateData(_rawVertexData);
		target.updateIndexData(_rawIndices);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function buildUVs(target:CompactSubGeometry):Void
	{
		var i:Int, j:Int;
		var data:Vector<Float>;
		var stride:Int = target.UVStride;
		var offset:Int = target.UVOffset;
		var skip:Int = target.UVStride - 2;
		
		// evaluate num uvs
		var numUvs:Int = _numVertices*stride;
		
		// need to initialize raw array or can be reused?
		if (target.UVData != null && numUvs == target.UVData.length)
			data = target.UVData;
		else {
			data = new Vector<Float>(numUvs, true);
			invalidateGeometry();
		}
		
		// current uv component index
		var currentUvCompIndex:Int = offset;
		
		// surface
		for (j in 0..._sectionsT + 1) {
			for (i in 0..._sectionsR + 1) {
				// revolution vertex
				data[currentUvCompIndex++] = ( i/_sectionsR )*target.scaleU;
				data[currentUvCompIndex++] = ( j/_sectionsT )*target.scaleV;
				currentUvCompIndex += skip;
			}
		}
		
		// build real data from raw data
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
	
	private function get_tubeRadius():Float
	{
		return _tubeRadius;
	}
	
	private function set_tubeRadius(value:Float):Float
	{
		_tubeRadius = value;
		invalidateGeometry();
		return value;
	}
	
	private function get_sectionsR():Int
	{
		return _sectionsR;
	}
	
	private function set_sectionsR(value:Int):Int
	{
		_sectionsR = value;
		invalidateGeometry();
		invalidateUVs();
		return value;
	}
	
	private function get_segmentsR():Int
	{
		return sectionsR;
	}
	
	private function set_segmentsR(value:Int):Int
	{
		return sectionsR = value;
	}
	
	private function get_sectionsT():Int
	{
		return _sectionsT;
	}
	
	private function set_sectionsT(value:Int):Int
	{
		_sectionsT = value;
		invalidateGeometry();
		invalidateUVs();
		return value;
	}
	
	private function get_segmentsT():Int
	{
		return sectionsT;
	}
	
	private function set_segmentsT(value:Int):Int
	{
		return sectionsT = value;
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
	
	/**
	 * Creates a new <code>Torus</code> object.
	 * @param radius The major radius of the torus.
	 * @param tubeRadius The minor radius of the torus, or the radius of the
	 * inner tube.
	 * @param sectionsR The number of sections the major circumference is
	 * divided into.
	 * @param sectionsT The number of sections the minor circumference (the
	 * circumference of the inner tube) is divided into.
	 * @param yUp Whether the torus poles should lay on the Y-axis (true) or on
	 * the Z-axis (false).
	 */
	public function new(radius:Float = 50, tubeRadius:Float = 50, sectionsR:Int = 16, sectionsT:Int = 8, yUp:Bool = true)
	{
		super();
		
		_radius = radius;
		_tubeRadius = tubeRadius;
		_sectionsR = sectionsR;
		_sectionsT = sectionsT;
		_yUp = yUp;
	}
}