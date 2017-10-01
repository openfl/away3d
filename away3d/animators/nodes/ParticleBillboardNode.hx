package away3d.animators.nodes;

import away3d.*;
import away3d.animators.*;
import away3d.animators.data.*;
import away3d.animators.states.*;
import away3d.materials.compilation.*;
import away3d.materials.passes.*;

import openfl.geom.Vector3D;

/**
 * A particle animation node that controls the rotation of a particle to always face the camera.
 */
class ParticleBillboardNode extends ParticleNodeBase
{
	/** @private */
	@:allow(away3d) private static inline var MATRIX_INDEX:Int = 0;
	
	/** @private */
	@:allow(away3d) private var _billboardAxis:Vector3D;
	
	/**
	 * Creates a new <code>ParticleBillboardNode</code>
	 */
	public function new(billboardAxis:Vector3D = null)
	{
		super("ParticleBillboard", ParticlePropertiesMode.GLOBAL, 0, 4);
		
		_stateConstructor = cast ParticleBillboardState.new;
		
		_billboardAxis = billboardAxis;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		var rotationMatrixRegister:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
		animationRegisterCache.setRegisterIndex(this, MATRIX_INDEX, rotationMatrixRegister.index);
		animationRegisterCache.getFreeVertexConstant();
		animationRegisterCache.getFreeVertexConstant();
		animationRegisterCache.getFreeVertexConstant();
		
		var code:String = "m33 " + animationRegisterCache.scaleAndRotateTarget + ".xyz," + animationRegisterCache.scaleAndRotateTarget + ".xyz," + rotationMatrixRegister + "\n";
		
		var shaderRegisterElement:ShaderRegisterElement;
		for (shaderRegisterElement in animationRegisterCache.rotationRegisters)
			code += "m33 " + shaderRegisterElement.regName + shaderRegisterElement.index + ".xyz," + shaderRegisterElement + "," + rotationMatrixRegister + "\n";
		
		return code;
	}
	
	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):ParticleBillboardState
	{
		return cast(animator.getAnimationState(this), ParticleBillboardState);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):Void{
		
		particleAnimationSet.hasBillboard = true;
	}
}