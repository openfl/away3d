package away3d.animators.data;

import away3d.library.assets.*;

import openfl.Vector;

/**
 * A collection of pose objects, determining the pose for an entire skeleton.
 * The <code>jointPoses</code> vector object corresponds to a skeleton's <code>joints</code> vector object, however, there is no
 * reference to a skeleton's instance, since several skeletons can be influenced by the same pose (eg: animation
 * clips are added to any animator with a valid skeleton)
 *
 * @see away3d.animators.data.Skeleton
 * @see away3d.animators.data.JointPose
 */
class SkeletonPose extends NamedAssetBase implements IAsset
{
	public var numJointPoses(get, never):Int;
	public var assetType(get, never):String;
	
	/**
	 * A flat list of pose objects that comprise the skeleton pose. The pose indices correspond to the target skeleton's joint indices.
	 *
	 * @see away3d.animators.data.Skeleton#joints
	 */
	public var jointPoses:Vector<JointPose>;
	
	/**
	 * The total number of joint poses in the skeleton pose.
	 */
	private function get_numJointPoses():Int
	{
		return jointPoses.length;
	}
	
	/**
	 * Creates a new <code>SkeletonPose</code> object.
	 */
	public function new()
	{
		jointPoses = new Vector<JointPose>();
		super();
	}
	
	/**
	 * @inheritDoc
	 */
	private function get_assetType():String
	{
		return Asset3DType.SKELETON_POSE;
	}
	
	/**
	 * Returns the joint pose object with the given joint name, otherwise returns a null object.
	 *
	 * @param jointName The name of the joint object whose pose is to be found.
	 * @return The pose object with the given joint name.
	 */
	public function jointPoseFromName(jointName:String):JointPose
	{
		var jointPoseIndex:Int = jointPoseIndexFromName(jointName);
		if (jointPoseIndex != -1)
			return jointPoses[jointPoseIndex]
		else return null;
	}
	
	/**
	 * Returns the pose index, given the joint name. -1 is returned if the joint name is not found in the pose.
	 *
	 * @param The name of the joint object whose pose is to be found.
	 * @return The index of the pose object in the jointPoses vector.
	 *
	 * @see #jointPoses
	 */
	public function jointPoseIndexFromName(jointName:String):Int
	{
		// this function is implemented as a linear search, rather than a possibly
		// more optimal method (Dictionary lookup, for example) because:
		// a) it is assumed that it will be called once for each joint
		// b) it is assumed that it will be called only during load, and not during main loop
		// c) maintaining a dictionary (for safety) would dictate an interface to access JointPoses,
		//    rather than direct array access.  this would be sub-optimal.
		var jointPoseIndex:Int = 0;
		for (jointPose in jointPoses) {
			if (jointPose.name == jointName)
				return jointPoseIndex;
			jointPoseIndex++;
		}
		
		return -1;
	}
	
	/**
	 * Creates a copy of the <code>SkeletonPose</code> object, with a dulpicate of its component joint poses.
	 *
	 * @return SkeletonPose
	 */
	public function clone():SkeletonPose
	{
		var clone:SkeletonPose = new SkeletonPose();
		var numJointPoses:Int = this.jointPoses.length;
		for (i in 0...numJointPoses) {
			var cloneJointPose:JointPose = new JointPose();
			var thisJointPose:JointPose = this.jointPoses[i];
			cloneJointPose.name = thisJointPose.name;
			cloneJointPose.copyFrom(thisJointPose);
			clone.jointPoses[i] = cloneJointPose;
		}
		return clone;
	}
	
	/**
	 * @inheritDoc
	 */
	public function dispose():Void
	{
		jointPoses.length = 0;
	}
}