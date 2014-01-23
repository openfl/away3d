/**
 * A Line Segment primitive.
 */
package away3d.primitives;

import away3d.primitives.data.Segment;
import flash.geom.Vector3D;

class LineSegment extends Segment {

    public var TYPE:String;
/**
	 * Create a line segment
	 * @param v0 Start position of the line segment
	 * @param v1 Ending position of the line segment
	 * @param color0 Starting color of the line segment
	 * @param color1 Ending colour of the line segment
	 * @param thickness Thickness of the line
	 */

    public function new(v0:Vector3D, v1:Vector3D, color0:Int = 0x333333, color1:Int = 0x333333, thickness:Float = 1) {
        TYPE = "line";
        super(v0, v1, null, color0, color1, thickness);
    }

}

