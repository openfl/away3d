package away3d.materials;

	//import away3d.arcane;
	
	//use namespace arcane;
	
	/**
	 * ColorMultiPassMaterial is a multi-pass material that uses a flat color as the surface's diffuse reflection value.
	 */
	class ColorMultiPassMaterial extends MultiPassMaterialBase
	{
		/**
		 * Creates a new ColorMultiPassMaterial object.
		 *
		 * @param color The material's diffuse surface color.
		 */
		public function new(color:UInt = 0xcccccc)
		{
			super();
			this.color = color;
		}
		
		/**
		 * The diffuse reflectivity color of the surface.
		 */
		public var color(get, set) : UInt;
		public function get_color() : UInt
		{
			return diffuseMethod.diffuseColor;
		}
		
		public function set_color(value:UInt) : UInt
		{
			diffuseMethod.diffuseColor = value;
			return value;
		}
	}

