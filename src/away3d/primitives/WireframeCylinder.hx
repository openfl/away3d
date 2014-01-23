/**
 * Generates a wireframd cylinder primitive.
 */
package away3d.primitives;

import flash.errors.Error;
import flash.Vector;
import flash.geom.Vector3D;

class WireframeCylinder extends WireframePrimitiveBase {
    public var topRadius(get_topRadius, set_topRadius):Float;
    public var bottomRadius(get_bottomRadius, set_bottomRadius):Float;
    public var height(get_height, set_height):Float;

    static private var TWO_PI:Float = 2 * Math.PI;
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

    public function new(topRadius:Float = 50, bottomRadius:Float = 50, height:Float = 100, segmentsW:Int = 16, segmentsH:Int = 1, color:Int = 0xFFFFFF, thickness:Float = 1) {
        super(color, thickness);
        _topRadius = topRadius;
        _bottomRadius = bottomRadius;
        _height = height;
        _segmentsW = segmentsW;
        _segmentsH = segmentsH;
    }

    override private function buildGeometry():Void {
        var i:Int = 0;
        var j:Int;
        var radius:Float = _topRadius;
        var revolutionAngle:Float;
        var revolutionAngleDelta:Float = TWO_PI / _segmentsW;
        var nextVertexIndex:Int = 0;
        var x:Float;
        var y:Float;
        var z:Float;
        var lastLayer:Vector<Vector<Vector3D>> = new Vector<Vector<Vector3D>>(_segmentsH + 1, true);
        j = 0;
        while (j <= _segmentsH) {
            lastLayer[j] = new Vector<Vector3D>(_segmentsW + 1, true);
            radius = _topRadius - ((j / _segmentsH) * (_topRadius - _bottomRadius));
            z = -(_height / 2) + (j / _segmentsH * _height);
            var previousV:Vector3D = null;
            i = 0;
            while (i <= _segmentsW) {
// revolution vertex
                revolutionAngle = i * revolutionAngleDelta;
                x = radius * Math.cos(revolutionAngle);
                y = radius * Math.sin(revolutionAngle);
                var vertex:Vector3D = null;
                if (previousV != null) {
                    vertex = new Vector3D(x, -z, y);
                    updateOrAddSegment(nextVertexIndex++, vertex, previousV);
                    previousV = vertex;
                }

                else previousV = new Vector3D(x, -z, y);
                if (j > 0) updateOrAddSegment(nextVertexIndex++, vertex, lastLayer[j - 1][i]);
                lastLayer[j][i] = previousV;
                ++i;
            }
            ++j;
        }
    }

/**
	 * Top radius of the cylinder
	 */

    public function get_topRadius():Float {
        return _topRadius;
    }

    public function set_topRadius(value:Float):Float {
        _topRadius = value;
        invalidateGeometry();
        return value;
    }

/**
	 * Bottom radius of the cylinder
	 */

    public function get_bottomRadius():Float {
        return _bottomRadius;
    }

    public function set_bottomRadius(value:Float):Float {
        _bottomRadius = value;
        invalidateGeometry();
        return value;
    }

/**
	 * The height of the cylinder
	 */

    public function get_height():Float {
        return _height;
    }

    public function set_height(value:Float):Float {
        if (height <= 0) throw new Error("Height must be a value greater than zero.");
        _height = value;
        invalidateGeometry();
        return value;
    }

}

