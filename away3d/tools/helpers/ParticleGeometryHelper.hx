package away3d.tools.helpers;

import away3d.core.base.ParticleGeometry;
import away3d.core.base.CompactSubGeometry;
import away3d.core.base.data.ParticleData;
import away3d.core.base.Geometry;
import away3d.core.base.ISubGeometry;
import away3d.tools.helpers.data.ParticleGeometryTransform;

import openfl.geom.Matrix;
import openfl.geom.Matrix3D;
import openfl.geom.Point;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * ...
 */
class ParticleGeometryHelper
{
	public static inline var MAX_VERTEX:Int = 65535;
	
	public static function generateGeometry(geometries:Vector<Geometry>, transforms:Vector<ParticleGeometryTransform> = null):ParticleGeometry
	{
		var allBuildGroups:Vector<BuildGroup> = new Vector<BuildGroup>();
		var activeBuildGroups:Vector<BuildGroup> = new Vector<BuildGroup>();
		var particles:Vector<ParticleData> = new Vector<ParticleData>();
		
		var tempVertex:Vector3D = new Vector3D();
		var tempNormal:Vector3D = new Vector3D();
		var tempTangents:Vector3D = new Vector3D();
		var tempUV:Point = new Point();
		
		for (i in 0...geometries.length) {
			var sourceSubGeometries:Vector<ISubGeometry> = geometries[i].subGeometries;
			for (srcIndex in 0...sourceSubGeometries.length) {
				var sourceSubGeometry:ISubGeometry = sourceSubGeometries[srcIndex];
				var buildGroup:BuildGroup = activeBuildGroups[srcIndex];
				
				//Create a new particle subgeometry group for each source subgeometry,
				//or whenever a group is about to exceed MAX_VERTEX.
				if (buildGroup == null || buildGroup.vertexCount + sourceSubGeometry.numVertices > MAX_VERTEX) {
					buildGroup = {
						vertices: new Vector<Float>(),
						indices: new Vector<UInt>(),
						subGeometry: new CompactSubGeometry(),
						vertexCount: 0
					};
					allBuildGroups.push(buildGroup);
					activeBuildGroups[srcIndex] = buildGroup;
				}
				
				var particleData:ParticleData = new ParticleData();
				particleData.numVertices = sourceSubGeometry.numVertices;
				particleData.startVertexIndex = buildGroup.vertexCount;
				particleData.particleIndex = i;
				particleData.subGeometry = buildGroup.subGeometry;
				particles.push(particleData);
				
				buildGroup.vertexCount += sourceSubGeometry.numVertices;
				
				if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(sourceSubGeometry, CompactSubGeometry)) {
					var compact:CompactSubGeometry = cast sourceSubGeometry;
					var vertices:Vector<Float> = buildGroup.vertices;
					var sourceVertices:Vector<Float> = compact.vertexData;
					
					if (transforms != null) {
						var particleGeometryTransform:ParticleGeometryTransform = transforms[i];
						var vertexTransform:Matrix3D = particleGeometryTransform.vertexTransform;
						var invVertexTransform:Matrix3D = particleGeometryTransform.invVertexTransform;
						var UVTransform:Matrix = particleGeometryTransform.UVTransform;
						
						for (k in 0...compact.numVertices) {
							/*
							 * 0 - 2: vertex position X, Y, Z
							 * 3 - 5: normal X, Y, Z
							 * 6 - 8: tangent X, Y, Z
							 * 9 - 10: U V
							 * 11 - 12: Secondary U V*/
							var index:Int = k*13;
							tempVertex.x = sourceVertices[index];
							tempVertex.y = sourceVertices[index + 1];
							tempVertex.z = sourceVertices[index + 2];
							tempNormal.x = sourceVertices[index + 3];
							tempNormal.y = sourceVertices[index + 4];
							tempNormal.z = sourceVertices[index + 5];
							tempTangents.x = sourceVertices[index + 6];
							tempTangents.y = sourceVertices[index + 7];
							tempTangents.z = sourceVertices[index + 8];
							tempUV.x = sourceVertices[index + 9];
							tempUV.y = sourceVertices[index + 10];
							if (vertexTransform != null) {
								tempVertex = vertexTransform.transformVector(tempVertex);
								tempNormal = invVertexTransform.deltaTransformVector(tempNormal);
								tempTangents = invVertexTransform.deltaTransformVector(tempNormal);
							}
							if (UVTransform != null)
								tempUV = UVTransform.transformPoint(tempUV);
							//This is faster than `concat()`.
							vertices.push(tempVertex.x);
							vertices.push(tempVertex.y);
							vertices.push(tempVertex.z);
							vertices.push(tempNormal.x);
							vertices.push(tempNormal.y);
							vertices.push(tempNormal.z);
							vertices.push(tempTangents.x);
							vertices.push(tempTangents.y);
							vertices.push(tempTangents.z);
							vertices.push(tempUV.x);
							vertices.push(tempUV.y);
							vertices.push(sourceVertices[index + 11]);
							vertices.push(sourceVertices[index + 12]);
						}
					} else {
						for (k in 0...compact.numVertices) {
							var index:Int = k*13;
							//This is faster than `concat()`.
							vertices.push(sourceVertices[index]);
							vertices.push(sourceVertices[index + 1]);
							vertices.push(sourceVertices[index + 2]);
							vertices.push(sourceVertices[index + 3]);
							vertices.push(sourceVertices[index + 4]);
							vertices.push(sourceVertices[index + 5]);
							vertices.push(sourceVertices[index + 6]);
							vertices.push(sourceVertices[index + 7]);
							vertices.push(sourceVertices[index + 8]);
							vertices.push(sourceVertices[index + 9]);
							vertices.push(sourceVertices[index + 10]);
							vertices.push(sourceVertices[index + 11]);
							vertices.push(sourceVertices[index + 12]);
						}
					}
				} else {
					//Todo
				}
				
				var indices:Vector<UInt> = buildGroup.indices;
				var sourceIndices:Vector<UInt> = sourceSubGeometry.indexData;
				var vertexCount:Int = buildGroup.vertexCount;
				for (k in 0...sourceSubGeometry.numTriangles) {
					var index:Int = k*3;
					indices.push(sourceIndices[index] + vertexCount);
					indices.push(sourceIndices[index + 1] + vertexCount);
					indices.push(sourceIndices[index + 2] + vertexCount);
				}
			}
		}
		
		var particleGeometry:ParticleGeometry = new ParticleGeometry();
		particleGeometry.particles = particles;
		particleGeometry.numParticles = geometries.length;
		
		for (buildGroup in allBuildGroups) {
			var subGeometry:CompactSubGeometry = buildGroup.subGeometry;
			subGeometry.updateData(buildGroup.vertices);
			subGeometry.updateIndexData(buildGroup.indices);
			particleGeometry.addSubGeometry(subGeometry);
		}
		
		return particleGeometry;
	}
}

private typedef BuildGroup = {
	var vertices:Vector<Float>;
	var indices:Vector<UInt>;
	var subGeometry:CompactSubGeometry;
	var vertexCount:Int;
};
