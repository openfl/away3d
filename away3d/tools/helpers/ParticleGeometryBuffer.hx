package away3d.tools.helpers;

import away3d.core.base.CompactSubGeometry;
import away3d.core.base.data.ParticleData;
import away3d.core.base.Geometry;
import away3d.core.base.ISubGeometry;
import away3d.core.base.ParticleGeometry;
import away3d.core.base.SubGeometry;
import away3d.tools.helpers.data.ParticleGeometryTransform;

import openfl.geom.Matrix;
import openfl.geom.Matrix3D;
import openfl.geom.Point;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * A collection of particle geometry data. Particles may be added one at a time
 * (see `addParticle()`) or in batches (see `addParticles()` and
 * `addTransformedParticles()`). Once enough particles are added, call
 * `getParticleGeometry()` to export them as `ParticleGeometry`.
 * 
 * Note: if you have multiple subgeometries and want to assign each one a
 * different material, see `getSubGeometryMapping()`.
 */
class ParticleGeometryBuffer
{
	/**
	 * One build group per output subgeometry. (For instance, if at least one
	 * particle has 3 subgeometries, then we must output 3 subgeometries, and
	 * this will have length 3.)
	 */
	private var buildGroups:Vector<BuildGroup>;
	
	/**
	 * The total number of particles added so far.
	 */
	public var numParticles(default, null):Int;
	
	/**
	 * All particle data built so far.
	 */
	public var particles:Vector<ParticleData>;
	
	public inline function new()
	{
		buildGroups = new Vector<BuildGroup>();
		numParticles = 0;
		particles = new Vector<ParticleData>();
	}
	
	/**
	 * Adds one particle to the buffer.
	 * @param geometry The particle's geometry, not including `transform`.
	 * @param transform An optional transform to apply to `geometry`. This
	 * transformation will be calculated only once, and will be baked into the
	 * output `ParticleGeometry`.
	 * @return The index of the newly-added particle.
	 */
	public function addParticle(geometry:Geometry, ?transform:ParticleGeometryTransform):Int
	{
		for (i in 0...geometry.subGeometries.length)
		{
			var subGeometry:ISubGeometry = geometry.subGeometries[i];
			var buildGroup:BuildGroup = buildGroups[i];
			if (buildGroup == null)
			{
				buildGroups[i] = buildGroup = new BuildGroup();
			}
			
			addParticleData(buildGroup, subGeometry.numVertices);
			buildGroup.addISubGeometry(subGeometry, transform);
		}
		
		return numParticles++;
	}
	
	/**
	 * Generates and saves the new `ParticleData`. Always call this before
	 * adding anything to `buildGroup`.
	 */
	private inline function addParticleData(buildGroup:BuildGroup, numVertices:Int):Void
	{
		var particleData:ParticleData = new ParticleData();
		particleData.numVertices = numVertices;
		particleData.startVertexIndex = buildGroup.vertexCount;
		particleData.particleIndex = numParticles;
		particleData.subGeometry = buildGroup.subGeometry;
		particles.push(particleData);
	}
	
	/**
	 * Adds multiple copies of a particle to the buffer.
	 * @param geometry The base geometry to copy.
	 * @param copies The total number of particles to add.
	 */
	public inline function addParticles(geometry:Geometry, copies:Int):Void
	{
		for (i in 0...copies)
		{
			addParticle(geometry);
		}
	}
	
	/**
	 * Adds multiple copies of a particle to the buffer.
	 * @param geometry The base geometry to copy.
	 * @param transforms One transform for each copy of the particle.
	 */
	public inline function addTransformedParticles(geometry:Geometry, transforms:Vector<ParticleGeometryTransform>):Void
	{
		for (transform in transforms)
		{
			addParticle(geometry, transform);
		}
	}
	
	/**
	 * Exports the current particle data as a single `ParticleGeometry`.
	 * 
	 * Note: this does not dispose the buffer, so it's possible to export
	 * multiple `ParticleGeometry` instances with the same data, or to add
	 * particles to the second that weren't in the first.
	 */
	public inline function getParticleGeometry():ParticleGeometry
	{
		var particleGeometry:ParticleGeometry = new ParticleGeometry();
		particleGeometry.particles = particles.copy();
		particleGeometry.numParticles = numParticles;
		
		for (buildGroup in buildGroups)
		{
			buildGroup.uploadAndReset();
			
			for (subGeometry in buildGroup.output)
			{
				particleGeometry.addSubGeometry(subGeometry);
			}
		}
		
		return particleGeometry;
	}
	
