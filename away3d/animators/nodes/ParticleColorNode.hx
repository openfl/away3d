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
 * A particle animation node used to control the color variation of a particle over time.
 */
class ParticleColorNode extends ParticleNodeBase
{
	/** @private */
	@:allow(away3d) private static inline var START_MULTIPLIER_INDEX:Int = 0;
	
	/** @private */
	@:allow(away3d) private static inline var DELTA_MULTIPLIER_INDEX:Int = 1;
	
	/** @private */
	@:allow(away3d) private static inline var START_OFFSET_INDEX:Int = 2;
	
	/** @private */
	@:allow(away3d) private static inline var DELTA_OFFSET_INDEX:Int = 3;
	
	/** @private */
	@:allow(away3d) private static inline var CYCLE_INDEX:Int = 4;
	
	//default values used when creating states
	/** @private */
	@:allow(away3d) private var _usesMultiplier:Bool;
	
	/** @private */
	@:allow(away3d) private var _usesOffset:Bool;
	
	/** @private */
	@:allow(away3d) private var _usesCycle:Bool;
	
	/** @private */
	@:allow(away3d) private var _usesPhase:Bool;
	
	/** @private */
	@:allow(away3d) private var _startColor:ColorTransform;
	
	/** @private */
	@:allow(away3d) private var _endColor:ColorTransform;
	
	/** @private */
	@:allow(away3d) private var _cycleDuration:Float;
	
	/** @private */
	@:allow(away3d) private var _cyclePhase:Float;
	
	/**
	 * Reference for color node properties on a single particle (when in local property mode).
	 * Expects a <code>ColorTransform</code> object representing the start color transform applied to the particle.
	 */
	public static inline var COLOR_START_COLORTRANSFORM:String = "ColorStartColorTransform";
	
	/**
	 * Reference for color node properties on a single particle (when in local property mode).
	 * Expects a <code>ColorTransform</code> object representing the end color transform applied to the particle.
	 */
	public static inline var COLOR_END_COLORTRANSFORM:String = "ColorEndColorTransform";
	
	/**
	 * Creates a new <code>ParticleColorNode</code>
	 *
	 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
	 * @param    [optional] usesMultiplier  Defines whether the node uses multiplier data in the shader for its color transformations. Defaults to true.
	 * @param    [optional] usesOffset      Defines whether the node uses offset data in the shader for its color transformations. Defaults to true.
	 * @param    [optional] usesCycle       Defines whether the node uses the <code>cycleDuration</code> property in the shader to calculate the period of the animation independent of particle duration. Defaults to false.
	 * @param    [optional] usesPhase       Defines whether the node uses the <code>cyclePhase</code> property in the shader to calculate a starting offset to the cycle rotation of the particle. Defaults to false.
	 * @param    [optional] startColor      Defines the default start color transform of the node, when in global mode.
	 * @param    [optional] endColor        Defines the default end color transform of the node, when in global mode.
	 * @param    [optional] cycleDuration   Defines the duration of the animation in seconds, used as a period independent of particle duration when in global mode. Defaults to 1.
	 * @param    [optional] cyclePhase      Defines the phase of the cycle in degrees, used as the starting offset of the cycle when in global mode. Defaults to 0.
	 */
	public function new(mode:Int, usesMultiplier:Bool = true, usesOffset:Bool = true, usesCycle:Bool = false, usesPhase:Bool = false, startColor:ColorTransform = null, endColor:ColorTransform = null, cycleDuration:Float = 1, cyclePhase:Float = 0)
	{
		_stateConstructor = cast ParticleColorState.new;
		
		_usesMultiplier = usesMultiplier;
		_usesOffset = usesOffset;
		_usesCycle = usesCycle;
		_usesPhase = usesPhase;
		
		_startColor = startColor;
		if (_startColor == null)_startColor = new ColorTransform();
		
		_endColor = endColor;
		if (_endColor == null)_endColor = new ColorTransform();
		
		_cycleDuration = cycleDuration;
		_cyclePhase = cyclePhase;
		
		super("ParticleColor", mode, (_usesMultiplier && _usesOffset)? 16 : 8, ParticleAnimationSet.COLOR_PRIORITY);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		var code:String = "";
		if (animationRegisterCache.needFragmentAnimation) {
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var sin:ShaderRegisterElement = null;
			
			if (_usesCycle) {
				var cycleConst:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
				animationRegisterCache.setRegisterIndex(this, CYCLE_INDEX, cycleConst.index);
				
				animationRegisterCache.addVertexTempUsages(temp, 1);
				sin = animationRegisterCache.getFreeVertexSingleTemp();
				animationRegisterCache.removeVertexTempUsage(temp);
				
				code += "mul " + sin + "," + animationRegisterCache.vertexTime + "," + cycleConst + ".x\n";
				
				if (_usesPhase)
					code += "add " + sin + "," + sin + "," + cycleConst + ".y\n";
				
				code += "sin " + sin + "," + sin + "\n";
			}
			
			if (_usesMultiplier) {
				var startMultiplierValue:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL)? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
				var deltaMultiplierValue:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL)? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
				
				animationRegisterCache.setRegisterIndex(this, START_MULTIPLIER_INDEX, startMultiplierValue.index);
				animationRegisterCache.setRegisterIndex(this, DELTA_MULTIPLIER_INDEX, deltaMultiplierValue.index);
				
				code += "mul " + temp + "," + deltaMultiplierValue + "," + (_usesCycle? sin.toString() : animationRegisterCache.vertexLife.toString()) + "\n";
				code += "add " + temp + "," + temp + "," + startMultiplierValue + "\n";
				code += "mul " + animationRegisterCache.colorMulTarget + "," + temp + "," + animationRegisterCache.colorMulTarget + "\n";
			}
			
