/**
 * A Capsule primitive mesh.
 */
package away3d.primitives;

import flash.Vector;
import away3d.core.base.CompactSubGeometry;

class CapsuleGeometry extends PrimitiveBase {
    public var radius(get_radius, set_radius):Float;
    public var height(get_height, set_height):Float;
    public var segmentsW(get_segmentsW, set_segmentsW):Int;
    public var segmentsH(get_segmentsH, set_segmentsH):Int;
    public var yUp(get_yUp, set_yUp):Bool;

    private var _radius:Float;
    private var _height:Float;
    private var _segmentsW:Int;
    private var _segmentsH:Int;
    private var _yUp:Bool;
/**
	 * Creates a new Capsule object.
	 * @param radius The radius of the capsule.
	 * @param height The height of the capsule.
	 * @param segmentsW Defines the number of horizontal segments that make up the capsule. Defaults to 16.
	 * @param segmentsH Defines the number of vertical segments that make up the capsule. Defaults to 15. Must be uneven value.
	 * @param yUp Defines whether the capsule poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */

    public function new(radius:Float = 50, height:Float = 100, segmentsW:Int = 16, segmentsH:Int = 15, yUp:Bool = true) {
        super();
        _radius = radius;
        _height = height;
        _segmentsW = segmentsW;
        _segmentsH = ((segmentsH % 2 == 0)) ? segmentsH + 1 : segmentsH;
        _yUp = yUp;
    }

/**
	 * @inheritDoc
	 */

    override private function buildGeometry(target:CompactSubGeometry):Void {
        var data:Vector<Float>;
        var indices:Vector<UInt>;
        var i:Int = 0;
        var j:Int = 0;
        var triIndex:Int = 0;
        var numVerts:Int = (_segmentsH + 1) * (_segmentsW + 1);
        var stride:Int = target.vertexStride;
        var skip:Int = stride - 9;
        var index:Int = 0;
        var startIndex:Int = 0;
        var comp1:Float = 0;
        var comp2:Float = 0;
        var t1:Float = 0;
        var t2:Float = 0;
        if (numVerts == target.numVertices) {
            data = target.vertexData;
            indices = target.indexData ;
            if (indices == null) indices = new Vector<UInt>((_segmentsH - 1) * _segmentsW * 6, true);
        }

        else {
            data = new Vector<Float>(numVerts * stride, true);
            indices = new Vector<UInt>((_segmentsH - 1) * _segmentsW * 6, true);
            invalidateUVs();
        }

        j = 0;
        while (j <= _segmentsH) {
            var horangle:Float = Math.PI * j / _segmentsH;
            var z:Float = -_radius * Math.cos(horangle);
            var ringradius:Float = _radius * Math.sin(horangle);
            startIndex = index;
            i = 0;
            while (i <= _segmentsW) {
                var verangle:Float = 2 * Math.PI * i / _segmentsW;
                var x:Float = ringradius * Math.cos(verangle);
                var offset:Float = j > _segmentsH / (2) ? _height / 2 : -_height / 2;
                var y:Float = ringradius * Math.sin(verangle);
                var normLen:Float = 1 / Math.sqrt(x * x + y * y + z * z);
                var tanLen:Float = Math.sqrt(y * y + x * x);
                if (_yUp) {
                    t1 = 0;
                    t2 = tanLen > (.007) ? x / tanLen : 0;
                    comp1 = -z;
                    comp2 = y;
                }

                else {
                    t1 = tanLen > (.007) ? x / tanLen : 0;
                    t2 = 0;
                    comp1 = y;
                    comp2 = z;
                }

                if (i == _segmentsW) {
                    data[index++] = data[startIndex];
                    data[index++] = data[startIndex + 1];
                    data[index++] = data[startIndex + 2];
                    data[index++] = (data[startIndex + 3] + (x * normLen)) * .5;
                    data[index++] = (data[startIndex + 4] + (comp1 * normLen)) * .5;
                    data[index++] = (data[startIndex + 5] + (comp2 * normLen)) * .5;
                    data[index++] = (data[startIndex + 6] + (tanLen > (.007) ? -y / tanLen : 1)) * .5;
                    data[index++] = (data[startIndex + 7] + t1) * .5;
                    data[index++] = (data[startIndex + 8] + t2) * .5;
                }

                else {
// vertex
                    data[index++] = x;
                    data[index++] = ((_yUp)) ? comp1 - offset : comp1;
                    data[index++] = ((_yUp)) ? comp2 : comp2 + offset;
// normal
                    data[index++] = x * normLen;
                    data[index++] = comp1 * normLen;
                    data[index++] = comp2 * normLen;
// tangent
                    data[index++] = tanLen > (.007) ? -y / tanLen : 1;
                    data[index++] = t1;
                    data[index++] = t2;
                }

                if (i > 0 && j > 0) {
                    var a:Int = (_segmentsW + 1) * j + i;
                    var b:Int = (_segmentsW + 1) * j + i - 1;
                    var c:Int = (_segmentsW + 1) * (j - 1) + i - 1;
                    var d:Int = (_segmentsW + 1) * (j - 1) + i;
                    if (j == _segmentsH) {
                        data[index - 9] = data[startIndex];
                        data[index - 8] = data[startIndex + 1];
                        data[index - 7] = data[startIndex + 2];
                        indices[triIndex++] = a;
                        indices[triIndex++] = c;
                        indices[triIndex++] = d;
                    }

                    else if (j == 1) {
                        indices[triIndex++] = a;
                        indices[triIndex++] = b;
                        indices[triIndex++] = c;
                    }

                    else {
                        indices[triIndex++] = a;
                        indices[triIndex++] = b;
                        indices[triIndex++] = c;
                        indices[triIndex++] = a;
                        indices[triIndex++] = c;
                        indices[triIndex++] = d;
                    }

                }
                index += skip;
                ++i;
            }
            ++j;
        }
        target.updateData(data);
        target.updateIndexData(indices);
    }

/**
	 * @inheritDoc
	 */

