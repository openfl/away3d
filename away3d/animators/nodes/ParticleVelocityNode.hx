package away3d.animators.nodes;

import away3d.*;
import away3d.animators.*;
import away3d.animators.data.*;
import away3d.animators.states.*;
import away3d.materials.compilation.*;
import away3d.materials.passes.*;

import openfl.errors.Error;
import openfl.geom.*;

/**
 * A particle animation node used to set the starting velocity of a particle.
 */
class ParticleVelocityNode extends ParticleNodeBase
{
	/** @private */
	@:allow(away3d) private static inline var VELOCITY_INDEX:Int = 0;
	
	/** @private */
	@:allow(away3d) private var _velocity:Vector3D;
	
	/**
	 * Reference for velocity node properties on a single particle (when in local property mode).
	 * Expects a <code>Vector3D</code> object representing the direction of movement on the particle.
	 */
	public static inline var VELOCITY_VECTOR3D:String = "VelocityVector3D";
	
	/**
	 * Creates a new <code>ParticleVelocityNode</code>
	 *
	 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
	 * @param    [optional] velocity        Defines the default velocity vector of the node, used when in global mode.
	 */
	public function new(mode:Int, velocity:Vector3D = null)
	{
		super("ParticleVelocity", mode, 3);
		
		_stateConstructor = cast ParticleVelocityState.new;
		
		_velocity = velocity;
		if (_velocity == null)
			_velocity = new Vector3D();
	}
	
	/**
	 * @inheritDoc
	 */
	override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		var velocityValue:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL)? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
		animationRegisterCache.setRegisterIndex(this, VELOCITY_INDEX, velocityValue.index);
		
		var distance:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
		var code:String = "";
		code += "mul " + distance + "," + animationRegisterCache.vertexTime + "," + velocityValue + "\n";
		code += "add " + animationRegisterCache.positionTarget + ".xyz," + distance + "," + animationRegisterCache.positionTarget + ".xyz\n";
		
		if (animationRegisterCache.needVelocity)
			code += "add " + animationRegisterCache.velocityTarget + ".xyz," + velocityValue + ".xyz," + animationRegisterCache.velocityTarget + ".xyz\n";
		
		return code;
	}
	
	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):ParticleVelocityState
	{
		return cast(animator.getAnimationState(this), ParticleVelocityState);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function generatePropertyOfOneParticle(param:ParticleProperties):Void
	{
		var _tempVelocity:Vector3D = param.nodes[VELOCITY_VECTOR3D];
		if (_tempVelocity == null)
			throw new Error("there is no " + VELOCITY_VECTOR3D + " in param!");
		
		_oneData[0] = _tempVelocity.x;
		_oneData[1] = _tempVelocity.y;
		_oneData[2] = _tempVelocity.z;
	}
}