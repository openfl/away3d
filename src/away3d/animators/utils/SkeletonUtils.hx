package away3d.animators.utils;

	//import away3d.arcane;
	import away3d.animators.data.*;
	import away3d.animators.nodes.*;
	
	import flash.geom.*;
	
	//use namespace arcane;
	
	class SkeletonUtils
	{
		public static generateDifferenceClip(source:SkeletonClipNode, referencePose:SkeletonPose):SkeletonClipNode
		{
			var diff:SkeletonClipNode = new SkeletonClipNode();
			var numFrames:UInt = source.frames.length;
			
			// For loop conversion - 						for (var i:UInt = 0; i < numFrames; ++i)
			
			var i:UInt = 0;
			
			for (i in 0...numFrames)
				diff.addFrame(generateDifferencePose(source.frames[i], referencePose), source.durations[i]);
			
			return diff;
		}
		
		public static generateDifferencePose(source:SkeletonPose, reference:SkeletonPose):SkeletonPose
		{
			if (source.numJointPoses != reference.numJointPoses)
				throw new Error("joint counts don't match!");
			
			var numJoints:UInt = source.numJointPoses;
			var diff:SkeletonPose = new SkeletonPose();
			var srcPose:JointPose;
			var refPose:JointPose;
			var diffPose:JointPose;
			var mtx:Matrix3D = new Matrix3D();
			var tempMtx:Matrix3D = new Matrix3D();
			var vec:Array<Vector3D>;
			
			// For loop conversion - 						for (var i:Int = 0; i < numJoints; ++i)
			
			var i:Int;
			
			for (i in 0...numJoints) {
				srcPose = source.jointPoses[i];
				refPose = reference.jointPoses[i];
				diffPose = new JointPose();
				diff.jointPoses[i] = diffPose;
				diffPose.name = srcPose.name;
				
				refPose.toMatrix3D(mtx);
				mtx.invert();
				mtx.append(srcPose.toMatrix3D(tempMtx));
				vec = mtx.decompose(Orientation3D.QUATERNION);
				diffPose.translation.copyFrom(vec[0]);
				diffPose.orientation.x = vec[1].x;
				diffPose.orientation.y = vec[1].y;
				diffPose.orientation.z = vec[1].z;
				diffPose.orientation.w = vec[1].w;
			}
			
			return diff;
		}
	}

