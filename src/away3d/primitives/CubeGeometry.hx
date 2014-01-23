/**
 * A Cube primitive mesh.
 */
package away3d.primitives;


import away3d.utils.ArrayUtils;
import flash.Vector;
import away3d.core.base.CompactSubGeometry; 
class CubeGeometry extends PrimitiveBase {
    public var width(get_width, set_width):Float;
    public var height(get_height, set_height):Float;
    public var depth(get_depth, set_depth):Float;
    public var tile6(get_tile6, set_tile6):Bool;
    public var segmentsW(get_segmentsW, set_segmentsW):Float;
    public var segmentsH(get_segmentsH, set_segmentsH):Float;
    public var segmentsD(get_segmentsD, set_segmentsD):Float;

    private var _width:Float;
    private var _height:Float;
    private var _depth:Float;
    private var _tile6:Bool;
    private var _segmentsW:Float;
    private var _segmentsH:Float;
    private var _segmentsD:Float;
/**
	 * Creates a new Cube object.
	 * @param width The size of the cube along its X-axis.
	 * @param height The size of the cube along its Y-axis.
	 * @param depth The size of the cube along its Z-axis.
	 * @param segmentsW The number of segments that make up the cube along the X-axis.
	 * @param segmentsH The number of segments that make up the cube along the Y-axis.
	 * @param segmentsD The number of segments that make up the cube along the Z-axis.
	 * @param tile6 The type of uv mapping to use. When true, a texture will be subdivided in a 2x3 grid, each used for a single face. When false, the entire image is mapped on each face.
	 */

    public function new(width:Float = 100, height:Float = 100, depth:Float = 100, segmentsW:Int = 1, segmentsH:Int = 1, segmentsD:Int = 1, tile6:Bool = true) {
        super();
        _width = width;
        _height = height;
        _depth = depth;
        _segmentsW = segmentsW;
        _segmentsH = segmentsH;
        _segmentsD = segmentsD;
        _tile6 = tile6;
    }

/**
	 * The size of the cube along its X-axis.
	 */

    public function get_width():Float {
        return _width;
    }

    public function set_width(value:Float):Float {
        _width = value;
        invalidateGeometry();
        return value;
    }

/**
	 * The size of the cube along its Y-axis.
	 */

    public function get_height():Float {
        return _height;
    }

    public function set_height(value:Float):Float {
        _height = value;
        invalidateGeometry();
        return value;
    }

/**
	 * The size of the cube along its Z-axis.
	 */

    public function get_depth():Float {
        return _depth;
    }

    public function set_depth(value:Float):Float {
        _depth = value;
        invalidateGeometry();
        return value;
    }

/**
	 * The type of uv mapping to use. When false, the entire image is mapped on each face.
	 * When true, a texture will be subdivided in a 3x2 grid, each used for a single face.
	 * Reading the tiles from left to right, top to bottom they represent the faces of the
	 * cube in the following order: bottom, top, back, left, front, right. This creates
	 * several shared edges (between the top, front, left and right faces) which simplifies
	 * texture painting.
	 */

    public function get_tile6():Bool {
        return _tile6;
    }

    public function set_tile6(value:Bool):Bool {
        _tile6 = value;
        invalidateUVs();
        return value;
    }

/**
	 * The number of segments that make up the cube along the X-axis. Defaults to 1.
	 */

    public function get_segmentsW():Float {
        return _segmentsW;
    }

    public function set_segmentsW(value:Float):Float {
        _segmentsW = value;
        invalidateGeometry();
        invalidateUVs();
        return value;
    }

/**
	 * The number of segments that make up the cube along the Y-axis. Defaults to 1.
	 */

    public function get_segmentsH():Float {
        return _segmentsH;
    }

    public function set_segmentsH(value:Float):Float {
        _segmentsH = value;
        invalidateGeometry();
        invalidateUVs();
        return value;
    }

/**
	 * The number of segments that make up the cube along the Z-axis. Defaults to 1.
	 */

    public function get_segmentsD():Float {
        return _segmentsD;
    }

