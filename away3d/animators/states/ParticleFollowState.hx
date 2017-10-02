package away3d.animators.states;

import away3d.animators.data.ParticleAnimationData;
import away3d.cameras.Camera3D;
import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.data.AnimationSubGeometry;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.animators.nodes.ParticleFollowNode;
import away3d.animators.ParticleAnimator;
import away3d.core.base.Object3D;
import away3d.core.math.MathConsts;

import openfl.display3D.Context3DVertexBufferFormat;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * ...
 */
class ParticleFollowState extends ParticleStateBase
{
	public var followTarget(get, set):Object3D;
	public var smooth(get, set):Bool;
	
	private var _particleFollowNode:ParticleFollowNode;
	private var _followTarget:Object3D;
	
	private var _targetPos:Vector3D = new Vector3D();
	private var _targetEuler:Vector3D = new Vector3D();
	private var _prePos:Vector3D;
	private var _preEuler:Vector3D;
	private var _smooth:Bool;
	
	//temporary vector3D for calculation
	private var temp:Vector3D = new Vector3D();
	
	public function new(animator:ParticleAnimator, particleFollowNode:ParticleFollowNode)
	{
		super(animator, particleFollowNode, true);
		
		_particleFollowNode = particleFollowNode;
		_smooth = particleFollowNode._smooth;
	}
	
	private function get_followTarget():Object3D
	{
		return _followTarget;
	}
	
	private function set_followTarget(value:Object3D):Object3D
	{
		_followTarget = value;
		return value;
	}
	
	private function get_smooth():Bool
	{
		return _smooth;
	}
	
