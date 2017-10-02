package away3d.animators.states;

import away3d.animators.data.ParticlePropertiesMode;
import away3d.cameras.Camera3D;
import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.data.AnimationSubGeometry;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.animators.nodes.ParticleScaleNode;
import away3d.animators.ParticleAnimator;

import openfl.errors.Error;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.geom.Vector3D;

/**
 * ...
 */
class ParticleScaleState extends ParticleStateBase
{
	public var minScale(get, set):Float;
	public var maxScale(get, set):Float;
	public var cycleDuration(get, set):Float;
	public var cyclePhase(get, set):Float;
	
	private var _particleScaleNode:ParticleScaleNode;
	private var _usesCycle:Bool;
	private var _usesPhase:Bool;
	private var _minScale:Float;
	private var _maxScale:Float;
	private var _cycleDuration:Float;
	private var _cyclePhase:Float;
	private var _scaleData:Vector3D;
	
	/**
	 * Defines the end scale of the state, when in global mode. Defaults to 1.
	 */
	private function get_minScale():Float
	{
		return _minScale;
	}
	
	private function set_minScale(value:Float):Float
	{
		_minScale = value;
		
		updateScaleData();
		return value;
	}
	
	/**
	 * Defines the end scale of the state, when in global mode. Defaults to 1.
	 */
	private function get_maxScale():Float
	{
		return _maxScale;
	}
	
	private function set_maxScale(value:Float):Float
	{
		_maxScale = value;
		
		updateScaleData();
		return value;
	}
	
	/**
	 * Defines the duration of the animation in seconds, used as a period independent of particle duration when in global mode. Defaults to 1.
	 */
	private function get_cycleDuration():Float
	{
		return _cycleDuration;
	}
	
	private function set_cycleDuration(value:Float):Float
	{
		_cycleDuration = value;
		
		updateScaleData();
		return value;
	}
	
	/**
	 * Defines the phase of the cycle in degrees, used as the starting offset of the cycle when in global mode. Defaults to 0.
	 */
	private function get_cyclePhase():Float
	{
		return _cyclePhase;
	}
	
	private function set_cyclePhase(value:Float):Float
	{
		_cyclePhase = value;
		
		updateScaleData();
		return value;
	}
	
	public function new(animator:ParticleAnimator, particleScaleNode:ParticleScaleNode)
	{
		super(animator, particleScaleNode);
		
		_particleScaleNode = particleScaleNode;
		_usesCycle = _particleScaleNode._usesCycle;
		_usesPhase = _particleScaleNode._usesPhase;
		_minScale = _particleScaleNode._minScale;
		_maxScale = _particleScaleNode._maxScale;
		_cycleDuration = _particleScaleNode._cycleDuration;
		_cyclePhase = _particleScaleNode._cyclePhase;
		
		updateScaleData();
	}
	
	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleScaleNode.SCALE_INDEX);
		
		if (_particleScaleNode.mode == ParticlePropertiesMode.LOCAL_STATIC) {
			if (_usesCycle) {
				if (_usesPhase)
					animationSubGeometry.activateVertexBuffer(index, _particleScaleNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
				else
					animationSubGeometry.activateVertexBuffer(index, _particleScaleNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			} else
				animationSubGeometry.activateVertexBuffer(index, _particleScaleNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_2);
		} else
			animationRegisterCache.setVertexConst(index, _scaleData.x, _scaleData.y, _scaleData.z, _scaleData.w);
	}
	
	private function updateScaleData():Void
	{
		if (_particleScaleNode.mode == ParticlePropertiesMode.GLOBAL) {
			if (_usesCycle) {
				if (_cycleDuration <= 0)
					throw(new Error("the cycle duration must be greater than zero"));
				_scaleData = new Vector3D((_minScale + _maxScale)/2, Math.abs(_minScale - _maxScale)/2, Math.PI*2/_cycleDuration, _cyclePhase*Math.PI/180);
			} else
				_scaleData = new Vector3D(_minScale, _maxScale - _minScale, 0, 0);
		}
	}
}