package away3d.tools.helpers;

	import away3d.core.base.ParticleGeometry;
	import away3d.core.base.CompactSubGeometry;
	import away3d.core.base.data.ParticleData;
	import away3d.core.base.Geometry;
	import away3d.core.base.ISubGeometry;
	import away3d.tools.helpers.data.ParticleGeometryTransform;
	
	import flash.geom.Matrix;
	import away3d.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	/**
	 * ...
	 */
	class ParticleGeometryHelper
	{
		public static var MAX_VERTEX:Int = 65535;
		
		public static generateGeometry(geometries:Array<Geometry>, transforms:Array<ParticleGeometryTransform> = null):ParticleGeometry
		{
			var verticesVector:Array<Array<Float>> = new Array<Array<Float>>();
			var indicesVector:Array<Array<UInt>> = new Array<Array<UInt>>();
			var vertexCounters:Array<UInt> = new Array<UInt>();
			var particles:Array<ParticleData> = new Array<ParticleData>();
			var subGeometries:Array<CompactSubGeometry> = new Array<CompactSubGeometry>();
			var numParticles:UInt = geometries.length;
			
			var sourceSubGeometries:Array<ISubGeometry>;
			var sourceSubGeometry:ISubGeometry;
			var numSubGeometries:UInt;
			var vertices:Array<Float>;
			var indices:Array<UInt>;
			var vertexCounter:UInt;
			var subGeometry:CompactSubGeometry;
			var i:Int;
			var j:Int;
			var sub2SubMap:Array<Int> = new Array<Int>;
			
			var tempVertex:Vector3D = new Vector3D;
			var tempNormal:Vector3D = new Vector3D;
			var tempTangents:Vector3D = new Vector3D;
			var tempUV:Point = new Point;
			
			// For loop conversion - 						for (i = 0; i < numParticles; i++)
			
			for (i in 0...numParticles) {
				sourceSubGeometries = geometries[i].subGeometries;
				numSubGeometries = sourceSubGeometries.length;
				// For loop conversion - 				for (var srcIndex:Int = 0; srcIndex < numSubGeometries; srcIndex++)
				var srcIndex:Int;
				for (srcIndex in 0...numSubGeometries) {
					//create a different particle subgeometry group for each source subgeometry in a particle.
					if (sub2SubMap.length <= srcIndex) {
						sub2SubMap.push(subGeometries.length);
						verticesVector.push(new Array<Float>);
						indicesVector.push(new Array<UInt>);
						subGeometries.push(new CompactSubGeometry());
						vertexCounters.push(0);
					}
					
					sourceSubGeometry = sourceSubGeometries[srcIndex];
					
					//add a new particle subgeometry if this source subgeometry will take us over the maxvertex limit
					if (sourceSubGeometry.numVertices + vertexCounters[sub2SubMap[srcIndex]] > MAX_VERTEX) {
						//update submap and add new subgeom vectors
						sub2SubMap[srcIndex] = subGeometries.length;
						verticesVector.push(new Array<Float>);
						indicesVector.push(new Array<UInt>);
						subGeometries.push(new CompactSubGeometry());
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
					var tempLen:Int;
					var compact:CompactSubGeometry = sourceSubGeometry as CompactSubGeometry;
					var product:UInt;
					var sourceVertices:Array<Float>;
					
					if (compact) {
						tempLen = compact.numVertices;
						compact.numTriangles;
						sourceVertices = compact.vertexData;
						
						if (transforms) {
							var particleGeometryTransform:ParticleGeometryTransform = transforms[i];
							var vertexTransform:Matrix3D = particleGeometryTransform.vertexTransform;
							var invVertexTransform:Matrix3D = particleGeometryTransform.invVertexTransform;
							var UVTransform:Matrix = particleGeometryTransform.UVTransform;
							
							// For loop conversion - 														for (k = 0; k < tempLen; k++)
							
							for (k in 0...tempLen) {
								/*
								 * 0 - 2: vertex position X, Y, Z
								 * 3 - 5: normal X, Y, Z
								 * 6 - 8: tangent X, Y, Z
								 * 9 - 10: U V
								 * 11 - 12: Secondary U V*/
								product = k*13;
								tempVertex.x = sourceVertices[product];
								tempVertex.y = sourceVertices[product + 1];
								tempVertex.z = sourceVertices[product + 2];
								tempNormal.x = sourceVertices[product + 3];
								tempNormal.y = sourceVertices[product + 4];
								tempNormal.z = sourceVertices[product + 5];
								tempTangents.x = sourceVertices[product + 6];
								tempTangents.y = sourceVertices[product + 7];
								tempTangents.z = sourceVertices[product + 8];
								tempUV.x = sourceVertices[product + 9];
								tempUV.y = sourceVertices[product + 10];
								if (vertexTransform) {
									tempVertex = vertexTransform.transformVector(tempVertex);
									tempNormal = invVertexTransform.deltaTransformVector(tempNormal);
									tempTangents = invVertexTransform.deltaTransformVector(tempNormal);
								}
								if (UVTransform)
									tempUV = UVTransform.transformPoint(tempUV);
								//this is faster than that only push one data
								vertices.push(tempVertex.x, tempVertex.y, tempVertex.z, tempNormal.x,
									tempNormal.y, tempNormal.z, tempTangents.x, tempTangents.y,
									tempTangents.z, tempUV.x, tempUV.y, sourceVertices[product + 11],
									sourceVertices[product + 12]);
							}
						} else {
							// For loop conversion - 							for (k = 0; k < tempLen; k++)
							for (k in 0...tempLen) {
								product = k*13;
								//this is faster than that only push one data
								vertices.push(sourceVertices[product], sourceVertices[product + 1], sourceVertices[product + 2], sourceVertices[product + 3],
									sourceVertices[product + 4], sourceVertices[product + 5], sourceVertices[product + 6], sourceVertices[product + 7],
									sourceVertices[product + 8], sourceVertices[product + 9], sourceVertices[product + 10], sourceVertices[product + 11],
									sourceVertices[product + 12]);
							}
						}
					} else {
						//Todo
					}
					
					var sourceIndices:Array<UInt> = sourceSubGeometry.indexData;
					tempLen = sourceSubGeometry.numTriangles;
					// For loop conversion - 					for (k = 0; k < tempLen; k++)
					for (k in 0...tempLen) {
						product = k*3;
						indices.push(sourceIndices[product] + vertexCounter, sourceIndices[product + 1] + vertexCounter, sourceIndices[product + 2] + vertexCounter);
					}
				}
			}
			
			var particleGeometry:ParticleGeometry = new ParticleGeometry();
			particleGeometry.particles = particles;
			particleGeometry.numParticles = numParticles;
			
			numParticles = subGeometries.length;
			// For loop conversion - 			for (i = 0; i < numParticles; i++)
			for (i in 0...numParticles) {
				subGeometry = subGeometries[i];
				subGeometry.updateData(verticesVector[i]);
				subGeometry.updateIndexData(indicesVector[i]);
				particleGeometry.addSubGeometry(subGeometry);
			}
			
			return particleGeometry;
		}
	}


