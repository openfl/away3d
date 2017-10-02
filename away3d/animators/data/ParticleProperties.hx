package away3d.animators.data;

/**
 * Dynamic class for holding the local properties of a particle, used for processing the static properties
 * of particles in the particle animation set before beginning upload to the GPU.
 */
class ParticleProperties
{
	/**
	 * The index of the current particle being set.
	 */
	public var index:Int;
	
	/**
	 * The total number of particles being processed by the particle animation set.
	 */
	public var total:Int;
	
	/**
	 * The start time of the particle.
	 */
	public var startTime:Float;
	
	/**
	 * The duration of the particle, an optional value used when the particle aniamtion set settings for <code>useDuration</code> are enabled in the constructor.
	 *
	 * @see away3d.animators.ParticleAnimationSet
	 */
	public var duration:Float;
	
	/**
	 * The delay between cycles of the particle, an optional value used when the particle aniamtion set settings for <code>useLooping</code> and  <code>useDelay</code> are enabled in the constructor.
	 *
	 * @see away3d.animators.ParticleAnimationSet
	 */
	public var delay:Float;
	
	public var nodes:Map<String, Dynamic> = new Map();
	
	public function new()
	{
		
	}
}