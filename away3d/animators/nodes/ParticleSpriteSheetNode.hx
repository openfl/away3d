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
 * A particle animation node used when a spritesheet texture is required to animate the particle.
 * NB: to enable use of this node, the <code>repeat</code> property on the material has to be set to true.
 */
class ParticleSpriteSheetNode extends ParticleNodeBase
{
	public var numColumns(get, never):Float;
	public var numRows(get, never):Float;
	public var totalFrames(get, never):Float;
	
	/** @private */
	@:allow(away3d) private static inline var UV_INDEX_0:Int = 0;
	
	/** @private */
	@:allow(away3d) private static inline var UV_INDEX_1:Int = 1;
	
	/** @private */
	@:allow(away3d) private var _usesCycle:Bool;
	
	/** @private */
	@:allow(away3d) private var _usesPhase:Bool;
	
	/** @private */
	@:allow(away3d) private var _totalFrames:Int;
	
	/** @private */
	@:allow(away3d) private var _numColumns:Int;
	
	/** @private */
	@:allow(away3d) private var _numRows:Int;
	
	/** @private */
	@:allow(away3d) private var _cycleDuration:Float;
	
	/** @private */
	@:allow(away3d) private var _cyclePhase:Float;
	
	/**
	 * Reference for spritesheet node properties on a single particle (when in local property mode).
	 * Expects a <code>Vector3D</code> representing the cycleDuration (x), optional phaseTime (y).
	 */
	public static inline var UV_VECTOR3D:String = "UVVector3D";
	
	/**
	 * Defines the number of columns in the spritesheet, when in global mode. Defaults to 1. Read only.
	 */
	private function get_numColumns():Float
	{
		return _numColumns;
	}
	
	/**
	 * Defines the number of rows in the spritesheet, when in global mode. Defaults to 1. Read only.
	 */
	private function get_numRows():Float
	{
		return _numRows;
	}
	
	/**
	 * Defines the total number of frames used by the spritesheet, when in global mode. Defaults to the number defined by numColumns and numRows. Read only.
	 */
	private function get_totalFrames():Float
	{
		return _totalFrames;
	}
	
	/**
	 * Creates a new <code>ParticleSpriteSheetNode</code>
	 *
	 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
	 * @param    [optional] numColumns      Defines the number of columns in the spritesheet, when in global mode. Defaults to 1.
	 * @param    [optional] numRows         Defines the number of rows in the spritesheet, when in global mode. Defaults to 1.
	 * @param    [optional] cycleDuration   Defines the default cycle duration in seconds, when in global mode. Defaults to 1.
	 * @param    [optional] cyclePhase      Defines the default cycle phase, when in global mode. Defaults to 0.
	 * @param    [optional] totalFrames     Defines the total number of frames used by the spritesheet, when in global mode. Defaults to the number defined by numColumns and numRows.
	 * @param    [optional] looping         Defines whether the spritesheet animation is set to loop indefinitely. Defaults to true.
	 */
	public function new(mode:Int, usesCycle:Bool, usesPhase:Bool, numColumns:Int = 1, numRows:Int = 1, cycleDuration:Float = 1, cyclePhase:Float = 0, totalFrames:Int = -1)
	{
		//todo totalFrames = Math.POSITIVE_INFINITY;
		
		var len:Int = 0;
		
		if (usesCycle) {
			len = 2;
			if (usesPhase)
				len++;
		}
		super("ParticleSpriteSheet", mode, len, ParticleAnimationSet.POST_PRIORITY + 1);
		
		_stateConstructor = cast ParticleSpriteSheetState.new;
		
		_usesCycle = usesCycle;
		_usesPhase = usesPhase;
		
		_numColumns = numColumns;
		_numRows = numRows;
		_cyclePhase = cyclePhase;
		_cycleDuration = cycleDuration;
		_totalFrames = Std.int(Math.min(totalFrames, numColumns*numRows));
	}
	
	/**
	 * @inheritDoc
	 */
	override public function getAGALUVCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		//get 2 vc
		var uvParamConst1:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
		var uvParamConst2:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL)? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
		animationRegisterCache.setRegisterIndex(this, UV_INDEX_0, uvParamConst1.index);
		animationRegisterCache.setRegisterIndex(this, UV_INDEX_1, uvParamConst2.index);
		
		var uTotal:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, 0);
		var uStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, 1);
		var vStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, 2);
		
		var uSpeed:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, 0);
		var cycle:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, 1);
		var phaseTime:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, 2);
		
		var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
		var time:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 0);
		var vOffset:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 1);
		temp = new ShaderRegisterElement(temp.regName, temp.index, 2);
		var temp2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 3);
		
		var u:ShaderRegisterElement = new ShaderRegisterElement(animationRegisterCache.uvTarget.regName, animationRegisterCache.uvTarget.index, 0);
		var v:ShaderRegisterElement = new ShaderRegisterElement(animationRegisterCache.uvTarget.regName, animationRegisterCache.uvTarget.index, 1);
		
		var code:String = "";
		//scale uv
		code += "mul " + u + "," + u + "," + uStep + "\n";
		if (_numRows > 1)
			code += "mul " + v + "," + v + "," + vStep + "\n";
		
		if (_usesCycle) {
			if (_usesPhase)
				code += "add " + time + "," + animationRegisterCache.vertexTime + "," + phaseTime + "\n";
			else
				code += "mov " + time + "," + animationRegisterCache.vertexTime + "\n";
			code += "div " + time + "," + time + "," + cycle + "\n";
			code += "frc " + time + "," + time + "\n";
			code += "mul " + time + "," + time + "," + cycle + "\n";
			code += "mul " + temp + "," + time + "," + uSpeed + "\n";
		} else
			code += "mul " + temp.toString() + "," + animationRegisterCache.vertexLife + "," + uTotal + "\n";
		
		if (_numRows > 1) {
			code += "frc " + temp2 + "," + temp + "\n";
			code += "sub " + vOffset + "," + temp + "," + temp2 + "\n";
			code += "mul " + vOffset + "," + vOffset + "," + vStep + "\n";
			code += "add " + v + "," + v + "," + vOffset + "\n";
		}
		
		code += "div " + temp2 + "," + temp + "," + uStep + "\n";
		code += "frc " + temp + "," + temp2 + "\n";
		code += "sub " + temp2 + "," + temp2 + "," + temp + "\n";
		code += "mul " + temp + "," + temp2 + "," + uStep + "\n";
		
		if (_numRows > 1)
			code += "frc " + temp + "," + temp + "\n";
		code += "add " + u + "," + u + "," + temp + "\n";
		
		return code;
	}
	
	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):ParticleSpriteSheetState
	{
		return cast(animator.getAnimationState(this), ParticleSpriteSheetState);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):Void
	{
		particleAnimationSet.hasUVNode = true;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function generatePropertyOfOneParticle(param:ParticleProperties):Void
	{
		if (_usesCycle) {
			var uvCycle:Vector3D = param.nodes[UV_VECTOR3D];
			if (uvCycle == null)
				throw(new Error("there is no " + UV_VECTOR3D + " in param!"));
			if (uvCycle.x <= 0)
				throw(new Error("the cycle duration must be greater than zero"));
			var uTotal:Float = _totalFrames/_numColumns;
			_oneData[0] = uTotal/uvCycle.x;
			_oneData[1] = uvCycle.x;
			if (_usesPhase)
				_oneData[2] = uvCycle.y;
		}
	}
}