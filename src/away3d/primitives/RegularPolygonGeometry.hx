/**
 * A UV RegularPolygon primitive mesh.
 */
package away3d.primitives;

class RegularPolygonGeometry extends CylinderGeometry {
    public var radius(get_radius, set_radius):Float;
    public var sides(get_sides, set_sides):Int;
    public var subdivisions(get_subdivisions, set_subdivisions):Int;

/**
	 * The radius of the regular polygon.
	 */

    public function get_radius():Float {
        return _bottomRadius;
    }

    public function set_radius(value:Float):Float {
        _bottomRadius = value;
        invalidateGeometry();
        return value;
    }

/**
	 * The number of sides of the regular polygon.
	 */

    public function get_sides():Int {
        return _segmentsW;
    }

    public function set_sides(value:Int):Int {
        segmentsW = value;
        return value;
    }

/**
	 * The number of subdivisions from the edge to the center of the regular polygon.
	 */

    public function get_subdivisions():Int {
        return _segmentsH;
    }

    public function set_subdivisions(value:Int):Int {
        segmentsH = value;
        return value;
    }

/**
	 * Creates a new RegularPolygon disc object.
	 * @param radius The radius of the regular polygon
	 * @param sides Defines the number of sides of the regular polygon.
	 * @param yUp Defines whether the regular polygon should lay on the Y-axis (true) or on the Z-axis (false).
	 */

    public function new(radius:Float = 100, sides:Int = 16, yUp:Bool = true) {
        super(radius, 0, 0, sides, 1, true, false, false, yUp);
    }

}

