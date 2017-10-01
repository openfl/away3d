package away3d.primitives;

import away3d.primitives.data.Segment;

import openfl.geom.Vector3D;

/**
 * A Line Segment primitive.
 */
class LineSegment extends Segment
{
	
	public static inline var TYPE:String = "line";
	
	/**
	 * Create a line segment
	 * @param v0 Start position of the line segment
	 * @param v1 Ending position of the line segment
	 * @param color0 Starting color of the line segment
	 * @param color1 Ending colour of the line segment
	 * @param thickness Thickness of the line
	 */
	public function new(v0:Vector3D, v1:Vector3D, color0:Int = 0x333333, color1:Int = 0x333333, thickness:Float = 1)
	{
		super(v0, v1, null, color0, color1, thickness);
	}
}