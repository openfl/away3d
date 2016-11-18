package away3d.core.math;

class PlaneClassification {

// "back" is synonymous with "in", but used for planes (back of plane is "inside" a solid volume walled by a plane)
	public static var BACK:Int = 0;
	public static var FRONT:Int = 1;
	public static var IN:Int = 0;
	public static var OUT:Int = 1;
	public static var INTERSECT:Int = 2;
}

