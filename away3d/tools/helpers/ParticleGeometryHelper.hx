/**
 * ...
 */
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

class ParticleGeometryHelper {

    static public var MAX_VERTEX:Int = 65535;

    static public function generateGeometry(geometries:Array<Geometry>, transforms:Array<ParticleGeometryTransform> = null):ParticleGeometry {
        var verticesVector:Array<Array<Float>> = new Array<Array<Float>>();
        var indicesVector:Array<Array<UInt>> = new Array<Array<UInt>>();
        var vertexCounters:Array<UInt> = new Array<UInt>();
        var particles:Array<ParticleData> = new Array<ParticleData>();
        var subGeometries:Array<CompactSubGeometry> = new Array<CompactSubGeometry>();
        var numParticles:Int = geometries.length;
        var sourceSubGeometries:Array<ISubGeometry>;
        var sourceSubGeometry:ISubGeometry;
        var numSubGeometries:Int;
        var vertices:Array<Float>;
        var indices:Array<UInt>;
        var vertexCounter:Int;
        var subGeometry:CompactSubGeometry;
        var i:Int;
        var j:Int;
        var sub2SubMap:Array<Int> = new Array<Int>();
        var tempVertex:Vector3D = new Vector3D();
        var tempNormal:Vector3D = new Vector3D();
        var tempTangents:Vector3D = new Vector3D();
        var tempUV:Point = new Point();
        i = 0;
        while (i < numParticles) {
            sourceSubGeometries = geometries[i].subGeometries;
            numSubGeometries = sourceSubGeometries.length;
            var srcIndex:Int = 0;
            while (srcIndex < numSubGeometries) {
//create a different particle subgeometry group for each source subgeometry in a particle.
                if (sub2SubMap.length <= srcIndex) {
                    sub2SubMap.push(subGeometries.length);
                    verticesVector.push(new Array<Float>());
                    indicesVector.push(new Array<UInt>());
                    subGeometries.push(new CompactSubGeometry());
                    vertexCounters.push(0);
                }
                sourceSubGeometry = sourceSubGeometries[srcIndex];
//add a new particle subgeometry if this source subgeometry will take us over the maxvertex limit
                if (Std.int(sourceSubGeometry.numVertices + vertexCounters[sub2SubMap[srcIndex]]) > MAX_VERTEX) {
//update submap and add new subgeom vectors
                    sub2SubMap[srcIndex] = subGeometries.length;
                    verticesVector.push(new Array<Float>());
                    indicesVector.push(new Array<UInt>());
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
                var compact:CompactSubGeometry = cast(sourceSubGeometry, CompactSubGeometry);
                var product:Int;
                var sourceVertices:Array<Float>;
                if (compact != null) {
                    tempLen = compact.numVertices;
                    compact.numTriangles;
                    sourceVertices = compact.vertexData;
                    if (transforms != null) {
                        var particleGeometryTransform:ParticleGeometryTransform = transforms[i];
                        var vertexTransform:Matrix3D = particleGeometryTransform.vertexTransform;
                        var invVertexTransform:Matrix3D = particleGeometryTransform.invVertexTransform;
                        var UVTransform:Matrix = particleGeometryTransform.UVTransform;
                        k = 0;
                        while (k < tempLen) {
/*
							 * 0 - 2: vertex position X, Y, Z
							 * 3 - 5: normal X, Y, Z
							 * 6 - 8: tangent X, Y, Z
							 * 9 - 10: U V
							 * 11 - 12: Secondary U V*/
                            product = k * 13;
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
                            if (vertexTransform != null) {
                                tempVertex = vertexTransform.transformVector(tempVertex);
                                tempNormal = invVertexTransform.deltaTransformVector(tempNormal);
                                tempTangents = invVertexTransform.deltaTransformVector(tempNormal);
                            }
                            if (UVTransform != null) tempUV = UVTransform.transformPoint(tempUV);
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
                            vertices.push(sourceVertices[product + 11]);
                            vertices.push(sourceVertices[product + 12]);
                            k++;
                        }
                    }

                    else {
                        k = 0;
                        while (k < tempLen) {
                            product = k * 13;
//this is faster than that only push one data
                            vertices.push(sourceVertices[product]);
                            vertices.push(sourceVertices[product + 1]);
                            vertices.push(sourceVertices[product + 2]);
                            vertices.push(sourceVertices[product + 3]);
                            vertices.push(sourceVertices[product + 4]);
                            vertices.push(sourceVertices[product + 5]);
                            vertices.push(sourceVertices[product + 6]);
                            vertices.push(sourceVertices[product + 7]);
                            vertices.push(sourceVertices[product + 8]);
                            vertices.push(sourceVertices[product + 9]);
                            vertices.push(sourceVertices[product + 10]);
                            vertices.push(sourceVertices[product + 11]);
                            vertices.push(sourceVertices[product + 12]);
                            k++;
                        }
                    }

                }

                else {
//Todo
                }

                var sourceIndices:Array<UInt> = sourceSubGeometry.indexData;
                tempLen = sourceSubGeometry.numTriangles;
                k = 0;
                while (k < tempLen) {
                    product = k * 3;
                    indices.push(sourceIndices[product] + vertexCounter);
                    indices.push(sourceIndices[product + 1] + vertexCounter);
                    indices.push(sourceIndices[product + 2] + vertexCounter);
                    k++;
                }
                srcIndex++;
            }
            i++;
        }
        var particleGeometry:ParticleGeometry = new ParticleGeometry();
        particleGeometry.particles = particles;
        particleGeometry.numParticles = numParticles;
        numParticles = subGeometries.length;
        i = 0;
        while (i < numParticles) {
            subGeometry = subGeometries[i];
            subGeometry.updateData(verticesVector[i]);
            subGeometry.updateIndexData(indicesVector[i]);
            particleGeometry.addSubGeometry(subGeometry);
            i++;
        }
        return particleGeometry;
    }
}

