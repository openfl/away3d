package away3d.animators.states;


import away3d.animators.data.SkeletonPose;
import away3d.animators.data.Skeleton;
interface ISkeletonAnimationState extends IAnimationState {

/**
	 * Returns the output skeleton pose of the animation node.
	 */
    function getSkeletonPose(skeleton:Skeleton):SkeletonPose;
}

