package away3d.primitives;

	//import away3d.arcane;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.entities.SegmentSet;
	import away3d.errors.AbstractMethodError;
	import away3d.primitives.data.Segment;
	
	import flash.geom.Vector3D;
	
	//use namespace arcane;
	
	class WireframePrimitiveBase extends SegmentSet
	{
		var _geomDirty:Bool = true;
		var _color:UInt;
		var _thickness:Float;
		
		public function new(color:UInt = 0xffffff, thickness:Float = 1)
		{
			super();
			if (thickness <= 0)
				thickness = 1;
			_color = color;
			_thickness = thickness;
			mouseEnabled = mouseChildren = false;
		}
		
		public var color(get, set) : UInt;
		
		public function get_color() : UInt
		{
			return _color;
		}
		
		public function set_color(value:UInt) : UInt
		{
			_color = value;
			
			Lambda.foreach(_segments, function(segRef:SegRef):Bool {
				segRef.segment.startColor = segRef.segment.endColor = value;
				return true;
			});
			return _color;
		}
		
		public var thickness(get, set) : Float;
		
		public function get_thickness() : Float
		{
			return _thickness;
		}
		
		public function set_thickness(value:Float) : Float
		{
			_thickness = value;
			
			Lambda.foreach(_segments, function(segRef:SegRef):Bool {
				segRef.segment.thickness = segRef.segment.thickness = value;
				return true;
			});
			return _thickness;
		}
		
		override public function removeAllSegments():Void
		{
			super.removeAllSegments();
		}
		
		override public function get_bounds() : BoundingVolumeBase
		{
			if (_geomDirty)
				updateGeometry();
			return super.bounds;
		}
		
		private function buildGeometry():Void
		{
			throw new AbstractMethodError();
		}
		
		private function invalidateGeometry():Void
		{
			_geomDirty = true;
			invalidateBounds();
		}
		
		private function updateGeometry():Void
		{
			buildGeometry();
			_geomDirty = false;
		}
		
		private function updateOrAddSegment(index:UInt, v0:Vector3D, v1:Vector3D):Void
		{
			var segment:Segment;
			var s:Vector3D, e:Vector3D;

			if ((segment = getSegment(index)) != null) {
				s = segment.start;
				e = segment.end;
				s.x = v0.x;
				s.y = v0.y;
				s.z = v0.z;
				e.x = v1.x;
				e.y = v1.y;
				e.z = v1.z;
				segment.updateSegment(s, e, null, _color, _color, _thickness);
			} else
				addSegment(new LineSegment(v0.clone(), v1.clone(), _color, _color, _thickness));
		}
		
		override private function updateMouseChildren():Void
		{
			_ancestorsAllowMouseEnabled = false;
		}
	}

