package away3d.animators.nodes;

import away3d.*;
import away3d.animators.*;
import away3d.animators.data.*;
import away3d.animators.states.*;
import away3d.materials.compilation.*;
import away3d.materials.passes.*;

import openfl.geom.*;

/**
 * A particle animation node used to control the UV offset and scale of a particle over time.
 */
class ParticleUVNode extends ParticleNodeBase
{
	public var cycle(get, set):Float;
	public var scale(get, set):Float;
	public var axis(get, set):String;
	
	/** @private */
	@:allow(away3d) private static inline var UV_INDEX:Int = 0;
	
	/** @private */
	@:allow(away3d) private var _uvData:Vector3D;
	
	/**
	 * Used to set the time node into global property mode.
	 */
	public static inline var GLOBAL:Int = 1;
	
	/**
	 *
	 */
	public static inline var U_AXIS:String = "x";
	
	/**
	 *
	 */
	public static inline var V_AXIS:String = "y";
	
	private var _cycle:Float;
	private var _scale:Float;
	private var _axis:String;
	
	/**
	 * Creates a new <code>ParticleTimeNode</code>
	 *
	 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
	 * @param    [optional] cycle           Defines whether the time track is in loop mode. Defaults to false.
	 * @param    [optional] scale           Defines whether the time track is in loop mode. Defaults to false.
	 * @param    [optional] axis            Defines whether the time track is in loop mode. Defaults to false.
	 */
	public function new(mode:Int, cycle:Float = 1, scale:Float = 1, axis:String = "x")
	{
		super("ParticleUV", mode, 4, ParticleAnimationSet.POST_PRIORITY + 1);
		
		_stateConstructor = cast ParticleUVState.new;
		
		_cycle = cycle;
		_scale = scale;
		_axis = axis;
		
		updateUVData();
	}
	
	/**
	 *
	 */
	private function get_cycle():Float
	{
		return _cycle;
	}
	
	private function set_cycle(value:Float):Float
	{
		_cycle = value;
		
		updateUVData();
		return value;
	}
	
	/**
	 *
	 */
	private function get_scale():Float
	{
		return _scale;
	}
	
	private function set_scale(value:Float):Float
	{
		_scale = value;
		
		updateUVData();
		return value;
	}
	
	/**
	 *
	 */
	private function get_axis():String
	{
		return _axis;
	}
	
	private function set_axis(value:String):String
	{
		_axis = value;
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function getAGALUVCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		var code:String = "";
		
		if (animationRegisterCache.needUVAnimation) {
			var uvConst:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, UV_INDEX, uvConst.index);
			
			var axisIndex:Int = _axis == "x"? 0 :
				_axis == "y"? 1 :
				2;
			var target:ShaderRegisterElement = new ShaderRegisterElement(animationRegisterCache.uvTarget.regName, animationRegisterCache.uvTarget.index, axisIndex);
			
			var sin:ShaderRegisterElement = animationRegisterCache.getFreeVertexSingleTemp();
			
			if (_scale != 1)
				code += "mul " + target + "," + target + "," + uvConst + ".y\n";
			
			code += "mul " + sin + "," + animationRegisterCache.vertexTime + "," + uvConst + ".x\n";
			code += "sin " + sin + "," + sin + "\n";
			code += "add " + target + "," + target + "," + sin + "\n";
		}
		
		return code;
	}
	
	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):ParticleUVState
	{
		return cast(animator.getAnimationState(this), ParticleUVState);
	}
	
	private function updateUVData():Void
	{
		_uvData = new Vector3D(Math.PI*2/_cycle, _scale, 0, 0);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):Void
	{
		particleAnimationSet.hasUVNode = true;
	}
}