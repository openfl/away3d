package away3d.animators.states;

import away3d.animators.data.ParticlePropertiesMode;
import away3d.cameras.Camera3D;
import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.data.AnimationSubGeometry;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.animators.nodes.ParticleAccelerationNode;
import away3d.animators.ParticleAnimator;

import openfl.display3D.Context3DVertexBufferFormat;
import openfl.geom.Vector3D;

/**
 * ...
 */
class ParticleAccelerationState extends ParticleStateBase
{
	public var acceleration(get, set):Vector3D;
	
	private var _particleAccelerationNode:ParticleAccelerationNode;
	private var _acceleration:Vector3D;
	private var _halfAcceleration:Vector3D;
	
	/**
	 * Defines the acceleration vector of the state, used when in global mode.
	 */
	private function get_acceleration():Vector3D
	{
		return _acceleration;
	}
	
	private function set_acceleration(value:Vector3D):Vector3D
	{
		_acceleration.x = value.x;
		_acceleration.y = value.y;
		_acceleration.z = value.z;
		
		updateAccelerationData();
		return value;
	}
	
	public function new(animator:ParticleAnimator, particleAccelerationNode:ParticleAccelerationNode)
	{
		super(animator, particleAccelerationNode);
		
		_particleAccelerationNode = particleAccelerationNode;
		_acceleration = _particleAccelerationNode._acceleration;
		
		updateAccelerationData();
	}
	
	/**
	 * @inheritDoc
	 */
	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		// TODO: not used
		
		var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleAccelerationNode.ACCELERATION_INDEX);
		
		if (_particleAccelerationNode.mode == ParticlePropertiesMode.LOCAL_STATIC)
			animationSubGeometry.activateVertexBuffer(index, _particleAccelerationNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		else
			animationRegisterCache.setVertexConst(index, _halfAcceleration.x, _halfAcceleration.y, _halfAcceleration.z);
	}
	
	private function updateAccelerationData():Void
	{
		if (_particleAccelerationNode.mode == ParticlePropertiesMode.GLOBAL)
			_halfAcceleration = new Vector3D(_acceleration.x/2, _acceleration.y/2, _acceleration.z/2);
	}
}