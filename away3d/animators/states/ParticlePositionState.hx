package away3d.animators.states;

import away3d.animators.ParticleAnimator;
import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.data.AnimationSubGeometry;
import away3d.animators.data.ParticlePropertiesMode;
import away3d.animators.nodes.ParticlePositionNode;
import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;

import openfl.display3D.Context3DVertexBufferFormat;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * ...
 * @author ...
 */
class ParticlePositionState extends ParticleStateBase
{
	public var position(get, set):Vector3D;
	
	private var _particlePositionNode:ParticlePositionNode;
	private var _position:Vector3D;
	
	/**
	 * Defines the position of the particle when in global mode. Defaults to 0,0,0.
	 */
	private function get_position():Vector3D
	{
		return _position;
	}
	
	private function set_position(value:Vector3D):Vector3D
	{
		_position = value;
		return value;
	}
	
	/**
	 *
	 */
	public function getPositions():Vector<Vector3D>
	{
		return _dynamicProperties;
	}
	
	public function setPositions(value:Vector<Vector3D>):Void
	{
		_dynamicProperties = value;
		_dynamicPropertiesDirty = new Map<AnimationSubGeometry, Bool>();
	}
	
	public function new(animator:ParticleAnimator, particlePositionNode:ParticlePositionNode)
	{
		super(animator, particlePositionNode);
		
		_particlePositionNode = particlePositionNode;
		_position = _particlePositionNode._position;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		if (_particlePositionNode.mode == LOCAL_DYNAMIC && !_dynamicPropertiesDirty.exists(animationSubGeometry))
			updateDynamicProperties(animationSubGeometry);
		
		var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticlePositionNode.POSITION_INDEX);
		
		if (_particlePositionNode.mode == GLOBAL)
			animationRegisterCache.setVertexConst(index, _position.x, _position.y, _position.z);
		else
			animationSubGeometry.activateVertexBuffer(index, _particlePositionNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
	}
}