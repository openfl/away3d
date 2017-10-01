package away3d.animators.states;

import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.data.AnimationSubGeometry;
import away3d.animators.nodes.ParticleSegmentedScaleNode;
import away3d.animators.ParticleAnimator;
import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;

import openfl.geom.Vector3D;
import openfl.Vector;

class ParticleSegmentedScaleState extends ParticleStateBase
{
	public var startScale(get, set):Vector3D;
	public var endScale(get, set):Vector3D;
	public var numSegmentPoint(get, never):Int;
	public var segmentPoints(get, set):Vector<Vector3D>;
	
	private var _startScale:Vector3D;
	private var _endScale:Vector3D;
	private var _segmentPoints:Vector<Vector3D>;
	private var _numSegmentPoint:Int;
	
	private var _scaleData:Vector<Float>;
	
	/**
	 * Defines the start scale of the state, when in global mode.
	 */
	private function get_startScale():Vector3D
	{
		return _startScale;
	}
	
	private function set_startScale(value:Vector3D):Vector3D
	{
		_startScale = value;
		
		updateScaleData();
		return value;
	}
	
	/**
	 * Defines the end scale of the state, when in global mode.
	 */
	private function get_endScale():Vector3D
	{
		return _endScale;
	}
	
	private function set_endScale(value:Vector3D):Vector3D
	{
		_endScale = value;
		updateScaleData();
		return value;
	}
	
	/**
	 * Defines the number of segments.
	 */
	private function get_numSegmentPoint():Int
	{
		return _numSegmentPoint;
	}
	
	/**
	 * Defines the key points of Scale
	 */
	private function get_segmentPoints():Vector<Vector3D>
	{
		return _segmentPoints;
	}
	
	private function set_segmentPoints(value:Vector<Vector3D>):Vector<Vector3D>
	{
		_segmentPoints = value;
		updateScaleData();
		return value;
	}
	
	public function new(animator:ParticleAnimator, particleSegmentedScaleNode:ParticleSegmentedScaleNode)
	{
		super(animator, particleSegmentedScaleNode);
	
		_startScale = particleSegmentedScaleNode._startScale;
		_endScale = particleSegmentedScaleNode._endScale;
		_segmentPoints = particleSegmentedScaleNode._segmentScales;
		_numSegmentPoint = particleSegmentedScaleNode._numSegmentPoint;
		updateScaleData();
	}
	
	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		animationRegisterCache.setVertexConstFromVector(animationRegisterCache.getRegisterIndex(_animationNode, ParticleSegmentedScaleNode.START_INDEX), _scaleData);
	}
	
	private function updateScaleData():Void
	{
		var _timeLifeData:Vector<Float> = new Vector<Float>();
		_scaleData = new Vector<Float>();
		for (i in 0..._numSegmentPoint)
		{
			if (i == 0)
				_timeLifeData.push(_segmentPoints[i].w);
			else
				_timeLifeData.push(_segmentPoints[i].w - _segmentPoints[i - 1].w);
		}
		if (_numSegmentPoint == 0)
			_timeLifeData.push(1);
		else
			_timeLifeData.push(1 - _segmentPoints[_numSegmentPoint - 1].w);
		
		_scaleData.push(_startScale.x);
		_scaleData.push(_startScale.y);
		_scaleData.push(_startScale.z);
		_scaleData.push(0);
		for (i in 0..._numSegmentPoint)
		{
			if (i == 0) {
				_scaleData.push((_segmentPoints[i].x - _startScale.x) / _timeLifeData[i]);
				_scaleData.push((_segmentPoints[i].y - _startScale.y) / _timeLifeData[i]);
				_scaleData.push((_segmentPoints[i].z - _startScale.z) / _timeLifeData[i]);
				_scaleData.push(_timeLifeData[i]);
			} else {
				_scaleData.push((_segmentPoints[i].x - _segmentPoints[i - 1].x) / _timeLifeData[i]);
				_scaleData.push((_segmentPoints[i].y - _segmentPoints[i - 1].y) / _timeLifeData[i]);
				_scaleData.push((_segmentPoints[i].z - _segmentPoints[i - 1].z) / _timeLifeData[i]);
				_scaleData.push(_timeLifeData[i]);
			}
		}
		var i = _numSegmentPoint;
		if (_numSegmentPoint == 0) {
			_scaleData.push(_endScale.x - _startScale.x);
			_scaleData.push(_endScale.y - _startScale.y);
			_scaleData.push(_endScale.z - _startScale.z);
			_scaleData.push(1);
		} else {
			_scaleData.push((_endScale.x - _segmentPoints[i - 1].x) / _timeLifeData[i]);
			_scaleData.push((_endScale.y - _segmentPoints[i - 1].y) / _timeLifeData[i]);
			_scaleData.push((_endScale.z - _segmentPoints[i - 1].z) / _timeLifeData[i]);
			_scaleData.push(_timeLifeData[i]);
		}
	}
}