			if (_usesOffset) {
				var startOffsetValue:ShaderRegisterElement = (_mode == ParticlePropertiesMode.LOCAL_STATIC)? animationRegisterCache.getFreeVertexAttribute() : animationRegisterCache.getFreeVertexConstant();
				var deltaOffsetValue:ShaderRegisterElement = (_mode == ParticlePropertiesMode.LOCAL_STATIC)? animationRegisterCache.getFreeVertexAttribute() : animationRegisterCache.getFreeVertexConstant();
				
				animationRegisterCache.setRegisterIndex(this, START_OFFSET_INDEX, startOffsetValue.index);
				animationRegisterCache.setRegisterIndex(this, DELTA_OFFSET_INDEX, deltaOffsetValue.index);
				
				code += "mul " + temp + "," + deltaOffsetValue + "," + (_usesCycle? sin.toString() : animationRegisterCache.vertexLife.toString()) + "\n";
				code += "add " + temp + "," + temp + "," + startOffsetValue + "\n";
				code += "add " + animationRegisterCache.colorAddTarget + "," + temp + "," + animationRegisterCache.colorAddTarget + "\n";
			}
		}
		
		return code;
	}
	
	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):ParticleColorState
	{
		return cast(animator.getAnimationState(this), ParticleColorState);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):Void
	{
		if (_usesMultiplier)
			particleAnimationSet.hasColorMulNode = true;
		if (_usesOffset)
			particleAnimationSet.hasColorAddNode = true;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function generatePropertyOfOneParticle(param:ParticleProperties):Void
	{
		var startColor:ColorTransform = param.nodes[COLOR_START_COLORTRANSFORM];
		if (startColor == null)
			throw(new Error("there is no " + COLOR_START_COLORTRANSFORM + " in param!"));
		
		var endColor:ColorTransform = param.nodes[COLOR_END_COLORTRANSFORM];
		if (endColor == null)
			throw(new Error("there is no " + COLOR_END_COLORTRANSFORM + " in param!"));
		
		var i:Int = 0;
		
		if (!_usesCycle) {
			//multiplier
			if (_usesMultiplier) {
				_oneData[i++] = startColor.redMultiplier;
				_oneData[i++] = startColor.greenMultiplier;
				_oneData[i++] = startColor.blueMultiplier;
				_oneData[i++] = startColor.alphaMultiplier;
				_oneData[i++] = endColor.redMultiplier - startColor.redMultiplier;
				_oneData[i++] = endColor.greenMultiplier - startColor.greenMultiplier;
				_oneData[i++] = endColor.blueMultiplier - startColor.blueMultiplier;
				_oneData[i++] = endColor.alphaMultiplier - startColor.alphaMultiplier;
			}
			
			//offset
			if (_usesOffset) {
				_oneData[i++] = startColor.redOffset/255;
				_oneData[i++] = startColor.greenOffset/255;
				_oneData[i++] = startColor.blueOffset/255;
				_oneData[i++] = startColor.alphaOffset/255;
				_oneData[i++] = (endColor.redOffset - startColor.redOffset)/255;
				_oneData[i++] = (endColor.greenOffset - startColor.greenOffset)/255;
				_oneData[i++] = (endColor.blueOffset - startColor.blueOffset)/255;
				_oneData[i++] = (endColor.alphaOffset - startColor.alphaOffset)/255;
			}
		} else {
			//multiplier
			if (_usesMultiplier) {
				_oneData[i++] = (startColor.redMultiplier + endColor.redMultiplier)/2;
				_oneData[i++] = (startColor.greenMultiplier + endColor.greenMultiplier)/2;
				_oneData[i++] = (startColor.blueMultiplier + endColor.blueMultiplier)/2;
				_oneData[i++] = (startColor.alphaMultiplier + endColor.alphaMultiplier)/2;
				_oneData[i++] = (startColor.redMultiplier - endColor.redMultiplier)/2;
				_oneData[i++] = (startColor.greenMultiplier - endColor.greenMultiplier)/2;
				_oneData[i++] = (startColor.blueMultiplier - endColor.blueMultiplier)/2;
				_oneData[i++] = (startColor.alphaMultiplier - endColor.alphaMultiplier)/2;
			}
			
			//offset
			if (_usesOffset) {
				_oneData[i++] = (startColor.redOffset + endColor.redOffset)/(255*2);
				_oneData[i++] = (startColor.greenOffset + endColor.greenOffset)/(255*2);
				_oneData[i++] = (startColor.blueOffset + endColor.blueOffset)/(255*2);
				_oneData[i++] = (startColor.alphaOffset + endColor.alphaOffset)/(255*2);
				_oneData[i++] = (startColor.redOffset - endColor.redOffset)/(255*2);
				_oneData[i++] = (startColor.greenOffset - endColor.greenOffset)/(255*2);
				_oneData[i++] = (startColor.blueOffset - endColor.blueOffset)/(255*2);
				_oneData[i++] = (startColor.alphaOffset - endColor.alphaOffset)/(255*2);
			}
		}
		
	}
}