package away3d.animators.states;

import away3d.cameras.Camera3D;
import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.data.AnimationSubGeometry;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.animators.nodes.ParticleUVNode;
import away3d.animators.ParticleAnimator;

import openfl.geom.Vector3D;

/**
 * ...
 */
class ParticleUVState extends ParticleStateBase
{
	private var _particleUVNode:ParticleUVNode;
	
	public function new(animator:ParticleAnimator, particleUVNode:ParticleUVNode)
	{
		super(animator, particleUVNode);
		
		_particleUVNode = particleUVNode;
	}
	
	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		if (animationRegisterCache.needUVAnimation) {
			var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleUVNode.UV_INDEX);
			var data:Vector3D = _particleUVNode._uvData;
			animationRegisterCache.setVertexConst(index, data.x, data.y);
		}
	}
}