	private function set_smooth(value:Bool):Bool
	{
		_smooth = value;
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		// TODO: not used
		
		if (_followTarget != null) {
			if (_particleFollowNode._usesPosition) {
				_targetPos.x = _followTarget.position.x/renderable.sourceEntity.scaleX;
				_targetPos.y = _followTarget.position.y/renderable.sourceEntity.scaleY;
				_targetPos.z = _followTarget.position.z/renderable.sourceEntity.scaleZ;
			}
			if (_particleFollowNode._usesRotation) {
				_targetEuler.x = _followTarget.rotationX;
				_targetEuler.y = _followTarget.rotationY;
				_targetEuler.z = _followTarget.rotationZ;
				_targetEuler.scaleBy(MathConsts.DEGREES_TO_RADIANS);
			}
		}
		//initialization
		if (_prePos == null)
			_prePos = _targetPos.clone();
		if (_preEuler == null)
			_preEuler = _targetEuler.clone();
		
		var currentTime:Float = _time/1000;
		var previousTime:Float = animationSubGeometry.previousTime;
		var deltaTime:Float = currentTime - previousTime;
		
		var needProcess:Bool = previousTime != currentTime;
		
		if (_particleFollowNode._usesPosition && _particleFollowNode._usesRotation) {
			if (needProcess)
				processPositionAndRotation(currentTime, deltaTime, animationSubGeometry);
			
			animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleFollowNode.FOLLOW_POSITION_INDEX), _particleFollowNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleFollowNode.FOLLOW_ROTATION_INDEX), _particleFollowNode.dataOffset + 3, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		} else if (_particleFollowNode._usesPosition) {
			if (needProcess)
				processPosition(currentTime, deltaTime, animationSubGeometry);
			animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleFollowNode.FOLLOW_POSITION_INDEX), _particleFollowNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		} else if (_particleFollowNode._usesRotation) {
			if (needProcess)
				precessRotation(currentTime, deltaTime, animationSubGeometry);
			animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleFollowNode.FOLLOW_ROTATION_INDEX), _particleFollowNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		}
		
		_prePos.copyFrom(_targetPos);
		_preEuler.copyFrom(_targetEuler);
		animationSubGeometry.previousTime = currentTime;
	}
	
	private function processPosition(currentTime:Float, deltaTime:Float, animationSubGeometry:AnimationSubGeometry):Void
	{
		var data:Vector<ParticleAnimationData> = animationSubGeometry.animationParticles;
		var vertexData:Vector<Float> = animationSubGeometry.vertexData;
		
		var changed:Bool = false;
		var len:Int = data.length;
		var interpolatedPos:Vector3D = null;
		var posVelocity:Vector3D = null;
		if (_smooth) {
			posVelocity = _prePos.subtract(_targetPos);
			posVelocity.scaleBy(1/deltaTime);
		} else
			interpolatedPos = _targetPos;
		for (i in 0...len) {
			var k:Float = (currentTime - data[i].startTime)/data[i].totalTime;
			var t:Float = (k - Math.floor(k))*data[i].totalTime;
			if (t - deltaTime <= 0) {
				var inc:Int = data[i].startVertexIndex*animationSubGeometry.totalLenOfOneVertex + _particleFollowNode.dataOffset;
				
				if (_smooth) {
					temp.copyFrom(posVelocity);
					temp.scaleBy(t);
					interpolatedPos = _targetPos.add(temp);
				}
				
				if (vertexData[inc] != interpolatedPos.x || vertexData[inc + 1] != interpolatedPos.y || vertexData[inc + 2] != interpolatedPos.z) {
					changed = true;
					for (j in 0...data[i].numVertices) {
						vertexData[inc++] = interpolatedPos.x;
						vertexData[inc++] = interpolatedPos.y;
						vertexData[inc++] = interpolatedPos.z;
					}
				}
			}
		}
		if (changed)
			animationSubGeometry.invalidateBuffer();
		
	}
	
	private function precessRotation(currentTime:Float, deltaTime:Float, animationSubGeometry:AnimationSubGeometry):Void
	{
		var data:Vector<ParticleAnimationData> = animationSubGeometry.animationParticles;
		var vertexData:Vector<Float> = animationSubGeometry.vertexData;
		
		var changed:Bool = false;
		var len:Int = data.length;
		
		var interpolatedRotation:Vector3D = null;
		var rotationVelocity:Vector3D = null;
		
		if (_smooth) {
			rotationVelocity = _preEuler.subtract(_targetEuler);
			rotationVelocity.scaleBy(1/deltaTime);
		} else
			interpolatedRotation = _targetEuler;
		
		for (i in 0...len) {
			var k:Float = (currentTime - data[i].startTime)/data[i].totalTime;
			var t:Float = (k - Math.floor(k))*data[i].totalTime;
			if (t - deltaTime <= 0) {
				var inc:Int = data[i].startVertexIndex*animationSubGeometry.totalLenOfOneVertex + _particleFollowNode.dataOffset;
				
				if (_smooth) {
					temp.copyFrom(rotationVelocity);
					temp.scaleBy(t);
					interpolatedRotation = _targetEuler.add(temp);
				}
				
				if (vertexData[inc] != interpolatedRotation.x || vertexData[inc + 1] != interpolatedRotation.y || vertexData[inc + 2] != interpolatedRotation.z) {
					changed = true;
					for (j in 0...data[i].numVertices) {
						vertexData[inc++] = interpolatedRotation.x;
						vertexData[inc++] = interpolatedRotation.y;
						vertexData[inc++] = interpolatedRotation.z;
					}
				}
			}
		}
		if (changed)
			animationSubGeometry.invalidateBuffer();
		
	}
	
	private function processPositionAndRotation(currentTime:Float, deltaTime:Float, animationSubGeometry:AnimationSubGeometry):Void
	{
		var data:Vector<ParticleAnimationData> = animationSubGeometry.animationParticles;
		var vertexData:Vector<Float> = animationSubGeometry.vertexData;
		
		var changed:Bool = false;
		var len:Int = data.length;
		
		var interpolatedPos:Vector3D = null;
		var interpolatedRotation:Vector3D = null;
		
		var posVelocity:Vector3D = null;
		var rotationVelocity:Vector3D = null;
		if (_smooth) {
			posVelocity = _prePos.subtract(_targetPos);
			posVelocity.scaleBy(1/deltaTime);
			rotationVelocity = _preEuler.subtract(_targetEuler);
			rotationVelocity.scaleBy(1/deltaTime);
		} else {
			interpolatedPos = _targetPos;
			interpolatedRotation = _targetEuler;
		}
		
		for (i in 0...len) {
			var k:Float = (currentTime - data[i].startTime) / data[i].totalTime;
			var t:Float = (k - Math.floor(k)) * data[i].totalTime;
			if (t - deltaTime <= 0) {
				var inc:Int = data[i].startVertexIndex * animationSubGeometry.totalLenOfOneVertex + _particleFollowNode.dataOffset;
				if (_smooth) {
					temp.copyFrom(posVelocity);
					temp.scaleBy(t);
					interpolatedPos = _targetPos.add(temp);
					
					temp.copyFrom(rotationVelocity);
					temp.scaleBy(t);
					interpolatedRotation = _targetEuler.add(temp);
				}
				
				if (vertexData[inc] != interpolatedPos.x || vertexData[inc + 1] != interpolatedPos.y || vertexData[inc + 2] != interpolatedPos.z || vertexData[inc + 3] != interpolatedRotation.x || vertexData[inc + 4] != interpolatedRotation.y || vertexData[inc + 5] != interpolatedRotation.z) {
					changed = true;
					for (j in 0...data[i].numVertices) {
						vertexData[inc++] = interpolatedPos.x;
						vertexData[inc++] = interpolatedPos.y;
						vertexData[inc++] = interpolatedPos.z;
						vertexData[inc++] = interpolatedRotation.x;
						vertexData[inc++] = interpolatedRotation.y;
						vertexData[inc++] = interpolatedRotation.z;
					}
				}
			}
		}
		if (changed)
			animationSubGeometry.invalidateBuffer();
	}

}