package away3d.animators.nodes;

import away3d.*;
import away3d.animators.*;
import away3d.animators.data.*;
import away3d.animators.states.*;
import away3d.materials.compilation.*;
import away3d.materials.passes.*;

/**
 * A particle animation node used as the base node for timekeeping inside a particle. Automatically added to a particle animation set on instatiation.
 */
class ParticleTimeNode extends ParticleNodeBase
{
	/** @private */
	@:allow(away3d) private static inline var TIME_STREAM_INDEX:Int = 0;
	
	/** @private */
	@:allow(away3d) private static inline var TIME_CONSTANT_INDEX:Int = 1;
	
	/** @private */
	@:allow(away3d) private var _usesDuration:Bool;
	/** @private */
	@:allow(away3d) private var _usesDelay:Bool;
	/** @private */
	@:allow(away3d) private var _usesLooping:Bool;
	
	/**
	 * Creates a new <code>ParticleTimeNode</code>
	 *
	 * @param    [optional] usesDuration    Defines whether the node uses the <code>duration</code> data in the static properties function to determine how long a particle is visible for. Defaults to false.
	 * @param    [optional] usesDelay       Defines whether the node uses the <code>delay</code> data in the static properties function to determine how long a particle is hidden for. Defaults to false. Requires <code>usesDuration</code> to be true.
	 * @param    [optional] usesLooping     Defines whether the node creates a looping timeframe for each particle determined by the <code>startTime</code>, <code>duration</code> and <code>delay</code> data in the static properties function. Defaults to false. Requires <code>usesLooping</code> to be true.
	 */
	public function new(usesDuration:Bool = false, usesLooping:Bool = false, usesDelay:Bool = false)
	{
		_stateConstructor = cast ParticleTimeState.new;
		
		_usesDuration = usesDuration;
		_usesLooping = usesLooping;
		_usesDelay = usesDelay;
		
		super("ParticleTime", ParticlePropertiesMode.LOCAL_STATIC, 4, 0);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		var timeStreamRegister:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute(); //timeStreamRegister.x is start，timeStreamRegister.y is during time
		animationRegisterCache.setRegisterIndex(this, TIME_STREAM_INDEX, timeStreamRegister.index);
		var timeConst:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
		animationRegisterCache.setRegisterIndex(this, TIME_CONSTANT_INDEX, timeConst.index);
		
		var code:String = "";
		code += "sub " + animationRegisterCache.vertexTime + "," + timeConst + "," + timeStreamRegister + ".x\n";
		//if time=0,set the position to zero.
		var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexSingleTemp();
		code += "sge " + temp + "," + animationRegisterCache.vertexTime + "," + animationRegisterCache.vertexZeroConst + "\n";
		code += "mul " + animationRegisterCache.scaleAndRotateTarget + ".xyz," + animationRegisterCache.scaleAndRotateTarget + ".xyz," + temp + "\n";
		if (_usesDuration) {
			if (_usesLooping) {
				var div:ShaderRegisterElement = animationRegisterCache.getFreeVertexSingleTemp();
				if (_usesDelay) {
					code += "div " + div + "," + animationRegisterCache.vertexTime + "," + timeStreamRegister + ".z\n";
					code += "frc " + div + "," + div + "\n";
					code += "mul " + animationRegisterCache.vertexTime + "," + div + "," + timeStreamRegister + ".z\n";
					code += "slt " + div + "," + animationRegisterCache.vertexTime + "," + timeStreamRegister + ".y\n";
					code += "mul " + animationRegisterCache.scaleAndRotateTarget + ".xyz," + animationRegisterCache.scaleAndRotateTarget + ".xyz," + div + "\n";
				} else {
					code += "mul " + div + "," + animationRegisterCache.vertexTime + "," + timeStreamRegister + ".w\n";
					code += "frc " + div + "," + div + "\n";
					code += "mul " + animationRegisterCache.vertexTime + "," + div + "," + timeStreamRegister + ".y\n";
				}
			} else {
				var sge:ShaderRegisterElement = animationRegisterCache.getFreeVertexSingleTemp();
				code += "sge " + sge + "," + timeStreamRegister + ".y," + animationRegisterCache.vertexTime + "\n";
				code += "mul " + animationRegisterCache.scaleAndRotateTarget + ".xyz," + animationRegisterCache.scaleAndRotateTarget + ".xyz," + sge + "\n";
			}
		}
		code += "mul " + animationRegisterCache.vertexLife + "," + animationRegisterCache.vertexTime + "," + timeStreamRegister + ".w\n";
		return code;
	}
	
	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):ParticleTimeState
	{
		return cast(animator.getAnimationState(this), ParticleTimeState);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function generatePropertyOfOneParticle(param:ParticleProperties):Void
	{
		_oneData[0] = param.startTime;
		_oneData[1] = param.duration;
		_oneData[2] = param.delay + param.duration;
		_oneData[3] = 1/param.duration;
		
	}
}