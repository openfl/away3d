package away3d.tools.helpers;

import away3d.core.base.ParticleGeometry;
import away3d.core.base.Geometry;
import away3d.tools.helpers.data.ParticleGeometryTransform;
import openfl.Vector;

class ParticleGeometryHelper
{
	public static inline function generateGeometry(geometries:Vector<Geometry>, transforms:Vector<ParticleGeometryTransform> = null):ParticleGeometry
	{
		var buffer:ParticleGeometryBuffer = new ParticleGeometryBuffer();
		
		if (transforms != null)
		{
			for (i in 0...geometries.length)
			{
				buffer.addParticle(geometries[i], transforms[i]);
			}
		}
		else
		{
			for (geometry in geometries)
			{
				buffer.addParticle(geometry);
			}
		}
		
		return buffer.getParticleGeometry();
	}
}