    public function set_segmentsD(value:Float):Float {
        _segmentsD = value;
        invalidateGeometry();
        invalidateUVs();
        return value;
    }

/**
	 * @inheritDoc
	 */

    override private function buildGeometry(target:CompactSubGeometry):Void {
        var data:Vector<Float>;
        var indices:Vector<UInt>;
        var tl:Int= 0;
        var tr:Int= 0;
        var bl:Int= 0;
        var br:Int= 0;
        var i:Int = 0;
        var j:Int= 0;
        var inc:Int = 0;
        var vidx:Int= 0;
        var fidx:Int= 0;
// indices
        var hw:Float= 0;
        var hh:Float= 0;
        var hd:Float= 0;
// halves
        var dw:Float= 0;
        var dh:Float= 0;
        var dd:Float= 0;
// deltas
        var outer_pos:Float;
        var numVerts:Int = Std.int(((_segmentsW + 1) * (_segmentsH + 1) + (_segmentsW + 1) * (_segmentsD + 1) + (_segmentsH + 1) * (_segmentsD + 1)) * 2);
        var stride:Int = target.vertexStride;
        var skip:Int = stride - 9;
        if (numVerts == target.numVertices) {
            data = target.vertexData;
            indices = target.indexData;
            if (indices == null){
                indices = new Vector<UInt>(Std.int((_segmentsW * _segmentsH + _segmentsW * _segmentsD + _segmentsH * _segmentsD) * 12), true);
                ArrayUtils.Prefill(indices,Std.int((_segmentsW * _segmentsH + _segmentsW * _segmentsD + _segmentsH * _segmentsD) * 12),0);
            }
        }

        else {
            data = new Vector<Float>(numVerts * stride, true);
            indices = new Vector<UInt>(Std.int((_segmentsW * _segmentsH + _segmentsW * _segmentsD + _segmentsH * _segmentsD) * 12), true);
            ArrayUtils.Prefill(data, numVerts * stride,0);
            ArrayUtils.Prefill(indices, Std.int((_segmentsW * _segmentsH + _segmentsW * _segmentsD + _segmentsH * _segmentsD) * 12),0);

            invalidateUVs();  
        }

// Indices
        vidx = target.vertexOffset;
        fidx = 0;
// half cube dimensions
        hw = _width / 2;
        hh = _height / 2;
        hd = _depth / 2;
// Segment dimensions
        dw = _width / _segmentsW;
        dh = _height / _segmentsH;
        dd = _depth / _segmentsD;
        i = 0;
        while (i <= _segmentsW) {
            outer_pos = -hw + i * dw;
            j = 0;
            while (j <= _segmentsH) {
// front
                data[vidx++] = outer_pos;
                data[vidx++] = -hh + j * dh;
                data[vidx++] = -hd;
                data[vidx++] = 0;
                data[vidx++] = 0;
                data[vidx++] = -1;
                data[vidx++] = 1;
                data[vidx++] = 0;
                data[vidx++] = 0;
                vidx += skip;
// back
                data[vidx++] = outer_pos;
                data[vidx++] = -hh + j * dh;
                data[vidx++] = hd;
                data[vidx++] = 0;
                data[vidx++] = 0;
                data[vidx++] = 1;
                data[vidx++] = -1;
                data[vidx++] = 0;
                data[vidx++] = 0;
                vidx += skip;
                if (i > 0 && j > 0) {
                    tl = Std.int(2 * ((i - 1) * (_segmentsH + 1) + (j - 1)));
                    tr = Std.int(2 * (i * (_segmentsH + 1) + (j - 1)));
                    bl = tl + 2;
                    br = tr + 2;
                    indices[fidx++] = tl;
                    indices[fidx++] = bl;
                    indices[fidx++] = br;
                    indices[fidx++] = tl;
                    indices[fidx++] = br;
                    indices[fidx++] = tr;
                    indices[fidx++] = tr + 1;
                    indices[fidx++] = br + 1;
                    indices[fidx++] = bl + 1;
                    indices[fidx++] = tr + 1;
                    indices[fidx++] = bl + 1;
                    indices[fidx++] = tl + 1;
                }
                j++;
            }
            i++;
        }
        inc += Std.int(2 * (_segmentsW + 1) * (_segmentsH + 1));
        i = 0;
        while (i <= _segmentsW) {
            outer_pos = -hw + i * dw;
            j = 0;
            while (j <= _segmentsD) {
// top
                data[vidx++] = outer_pos;
                data[vidx++] = hh;
                data[vidx++] = -hd + j * dd;
                data[vidx++] = 0;
                data[vidx++] = 1;
                data[vidx++] = 0;
                data[vidx++] = 1;
                data[vidx++] = 0;
                data[vidx++] = 0;
                vidx += skip;
// bottom
                data[vidx++] = outer_pos;
                data[vidx++] = -hh;
                data[vidx++] = -hd + j * dd;
                data[vidx++] = 0;
                data[vidx++] = -1;
                data[vidx++] = 0;
                data[vidx++] = 1;
                data[vidx++] = 0;
                data[vidx++] = 0;
                vidx += skip;
                if (i > 0 && j > 0) {
                    tl = Std.int(inc + 2 * ((i - 1) * (_segmentsD + 1) + (j - 1)));
                    tr = Std.int(inc + 2 * (i * (_segmentsD + 1) + (j - 1)));
                    bl = tl + 2;
                    br = tr + 2;
                    indices[fidx++] = tl;
                    indices[fidx++] = bl;
                    indices[fidx++] = br;
                    indices[fidx++] = tl;
                    indices[fidx++] = br;
                    indices[fidx++] = tr;
                    indices[fidx++] = tr + 1;
                    indices[fidx++] = br + 1;
                    indices[fidx++] = bl + 1;
                    indices[fidx++] = tr + 1;
                    indices[fidx++] = bl + 1;
                    indices[fidx++] = tl + 1;
                }
                j++;
            }
            i++;
        }
        inc += Std.int(2 * (_segmentsW + 1) * (_segmentsD + 1));
        i = 0;
        while (i <= _segmentsD) {
            outer_pos = hd - i * dd;
            j = 0;
            while (j <= _segmentsH) {
// left
                data[vidx++] = -hw;
                data[vidx++] = -hh + j * dh;
                data[vidx++] = outer_pos;
                data[vidx++] = -1;
                data[vidx++] = 0;
                data[vidx++] = 0;
                data[vidx++] = 0;
                data[vidx++] = 0;
                data[vidx++] = -1;
                vidx += skip;
// right
                data[vidx++] = hw;
                data[vidx++] = -hh + j * dh;
                data[vidx++] = outer_pos;
                data[vidx++] = 1;
                data[vidx++] = 0;
                data[vidx++] = 0;
                data[vidx++] = 0;
                data[vidx++] = 0;
                data[vidx++] = 1;
                vidx += skip;
                if (i > 0 && j > 0) {
                    tl = Std.int(inc + 2 * ((i - 1) * (_segmentsH + 1) + (j - 1)));
                    tr = Std.int(inc + 2 * (i * (_segmentsH + 1) + (j - 1)));
                    bl = tl + 2;
                    br = tr + 2;
                    indices[fidx++] = tl;
                    indices[fidx++] = bl;
                    indices[fidx++] = br;
                    indices[fidx++] = tl;
                    indices[fidx++] = br;
                    indices[fidx++] = tr;
                    indices[fidx++] = tr + 1;
                    indices[fidx++] = br + 1;
                    indices[fidx++] = bl + 1;
                    indices[fidx++] = tr + 1;
                    indices[fidx++] = bl + 1;
                    indices[fidx++] = tl + 1;
                }
                j++;
            }
            i++;
        }
        target.updateData(data);
        target.updateIndexData(indices);
    }

/**
	 * @inheritDoc
	 */

