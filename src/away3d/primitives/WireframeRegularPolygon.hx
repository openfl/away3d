/**
 * A WireframeRegularPolygon primitive mesh.
 */
package away3d.primitives;

import flash.geom.Vector3D;

class WireframeRegularPolygon extends WireframePrimitiveBase {
    public var orientation(get_orientation, set_orientation):String;
    public var radius(get_radius, set_radius):Float;
    public var sides(get_sides, set_sides):Int;

    static public var ORIENTATION_YZ:String = "yz";
    static public var ORIENTATION_XY:String = "xy";
    static public var ORIENTATION_XZ:String = "xz";
    private var _radius:Float;
    private var _sides:Int;
    private var _orientation:String;
/**
	 * Creates a new WireframeRegularPolygon object.
	 * @param radius The radius of the polygon.
	 * @param sides The number of sides on the polygon.
	 * @param color The colour of the wireframe lines
	 * @param thickness The thickness of the wireframe lines
	 * @param orientation The orientaion in which the plane lies.
	 */

    public function new(radius:Float, sides:Int, color:Int = 0xFFFFFF, thickness:Float = 1, orientation:String = "yz") {
        super(color, thickness);
        _radius = radius;
        _sides = sides;
        _orientation = orientation;
    }

/**
	 * The orientaion in which the polygon lies.
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
	 * The radius of the regular polygon.
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
	 * The number of sides to the regular polygon.
	 */

    public function get_sides():Int {
        return _sides;
    }

    public function set_sides(value:Int):Int {
        _sides = value;
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
        var index:Int = 0;
        var s:Int = 0;
        if (_orientation == ORIENTATION_XY) {
            v0.z = 0;
            v1.z = 0;
            s = 0;
            while (s < _sides) {
                v0.x = _radius * Math.cos(2 * Math.PI * s / _sides);
                v0.y = _radius * Math.sin(2 * Math.PI * s / _sides);
                v1.x = _radius * Math.cos(2 * Math.PI * (s + 1) / _sides);
                v1.y = _radius * Math.sin(2 * Math.PI * (s + 1) / _sides);
                updateOrAddSegment(index++, v0, v1);
                ++s;
            }
        }

        else if (_orientation == ORIENTATION_XZ) {
            v0.y = 0;
            v1.y = 0;
            s = 0;
            while (s < _sides) {
                v0.x = _radius * Math.cos(2 * Math.PI * s / _sides);
                v0.z = _radius * Math.sin(2 * Math.PI * s / _sides);
                v1.x = _radius * Math.cos(2 * Math.PI * (s + 1) / _sides);
                v1.z = _radius * Math.sin(2 * Math.PI * (s + 1) / _sides);
                updateOrAddSegment(index++, v0, v1);
                ++s;
            }
        }

        else if (_orientation == ORIENTATION_YZ) {
            v0.x = 0;
            v1.x = 0;
            s = 0;
            while (s < _sides) {
                v0.z = _radius * Math.cos(2 * Math.PI * s / _sides);
                v0.y = _radius * Math.sin(2 * Math.PI * s / _sides);
                v1.z = _radius * Math.cos(2 * Math.PI * (s + 1) / _sides);
                v1.y = _radius * Math.sin(2 * Math.PI * (s + 1) / _sides);
                updateOrAddSegment(index++, v0, v1);
                ++s;
            }
        }
    }

}

