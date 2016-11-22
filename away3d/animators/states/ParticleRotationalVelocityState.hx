package away3d.animators.states;

import away3d.animators.data.ParticlePropertiesMode;
import away3d.cameras.Camera3D;
import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.data.AnimationSubGeometry;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.animators.nodes.ParticleRotationalVelocityNode;
import away3d.animators.ParticleAnimator;

import openfl.display3D.Context3DVertexBufferFormat;
import openfl.errors.Error;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * ...
 */
class ParticleRotationalVelocityState extends ParticleStateBase
{
	public var rotationalVelocity(get, set):Vector3D;
	
	private var _particleRotationalVelocityNode:ParticleRotationalVelocityNode;
	private var _rotationalVelocityData:Vector3D;
	private var _rotationalVelocity:Vector3D;
	
	/**
	 * Defines the default rotationalVelocity of the state, used when in global mode.
	 */
	private function get_rotationalVelocity():Vector3D
	{
		return _rotationalVelocity;
	}
	
	private function set_rotationalVelocity(value:Vector3D):Vector3D
	{
		_rotationalVelocity = value;
		
		updateRotationalVelocityData();
		return value;
	}
	
	/**
	 *
	 */
	public function getRotationalVelocities():Vector<Vector3D>
	{
		return _dynamicProperties;
	}
	
	public function setRotationalVelocities(value:Vector<Vector3D>):Void
	{
		_dynamicProperties = value;
		
		_dynamicPropertiesDirty = new Map<AnimationSubGeometry, Bool>();
	}
	
	public function new(animator:ParticleAnimator, particleRotationNode:ParticleRotationalVelocityNode)
	{
		super(animator, particleRotationNode);
		
		_particleRotationalVelocityNode = particleRotationNode;
		_rotationalVelocity = _particleRotationalVelocityNode._rotationalVelocity;
		
		updateRotationalVelocityData();
	}
	
	/**
	 * @inheritDoc
	 */
	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		// TODO: not used
		
		if (_particleRotationalVelocityNode.mode == ParticlePropertiesMode.LOCAL_DYNAMIC && !_dynamicPropertiesDirty.exists(animationSubGeometry))
			updateDynamicProperties(animationSubGeometry);
		
		var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleRotationalVelocityNode.ROTATIONALVELOCITY_INDEX);
		
		if (_particleRotationalVelocityNode.mode == ParticlePropertiesMode.GLOBAL)
			animationRegisterCache.setVertexConst(index, _rotationalVelocityData.x, _rotationalVelocityData.y, _rotationalVelocityData.z, _rotationalVelocityData.w);
		else
			animationSubGeometry.activateVertexBuffer(index, _particleRotationalVelocityNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
	}
	
	private function updateRotationalVelocityData():Void
	{
		if (_particleRotationalVelocityNode.mode == ParticlePropertiesMode.GLOBAL) {
			if (_rotationalVelocity.w <= 0)
				throw(new Error("the cycle duration must greater than zero"));
			var rotation:Vector3D = _rotationalVelocity.clone();
			
			if (rotation.length <= 0)
				rotation.z = 1; //set the default direction
			else
				rotation.normalize();
			// w is used as angle/2 in agal
			_rotationalVelocityData = new Vector3D(rotation.x, rotation.y, rotation.z, Math.PI/rotation.w);
		}
	}
}