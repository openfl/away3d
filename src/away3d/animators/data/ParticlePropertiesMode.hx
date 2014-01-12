package away3d.animators.data;

	
	/**
	 * Options for setting the properties mode of a particle animation node.
	 */
	class ParticlePropertiesMode
	{
		/**
		 * Mode that defines the particle node as acting on global properties (ie. the properties set in the node constructor or the corresponding animation state).
		 */
		public static var GLOBAL:UInt = 0;
		
		/**
		 * Mode that defines the particle node as acting on local static properties (ie. the properties of particles set in the initialising function on the animation set).
		 */
		public static var LOCAL_STATIC:UInt = 1;
		
		/**
		 * Mode that defines the particle node as acting on local dynamic properties (ie. the properties of the particles set in the corresponding animation state).
		 */
		public static var LOCAL_DYNAMIC:UInt = 2;
	}

