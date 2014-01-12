package away3d.tools.serialize;

	import away3d.animators.IAnimator;
	import away3d.animators.data.JointPose;
	import away3d.animators.data.Skeleton;
	import away3d.animators.data.SkeletonJoint;
	import away3d.animators.data.SkeletonPose;
	//import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.core.base.ISubGeometry;
	import away3d.core.base.SkinnedSubGeometry;
	import away3d.core.base.SubMesh;
	import away3d.entities.Mesh;
	import away3d.materials.MaterialBase;
	import away3d.materials.lightpickers.StaticLightPicker;
	
	import flash.utils.getQualifiedClassName;
	
	//use namespace arcane;
	
	class Serialize
	{
		public static var tabSize:UInt = 2;
		
		public function new()
		{
		}
		
		public static serializeScene(scene:Scene3D, serializer:SerializerBase):Void
		{
			// For loop conversion - 			for (var i:UInt = 0; i < scene.numChildren; i++)
			var i:UInt = 0;
			for (i in 0...scene.numChildren)
				serializeObjectContainer(scene.getChildAt(i), serializer);
		}
		
		public static serializeObjectContainer(objectContainer3D:ObjectContainer3D, serializer:SerializerBase):Void
		{
			if (objectContainer3D is Mesh)
				serializeMesh(objectContainer3D as Mesh, serializer); // do not indent any extra for first level here
			else
				serializeObjectContainerInternal(objectContainer3D, serializer, true /* serializeChildrenAndEnd */);
		}
		
		public static serializeMesh(mesh:Mesh, serializer:SerializerBase):Void
		{
			serializeObjectContainerInternal(mesh as ObjectContainer3D, serializer, false /* serializeChildrenAndEnd */);
			serializer.writeBoolean("castsShadows", mesh.castsShadows);
			
			if (mesh.animator)
				serializeAnimationState(mesh.animator, serializer);
			
			if (mesh.material)
				serializeMaterial(mesh.material, serializer);
			
			if (mesh.subMeshes.length) {
				for each (var subMesh:SubMesh in mesh.subMeshes)
					serializeSubMesh(subMesh, serializer);
			}
			serializeChildren(mesh as ObjectContainer3D, serializer);
			serializer.endObject();
		}
		
		public static serializeAnimationState(animator:IAnimator, serializer:SerializerBase):Void
		{
			serializer.beginObject(classNameFromInstance(animator), null);
			serializeAnimator(animator, serializer);
			serializer.endObject();
		}
		
		public static serializeAnimator(animator:IAnimator, serializer:SerializerBase):Void
		{
			serializer.beginObject(classNameFromInstance(animator), null);
			serializer.endObject();
		}
		
		public static serializeSubMesh(subMesh:SubMesh, serializer:SerializerBase):Void
		{
			serializer.beginObject(classNameFromInstance(subMesh), null);
			if (subMesh.material)
				serializeMaterial(subMesh.material, serializer);
			if (subMesh.subGeometry)
				serializeSubGeometry(subMesh.subGeometry, serializer);
			serializer.endObject();
		}
		
		public static serializeMaterial(material:MaterialBase, serializer:SerializerBase):Void
		{
			serializer.beginObject(classNameFromInstance(material), material.name);
			
			if (material.lightPicker is StaticLightPicker)
				serializer.writeString("lights", String(StaticLightPicker(material.lightPicker).lights));
			serializer.writeBoolean("mipmap", material.mipmap);
			serializer.writeBoolean("smooth", material.smooth);
			serializer.writeBoolean("repeat", material.repeat);
			serializer.writeBoolean("bothSides", material.bothSides);
			serializer.writeString("blendMode", material.blendMode);
			serializer.writeBoolean("requiresBlending", material.requiresBlending);
			serializer.writeUint("uniqueId", material.uniqueId);
			serializer.writeUint("numPasses", material.numPasses);
			serializer.endObject();
		}
		
		public static serializeSubGeometry(subGeometry:ISubGeometry, serializer:SerializerBase):Void
		{
			serializer.beginObject(classNameFromInstance(subGeometry), null);
			serializer.writeUint("numTriangles", subGeometry.numTriangles);
			if (subGeometry.indexData)
				serializer.writeUint("numIndices", subGeometry.indexData.length);
			serializer.writeUint("numVertices", subGeometry.numVertices);
			if (subGeometry.UVData)
				serializer.writeUint("numUVs", subGeometry.UVData.length);
			var skinnedSubGeometry:SkinnedSubGeometry = subGeometry as SkinnedSubGeometry;
			if (skinnedSubGeometry) {
				if (skinnedSubGeometry.jointWeightsData)
					serializer.writeUint("numJointWeights", skinnedSubGeometry.jointWeightsData.length);
				if (skinnedSubGeometry.jointIndexData)
					serializer.writeUint("numJointIndexes", skinnedSubGeometry.jointIndexData.length);
			}
			serializer.endObject();
		}
		
		public static serializeSkeletonJoint(skeletonJoint:SkeletonJoint, serializer:SerializerBase):Void
		{
			serializer.beginObject(classNameFromInstance(skeletonJoint), skeletonJoint.name);
			serializer.writeInt("parentIndex", skeletonJoint.parentIndex);
			serializer.writeTransform("inverseBindPose", skeletonJoint.inverseBindPose);
			serializer.endObject();
		}
		
		public static serializeSkeleton(skeleton:Skeleton, serializer:SerializerBase):Void
		{
			serializer.beginObject(classNameFromInstance(skeleton), skeleton.name);
			for each (var skeletonJoint:SkeletonJoint in skeleton.joints)
				serializeSkeletonJoint(skeletonJoint, serializer);
			serializer.endObject();
		}
		
		public static serializeJointPose(jointPose:JointPose, serializer:SerializerBase):Void
		{
			serializer.beginObject(classNameFromInstance(jointPose), jointPose.name);
			serializer.writeVector3D("translation", jointPose.translation);
			serializer.writeQuaternion("orientation", jointPose.orientation);
			serializer.endObject();
		}
		
		public static serializeSkeletonPose(skeletonPose:SkeletonPose, serializer:SerializerBase):Void
		{
			serializer.beginObject(classNameFromInstance(skeletonPose), "" /*skeletonPose.name*/);
			serializer.writeUint("numJointPoses", skeletonPose.numJointPoses);
			for each (var jointPose:JointPose in skeletonPose.jointPoses)
				serializeJointPose(jointPose, serializer);
			serializer.endObject();
		}
		
		// private stuff - shouldn't ever need to call externally
		
		private static function serializeChildren(parent:ObjectContainer3D, serializer:SerializerBase):Void
		{
			// For loop conversion - 			for (var i:UInt = 0; i < parent.numChildren; i++)
			var i:UInt = 0;
			for (i in 0...parent.numChildren)
				serializeObjectContainer(parent.getChildAt(i), serializer);
		}
		
		private static function classNameFromInstance(instance:Dynamic):String
		{
			return getQualifiedClassName(instance).split("::").pop();
		}
		
		private static function serializeObjectContainerInternal(objectContainer:ObjectContainer3D, serializer:SerializerBase, serializeChildrenAndEnd:Bool):Void
		{
			serializer.beginObject(classNameFromInstance(objectContainer), objectContainer.name);
			serializer.writeTransform("transform", objectContainer.transform.rawData);
			if (serializeChildrenAndEnd) {
				serializeChildren(objectContainer, serializer);
				serializer.endObject();
			}
		}
	}

