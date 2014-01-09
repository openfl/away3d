package away3d.materials.utils;

	import away3d.materials.MaterialBase;
	
	class MultipleMaterials
	{
		var _left:MaterialBase;
		var _right:MaterialBase;
		var _bottom:MaterialBase;
		var _top:MaterialBase;
		var _front:MaterialBase;
		var _back:MaterialBase;
		
		/**
		 * Creates a new <code>MultipleMaterials</code> object.
		 * Class can hold up to 6 materials. Class is designed to work as typed object for materials setters in a multitude of classes such as Cube, LatheExtrude (with thickness) etc...
		 *
		 * @param    front:MaterialBase        [optional] The front material.
		 * @param    back:MaterialBase        [optional] The back material.
		 * @param    left:MaterialBase        [optional] The left material.
		 * @param    right:MaterialBase        [optional] The right material.
		 * @param    top:MaterialBase        [optional] The top material.
		 * @param    down:MaterialBase        [optional] The down material.
		 */
		
		public function new(front:MaterialBase = null, back:MaterialBase = null, left:MaterialBase = null, right:MaterialBase = null, top:MaterialBase = null)
		{
			_left = left;
			_right = right;
			_bottom = bottom;
			_top = top;
			_front = front;
			_back = back;
		}
		
		/**
		 * Defines the material applied to the left side of the cube.
		 */
		public var left(get, set) : MaterialBase;
		public function get_left() : MaterialBase
		{
			return _left;
		}
		
		public function set_left(val:MaterialBase) : MaterialBase
		{
			if (_left == val)
				return;
			
			_left = val;
		}
		
		/**
		 * Defines the material applied to the right side of the cube.
		 */
		public var right(get, set) : MaterialBase;
		public function get_right() : MaterialBase
		{
			return _right;
		}
		
		public function set_right(val:MaterialBase) : MaterialBase
		{
			if (_right == val)
				return;
			
			_right = val;
		}
		
		/**
		 * Defines the material applied to the bottom side of the cube.
		 */
		public var bottom(get, set) : MaterialBase;
		public function get_bottom() : MaterialBase
		{
			return _bottom;
		}
		
		public function set_bottom(val:MaterialBase) : MaterialBase
		{
			if (_bottom == val)
				return;
			
			_bottom = val;
		}
		
		/**
		 * Defines the material applied to the top side of the cube.
		 */
		public var top(get, set) : MaterialBase;
		public function get_top() : MaterialBase
		{
			return _top;
		}
		
		public function set_top(val:MaterialBase) : MaterialBase
		{
			if (_top == val)
				return;
			
			_top = val;
		}
		
		/**
		 * Defines the material applied to the front side of the cube.
		 */
		public var front(get, set) : MaterialBase;
		public function get_front() : MaterialBase
		{
			return _front;
		}
		
		public function set_front(val:MaterialBase) : MaterialBase
		{
			if (_front == val)
				return;
			
			_front = val;
		}
		
		/**
		 * Defines the material applied to the back side of the cube.
		 */
		public var back(get, set) : MaterialBase;
		public function get_back() : MaterialBase
		{
			return _back;
		}
		
		public function set_back(val:MaterialBase) : MaterialBase
		{
			if (_back == val)
				return;
			
			_back = val;
		}
	
	}

