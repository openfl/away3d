package away3d.paths;

	import away3d.errors.AbstractMethodError;
	
	import flash.geom.Vector3D;
	
	class SegmentedPathBase implements IPath
	{
		var _pointsPerSegment:UInt;
		var _segments:Array<IPathSegment>;
		
		public function new(pointsPerSegment:UInt, data:Array<Vector3D> = null)
		{
			_pointsPerSegment = pointsPerSegment;
			if (data)
				pointData = data;
		}
		
		public var pointData(null, set) : Void;
		
		public function set_pointData(data:Array<Vector3D>) : Void
		{
			if (data.length < _pointsPerSegment)
				throw new Error("Path Array<Vector3D> must contain at least " + _pointsPerSegment + " Vector3D's");
			
			if (data.length%_pointsPerSegment != 0)
				throw new Error("Path Array<Vector3D> must contain series of " + _pointsPerSegment + " Vector3D's per segment");
			
			_segments = new Array<IPathSegment>();
			// For loop conversion - 			for (var i:UInt = 0, len:Int = data.length; i < len; i += _pointsPerSegment)
			var i:UInt = 0;
			for (i in 0, len:Int = data.length...len)
				_segments.push(createSegmentFromArrayEntry(data, i));
		}
		
		// factory method
		private function createSegmentFromArrayEntry(data:Array<Vector3D>, offset:UInt):IPathSegment
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * The number of segments in the Path
		 */
		public var numSegments(get, null) : UInt;
		public function get_numSegments() : UInt
		{
			return _segments.length;
		}
		
		/**
		 * returns the Vector.&lt;PathSegment&gt; holding the elements (PathSegment) of the path
		 *
		 * @return    a Vector.&lt;PathSegment&gt;: holding the elements (PathSegment) of the path
		 */
		public var segments(get, null) : Array<IPathSegment>;
		public function get_segments() : Array<IPathSegment>
		{
			return _segments;
		}
		
		/**
		 * returns a given PathSegment from the path (PathSegment holds 3 Vector3D's)
		 *
		 * @param     indice uint. the indice of a given PathSegment
		 * @return    given PathSegment from the path
		 */
		public function getSegmentAt(index:UInt):IPathSegment
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
		public function removeSegment(index:UInt, join:Bool = false):Void
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
			for (var i:UInt, len:UInt = _segments.length; i < len; ++i)
				_segments[i].dispose();
			
			_segments = null;
		}
		
		public function getPointOnCurve(t:Float, target:Vector3D = null):Vector3D
		{
			var numSegments:Int = _segments.length;
			t *= numSegments;
			var segment:Int = int(t);
			
			if (segment == numSegments) {
				segment = numSegments - 1;
				t = 1;
			} else
				t -= segment;
			
			return _segments[segment].getPointOnSegment(t, target);
		}
		
		public function getPointsOnCurvePerSegment(subdivision:UInt):Array<Array<Vector3D>>
		{
			var points:Array<Array<Vector3D>> = new Array<Array<Vector3D>>();
			
			// For loop conversion - 						for (var i:UInt = 0, len:UInt = _segments.length; i < len; ++i)
			
			var i:UInt = 0;
			
			for (i in 0, len:UInt = _segments.length...len)
				points[i] = getSegmentPoints(_segments[i], subdivision, (i == len - 1));
			
			return points;
		}
		
		private function getSegmentPoints(segment:IPathSegment, n:UInt, last:Bool):Array<Vector3D>
		{
			var points:Array<Vector3D> = new Array<Vector3D>();
			
			// For loop conversion - 						for (var i:UInt = 0; i < n + ((last)? 1 : 0); ++i)
			
			var i:UInt = 0;
			
			for (i in 0...n + ((last)? 1 : 0))
				points[i] = segment.getPointOnSegment(i/n);
			
			return points;
		}
	}

