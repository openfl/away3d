package away3d.animators.states;

import away3d.animators.IAnimator;
import away3d.animators.data.*;
import away3d.animators.nodes.*;
import away3d.core.math.*;

import openfl.geom.Vector3D;
import openfl.Vector;

/**
 *
 */
class SkeletonDifferenceState extends AnimationStateBase implements ISkeletonAnimationState
{
	public var blendWeight(get, set):Float;
	
	private var _blendWeight:Float = 0;
	private static var _tempQuat:Quaternion = new Quaternion();
	private var _skeletonAnimationNode:SkeletonDifferenceNode;
	private var _skeletonPose:SkeletonPose = new SkeletonPose();
	private var _skeletonPoseDirty:Bool = true;
	private var _baseInput:ISkeletonAnimationState;
	private var _differenceInput:ISkeletonAnimationState;
	
	/**
	 * Defines a fractional value between 0 and 1 representing the blending ratio between the base input (0) and difference input (1),
	 * used to produce the skeleton pose output.
	 *
	 * @see #baseInput
	 * @see #differenceInput
	 */
	private function get_blendWeight():Float
	{
		return _blendWeight;
	}
	
	private function set_blendWeight(value:Float):Float
	{
		_blendWeight = value;
		
		_positionDeltaDirty = true;
		_skeletonPoseDirty = true;
		return value;
	}
	
	public function new(animator:IAnimator, skeletonAnimationNode:SkeletonDifferenceNode)
	{
		super(animator, skeletonAnimationNode);
		
		_skeletonAnimationNode = skeletonAnimationNode;
		
		_baseInput = cast(animator.getAnimationState(_skeletonAnimationNode.baseInput), ISkeletonAnimationState);
		_differenceInput = cast(animator.getAnimationState(_skeletonAnimationNode.differenceInput), ISkeletonAnimationState);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function phase(value:Float):Void
	{
		_skeletonPoseDirty = true;
		
		_positionDeltaDirty = true;
		
		_baseInput.phase(value);
		_baseInput.phase(value);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateTime(time:Int):Void
	{
		_skeletonPoseDirty = true;
		
		_baseInput.update(time);
		_differenceInput.update(time);
		
		super.updateTime(time);
	}
	
	/**
	 * Returns the current skeleton pose of the animation in the clip based on the internal playhead position.
	 */
	public function getSkeletonPose(skeleton:Skeleton):SkeletonPose
	{
		if (_skeletonPoseDirty)
			updateSkeletonPose(skeleton);
		
		return _skeletonPose;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updatePositionDelta():Void
	{
		_positionDeltaDirty = false;
		
		var deltA:Vector3D = _baseInput.positionDelta;
		var deltB:Vector3D = _differenceInput.positionDelta;
		
		positionDelta.x = deltA.x + _blendWeight*deltB.x;
		positionDelta.y = deltA.y + _blendWeight*deltB.y;
		positionDelta.z = deltA.z + _blendWeight*deltB.z;
	}
	
	/**
	 * Updates the output skeleton pose of the node based on the blendWeight value between base input and difference input nodes.
	 *
	 * @param skeleton The skeleton used by the animator requesting the ouput pose.
	 */
	
	private function updateSkeletonPose(skeleton:Skeleton):Void
	{
		_skeletonPoseDirty = false;
		
		var endPose:JointPose;
		var endPoses:Vector<JointPose> = _skeletonPose.jointPoses;
		var basePoses:Vector<JointPose> = _baseInput.getSkeletonPose(skeleton).jointPoses;
		var diffPoses:Vector<JointPose> = _differenceInput.getSkeletonPose(skeleton).jointPoses;
		var base:JointPose, diff:JointPose;
		var basePos:Vector3D, diffPos:Vector3D;
		var tr:Vector3D;
		var numJoints:Int = skeleton.numJoints;
		
		// :s
		if (endPoses.length != numJoints)
			endPoses.length = numJoints;
		
		for (i in 0...numJoints) {
			if (endPoses[i] == null)endPoses[i] = new JointPose();
			endPose = endPoses[i];
			base = basePoses[i];
			diff = diffPoses[i];
			basePos = base.translation;
			diffPos = diff.translation;
			
			_tempQuat.multiply(diff.orientation, base.orientation);
			endPose.orientation.lerp(base.orientation, _tempQuat, _blendWeight);
			
			tr = endPose.translation;
			tr.x = basePos.x + _blendWeight*diffPos.x;
			tr.y = basePos.y + _blendWeight*diffPos.y;
			tr.z = basePos.z + _blendWeight*diffPos.z;
		}
	}
}