package away3d.primitives;

/**
 * A UV Cone primitive mesh.
 */
class ConeGeometry extends CylinderGeometry
{
	/**
	 * The radius of the bottom end of the cone.
	 */
	public var radius(get, set):Float;
	
	private function get_radius():Float
	{
		return _bottomRadius;
	}
	
	private function set_radius(value:Float):Float
	{
		_bottomRadius = value;
		invalidateGeometry();
		return value;
	}
	
	/**
	 * Creates a new Cone object.
	 * @param radius The radius of the bottom end of the cone
	 * @param height The height of the cone
	 * @param sectionsC The number of sections the circumference is divided
	 * into. Defaults to 16.
	 * @param sectionsH The number of sections the cone's height is divided
	 * into. Defaults to 1.
	 * @param yUp Whether the cone poles should lay on the Y-axis (true) or on
	 * the Z-axis (false).
	 */
	public function new(radius:Float = 50, height:Float = 100, sectionsC:Int = 16, sectionsH:Int = 1, closed:Bool = true, yUp:Bool = true)
	{
		super(0, radius, height, sectionsC, sectionsH, false, closed, true, yUp);
	}
}