    override private function buildUVs(target:CompactSubGeometry):Void {
        var i:Int;
        var j:Int;
        var index:Int;
        var data:Vector<Float>;
        var stride:Int = target.UVStride;
        var UVlen:Int = (_segmentsH + 1) * (_segmentsW + 1) * stride;
        var skip:Int = stride - 2;
        if (target.UVData != null && UVlen == target.UVData.length) data = target.UVData
        else {
            data = new Vector<Float>(UVlen, true);
            invalidateGeometry();
        }

        index = target.UVOffset;
        j = 0;
        while (j <= _segmentsH) {
            i = 0;
            while (i <= _segmentsW) {
                data[index++] = (i / _segmentsW) * target.scaleU;
                data[index++] = (j / _segmentsH) * target.scaleV;
                index += skip;
                ++i;
            }
            ++j;
        }
        target.updateData(data);
    }

/**
	 * The radius of the capsule.
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
	 * The height of the capsule.
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
	 * Defines the number of horizontal segments that make up the capsule. Defaults to 16.
	 */

    public function get_segmentsW():Int {
        return _segmentsW;
    }

    public function set_segmentsW(value:Int):Int {
        _segmentsW = value;
        invalidateGeometry();
        invalidateUVs();
        return value;
    }

/**
	 * Defines the number of vertical segments that make up the capsule. Defaults to 15. Must be uneven.
	 */

    public function get_segmentsH():Int {
        return _segmentsH;
    }

    public function set_segmentsH(value:Int):Int {
        _segmentsH = ((value % 2 == 0)) ? value + 1 : value;
        invalidateGeometry();
        invalidateUVs();
        return value;
    }

/**
	 * Defines whether the capsule poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */

    public function get_yUp():Bool {
        return _yUp;
    }

    public function set_yUp(value:Bool):Bool {
        _yUp = value;
        invalidateGeometry();
        return value;
    }

}

