package away3d.primitives.data;

	//import away3d.arcane;
	import away3d.entities.SegmentSet;
	
	import flash.geom.Vector3D;
	
	//use namespace arcane;
	
	class Segment
	{
		/*arcane*/ public var _segmentsBase:SegmentSet;
		/*arcane*/ public var _thickness:Float;
		/*arcane*/ public var _start:Vector3D;
		/*arcane*/ public var _end:Vector3D;
		/*arcane*/ public var _startR:Float;
		/*arcane*/ public var _startG:Float;
		/*arcane*/ public var _startB:Float;
		/*arcane*/ public var _endR:Float;
		/*arcane*/ public var _endG:Float;
		/*arcane*/ public var _endB:Float;
		
		var _index:Int = -1;
		var _subSetIndex:Int = -1;
		var _startColor:UInt;
		var _endColor:UInt;
		
		public function new(start:Vector3D, end:Vector3D, anchor:Vector3D, colorStart:UInt = 0x333333, colorEnd:UInt = 0x333333, thickness:Float = 1):Void
		{
			// TODO: not yet used: for CurveSegment support
			anchor = null;
			
			_thickness = thickness*.5;
			// TODO: add support for curve using anchor v1
			// Prefer removing v1 from this, and make Curve a separate class extending Segment? (- David)
			_start = start;
			_end = end;
			startColor = colorStart;
			endColor = colorEnd;
		}
		
		public function updateSegment(start:Vector3D, end:Vector3D, anchor:Vector3D, colorStart:UInt = 0x333333, colorEnd:UInt = 0x333333, thickness:Float = 1):Void
		{
			// TODO: not yet used: for CurveSegment support
			anchor = null;
			_start = start;
			_end = end;
			
			if (_startColor != colorStart)
				startColor = colorStart;
			
			if (_endColor != colorEnd)
				endColor = colorEnd;
			
			_thickness = thickness*.5;
			update();
		}
		
		/**
		 * Defines the starting vertex.
		 */
		public var start(get, set) : Vector3D;
		public function get_start() : Vector3D
		{
			return _start;
		}
		
		public function set_start(value:Vector3D) : Vector3D
		{
			_start = value;
			update();
			return value;
		}
		
		/**
		 * Defines the ending vertex.
		 */
		public var end(get, set) : Vector3D;
		public function get_end() : Vector3D
		{
			return _end;
		}
		
		public function set_end(value:Vector3D) : Vector3D
		{
			_end = value;
			update();
			return value;
		}
		
		/**
		 * Defines the ending vertex.
		 */
		public var thickness(get, set) : Float;
		public function get_thickness() : Float
		{
			return _thickness*2;
		}
		
		public function set_thickness(value:Float) : Float
		{
			_thickness = value*.5;
			update();
			return value;
		}
		
		/**
		 * Defines the startColor
		 */
		public var startColor(get, set) : UInt;
		public function get_startColor() : UInt
		{
			return _startColor;
		}
		
		public function set_startColor(color:UInt) : UInt
		{
			_startR = ( ( color >> 16 ) & 0xff )/255;
			_startG = ( ( color >> 8 ) & 0xff )/255;
			_startB = ( color & 0xff )/255;
			
			_startColor = color;
			
			update();
			return _startColor;
		}
		
		/**
		 * Defines the endColor
		 */
		public var endColor(get, set) : UInt;
		public function get_endColor() : UInt
		{
			return _endColor;
		}
		
		public function set_endColor(color:UInt) : UInt
		{
			_endR = ( ( color >> 16 ) & 0xff )/255;
			_endG = ( ( color >> 8 ) & 0xff )/255;
			_endB = ( color & 0xff )/255;
			
			_endColor = color;
			
			update();
			return _endColor;
		}
		
		public function dispose():Void
		{
			_start = null;
			_end = null;
		}
		
		public var index(get, set) : Int;
		
		public function get_index() : Int
		{
			return _index;
		}
		
		public function set_index(ind:Int) : Int
		{
			_index = ind;
			return _index;
		}
		
		public var subSetIndex(get, set) : Int;
		
		public function get_subSetIndex() : Int
		{
			return _subSetIndex;
		}
		
		public function set_subSetIndex(ind:Int) : Int
		{
			_subSetIndex = ind;
			return _subSetIndex;
		}
		
		public var segmentsBase(default, set) : SegmentSet;
		
		public function set_segmentsBase(segBase:SegmentSet) : SegmentSet
		{
			_segmentsBase = segBase;
			return _segmentsBase;
		}
		
		private function update():Void
		{
			if (_segmentsBase==null)
				return;
			_segmentsBase.updateSegment(this);
		}
	
	}

