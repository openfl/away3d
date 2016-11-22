package away3d.core.base;

import away3d.core.base.data.ParticleData;

import openfl.Vector;

/**
 * ...
 */
class ParticleGeometry extends Geometry
{
	public var particles:Vector<ParticleData>;
	
	public var numParticles:Int;
	
	public function new()
	{
		super();
	}
	
}