    override private function buildUVs(target:CompactSubGeometry):Void {
        var i:Int = 0;
        var j:Int;
        var uidx:Int;
        var data:Vector<Float>;
        var u_tile_dim:Float;
        var v_tile_dim:Float;
        var u_tile_step:Float;
        var v_tile_step:Float;
        var tl0u:Float;
        var tl0v:Float;
        var tl1u:Float;
        var tl1v:Float;
        var du:Float;
        var dv:Float;
        var stride:Int = target.UVStride;
        var numUvs:Int = Std.int(((_segmentsW + 1) * (_segmentsH + 1) + (_segmentsW + 1) * (_segmentsD + 1) + (_segmentsH + 1) * (_segmentsD + 1)) * 2 * stride);
        var skip:Int = stride - 2;
        if (target.UVData != null && numUvs == target.UVData.length) data = target.UVData
        else {
            data = new Vector<Float>(numUvs, true);
            ArrayUtils.Prefill(data,numUvs,0);
            invalidateGeometry();
        }

        if (_tile6) {
            u_tile_dim = u_tile_step = 1 / 3;
            v_tile_dim = v_tile_step = 1 / 2;
        }

        else {
            u_tile_dim = v_tile_dim = 1;
            u_tile_step = v_tile_step = 0;
        }

// Create planes two and two, the same way that they were
// constructed in the buildGeometry() function. First calculate
// the top-left UV coordinate for both planes, and then loop
// over the points, calculating the UVs from these numbers.
// When tile6 is true, the layout is as follows:
//       .-----.-----.-----. (1,1)
//       | Bot |  T  | Bak |
//       |-----+-----+-----|
//       |  L  |  F  |  R  |
// (0,0)'-----'-----'-----'
        uidx = target.UVOffset;
// FRONT / BACK
        tl0u = 1 * u_tile_step;
        tl0v = 1 * v_tile_step;
        tl1u = 2 * u_tile_step;
        tl1v = 0 * v_tile_step;
        du = u_tile_dim / _segmentsW;
        dv = v_tile_dim / _segmentsH;
        i = 0;
        while (i <= _segmentsW) {
            j = 0;
            while (j <= _segmentsH) {
                data[uidx++] = (tl0u + i * du) * target.scaleU;
                data[uidx++] = (tl0v + (v_tile_dim - j * dv)) * target.scaleV;
                uidx += skip;
                data[uidx++] = (tl1u + (u_tile_dim - i * du)) * target.scaleU;
                data[uidx++] = (tl1v + (v_tile_dim - j * dv)) * target.scaleV;
                uidx += skip;
                j++;
            }
            i++;
        }
// TOP / BOTTOM
        tl0u = 1 * u_tile_step;
        tl0v = 0 * v_tile_step;
        tl1u = 0 * u_tile_step;
        tl1v = 0 * v_tile_step;
        du = u_tile_dim / _segmentsW;
        dv = v_tile_dim / _segmentsD;
        i = 0;
        while (i <= _segmentsW) {
            j = 0;
            while (j <= _segmentsD) {
                data[uidx++] = (tl0u + i * du) * target.scaleU;
                data[uidx++] = (tl0v + (v_tile_dim - j * dv)) * target.scaleV;
                uidx += skip;
                data[uidx++] = (tl1u + i * du) * target.scaleU;
                data[uidx++] = (tl1v + j * dv) * target.scaleV;
                uidx += skip;
                j++;
            }
            i++;
        }
// LEFT / RIGHT
        tl0u = 0 * u_tile_step;
        tl0v = 1 * v_tile_step;
        tl1u = 2 * u_tile_step;
        tl1v = 1 * v_tile_step;
        du = u_tile_dim / _segmentsD;
        dv = v_tile_dim / _segmentsH;
        i = 0;
        while (i <= _segmentsD) {
            j = 0;
            while (j <= _segmentsH) {
                data[uidx++] = (tl0u + i * du) * target.scaleU;
                data[uidx++] = (tl0v + (v_tile_dim - j * dv)) * target.scaleV;
                uidx += skip;
                data[uidx++] = (tl1u + (u_tile_dim - i * du)) * target.scaleU;
                data[uidx++] = (tl1v + (v_tile_dim - j * dv)) * target.scaleV;
                uidx += skip;
                j++;
            }
            i++;
        }
        target.updateData(data);
    }

}

