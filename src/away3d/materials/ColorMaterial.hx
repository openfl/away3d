package away3d.materials;

	//import away3d.arcane;
	
	import flash.display.BlendMode;
	
	//use namespace arcane;
	
	/**
	 * ColorMaterial is a single-pass material that uses a flat color as the surface's diffuse reflection value.
	 */
	class ColorMaterial extends SinglePassMaterialBase
	{
		var _diffuseAlpha:Float = 1;
		
		/**
		 * Creates a new ColorMaterial object.
		 * @param color The material's diffuse surface color.
		 * @param alpha The material's surface alpha.
		 */
		public function new(color:UInt = 0xcccccc, alpha:Float = 1)
		{
			super();
			this.color = color;
			this.alpha = alpha;
		}
		
		/**
		 * The alpha of the surface.
		 */
		public var alpha(get, set) : Float;
		public function get_alpha() : Float
		{
			return _screenPass.diffuseMethod.diffuseAlpha;
		}
		
		public function set_alpha(value:Float) : Float
		{
			if (value > 1)
				value = 1;
			else if (value < 0)
				value = 0;
			_screenPass.diffuseMethod.diffuseAlpha = _diffuseAlpha = value;
			_screenPass.preserveAlpha = requiresBlending;
			_screenPass.setBlendMode(blendMode == BlendMode.NORMAL && requiresBlending? BlendMode.LAYER : blendMode);
			return value;
		}
		
		/**
		 * The diffuse reflectivity color of the surface.
		 */
		public var color(get, set) : UInt;
		public function get_color() : UInt
		{
			return _screenPass.diffuseMethod.diffuseColor;
		}
		
		public function set_color(value:UInt) : UInt
		{
			_screenPass.diffuseMethod.diffuseColor = value;
			return value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get_requiresBlending() : Bool
		{
			return super.requiresBlending || _diffuseAlpha < 1;
		}
	}

