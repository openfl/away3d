package away3d.animators.data;

	import flash.geom.ColorTransform;
	
	class ColorSegmentPoint
	{
		var _color:ColorTransform;
		var _life:Float;
		
		public function new(life:Float, color:ColorTransform)
		{
			//0<life<1
			if (life <= 0 || life >= 1)
				throw(new Error("life exceeds range (0,1)"));
			_life = life;
			_color = color;
		}
		
		public var color(get, null) : ColorTransform;
		
		public function get_color() : ColorTransform
		{
			return _color;
		}
		
		public var life(get, null) : Float;
		
		public function get_life() : Float
		{
			return _life;
		}
	
	}


