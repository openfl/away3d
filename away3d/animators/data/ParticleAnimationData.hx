package away3d.animators.data;

	import away3d.core.base.data.ParticleData;
	
	/**
	 * ...
	 */
	class ParticleAnimationData
	{
		public var index:UInt;
		public var startTime:Float;
		public var totalTime:Float;
		public var duration:Float;
		public var delay:Float;
		public var startVertexIndex:UInt;
		public var numVertices:UInt;
		
		public function new(index:UInt, startTime:Float, duration:Float, delay:Float, particle:ParticleData)
		{
			this.index = index;
			this.startTime = startTime;
			this.totalTime = duration + delay;
			this.duration = duration;
			this.delay = delay;
			this.startVertexIndex = particle.startVertexIndex;
			this.numVertices = particle.numVertices;
		}
	}


