/**
 * A WireframePlane primitive mesh.
 */
package away3d.primitives;

import flash.errors.Error;
import flash.geom.Vector3D;

class WireframePlane extends WireframePrimitiveBase {
    public var orientation(get_orientation, set_orientation):String;
    public var width(get_width, set_width):Float;
    public var height(get_height, set_height):Float;
    public var segmentsW(get_segmentsW, set_segmentsW):Int;
    public var segmentsH(get_segmentsH, set_segmentsH):Int;

    static public var ORIENTATION_YZ:String = "yz";
    static public var ORIENTATION_XY:String = "xy";
    static public var ORIENTATION_XZ:String = "xz";
    private var _width:Float;
    private var _height:Float;
    private var _segmentsW:Int;
    private var _segmentsH:Int;
    private var _orientation:String;
/**
	 * Creates a new WireframePlane object.
	 * @param width The size of the cube along its X-axis.
	 * @param height The size of the cube along its Y-axis.
	 * @param segmentsW The number of segments that make up the cube along the X-axis.
	 * @param segmentsH The number of segments that make up the cube along the Y-axis.
	 * @param color The colour of the wireframe lines
	 * @param thickness The thickness of the wireframe lines
	 * @param orientation The orientaion in which the plane lies.
	 */

    public function new(width:Float, height:Float, segmentsW:Int = 10, segmentsH:Int = 10, color:Int = 0xFFFFFF, thickness:Float = 1, orientation:String = "yz") {
        super(color, thickness);
        _width = width;
        _height = height;
        _segmentsW = segmentsW;
        _segmentsH = segmentsH;
        _orientation = orientation;
    }

/**
	 * The orientaion in which the plane lies.
	 */

    public function get_orientation():String {
        return _orientation;
    }

    public function set_orientation(value:String):String {
        _orientation = value;
        invalidateGeometry();
        return value;
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
        if (value <= 0) throw new Error("Value needs to be greater than 0");
        _height = value;
        invalidateGeometry();
        return value;
    }

/**
	 * The number of segments that make up the plane along the X-axis.
	 */

    public function get_segmentsW():Int {
        return _segmentsW;
    }

    public function set_segmentsW(value:Int):Int {
        _segmentsW = value;
        removeAllSegments();
        invalidateGeometry();
        return value;
    }

/**
	 * The number of segments that make up the plane along the Y-axis.
	 */

    public function get_segmentsH():Int {
        return _segmentsH;
    }

    public function set_segmentsH(value:Int):Int {
        _segmentsH = value;
        removeAllSegments();
        invalidateGeometry();
        return value;
    }

/**
	 * @inheritDoc
	 */

    override private function buildGeometry():Void {
        var v0:Vector3D = new Vector3D();
        var v1:Vector3D = new Vector3D();
        var hw:Float = _width * .5;
        var hh:Float = _height * .5;
        var index:Int = 0;
        var ws:Int = 0;
        var hs:Int = 0;
        if (_orientation == ORIENTATION_XY) {
            v0.y = hh;
            v0.z = 0;
            v1.y = -hh;
            v1.z = 0;
            ws = 0;
            while (ws <= _segmentsW) {
                v0.x = v1.x = (ws / _segmentsW - .5) * _width;
                updateOrAddSegment(index++, v0, v1);
                ++ws;
            }
            v0.x = -hw;
            v1.x = hw;
            hs = 0;
            while (hs <= _segmentsH) {
                v0.y = v1.y = (hs / _segmentsH - .5) * _height;
                updateOrAddSegment(index++, v0, v1);
                ++hs;
            }
        }

        else if (_orientation == ORIENTATION_XZ) {
            v0.z = hh;
            v0.y = 0;
            v1.z = -hh;
            v1.y = 0;
            ws = 0;
            while (ws <= _segmentsW) {
                v0.x = v1.x = (ws / _segmentsW - .5) * _width;
                updateOrAddSegment(index++, v0, v1);
                ++ws;
            }
            v0.x = -hw;
            v1.x = hw;
            hs = 0;
            while (hs <= _segmentsH) {
                v0.z = v1.z = (hs / _segmentsH - .5) * _height;
                updateOrAddSegment(index++, v0, v1);
                ++hs;
            }
        }

        else if (_orientation == ORIENTATION_YZ) {
            v0.y = hh;
            v0.x = 0;
            v1.y = -hh;
            v1.x = 0;
            ws = 0;
            while (ws <= _segmentsW) {
                v0.z = v1.z = (ws / _segmentsW - .5) * _width;
                updateOrAddSegment(index++, v0, v1);
                ++ws;
            }
            v0.z = hw;
            v1.z = -hw;
            hs = 0;
            while (hs <= _segmentsH) {
                v0.y = v1.y = (hs / _segmentsH - .5) * _height;
                updateOrAddSegment(index++, v0, v1);
                ++hs;
            }
        }
    }

}

