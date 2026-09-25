package away3d.tools.helpers;

import away3d.core.base.ParticleGeometry;
import away3d.core.base.CompactSubGeometry;
import away3d.core.base.data.ParticleData;
import away3d.core.base.data.VertexDefinition;
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
	
	public static function generateGeometry(geometries:Vector<Geometry>, transforms:Vector<ParticleGeometryTransform> = null, ?vertexDefinition:VertexDefinition):ParticleGeometry
	{
		var verticesVector:Vector<Vector<Float>> = new Vector<Vector<Float>>();
		var indicesVector:Vector<Vector<UInt>> = new Vector<Vector<UInt>>();
		var vertexCounters:Vector<UInt> = new Vector<UInt>();
		var particles:Vector<ParticleData> = new Vector<ParticleData>();
		var subGeometries:Vector<CompactSubGeometry> = new Vector<CompactSubGeometry>();
		var numParticles:Int = geometries.length;
		
		var sourceSubGeometries:Vector<ISubGeometry>;
		var sourceSubGeometry:ISubGeometry;
		var numSubGeometries:Int;
		var vertices:Vector<Float>;
		var indices:Vector<UInt>;
		var vertexCounter:Int;
		var subGeometry:CompactSubGeometry;
		var i:Int;
		var j:Int;
		var sub2SubMap:Vector<Int> = new Vector<Int>();
		
		var tempVertex:Vector3D = new Vector3D();
		var tempNormal:Vector3D = new Vector3D();
		var tempTangents:Vector3D = new Vector3D();
		var tempUV:Point = new Point();
		
		var positionDefinition:AttributeDefinition = vertexDefinition.get("position");
		var normalDefinition:AttributeDefinition = vertexDefinition.get("normal");
		var tangentDefinition:AttributeDefinition = vertexDefinition.get("tangent");
		var uvDefinition:AttributeDefinition = vertexDefinition.get("UV");
		
		for (i in 0...numParticles) {
			sourceSubGeometries = geometries[i].subGeometries;
			numSubGeometries = sourceSubGeometries.length;
			for (srcIndex in 0...numSubGeometries) {
				//create a different particle subgeometry group for each source subgeometry in a particle.
				if (sub2SubMap.length <= srcIndex) {
					sub2SubMap.push(subGeometries.length);
					verticesVector.push(new Vector<Float>());
					indicesVector.push(new Vector<UInt>());
					subGeometries.push(new CompactSubGeometry(vertexDefinition));
					vertexCounters.push(0);
				}
				
				sourceSubGeometry = sourceSubGeometries[srcIndex];
				
				//add a new particle subgeometry if this source subgeometry will take us over the maxvertex limit
				if (Std.int(sourceSubGeometry.numVertices + vertexCounters[sub2SubMap[srcIndex]]) > MAX_VERTEX) {
					//update submap and add new subgeom vectors
					sub2SubMap[srcIndex] = subGeometries.length;
					verticesVector.push(new Vector<Float>());
					indicesVector.push(new Vector<UInt>());
					subGeometries.push(new CompactSubGeometry(vertexDefinition));
					vertexCounters.push(0);
				}
				
				j = sub2SubMap[srcIndex];
				
				//select the correct vector
				vertices = verticesVector[j];
				indices = indicesVector[j];
				vertexCounter = vertexCounters[j];
				subGeometry = subGeometries[j];
				
				var particleData:ParticleData = new ParticleData();
				particleData.numVertices = sourceSubGeometry.numVertices;
				particleData.startVertexIndex = vertexCounter;
				particleData.particleIndex = i;
				particleData.subGeometry = subGeometry;
				particles.push(particleData);
				
				vertexCounters[j] += sourceSubGeometry.numVertices;
				
				var k:Int;
				var compact:CompactSubGeometry = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(sourceSubGeometry, CompactSubGeometry) ? cast sourceSubGeometry : null;
				var product:Int;
				var sourceVertices:Vector<Float>;
				var attributesDone:Array<String> = [];
				
				var inStride:Int = compact.definition.length;
				var outStride:Int = subGeometry.definition.length;
				var startIndex:Int = vertices.length;
				vertices.length += outStride * compact.numVertices;
				
				if (compact != null) {
					compact.numTriangles;
					sourceVertices = compact.vertexData;
					
					if (transforms != null) {
						var particleGeometryTransform:ParticleGeometryTransform = transforms[i];
						var vertexTransform:Matrix3D = particleGeometryTransform.vertexTransform;
						var invVertexTransform:Matrix3D = particleGeometryTransform.invVertexTransform;
						var UVTransform:Matrix = particleGeometryTransform.UVTransform;
						
						var inPositionDefinition:AttributeDefinition = compact.definition.get("position");
						var inNormalDefinition:AttributeDefinition = compact.definition.get("normal");
						var inTangentDefinition:AttributeDefinition = compact.definition.get("tangent");
						var inUVDefinition:AttributeDefinition = compact.definition.get("UV");
						
						for (k in 0...compact.numVertices) {
							product = k*compact.definition.length;
							
							if (inPositionDefinition != null && positionDefinition != null && vertexTransform != null) {
								tempVertex.x = sourceVertices[product + inPositionDefinition.offset];
								tempVertex.y = sourceVertices[product + inPositionDefinition.offset + 1];
								tempVertex.z = sourceVertices[product + inPositionDefinition.offset + 2];
								#if flash
								tempVertex = vertexTransform.transformVector(tempVertex);
								#else
								vertexTransform.transformVectorToOutput(tempVertex, tempVertex);
								#end
								vertices[startIndex + k * vertexDefinition.length + positionDefinition.offset] = tempVertex.x;
								vertices[startIndex + k * vertexDefinition.length + positionDefinition.offset + 1] = tempVertex.y;
								vertices[startIndex + k * vertexDefinition.length + positionDefinition.offset + 2] = tempVertex.z;
								
								attributesDone.push("position");
							}
							
							if (inNormalDefinition != null && normalDefinition != null && vertexTransform != null) {
								tempNormal.x = sourceVertices[product + inNormalDefinition.offset];
								tempNormal.y = sourceVertices[product + inNormalDefinition.offset + 1];
								tempNormal.z = sourceVertices[product + inNormalDefinition.offset + 2];
								#if flash
								tempNormal = invVertexTransform.deltaTransformVector(tempNormal);
								#else
								invVertexTransform.deltaTransformVectorToOutput(tempNormal, tempNormal);
								#end
								vertices[startIndex + k * vertexDefinition.length + normalDefinition.offset] = tempNormal.x;
								vertices[startIndex + k * vertexDefinition.length + normalDefinition.offset + 1] = tempNormal.y;
								vertices[startIndex + k * vertexDefinition.length + normalDefinition.offset + 2] = tempNormal.z;
								
								attributesDone.push("normal");
							}
							
							if (inTangentDefinition != null && tangentDefinition != null && vertexTransform != null) {
								tempTangents.x = sourceVertices[product + inTangentDefinition.offset];
								tempTangents.y = sourceVertices[product + inTangentDefinition.offset + 1];
								tempTangents.z = sourceVertices[product + inTangentDefinition.offset + 2];
								#if flash
								tempTangents = invVertexTransform.deltaTransformVector(tempTangents);
								#else
								invVertexTransform.deltaTransformVectorToOutput(tempTangents, tempTangents);
								#end
								vertices[startIndex + k * vertexDefinition.length + tangentDefinition.offset] = tempTangents.x;
								vertices[startIndex + k * vertexDefinition.length + tangentDefinition.offset + 1] = tempTangents.y;
								vertices[startIndex + k * vertexDefinition.length + tangentDefinition.offset + 2] = tempTangents.z;
								
								attributesDone.push("tangent");
							}
							
							if (inUVDefinition != null && uvDefinition != null && UVTransform != null) {
								tempUV.x = sourceVertices[product + inUVDefinition.offset];
								tempUV.y = sourceVertices[product + inUVDefinition.offset + 1];
								#if flash
								tempUV = UVTransform.transformPoint(tempUV);
								#else
								UVTransform.transformPointToOutput(tempUV, tempUV);
								#end
								vertices[startIndex + k * vertexDefinition.length + uvDefinition.offset] = tempUV.x;
								vertices[startIndex + k * vertexDefinition.length + uvDefinition.offset + 1] = tempUV.y;
								
								attributesDone.push("UV");
							}
						}
					}
					
					for (outAttribute in subGeometry.definition.attributes) {
						if (attributesDone.indexOf(outAttribute.name) >= 0) {
							continue;
						}
						
						var sourceAttribute:AttributeDefinition = compact.definition.get(outAttribute.name);
						
						if (sourceAttribute == null) {
							throw 'Input data does not include attribute "${ outAttribute.name }". It defines "'
								+ [for(attribute in compact.definition.attributes) attribute.name].join('", "') + '".';
						}
						
						if (outAttribute.length != sourceAttribute.length) {
							throw 'Length mismatch for attribute "${ outAttribute.name }": source has length ${ sourceAttribute.length }, destination needs length ${ outAttribute.name }.';
						}
						
						var length:Int = outAttribute.length;
						var inOffset:Int = sourceAttribute.offset;
						var outOffset:Int = outAttribute.offset;
						
						for (k in 0...compact.numVertices) {
							for (l in 0...length) {
								vertices[startIndex + k * outStride + outOffset + l] = sourceVertices[k * inStride + inOffset + l];
							}
						}
					}
				} else {
					//Todo
				}
				
				var sourceIndices:Vector<UInt> = sourceSubGeometry.indexData;
				for (k in 0...sourceSubGeometry.numTriangles) {
					product = k*3;
					indices.push(sourceIndices[product] + vertexCounter);
					indices.push(sourceIndices[product + 1] + vertexCounter);
					indices.push(sourceIndices[product + 2] + vertexCounter);
				}
			}
		}
		
		var particleGeometry:ParticleGeometry = new ParticleGeometry();
		particleGeometry.particles = particles;
		particleGeometry.numParticles = numParticles;
		
		for (i in 0...subGeometries.length) {
			subGeometry = subGeometries[i];
			subGeometry.updateData(verticesVector[i]);
			subGeometry.updateIndexData(indicesVector[i]);
			particleGeometry.addSubGeometry(subGeometry);
		}
		
		return particleGeometry;
	}
}