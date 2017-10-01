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
 * A particle animation node used to control the position of a particle over time along a bezier curve.
 */
class ParticleBezierCurveNode extends ParticleNodeBase
{
	/** @private */
	@:allow(away3d) private static inline var BEZIER_CONTROL_INDEX:Int = 0;
	
	/** @private */
	@:allow(away3d) private static inline var BEZIER_END_INDEX:Int = 1;
	
	/** @private */
	@:allow(away3d) private var _controlPoint:Vector3D;
	
	/** @private */
	@:allow(away3d) private var _endPoint:Vector3D;
	
	/**
	 * Reference for bezier curve node properties on a single particle (when in local property mode).
	 * Expects a <code>Vector3D</code> object representing the control point position (0, 1, 2) of the curve.
	 */
	public static inline var BEZIER_CONTROL_VECTOR3D:String = "BezierControlVector3D";
	
	/**
	 * Reference for bezier curve node properties on a single particle (when in local property mode).
	 * Expects a <code>Vector3D</code> object representing the end point position (0, 1, 2) of the curve.
	 */
	public static inline var BEZIER_END_VECTOR3D:String = "BezierEndVector3D";
	
	/**
	 * Creates a new <code>ParticleBezierCurveNode</code>
	 *
	 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
	 * @param    [optional] controlPoint    Defines the default control point of the node, used when in global mode.
	 * @param    [optional] endPoint        Defines the default end point of the node, used when in global mode.
	 */
	public function new(mode:Int, controlPoint:Vector3D = null, endPoint:Vector3D = null)
	{
		super("ParticleBezierCurve", mode, 6);
		
		_stateConstructor = cast ParticleBezierCurveState.new;
		
		_controlPoint = controlPoint;
		if (_controlPoint == null)
			_controlPoint = new Vector3D();
		
		_endPoint = endPoint;
		if (_endPoint == null)
			_endPoint = new Vector3D();
	}
	
	/**
	 * @inheritDoc
	 */
	override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		var controlValue:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL)? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
		animationRegisterCache.setRegisterIndex(this, BEZIER_CONTROL_INDEX, controlValue.index);
		
		var endValue:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL)? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
		animationRegisterCache.setRegisterIndex(this, BEZIER_END_INDEX, endValue.index);
		
		var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
		var rev_time:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 0);
		var time_2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 1);
		var time_temp:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 2);
		animationRegisterCache.addVertexTempUsages(temp, 1);
		var temp2:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
		var distance:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index);
		animationRegisterCache.removeVertexTempUsage(temp);
		
		var code:String = "";
		code += "sub " + rev_time + "," + animationRegisterCache.vertexOneConst + "," + animationRegisterCache.vertexLife + "\n";
		code += "mul " + time_2 + "," + animationRegisterCache.vertexLife + "," + animationRegisterCache.vertexLife + "\n";
		
		code += "mul " + time_temp + "," + animationRegisterCache.vertexLife + "," + rev_time + "\n";
		code += "mul " + time_temp + "," + time_temp + "," + animationRegisterCache.vertexTwoConst + "\n";
		code += "mul " + distance + ".xyz," + time_temp + "," + controlValue + "\n";
		code += "add " + animationRegisterCache.positionTarget + ".xyz," + distance + ".xyz," + animationRegisterCache.positionTarget + ".xyz\n";
		code += "mul " + distance + ".xyz," + time_2 + "," + endValue + "\n";
		code += "add " + animationRegisterCache.positionTarget + ".xyz," + distance + ".xyz," + animationRegisterCache.positionTarget + ".xyz\n";
		
		if (animationRegisterCache.needVelocity) {
			code += "mul " + time_2 + "," + animationRegisterCache.vertexLife + "," + animationRegisterCache.vertexTwoConst + "\n";
			code += "sub " + time_temp + "," + animationRegisterCache.vertexOneConst + "," + time_2 + "\n";
			code += "mul " + time_temp + "," + animationRegisterCache.vertexTwoConst + "," + time_temp + "\n";
			code += "mul " + distance + ".xyz," + controlValue + "," + time_temp + "\n";
			code += "add " + animationRegisterCache.velocityTarget + ".xyz," + distance + ".xyz," + animationRegisterCache.velocityTarget + ".xyz\n";
			code += "mul " + distance + ".xyz," + endValue + "," + time_2 + "\n";
			code += "add " + animationRegisterCache.velocityTarget + ".xyz," + distance + ".xyz," + animationRegisterCache.velocityTarget + ".xyz\n";
		}
		
		return code;
	}
	
	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):ParticleBezierCurveState
	{
		return cast(animator.getAnimationState(this), ParticleBezierCurveState);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function generatePropertyOfOneParticle(param:ParticleProperties):Void
	{
		var bezierControl:Vector3D = param.nodes[BEZIER_CONTROL_VECTOR3D];
		
		if (bezierControl == null) 
			throw new Error("there is no " + BEZIER_CONTROL_VECTOR3D + " in param!");
		
		var bezierEnd:Vector3D = param.nodes[BEZIER_END_VECTOR3D];
		if (bezierEnd == null) 
			throw new Error("there is no " + BEZIER_END_VECTOR3D + " in param!");
		
		_oneData[0] = bezierControl.x;
		_oneData[1] = bezierControl.y;
		_oneData[2] = bezierControl.z;
		_oneData[3] = bezierEnd.x;
		_oneData[4] = bezierEnd.y;
		_oneData[5] = bezierEnd.z;
	}
}