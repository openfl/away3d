package away3d.paths;

import openfl.geom.Vector3D;
import openfl.Vector;

interface IPath
{
	/**
	 * The number of <code>CubicPathSegment</code> instances in the path.
	 */
	public var numSegments(get, never):Int;
	
	/**
	 * The <code>IPathSegment</code> instances which make up this path.
	 */
	public var segments(get, never):Vector<IPathSegment>;
	
	/**
	 * Returns the <code>CubicPathSegment</code> at the specified index
	 * @param index The index of the segment
	 * @return A <code>CubicPathSegment</code> instance
	 */
	public function getSegmentAt(index:Int):IPathSegment;
	
	/**
	 * Adds a <code>CubicPathSegment</code> to the end of the path
	 * @param segment
	 */
	public function addSegment(segment:IPathSegment):Void;
	
	/**
	 * Removes a segment from the path
	 * @param index The index of the <code>CubicPathSegment</code> to be removed
	 * @param join Determines if the segments on either side of the removed segment should be adjusted so there is no gap.
	 */
	public function removeSegment(index:Int, join:Bool = false):Void;
	
	/**
	 * Disposes the path and all the segments
	 */
	public function dispose():Void;
	
	/**
	 * Discretizes the segment into a set of sample points.
	 *
	 * @param numSegments The amount of segments to split the sampling in. The amount of points returned is numSegments + 1
	 */
	public function getPointsOnCurvePerSegment(numSegments:Int):Vector<Vector<Vector3D>>;
	
	/**
	 * Gets a point on the curve
	 * @param t The phase for which to get the point. A number between 0 and 1.
	 * @param target An optional parameter to store the calculation, to avoid creating a new Vector3D object
	 * @return The point on the curve for the given phase
	 */
	public function getPointOnCurve(t:Float, target:Vector3D = null):Vector3D;
	
}