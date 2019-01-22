package away3d.animators.states;

import away3d.animators.*;
import away3d.animators.data.*;
import away3d.animators.nodes.*;
import away3d.core.math.*;

import openfl.geom.*;
import openfl.Vector;

/**
 *
 */
class SkeletonNaryLERPState extends AnimationStateBase implements ISkeletonAnimationState
{
	private var _skeletonAnimationNode:SkeletonNaryLERPNode;
	private var _skeletonPose:SkeletonPose = new SkeletonPose();
	private var _skeletonPoseDirty:Bool = true;
	private var _blendWeights:Vector<Float> = new Vector<Float>();
	private var _inputs:Vector<ISkeletonAnimationState> = new Vector<ISkeletonAnimationState>();
	
	public function new(animator:IAnimator, skeletonAnimationNode:SkeletonNaryLERPNode)
	{
		super(animator, skeletonAnimationNode);
		
		_skeletonAnimationNode = skeletonAnimationNode;
		
		var i:Int = _skeletonAnimationNode.numInputs;
		
		while (i-- > 0)
			_inputs[i] = cast(animator.getAnimationState(_skeletonAnimationNode._inputs[i]), ISkeletonAnimationState);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function phase(value:Float):Void
	{
		_skeletonPoseDirty = true;
		
		_positionDeltaDirty = true;
		
		for (j in 0..._skeletonAnimationNode.numInputs) {
			if (_blendWeights[j] > 0) 
				_inputs[j].update(Std.int(value));
		}
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateTime(time:Int):Void
	{
		for (j in 0..._skeletonAnimationNode.numInputs) {
			if (_blendWeights[j] > 0) 
				_inputs[j].update(time);
		}
		
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
	 * Returns the blend weight of the skeleton aniamtion node that resides at the given input index.
	 *
	 * @param index The input index for which the skeleton animation node blend weight is requested.
	 */
	public function getBlendWeightAt(index:Int):Float
	{
		return _blendWeights[index];
	}
	
	/**
	 * Sets the blend weight of the skeleton aniamtion node that resides at the given input index.
	 *
	 * @param index The input index on which the skeleton animation node blend weight is to be set.
	 * @param blendWeight The blend weight value to use for the given skeleton animation node index.
	 */
	public function setBlendWeightAt(index:Int, blendWeight:Float):Void
	{
		_blendWeights[index] = blendWeight;
		
		_positionDeltaDirty = true;
		_skeletonPoseDirty = true;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updatePositionDelta():Void
	{
		_positionDeltaDirty = false;
		
		var delta:Vector3D;
		var weight:Float;
		
		positionDelta.x = 0;
		positionDelta.y = 0;
		positionDelta.z = 0;
		
		for (j in 0..._skeletonAnimationNode.numInputs) {
			weight = _blendWeights[j];
			
			if (weight > 0) {
				delta = _inputs[j].positionDelta;
				positionDelta.x += weight*delta.x;
				positionDelta.y += weight*delta.y;
				positionDelta.z += weight*delta.z;
			}
		}
	}
	
	/**
	 * Updates the output skeleton pose of the node based on the blend weight values given to the input nodes.
	 *
	 * @param skeleton The skeleton used by the animator requesting the ouput pose.
	 */
	private function updateSkeletonPose(skeleton:Skeleton):Void
	{
		_skeletonPoseDirty = false;
		
		var weight:Float;
		var endPoses:Vector<JointPose> = _skeletonPose.jointPoses;
		var poses:Vector<JointPose>;
		var endPose:JointPose, pose:JointPose;
		var endTr:Vector3D, tr:Vector3D;
		var endQuat:Quaternion, q:Quaternion;
		var firstPose:Vector<JointPose> = null;
		var i:Int;
		var w0:Float, x0:Float, y0:Float, z0:Float;
		var w1:Float, x1:Float, y1:Float, z1:Float;
		var numJoints:Int = skeleton.numJoints;
		
		// :s
		if (endPoses.length != numJoints)
			endPoses.length = numJoints;
		
		for (j in 0..._skeletonAnimationNode.numInputs) {
			weight = _blendWeights[j];
			
			if (weight == 0)
				continue;
			
			poses = _inputs[j].getSkeletonPose(skeleton).jointPoses;
			
			if (firstPose == null) {
				firstPose = poses;
				for (i in 0...numJoints) {
					if (endPoses[i] == null) 
						endPoses[i] = new JointPose();
					
					endPose = endPoses[i];
					pose = poses[i];
					q = pose.orientation;
					tr = pose.translation;
					
					endQuat = endPose.orientation;
					
					endQuat.x = weight*q.x;
					endQuat.y = weight*q.y;
					endQuat.z = weight*q.z;
					endQuat.w = weight*q.w;
					
					endTr = endPose.translation;
					endTr.x = weight*tr.x;
					endTr.y = weight*tr.y;
					endTr.z = weight*tr.z;
				}
			} else {
				for (i in 0...skeleton.numJoints) {
					endPose = endPoses[i];
					pose = poses[i];
					
					q = firstPose[i].orientation;
					x0 = q.x;
					y0 = q.y;
					z0 = q.z;
					w0 = q.w;
					
					q = pose.orientation;
					tr = pose.translation;
					
					x1 = q.x;
					y1 = q.y;
					z1 = q.z;
					w1 = q.w;
					// find shortest direction
					if (x0*x1 + y0*y1 + z0*z1 + w0*w1 < 0) {
						x1 = -x1;
						y1 = -y1;
						z1 = -z1;
						w1 = -w1;
					}
					endQuat = endPose.orientation;
					endQuat.x += weight*x1;
					endQuat.y += weight*y1;
					endQuat.z += weight*z1;
					endQuat.w += weight*w1;
					
					endTr = endPose.translation;
					endTr.x += weight*tr.x;
					endTr.y += weight*tr.y;
					endTr.z += weight*tr.z;
				}
			}
		}
		
		for (i in 0...skeleton.numJoints)
			endPoses[i].orientation.normalize();
	}
}