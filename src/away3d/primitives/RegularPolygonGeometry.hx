package away3d.primitives;

	
	/**
	 * A UV RegularPolygon primitive mesh.
	 */
	class RegularPolygonGeometry extends CylinderGeometry
	{
		
		/**
		 * The radius of the regular polygon.
		 */
		public var radius(get, set) : Float;
		public function get_radius() : Float
		{
			return _bottomRadius;
		}
		
		public function set_radius(value:Float) : Float
		{
			_bottomRadius = value;
			invalidateGeometry();
		}
		
		/**
		 * The number of sides of the regular polygon.
		 */
		public var sides(get, set) : UInt;
		public function get_sides() : UInt
		{
			return _segmentsW;
		}
		
		public function set_sides(value:UInt) : UInt
		{
			segmentsW = value;
		}
		
		/**
		 * The number of subdivisions from the edge to the center of the regular polygon.
		 */
		public var subdivisions(get, set) : UInt;
		public function get_subdivisions() : UInt
		{
			return _segmentsH;
		}
		
		public function set_subdivisions(value:UInt) : UInt
		{
			segmentsH = value;
		}
		
		/**
		 * Creates a new RegularPolygon disc object.
		 * @param radius The radius of the regular polygon
		 * @param sides Defines the number of sides of the regular polygon.
		 * @param yUp Defines whether the regular polygon should lay on the Y-axis (true) or on the Z-axis (false).
		 */
		public function new(radius:Float = 100, sides:UInt = 16, yUp:Bool = true)
		{
			super(radius, 0, 0, sides, 1, true, false, false, yUp);
		}
	}

