/**
 * A particle animation node that controls the rotation of a particle to always face the camera.
 */
package away3d.animators.nodes;

import away3d.materials.compilation.ShaderRegisterElement;
import away3d.animators.data.AnimationRegisterCache;
import away3d.materials.passes.MaterialPassBase;
import away3d.animators.states.ParticleBillboardState;
import away3d.animators.data.ParticlePropertiesMode;
import openfl.geom.Vector3D;

class ParticleBillboardNode extends ParticleNodeBase {

    /** @private */
    static public var MATRIX_INDEX:Int = 0;

    /** @private */
    public var _billboardAxis:Vector3D;

    /**
	 * Creates a new <code>ParticleBillboardNode</code>
	 */
    public function new(billboardAxis:Vector3D = null) {
        super("ParticleBillboard", ParticlePropertiesMode.GLOBAL, 0, 4);
        _stateClass = ParticleBillboardState;
        _billboardAxis = billboardAxis;
    }

    /**
	 * @inheritDoc
	 */
    override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String {

        var rotationMatrixRegister:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
        animationRegisterCache.setRegisterIndex(this, MATRIX_INDEX, rotationMatrixRegister.index);
        animationRegisterCache.getFreeVertexConstant();
        animationRegisterCache.getFreeVertexConstant();
        animationRegisterCache.getFreeVertexConstant();

        var temp = animationRegisterCache.getFreeVertexVectorTemp();

        var code:String = "m33 " + temp + ".xyz," + animationRegisterCache.scaleAndRotateTarget + "," + rotationMatrixRegister + "\n" + "mov " + animationRegisterCache.scaleAndRotateTarget + ".xyz," + temp + ".xyz\n";
        var shaderRegisterElement;
        for (i in 0...animationRegisterCache.rotationRegisters.length) {
            shaderRegisterElement = animationRegisterCache.rotationRegisters[i];
            code += "m33 " + temp + ".xyz," + shaderRegisterElement + "," + rotationMatrixRegister + "\n" + "mov " + shaderRegisterElement + ".xyz," + shaderRegisterElement + "\n";
        }
                
        return code;
    }

    /**
	 * @inheritDoc
	 */
    public function getAnimationState(animator:IAnimator):ParticleBillboardState {
        return cast(animator.getAnimationState(this), ParticleBillboardState) ;
    }

    /**
	 * @inheritDoc
	 */
    override public function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):Void {
        particleAnimationSet.hasBillboard = true;
    }
}

