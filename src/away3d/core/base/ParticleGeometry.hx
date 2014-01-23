/**
 * ...
 */
package away3d.core.base;

import flash.Vector;
import away3d.core.base.data.ParticleData;

class ParticleGeometry extends Geometry {

    public var particles:Vector<ParticleData>;
    public var numParticles:Int;

    public function new() {
        super();
    }

}

