package away3d.core.math;

class PlaneClassification {

// "back" is synonymous with "in", but used for planes (back of plane is "inside" a solid volume walled by a plane)
    static public var BACK:Int = 0;
    static public var FRONT:Int = 1;
    static public var IN:Int = 0;
    static public var OUT:Int = 1;
    static public var INTERSECT:Int = 2;
}

