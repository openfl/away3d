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
 * A particle animation node used to set the starting position of a particle.
 */
class ParticlePositionNode extends ParticleNodeBase
{
	/** @private */
	@:allow(away3d) private static inline var POSITION_INDEX:Int = 0;
	
	/** @private */
	@:allow(away3d) private var _position:Vector3D;
	
	/**
	 * Reference for position node properties on a single particle (when in local property mode).
	 * Expects a <code>Vector3D</code> object representing position of the particle.
	 */
	public static inline var POSITION_VECTOR3D:String = "PositionVector3D";
	
	/**
	 * Creates a new <code>ParticlePositionNode</code>
	 *
	 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
	 * @param    [optional] position        Defines the default position of the particle when in global mode. Defaults to 0,0,0.
	 */
	public function new(mode:Int, position:Vector3D = null)
	{
		super("ParticlePosition", mode, 3);
		
		_stateConstructor = cast ParticlePositionState.new;

		_position = position;
		if (_position == null)
			_position = new Vector3D();
	}
	
	/**
	 * @inheritDoc
	 */
	override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		var positionAttribute:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL)? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
		animationRegisterCache.setRegisterIndex(this, POSITION_INDEX, positionAttribute.index);
		
		return "add " + animationRegisterCache.positionTarget + ".xyz," + positionAttribute + ".xyz," + animationRegisterCache.positionTarget + ".xyz\n";
	}
	
	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):ParticlePositionState
	{
		return cast(animator.getAnimationState(this), ParticlePositionState);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function generatePropertyOfOneParticle(param:ParticleProperties):Void
	{
		var offset:Vector3D = param.nodes[POSITION_VECTOR3D];
		if (offset == null)
			throw(new Error("there is no " + POSITION_VECTOR3D + " in param!"));
		
		_oneData[0] = offset.x;
		_oneData[1] = offset.y;
		_oneData[2] = offset.z;
	}
}