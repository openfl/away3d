package away3d.animators.states;

import away3d.animators.data.ParticlePropertiesMode;
import away3d.cameras.Camera3D;
import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.data.AnimationSubGeometry;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.animators.nodes.ParticleOrbitNode;
import away3d.animators.ParticleAnimator;

import openfl.display3D.Context3DVertexBufferFormat;
import openfl.errors.Error;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

/**
 * ...
 */
class ParticleOrbitState extends ParticleStateBase
{
	public var radius(get, set):Float;
	public var cycleDuration(get, set):Float;
	public var cyclePhase(get, set):Float;
	public var eulers(get, set):Vector3D;
	
	private var _particleOrbitNode:ParticleOrbitNode;
	private var _usesEulers:Bool;
	private var _usesCycle:Bool;
	private var _usesPhase:Bool;
	private var _radius:Float;
	private var _cycleDuration:Float;
	private var _cyclePhase:Float;
	private var _eulers:Vector3D;
	private var _orbitData:Vector3D;
	private var _eulersMatrix:Matrix3D;
	
	/**
	 * Defines the radius of the orbit when in global mode. Defaults to 100.
	 */
	private function get_radius():Float
	{
		return _radius;
	}
	
	private function set_radius(value:Float):Float
	{
		_radius = value;
		
		updateOrbitData();
		return value;
	}
	
	/**
	 * Defines the duration of the orbit in seconds, used as a period independent of particle duration when in global mode. Defaults to 1.
	 */
	private function get_cycleDuration():Float
	{
		return _cycleDuration;
	}
	
	private function set_cycleDuration(value:Float):Float
	{
		_cycleDuration = value;
		
		updateOrbitData();
		return value;
	}
	
	/**
	 * Defines the phase of the orbit in degrees, used as the starting offset of the cycle when in global mode. Defaults to 0.
	 */
	private function get_cyclePhase():Float
	{
		return _cyclePhase;
	}
	
	private function set_cyclePhase(value:Float):Float
	{
		_cyclePhase = value;
		
		updateOrbitData();
		return value;
	}
	
	/**
	 * Defines the euler rotation in degrees, applied to the orientation of the orbit when in global mode.
	 */
	private function get_eulers():Vector3D
	{
		return _eulers;
	}
	
	private function set_eulers(value:Vector3D):Vector3D
	{
		_eulers = value;
		
		updateOrbitData();
		return value;
	}
	
	public function new(animator:ParticleAnimator, particleOrbitNode:ParticleOrbitNode)
	{
		super(animator, particleOrbitNode);
		
		_particleOrbitNode = particleOrbitNode;
		_usesEulers = _particleOrbitNode._usesEulers;
		_usesCycle = _particleOrbitNode._usesCycle;
		_usesPhase = _particleOrbitNode._usesPhase;
		_eulers = _particleOrbitNode._eulers;
		_radius = _particleOrbitNode._radius;
		_cycleDuration = _particleOrbitNode._cycleDuration;
		_cyclePhase = _particleOrbitNode._cyclePhase;
		updateOrbitData();
	}
	
	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleOrbitNode.ORBIT_INDEX);
		
		if (_particleOrbitNode.mode == LOCAL_STATIC) {
			if (_usesPhase)
				animationSubGeometry.activateVertexBuffer(index, _particleOrbitNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
			else
				animationSubGeometry.activateVertexBuffer(index, _particleOrbitNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		} else
			animationRegisterCache.setVertexConst(index, _orbitData.x, _orbitData.y, _orbitData.z, _orbitData.w);
		
		if (_usesEulers)
			animationRegisterCache.setVertexConstFromMatrix(animationRegisterCache.getRegisterIndex(_animationNode, ParticleOrbitNode.EULERS_INDEX), _eulersMatrix);
	}
	
	private function updateOrbitData():Void
	{
		if (_usesEulers) {
			_eulersMatrix = new Matrix3D();
			_eulersMatrix.appendRotation(_eulers.x, Vector3D.X_AXIS);
			_eulersMatrix.appendRotation(_eulers.y, Vector3D.Y_AXIS);
			_eulersMatrix.appendRotation(_eulers.z, Vector3D.Z_AXIS);
		}
		if (_particleOrbitNode.mode == GLOBAL) {
			_orbitData = new Vector3D(_radius, 0, _radius*Math.PI*2, _cyclePhase*Math.PI/180);
			if (_usesCycle) {
				if (_cycleDuration <= 0)
					throw(new Error("the cycle duration must be greater than zero"));
				_orbitData.y = Math.PI*2/_cycleDuration;
			} else
				_orbitData.y = Math.PI*2;
		}
	}
}