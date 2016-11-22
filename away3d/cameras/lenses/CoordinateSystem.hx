package away3d.cameras.lenses;

/**
 * Provides constant values for camera lens projection options use the the <code>coordinateSystem</code> property
 * 
 * @see away3d.cameras.lenses.PerspectiveLens#coordinateSystem
 */
class CoordinateSystem
{
	/**
	 * Default option, projects to a left-handed coordinate system
	 */
	public static inline var LEFT_HANDED:Int = 0;
	
	/**
	 * Projects to a right-handed coordinate system
	 */
	public static inline var RIGHT_HANDED:Int = 1;
}