package away3d.core.math;

class PlaneClassification
{
	// "back" is synonymous with "in", but used for planes (back of plane is "inside" a solid volume walled by a plane)
	public static inline var BACK:Int = 0;
	public static inline var FRONT:Int = 1;
	
	public static inline var IN:Int = 0;
	public static inline var OUT:Int = 1;
	public static inline var INTERSECT:Int = 2;
}