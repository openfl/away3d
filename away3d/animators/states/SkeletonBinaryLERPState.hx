package away3d.animators.states;

import away3d.animators.IAnimator;
import away3d.animators.data.*;
import away3d.animators.nodes.*;

import openfl.geom.*;
import openfl.Vector;

/**
 *
 */
class SkeletonBinaryLERPState extends AnimationStateBase implements ISkeletonAnimationState
{
	public var blendWeight(get, set):Float;
	
	private var _blendWeight:Float = 0;
	private var _skeletonAnimationNode:SkeletonBinaryLERPNode;
	private var _skeletonPose:SkeletonPose = new SkeletonPose();
	private var _skeletonPoseDirty:Bool = true;
	private var _inputA:ISkeletonAnimationState;
	private var _inputB:ISkeletonAnimationState;
	
	/**
	 * Defines a fractional value between 0 and 1 representing the blending ratio between inputA (0) and inputB (1),
	 * used to produce the skeleton pose output.
	 *
	 * @see inputA
	 * @see inputB
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
	
	public function new(animator:IAnimator, skeletonAnimationNode:SkeletonBinaryLERPNode)
	{
		super(animator, skeletonAnimationNode);
		
		_skeletonAnimationNode = skeletonAnimationNode;
		
		_inputA = cast(animator.getAnimationState(_skeletonAnimationNode.inputA), ISkeletonAnimationState);
		_inputB = cast(animator.getAnimationState(_skeletonAnimationNode.inputB), ISkeletonAnimationState);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function phase(value:Float):Void
	{
		_skeletonPoseDirty = true;
		
		_positionDeltaDirty = true;
		
		_inputA.phase(value);
		_inputB.phase(value);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateTime(time:Int):Void
	{
		_skeletonPoseDirty = true;
		
		_inputA.update(time);
		_inputB.update(time);
		
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
		
		var deltA:Vector3D = _inputA.positionDelta;
		var deltB:Vector3D = _inputB.positionDelta;
		
		_rootDelta.x = deltA.x + _blendWeight*(deltB.x - deltA.x);
		_rootDelta.y = deltA.y + _blendWeight*(deltB.y - deltA.y);
		_rootDelta.z = deltA.z + _blendWeight*(deltB.z - deltA.z);
	}
	
	/**
	 * Updates the output skeleton pose of the node based on the blendWeight value between input nodes.
	 *
	 * @param skeleton The skeleton used by the animator requesting the ouput pose.
	 */
	private function updateSkeletonPose(skeleton:Skeleton):Void
	{
		_skeletonPoseDirty = false;
		
		var endPose:JointPose;
		var endPoses:Vector<JointPose> = _skeletonPose.jointPoses;
		var poses1:Vector<JointPose> = _inputA.getSkeletonPose(skeleton).jointPoses;
		var poses2:Vector<JointPose> = _inputB.getSkeletonPose(skeleton).jointPoses;
		var pose1:JointPose, pose2:JointPose;
		var p1:Vector3D, p2:Vector3D;
		var tr:Vector3D;
		var numJoints:Int = skeleton.numJoints;
		
		// :s
		if (endPoses.length != numJoints)
			endPoses.length = numJoints;
		
		for (i in 0...numJoints) {
			if (endPoses[i] == null) endPoses[i] = new JointPose();
			endPose = endPoses[i];
			pose1 = poses1[i];
			pose2 = poses2[i];
			p1 = pose1.translation;
			p2 = pose2.translation;
			
			endPose.orientation.lerp(pose1.orientation, pose2.orientation, _blendWeight);
			
			tr = endPose.translation;
			tr.x = p1.x + _blendWeight*(p2.x - p1.x);
			tr.y = p1.y + _blendWeight*(p2.y - p1.y);
			tr.z = p1.z + _blendWeight*(p2.z - p1.z);
		}
	}
}