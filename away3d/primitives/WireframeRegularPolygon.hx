package away3d.primitives;

	import flash.geom.Vector3D;
	
	/**
	 * A WireframeRegularPolygon primitive mesh.
	 */
	class WireframeRegularPolygon extends WireframePrimitiveBase
	{
		public static var ORIENTATION_YZ:String = "yz";
		public static var ORIENTATION_XY:String = "xy";
		public static var ORIENTATION_XZ:String = "xz";
		
		var _radius:Float;
		var _sides:Int;
		var _orientation:String;
		
		/**
		 * Creates a new WireframeRegularPolygon object.
		 * @param radius The radius of the polygon.
		 * @param sides The number of sides on the polygon.
		 * @param color The colour of the wireframe lines
		 * @param thickness The thickness of the wireframe lines
		 * @param orientation The orientaion in which the plane lies.
		 */
		public function new(radius:Float, sides:Int, color:UInt = 0xFFFFFF, thickness:Float = 1, orientation:String = "yz")
		{
			super(color, thickness);
			
			_radius = radius;
			_sides = sides;
			_orientation = orientation;
		}
		
		/**
		 * The orientaion in which the polygon lies.
		 */
		public var orientation(get, set) : String;
		public function get_orientation() : String
		{
			return _orientation;
		}
		
		public function set_orientation(value:String) : String
		{
			_orientation = value;
			invalidateGeometry();
		}
		
		/**
		 * The radius of the regular polygon.
		 */
		public var radius(get, set) : Float;
		public function get_radius() : Float
		{
			return _radius;
		}
		
		public function set_radius(value:Float) : Float
		{
			_radius = value;
			invalidateGeometry();
		}
		
		/**
		 * The number of sides to the regular polygon.
		 */
		public var sides(get, set) : Int;
		public function get_sides() : Int
		{
			return _sides;
		}
		
		public function set_sides(value:Int) : Int
		{
			_sides = value;
			removeAllSegments();
			invalidateGeometry();
		}
		
		/**
		 * @inheritDoc
		 */
		override private function buildGeometry():Void
		{
			var v0:Vector3D = new Vector3D();
			var v1:Vector3D = new Vector3D();
			var index:Int;
			var s:Int;
			
			if (_orientation == ORIENTATION_XY) {
				v0.z = 0;
				v1.z = 0;
				
				// For loop conversion - 								for (s = 0; s < _sides; ++s)
				
				for (s in 0..._sides) {
					v0.x = _radius*Math.cos(2*Math.PI*s/_sides);
					v0.y = _radius*Math.sin(2*Math.PI*s/_sides);
					v1.x = _radius*Math.cos(2*Math.PI*(s + 1)/_sides);
					v1.y = _radius*Math.sin(2*Math.PI*(s + 1)/_sides);
					updateOrAddSegment(index++, v0, v1);
				}
			}
			
			else if (_orientation == ORIENTATION_XZ) {
				v0.y = 0;
				v1.y = 0;
				
				// For loop conversion - 								for (s = 0; s < _sides; ++s)
				
				for (s in 0..._sides) {
					v0.x = _radius*Math.cos(2*Math.PI*s/_sides);
					v0.z = _radius*Math.sin(2*Math.PI*s/_sides);
					v1.x = _radius*Math.cos(2*Math.PI*(s + 1)/_sides);
					v1.z = _radius*Math.sin(2*Math.PI*(s + 1)/_sides);
					updateOrAddSegment(index++, v0, v1);
				}
			}
			
			else if (_orientation == ORIENTATION_YZ) {
				v0.x = 0;
				v1.x = 0;
				
				// For loop conversion - 								for (s = 0; s < _sides; ++s)
				
				for (s in 0..._sides) {
					v0.z = _radius*Math.cos(2*Math.PI*s/_sides);
					v0.y = _radius*Math.sin(2*Math.PI*s/_sides);
					v1.z = _radius*Math.cos(2*Math.PI*(s + 1)/_sides);
					v1.y = _radius*Math.sin(2*Math.PI*(s + 1)/_sides);
					updateOrAddSegment(index++, v0, v1);
				}
			}
		}
	
	}

