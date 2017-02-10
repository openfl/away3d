package away3d.paths;

import away3d.errors.AbstractMethodError;

import openfl.errors.Error;
import openfl.geom.Vector3D;
import openfl.Vector;

class SegmentedPathBase implements IPath
{
	public var pointData(never, set):Vector<Vector3D>;
	public var numSegments(get, never):Int;
	public var segments(get, never):Vector<IPathSegment>;
	
	private var _pointsPerSegment:Int;
	private var _segments:Vector<IPathSegment>;
	
	public function new(pointsPerSegment:Int, data:Vector<Vector3D> = null)
	{
		_pointsPerSegment = pointsPerSegment;
		if (data != null)
			pointData = data;
	}
	
	private function set_pointData(data:Vector<Vector3D>):Vector<Vector3D>
	{
		if (data.length < _pointsPerSegment)
			throw new Error("Path Vector.<Vector3D> must contain at least " + _pointsPerSegment + " Vector3D's");
		
		if (data.length % _pointsPerSegment != 0)
			throw new Error("Path Vector.<Vector3D> must contain series of " + _pointsPerSegment + " Vector3D's per segment");
		
		_segments = new Vector<IPathSegment>();
		var i:Int = 0;
		var len:Int = data.length;
		while (i < len) {
			_segments.push(createSegmentFromArrayEntry(data, i));
			i += _pointsPerSegment;
		}
		return data;
	}
	
	// factory method
	private function createSegmentFromArrayEntry(data:Vector<Vector3D>, offset:Int):IPathSegment
	{
		throw new AbstractMethodError();
		return null;
	}
	
	/**
	 * The number of segments in the Path
	 */
	private function get_numSegments():Int
	{
		return _segments.length;
	}
	
	/**
	 * returns the Vector.&lt;PathSegment&gt; holding the elements (PathSegment) of the path
	 *
	 * @return    a Vector.&lt;PathSegment&gt;: holding the elements (PathSegment) of the path
	 */
	private function get_segments():Vector<IPathSegment>
	{
		return _segments;
	}
	
	/**
	 * returns a given PathSegment from the path (PathSegment holds 3 Vector3D's)
	 *
	 * @param     indice uint. the indice of a given PathSegment
	 * @return    given PathSegment from the path
	 */
	public function getSegmentAt(index:Int):IPathSegment
	{
		return _segments[index];
	}
	
	public function addSegment(segment:IPathSegment):Void
	{
		_segments.push(segment);
	}
	
	/**
	 * removes a segment in the path according to id.
	 *
	 * @param     index    int. The index in path of the to be removed curvesegment
	 * @param     join        Boolean. If true previous and next segments coordinates are reconnected
	 */
	public function removeSegment(index:Int, join:Bool = false):Void
	{
		if (_segments.length == 0 || index >= _segments.length - 1)
			return;
		
		if (join && index > 0 && index < _segments.length - 1)
			stitchSegment(_segments[index - 1], _segments[index], _segments[index + 1]);
		
		_segments.splice(index, 1);
	}
	
	/**
	 * Stitches two segments together based on a segment between them. This is an abstract method used by the template method removeSegment and must be overridden by concrete subclasses!
	 * @param start The section of which the end points must be connected with "end"
	 * @param middle The section that was removed and forms the position hint
	 * @param end The section of which the start points must be connected with "start"
	 */
	private function stitchSegment(start:IPathSegment, middle:IPathSegment, end:IPathSegment):Void
	{
		throw new AbstractMethodError();
	}
	
	public function dispose():Void
	{
		var len:Int = _segments.length;
		for (i in 0...len)
			_segments[i].dispose();
		
		_segments = null;
	}
	
	public function getPointOnCurve(t:Float, target:Vector3D = null):Vector3D
	{
		var numSegments:Int = _segments.length;
		t *= numSegments;
		var segment:Int = Std.int(t);
		
		if (segment == numSegments) {
			segment = numSegments - 1;
			t = 1;
		} else
			t -= segment;
		
		return _segments[segment].getPointOnSegment(t, target);
	}
	
	public function getPointsOnCurvePerSegment(subdivision:Int):Vector<Vector<Vector3D>>
	{
		var points:Vector<Vector<Vector3D>> = new Vector<Vector<Vector3D>>();
		
		var len:Int = _segments.length;
		for (i in 0...len)
			points[i] = getSegmentPoints(_segments[i], subdivision, (i == len - 1));
		
		return points;
	}
	
	private function getSegmentPoints(segment:IPathSegment, n:Int, last:Bool):Vector<Vector3D>
	{
		var points:Vector<Vector3D> = new Vector<Vector3D>();
		
		for (i in 0...(n + (last? 1 : 0)))
			points[i] = segment.getPointOnSegment(i / n);
		
		return points;
	}
}