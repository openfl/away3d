package away3d.animators.states;

import away3d.animators.ParticleAnimator;
import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.data.AnimationSubGeometry;
import away3d.animators.data.ParticlePropertiesMode;
import away3d.animators.nodes.ParticleInitialColorNode;
import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;

import openfl.display3D.Context3DVertexBufferFormat;
import openfl.geom.ColorTransform;
import openfl.geom.Vector3D;

class ParticleInitialColorState extends ParticleStateBase
{
	public var initialColor(get, set):ColorTransform;
	
	private var _particleInitialColorNode:ParticleInitialColorNode;
	private var _usesMultiplier:Bool;
	private var _usesOffset:Bool;
	private var _initialColor:ColorTransform;
	private var _multiplierData:Vector3D;
	private var _offsetData:Vector3D;
	
	public function new(animator:ParticleAnimator, particleInitialColorNode:ParticleInitialColorNode)
	{
		super(animator, particleInitialColorNode);
		
		_particleInitialColorNode = particleInitialColorNode;
		_usesMultiplier = particleInitialColorNode._usesMultiplier;
		_usesOffset = particleInitialColorNode._usesOffset;
		_initialColor = particleInitialColorNode._initialColor;
		
		updateColorData();
	}
	
	/**
	 * Defines the initial color transform of the state, when in global mode.
	 */
	private function get_initialColor():ColorTransform
	{
		return _initialColor;
	}
	
	private function set_initialColor(value:ColorTransform):ColorTransform
	{
		_initialColor = value;
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		// TODO: not used
		
		if (animationRegisterCache.needFragmentAnimation) {
			if (_particleInitialColorNode.mode == ParticlePropertiesMode.LOCAL_STATIC) {
				var dataOffset:Int = _particleInitialColorNode.dataOffset;
				if (_usesMultiplier) {
					animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleInitialColorNode.MULTIPLIER_INDEX), dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
					dataOffset += 4;
				}
				if (_usesOffset)
					animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleInitialColorNode.OFFSET_INDEX), dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
			} else {
				if (_usesMultiplier)
					animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleInitialColorNode.MULTIPLIER_INDEX), _multiplierData.x, _multiplierData.y, _multiplierData.z, _multiplierData.w);
				if (_usesOffset)
					animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleInitialColorNode.OFFSET_INDEX), _offsetData.x, _offsetData.y, _offsetData.z, _offsetData.w);
			}
		}
	}
	
	private function updateColorData():Void
	{
		if (_particleInitialColorNode.mode == ParticlePropertiesMode.GLOBAL) {
			if (_usesMultiplier)
				_multiplierData = new Vector3D(_initialColor.redMultiplier, _initialColor.greenMultiplier, _initialColor.blueMultiplier, _initialColor.alphaMultiplier);
			if (_usesOffset)
				_offsetData = new Vector3D(_initialColor.redOffset/255, _initialColor.greenOffset/255, _initialColor.blueOffset/255, _initialColor.alphaOffset/255);
		}
	}
}