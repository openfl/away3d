/**
 * A UV Cylinder primitive mesh.
 */
package away3d.primitives;


import away3d.utils.ArrayUtils;
import flash.Vector;
import away3d.core.base.CompactSubGeometry;

class TorusGeometry extends PrimitiveBase {
    public var radius(get_radius, set_radius):Float;
    public var tubeRadius(get_tubeRadius, set_tubeRadius):Float;
    public var segmentsR(get_segmentsR, set_segmentsR):Int;
    public var segmentsT(get_segmentsT, set_segmentsT):Int;
    public var yUp(get_yUp, set_yUp):Bool;

    private var _radius:Float;
    private var _tubeRadius:Float;
    private var _segmentsR:Int;
    private var _segmentsT:Int;
    private var _yUp:Bool;
    private var _rawVertexData:Vector<Float>;
    private var _rawIndices:Vector<UInt>;
    private var _nextVertexIndex:Int;
    private var _currentIndex:Int;
    private var _currentTriangleIndex:Int;
    private var _numVertices:Int;
    private var _vertexStride:Int;
    private var _vertexOffset:Int;

    private function addVertex(px:Float, py:Float, pz:Float, nx:Float, ny:Float, nz:Float, tx:Float, ty:Float, tz:Float):Void {
        var compVertInd:Int = _vertexOffset + _nextVertexIndex * _vertexStride;
// current component vertex index
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

    private function addTriangleClockWise(cwVertexIndex0:Int, cwVertexIndex1:Int, cwVertexIndex2:Int):Void {
        _rawIndices[_currentIndex++] = cwVertexIndex0;
        _rawIndices[_currentIndex++] = cwVertexIndex1;
        _rawIndices[_currentIndex++] = cwVertexIndex2;
        _currentTriangleIndex++;
    }

/**
	 * @inheritDoc
	 */

    override private function buildGeometry(target:CompactSubGeometry):Void {
        var i:Int = 0;
        var j:Int;
        var x:Float;
        var y:Float;
        var z:Float;
        var nx:Float;
        var ny:Float;
        var nz:Float;
        var revolutionAngleR:Float;
        var revolutionAngleT:Float;
        var numTriangles:Int;
// reset utility variables
        _numVertices = 0;
        _nextVertexIndex = 0;
        _currentIndex = 0;
        _currentTriangleIndex = 0;
        _vertexStride = target.vertexStride;
        _vertexOffset = target.vertexOffset;
// evaluate target number of vertices, triangles and indices
        _numVertices = (_segmentsT + 1) * (_segmentsR + 1);
// segmentsT + 1 because of closure, segmentsR + 1 because of closure
        numTriangles = _segmentsT * _segmentsR * 2;
// each level has segmentR quads, each of 2 triangles
// need to initialize raw arrays or can be reused?
        if (_numVertices == target.numVertices) {
            _rawVertexData = target.vertexData;

            _rawIndices = target.indexData ;
            if (_rawIndices == null){
                _rawIndices = new Vector<UInt>(numTriangles * 3, true);
                ArrayUtils.Prefill(_rawIndices,numTriangles * 3,0);
            }
        }

        else {
            var numVertComponents:Int = _numVertices * _vertexStride;
            _rawVertexData = new Vector<Float>(numVertComponents, true);
            _rawIndices = new Vector<UInt>(numTriangles * 3, true);
            ArrayUtils.Prefill(_rawVertexData,numVertComponents,0);
            ArrayUtils.Prefill(_rawIndices,numTriangles * 3,0);
            invalidateUVs();
        }

// evaluate revolution steps
        var revolutionAngleDeltaR:Float = 2 * Math.PI / _segmentsR;
        var revolutionAngleDeltaT:Float = 2 * Math.PI / _segmentsT;
        var comp1:Float;
        var comp2:Float;
        var t1:Float;
        var t2:Float;
        var n1:Float;
        var n2:Float;
        var startIndex:Int;
// surface
        var a:Int;
        var b:Int;
        var c:Int;
        var d:Int;
        var length:Float;
        j = 0;
        while (j <= _segmentsT) {
            startIndex = _vertexOffset + _nextVertexIndex * _vertexStride;
            i = 0;
            while (i <= _segmentsR) {
// revolution vertex
                revolutionAngleR = i * revolutionAngleDeltaR;
                revolutionAngleT = j * revolutionAngleDeltaT;
                length = Math.cos(revolutionAngleT);
                nx = length * Math.cos(revolutionAngleR);
                ny = length * Math.sin(revolutionAngleR);
                nz = Math.sin(revolutionAngleT);
                x = _radius * Math.cos(revolutionAngleR) + _tubeRadius * nx;
                y = _radius * Math.sin(revolutionAngleR) + _tubeRadius * ny;
                z = ((j == _segmentsT)) ? 0 : _tubeRadius * nz;
                if (_yUp) {
                    n1 = -nz;
                    n2 = ny;
                    t1 = 0;
                    t2 = ((length > 0) ? nx / length : x / _radius);
                    comp1 = -z;
                    comp2 = y;
                }

                else {
                    n1 = ny;
                    n2 = nz;
                    t1 = ((length > 0) ? nx / length : x / _radius);
                    t2 = 0;
                    comp1 = y;
                    comp2 = z;
                }

                if (i == _segmentsR) {
                    addVertex(x, _rawVertexData[startIndex + 1], _rawVertexData[startIndex + 2], nx, n1, n2, -((length > 0) ? ny / length : y / _radius), t1, t2);
                }

                else {
                    addVertex(x, comp1, comp2, nx, n1, n2, -((length > 0) ? ny / length : y / _radius), t1, t2);
                }

// close triangle
                if (i > 0 && j > 0) {
                    a = _nextVertexIndex - 1;
// current
                    b = _nextVertexIndex - 2;
// previous
                    c = b - _segmentsR - 1;
// previous of last level
                    d = a - _segmentsR - 1;
// current of last level
                    addTriangleClockWise(a, b, c);
                    addTriangleClockWise(a, c, d);
                }
                ++i;
            }
            ++j;
        }
// build real data from raw data
        target.updateData(_rawVertexData);
        target.updateIndexData(_rawIndices);
    }

/**
	 * @inheritDoc
	 */

    override private function buildUVs(target:CompactSubGeometry):Void {
        var i:Int;
        var j:Int;
        var data:Vector<Float>;
        var stride:Int = target.UVStride;
        var offset:Int = target.UVOffset;
        var skip:Int = target.UVStride - 2;
// evaluate num uvs
        var numUvs:Int = _numVertices * stride;
// need to initialize raw array or can be reused?
        if (target.UVData != null && numUvs == target.UVData.length) data = target.UVData
        else {
            data = new Vector<Float>(numUvs, true);
            ArrayUtils.Prefill(data,numUvs,0);
            invalidateGeometry();
        }

// current uv component index
        var currentUvCompIndex:Int = offset;
// surface
        j = 0;
        while (j <= _segmentsT) {
            i = 0;
            while (i <= _segmentsR) {
// revolution vertex
                data[currentUvCompIndex++] = (i / _segmentsR) * target.scaleU;
                data[currentUvCompIndex++] = (j / _segmentsT) * target.scaleV;
                currentUvCompIndex += skip;
                ++i;
            }
            ++j;
        }
// build real data from raw data
        target.updateData(data);
    }

/**
	 * The radius of the torus.
	 */

    public function get_radius():Float {
        return _radius;
    }

    public function set_radius(value:Float):Float {
        _radius = value;
        invalidateGeometry();
        return value;
    }

/**
	 * The radius of the inner tube of the torus.
	 */

    public function get_tubeRadius():Float {
        return _tubeRadius;
    }

    public function set_tubeRadius(value:Float):Float {
        _tubeRadius = value;
        invalidateGeometry();
        return value;
    }

/**
	 * Defines the number of horizontal segments that make up the torus. Defaults to 16.
	 */

    public function get_segmentsR():Int {
        return _segmentsR;
    }

    public function set_segmentsR(value:Int):Int {
        _segmentsR = value;
        invalidateGeometry();
        invalidateUVs();
        return value;
    }

/**
	 * Defines the number of vertical segments that make up the torus. Defaults to 8.
	 */

    public function get_segmentsT():Int {
        return _segmentsT;
    }

    public function set_segmentsT(value:Int):Int {
        _segmentsT = value;
        invalidateGeometry();
        invalidateUVs();
        return value;
    }

/**
	 * Defines whether the torus poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */

    public function get_yUp():Bool {
        return _yUp;
    }

    public function set_yUp(value:Bool):Bool {
        _yUp = value;
        invalidateGeometry();
        return value;
    }

/**
	 * Creates a new <code>Torus</code> object.
	 * @param radius The radius of the torus.
	 * @param tuebRadius The radius of the inner tube of the torus.
	 * @param segmentsR Defines the number of horizontal segments that make up the torus.
	 * @param segmentsT Defines the number of vertical segments that make up the torus.
	 * @param yUp Defines whether the torus poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */

    public function new(radius:Float = 50, tubeRadius:Float = 50, segmentsR:Int = 16, segmentsT:Int = 8, yUp:Bool = true) {
        super();
        _radius = radius;
        _tubeRadius = tubeRadius;
        _segmentsR = segmentsR;
        _segmentsT = segmentsT;
        _yUp = yUp;
    }

}