	/**
	 * Gets a list with one entry per output subgeometry. Each entry's value is
	 * the corresponding input subgeometry index. If all of your particles have
	 * only one subgeometry, you may safely ignore this function.
	 * 
	 * If you use multiple subgeometries (typically because you use multiple
	 * materials), each input subgeometry's index will be preserved as much as
	 * possible. For instance, all particles have subgeometry 0, and this data
	 * will be combined into one large `CompactSubGeometry` if possible.
	 * 
	 * However, no subgeometry may have more than 65535 vertices, so if too many
	 * particles are added, a new `CompactSubGeometry` instance must be created
	 * to store further vertices. This is represented by a mapping of `[0, 0]`:
	 * two output subgeometries, each corresponding to input index 0.
	 * 
	 * If some of the input particles also use subgeometry 1, this data will be
	 * added to a separate `CompactSubGeometry`. If subgeometry 0 does not
	 * overflow, the output mapping will be `[0, 1]`. If it does, the mapping
	 * will instead be `[0, 0, 1]`. If both overflow, you get `[0, 0, 1, 1]`,
	 * and so on.
	 */
	public inline function getSubGeometryMapping():Vector<Int>
	{
		var mapping:Vector<Int> = new Vector<Int>();
		
		for (inputIndex in 0...buildGroups.length)
		{
			for (i in 0...buildGroups[inputIndex].outputCount)
			{
				mapping.push(inputIndex);
			}
		}
		
		return mapping;
	}
}

/**
 * A buffer collecting data corresponding to a single input subgeometry index.
 * 
 * To get this buffer's data, call `uploadAndReset()`, then examine `output`.
 */
