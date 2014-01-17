/**
 * A UV Cone primitive mesh.
 */
package away3d.primitives;

class ConeGeometry extends CylinderGeometry {
    public var radius(get_radius, set_radius):Float;

/**
	 * The radius of the bottom end of the cone.
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
	 * Creates a new Cone object.
	 * @param radius The radius of the bottom end of the cone
	 * @param height The height of the cone
	 * @param segmentsW Defines the number of horizontal segments that make up the cone. Defaults to 16.
	 * @param segmentsH Defines the number of vertical segments that make up the cone. Defaults to 1.
	 * @param yUp Defines whether the cone poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */

    public function new(radius:Float = 50, height:Float = 100, segmentsW:Int = 16, segmentsH:Int = 1, closed:Bool = true, yUp:Bool = true) {
        super(0, radius, height, segmentsW, segmentsH, false, closed, true, yUp);
    }

}

