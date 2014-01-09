package away3d.core.base.data;

	
	/**
	 * Vertex value object.
	 */
	class Vertex
	{
		var _x:Float;
		var _y:Float;
		var _z:Float;
		var _index:UInt;
		
		/**
		 * Creates a new <code>Vertex</code> value object.
		 *
		 * @param    x            [optional]    The x value. Defaults to 0.
		 * @param    y            [optional]    The y value. Defaults to 0.
		 * @param    z            [optional]    The z value. Defaults to 0.
		 * @param    index        [optional]    The index value. Defaults is NaN.
		 */
		public function new(x:Float = 0, y:Float = 0, z:Float = 0, index:UInt = 0)
		{
			_x = x;
			_y = y;
			_z = z;
			_index = index;
		}
		
		/**
		 * To define/store the index of value object
		 * @param    ind        The index
		 */
		public function set_index(ind:UInt) : Void
		{
			_index = ind;
		}
		
		public var index(get, set) : Void;
		
		public function get_index() : Void
		{
			return _index;
		}
		
		/**
		 * To define/store the x value of the value object
		 * @param    value        The x value
		 */
		public var x(get, set) : Float;
		public function get_x() : Float
		{
			return _x;
		}
		
		public function set_x(value:Float) : Float
		{
			_x = value;
		}
		
		/**
		 * To define/store the y value of the value object
		 * @param    value        The y value
		 */
		public var y(get, set) : Float;
		public function get_y() : Float
		{
			return _y;
		}
		
		public function set_y(value:Float) : Float
		{
			_y = value;
		}
		
		/**
		 * To define/store the z value of the value object
		 * @param    value        The z value
		 */
		public var z(get, set) : Float;
		public function get_z() : Float
		{
			return _z;
		}
		
		public function set_z(value:Float) : Float
		{
			_z = value;
		}
		
		/**
		 * returns a new Vertex value Object
		 */
		public function clone():Vertex
		{
			return new Vertex(_x, _y, _z);
		}
		
		/**
		 * returns the value object as a string for trace/debug purpose
		 */
		public function toString():String
		{
			return _x + "," + _y + "," + _z;
		}
	
	}

