package away3d.animators.states;

import away3d.cameras.Camera3D;
import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.data.AnimationSubGeometry;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.animators.nodes.ParticleTimeNode;
import away3d.animators.ParticleAnimator;

import openfl.display3D.Context3DVertexBufferFormat;

/**
 * ...
 */
class ParticleTimeState extends ParticleStateBase
{
	private var _particleTimeNode:ParticleTimeNode;
	
	public function new(animator:ParticleAnimator, particleTimeNode:ParticleTimeNode)
	{
		super(animator, particleTimeNode, true);
		
		_particleTimeNode = particleTimeNode;
	}
	
	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleTimeNode.TIME_STREAM_INDEX), _particleTimeNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
		
		var particleTime:Float = _time/1000;
		animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleTimeNode.TIME_CONSTANT_INDEX), particleTime, particleTime, particleTime, particleTime);
	}
}