@:forward
abstract BuildGroup({
	var vertices:Vector<Float>;
	var indices:Vector<UInt>;
	var subGeometry:CompactSubGeometry;
	var vertexCount:Int;
	var output:Vector<CompactSubGeometry>;
})
{
	public static inline var MAX_VERTEX:Int = 65535;
	
	/**
	 * The number of subgeometries that will be in `output` after the next call
	 * to `uploadAndReset()`.
	 */
	public var outputCount(get, never):Int;
	
	public inline function new()
	{
		this = {
			vertices: new Vector<Float>(),
			indices: new Vector<UInt>(),
			vertexCount: 0,
			subGeometry: new CompactSubGeometry(),
			output: new Vector<CompactSubGeometry>()
		};
	}
	
	public function addCompactSubGeometry(subGeometry:CompactSubGeometry, ?transform:ParticleGeometryTransform):Void
	{
		var oldVertexCount:Int = this.vertexCount;
		var newVertexCount:Int = this.vertexCount + subGeometry.numVertices;
		if (newVertexCount > MAX_VERTEX)
		{
			uploadAndReset();
		}
		
		this.vertexCount += subGeometry.numVertices;
		
		var vertices:BuildVector = this.vertices;
		var sourceVertices:Vector<Float> = subGeometry.vertexData;
		
		if (transform != null)
		{
			var vertexTransform:Matrix3D = transform.vertexTransform;
			var invVertexTransform:Matrix3D = transform.invVertexTransform;
			var uvTransform:Matrix = transform.UVTransform;
			
			for (i in 0...subGeometry.numVertices)
			{
				var start:Int = i * 13;
				
				// 0 - 2: vertex position X, Y, Z
				// 3 - 5: normal X, Y, Z
				// 6 - 8: tangent X, Y, Z
				// 9 - 10: U V
				// 11 - 12: Secondary U V
				
				var vertex:Vector3D = #if haxe4 inline #end new Vector3D(
					sourceVertices[start],
					sourceVertices[start + 1],
					sourceVertices[start + 2]
				);
				var normal:Vector3D = #if haxe4 inline #end new Vector3D(
					sourceVertices[start + 3],
					sourceVertices[start + 4],
					sourceVertices[start + 5]
				);
				var tangent:Vector3D = #if haxe4 inline #end new Vector3D(
					sourceVertices[start + 6],
					sourceVertices[start + 7],
					sourceVertices[start + 8]
				);
				var uv:Point = #if haxe4 inline #end new Point(
					sourceVertices[start + 9],
					sourceVertices[start + 10]
				);
				var secondaryUV:Point = #if haxe4 inline #end new Point(
					sourceVertices[start + 11],
					sourceVertices[start + 12]
				);
				
				if (vertexTransform != null)
				{
					vertices.pushVector3D(#if haxe4 inline #end
						vertexTransform.transformVector(vertex));
					vertices.pushVector3D(#if haxe4 inline #end
						invVertexTransform.deltaTransformVector(normal));
					vertices.pushVector3D(#if haxe4 inline #end
						invVertexTransform.deltaTransformVector(tangent));
				}
				else
				{
					vertices.pushVector3D(vertex);
					vertices.pushVector3D(normal);
					vertices.pushVector3D(tangent);
				}
				
				if (uvTransform != null)
				{
					vertices.pushPoint(#if haxe4 inline #end
						uvTransform.transformPoint(uv));
					vertices.pushPoint(#if haxe4 inline #end
						uvTransform.transformPoint(secondaryUV));
				}
				else
				{
					vertices.pushPoint(uv);
					vertices.pushPoint(secondaryUV);
				}
			}
		}
		else
		{
			for (vertex in 0...subGeometry.numVertices)
			{
				var start:Int = vertex * 13;
				
				//`push()` is faster than `concat()`.
				vertices.push(sourceVertices[start]);
				vertices.push(sourceVertices[start + 1]);
				vertices.push(sourceVertices[start + 2]);
				vertices.push(sourceVertices[start + 3]);
				vertices.push(sourceVertices[start + 4]);
				vertices.push(sourceVertices[start + 5]);
				vertices.push(sourceVertices[start + 6]);
				vertices.push(sourceVertices[start + 7]);
				vertices.push(sourceVertices[start + 8]);
				vertices.push(sourceVertices[start + 9]);
				vertices.push(sourceVertices[start + 10]);
				vertices.push(sourceVertices[start + 11]);
				vertices.push(sourceVertices[start + 12]);
			}
		}
		
		var sourceIndices:Vector<UInt> = subGeometry.indexData;
		for (i in 0...subGeometry.numTriangles)
		{
			var start:Int = i * 3;
			this.indices.push(sourceIndices[start] + oldVertexCount);
			this.indices.push(sourceIndices[start + 1] + oldVertexCount);
			this.indices.push(sourceIndices[start + 2] + oldVertexCount);
		}
	}
	
	public inline function addISubGeometry(subGeometry:ISubGeometry, ?transform:ParticleGeometryTransform):Void
	{
		if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(subGeometry, CompactSubGeometry))
		{
			addCompactSubGeometry(cast subGeometry, transform);
		}
		else
		{
			// Not implemented yet.
			throw 'Expected a CompactSubGeometry, got $subGeometry.';
		}
	}
	
	/**
	 * Saves all current data to `output`, then clears everything to make space
	 * for new data.
	 */
	public inline function uploadAndReset():Void
	{
		if (this.vertexCount > 0)
		{
			this.subGeometry.updateData(this.vertices);
			this.subGeometry.updateIndexData(this.indices);
			this.output.push(this.subGeometry);
			
			this.vertices = new Vector<Float>();
			this.indices = new Vector<UInt>();
			this.subGeometry = new CompactSubGeometry();
			this.vertexCount = 0;
		}
	}
	
	// Getters & Setters
	
	private inline function get_outputCount():Int
	{
		return this.output.length + this.vertexCount > 0 ? 1 : 0;
	}
}

/**
 * A few `Vector` utility methods used by `BuildGroup`.
 */
@:forward
private abstract BuildVector(Vector<Float>) from Vector<Float> to Vector<Float> {
	/**
	 * Pushes the given point's `x` and `y` values in that order.
	 */
	public inline function pushPoint(point:Point):Void
	{
		this.push(point.x);
		this.push(point.y);
	}
	
	/**
	 * Pushes the given vector's `x`, `y`, and `z` values in that order.
	 */
	public inline function pushVector3D(vector:Vector3D):Void
	{
		this.push(vector.x);
		this.push(vector.y);
		this.push(vector.z);
	}
}
