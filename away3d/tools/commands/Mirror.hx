package away3d.tools.commands;

import away3d.bounds.BoundingVolumeBase;
import away3d.containers.ObjectContainer3D;
import away3d.core.base.Geometry;
import away3d.core.base.ISubGeometry;
import away3d.entities.Mesh;
import away3d.tools.utils.GeomUtil;

import openfl.geom.Matrix3D;
import openfl.Vector;

class Mirror
{
	public var recenter(get, set):Bool;
	public var duplicate(get, set):Bool;
	
	public static inline var X_AXIS:Int = 1; // 001
	public static inline var Y_AXIS:Int = 2; // 010
	public static inline var Z_AXIS:Int = 4; // 100
	
	public static inline var MIN_BOUND:String = "min";
	public static inline var MAX_BOUND:String = "max";
	public static inline var CENTER:String = "center";
	
	private var _recenter:Bool;
	private var _duplicate:Bool;
	private var _axis:Int;
	private var _offset:String;
	private var _additionalOffset:Float;
	private var _scaleTransform:Matrix3D;
	private var _fullTransform:Matrix3D;
	private var _centerTransform:Matrix3D;
	private var _flipWinding:Bool;
	
	public function new(recenter:Bool = false, duplicate:Bool = true)
	{
		_recenter = recenter;
		_duplicate = duplicate;
	}
	
	private function set_recenter(b:Bool):Bool
	{
		_recenter = b;
		return b;
	}
	
	private function get_recenter():Bool
	{
		return _recenter;
	}
	
	private function set_duplicate(b:Bool):Bool
	{
		_duplicate = b;
		return b;
	}
	
	private function get_duplicate():Bool
	{
		return _duplicate;
	}
	
	/**
	 * Clones a Mesh and mirrors the cloned mesh. returns the cloned (and mirrored) mesh.
	 * @param mesh the mesh to clone and mirror.
	 * @param axis the axis to mirror the mesh.
	 * @param offset can be MIN_BOUND, MAX_BOUND or CENTER.
	 * @param additionalOffset if MIN_BOUND or MAX_BOUND is selected as offset, this addional offset can be added.
	 */
	public function getMirroredClone(mesh:Mesh, axis:Int, offset:String = CENTER, additionalOffset:Float = 0):Mesh
	{
		_axis = axis;
		_offset = offset;
		_additionalOffset = additionalOffset;
		
		//var originalDuplicateMode:Boolean = _duplicate;
		_duplicate = false;
		
		var newMesh:Mesh = cast(mesh.clone(), Mesh);
		initTransforms(newMesh.bounds);
		applyToMesh(newMesh, true);
		_duplicate = false;
		
		return newMesh;
	}
	
	/**
	 * Clones a ObjectContainer3D and all its children and mirrors the cloned Objects. returns the cloned (and mirrored) ObjectContainer3D.
	 * @param mesh the ObjectContainer3D to clone and mirror.
	 * @param axis the axis to mirror the ObjectContainer3D.
	 * @param offset can be MIN_BOUND, MAX_BOUND or CENTER.
	 * @param additionalOffset if MIN_BOUND or MAX_BOUND is selected as offset, this additional offset can be added.
	 */
	public function getMirroredCloneContainer(ctr:ObjectContainer3D, axis:Int, offset:String = CENTER, additionalOffset:Float = 0):ObjectContainer3D
	{
		var meshes:Vector<Mesh> = new Vector<Mesh>();
		_axis = axis;
		_offset = offset;
		_additionalOffset = additionalOffset;
		
		//var originalDuplicateMode:Boolean = _duplicate; //store the _duplicateMode, because for this function we want to set it to false, but want to restore it later
		_duplicate = false;
		
		var newObjectContainer:ObjectContainer3D = cast(ctr.clone(), ObjectContainer3D);
		
		// Collect ctr (if it's a mesh) and all it's
		// mesh children to a flat list.
		if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(newObjectContainer, Mesh))
			meshes.push(cast(newObjectContainer, Mesh));
		
		collectMeshChildren(newObjectContainer, meshes);
		var len:Int = meshes.length;
		for (i in 0...len) {
			initTransforms(meshes[i].bounds);
			applyToMesh(meshes[i], true);
		}
		_duplicate = false;
		
		return newObjectContainer;
	}
	
	/**
	 * Mirror a Mesh along a given Axis.
	 * @param mesh the mesh to mirror.
	 * @param axis the axis to mirror the mesh.
	 * @param offset can be MIN_BOUND, MAX_BOUND or CENTER.
	 * @param additionalOffset if MIN_BOUND or MAX_BOUND is selected as offset, this addional offset can be added.
	 */
	public function apply(mesh:Mesh, axis:Int, offset:String = CENTER, additionalOffset:Float = 0):Void
	{
		_axis = axis;
		_offset = offset;
		_additionalOffset = additionalOffset;
		
		initTransforms(mesh.bounds);
		applyToMesh(mesh);
	}
	
	/**
	 * Mirror a ObjectContainer3d, and all its children along a given Axis.
	 * @param ctr the ObjectContainer3d to mirror.
	 * @param axis the axis to mirror the ObjectContainer3d.
	 * @param offset can be MIN_BOUND, MAX_BOUND or CENTER.
	 * @param additionalOffset if MIN_BOUND or MAX_BOUND is selected as offset, this addional offset can be added.
	 */
	public function applyToContainer(ctr:ObjectContainer3D, axis:Int, offset:String = CENTER, additionalOffset:Float = 0):Void
	{
		var len:Int;
		_axis = axis;
		_offset = offset;
		_additionalOffset = additionalOffset;
		
		// Collect ctr (if it's a mesh) and all it's
		// mesh children to a flat list.
		var meshes:Vector<Mesh> = new Vector<Mesh>();
		
		if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(ctr, Mesh))
			meshes.push(cast(ctr, Mesh));
		
		collectMeshChildren(ctr, meshes);
		len = meshes.length;
		
		for (i in 0...len) {
			initTransforms(meshes[i].bounds);
			applyToMesh(meshes[i]);
		}
	}
	
	private function applyToMesh(mesh:Mesh, keepOld:Bool = false):Void
	{
		var geom:Geometry = mesh.geometry;
		var newGeom:Geometry = new Geometry();
		var len:Int = geom.subGeometries.length;
		
		for (i in 0...len)
			applyToSubGeom(geom.subGeometries[i], newGeom, keepOld);
		
		mesh.geometry = newGeom;
	}
	
	private function applyToSubGeom(subGeom:ISubGeometry, geometry:Geometry, keepOld:Bool):Void
	{
		var i:Int = 0;
		var len:Int;
		var indices:Vector<UInt>;
		var vertices:Vector<Float>;
		var normals:Vector<Float>;
		var uvs:Vector<Float>;
		var newSubGeoms:Vector<ISubGeometry>;
		
		var vIdx:Int, nIdx:Int, uIdx:Int;
		var vd:Vector<Float>, nd:Vector<Float>, ud:Vector<Float>;
		var vStride:Int, nStride:Int, uStride:Int;
		var vOffs:Int, nOffs:Int, uOffs:Int;
		
		vertices = new Vector<Float>();
		normals = new Vector<Float>();
		uvs = new Vector<Float>();
		
		if (keepOld) {
			indices = subGeom.indexData.concat();
			
			vd = subGeom.vertexData.concat();
			nd = subGeom.vertexNormalData.concat();
			ud = subGeom.UVData.concat();
			
		} else {
			indices = subGeom.indexData;
			vd = subGeom.vertexData;
			nd = subGeom.vertexNormalData;
			ud = subGeom.UVData;
		}
		
		indices.fixed = false;
		vOffs = subGeom.vertexOffset;
		nOffs = subGeom.vertexNormalOffset;
		uOffs = subGeom.UVOffset;
		vStride = subGeom.vertexStride;
		nStride = subGeom.vertexNormalStride;
		uStride = subGeom.UVStride;
		
		vIdx = nIdx = uIdx = 0;
		len = subGeom.numVertices;
		
		for (i in 0...len) {
			vertices[vIdx++] = vd[vOffs + i*vStride + 0];
			vertices[vIdx++] = vd[vOffs + i*vStride + 1];
			vertices[vIdx++] = vd[vOffs + i*vStride + 2];
			
			normals[nIdx++] = nd[nOffs + i*nStride + 0];
			normals[nIdx++] = nd[nOffs + i*nStride + 1];
			normals[nIdx++] = nd[nOffs + i*nStride + 2];
			
			uvs[uIdx++] = ud[uOffs + i*uStride + 0];
			uvs[uIdx++] = ud[uOffs + i*uStride + 1];
		}
		
		var indexOffset:Int = 0;
		
		if (_duplicate) {
			//var indexOffset : uint;
			var flippedVertices:Vector<Float> = new Vector<Float>();
			var flippedNormals:Vector<Float> = new Vector<Float>();
			
			_fullTransform.transformVectors(vertices, flippedVertices);
			_scaleTransform.transformVectors(normals, flippedNormals);
			
			// Copy vertex attributes
			len = subGeom.numVertices;
			for (i in 0...len) {
				vertices[len*3 + i*3 + 0] = flippedVertices[i*3 + 0];
				vertices[len*3 + i*3 + 1] = flippedVertices[i*3 + 1];
				vertices[len*3 + i*3 + 2] = flippedVertices[i*3 + 2];
				
				normals[len*3 + i*3 + 0] = flippedNormals[i*3 + 0];
				normals[len*3 + i*3 + 1] = flippedNormals[i*3 + 1];
				normals[len*3 + i*3 + 2] = flippedNormals[i*3 + 2];
				
				uvs[len*2 + i*2 + 0] = uvs[i*2 + 0];
				uvs[len*2 + i*2 + 1] = uvs[i*2 + 1];
			}
			// Copy indices
			len = indices.length;
			indexOffset = subGeom.numVertices;
			
			if (_flipWinding) {
				var i = 0;
				while (i < len) {
					indices[len + i + 0] = indices[i + 2] + indexOffset;
					indices[len + i + 1] = indices[i + 1] + indexOffset;
					indices[len + i + 2] = indices[i + 0] + indexOffset;
					i += 3;
				}
				
			} else {
				var i = 0;
				while (i < len) {
					indices[len + i + 0] = indices[i + 0] + indexOffset;
					indices[len + i + 1] = indices[i + 1] + indexOffset;
					indices[len + i + 2] = indices[i + 2] + indexOffset;
					i += 3;
				}
			}
			
		} else {
			
			len = indices.length;
			var oldindicies:Vector<UInt> = indices.concat();
			
			if (_flipWinding) {
				var i = 0;
				while (i < len) {
					indices[i + 0] = oldindicies[i + 2];
					indices[i + 1] = oldindicies[i + 1];
					indices[i + 2] = oldindicies[i + 0];
					i += 3;
				}
			}
			
			_fullTransform.transformVectors(vertices, vertices);
			_scaleTransform.transformVectors(normals, normals);
		}
		
		if (_recenter)
			_centerTransform.transformVectors(vertices, vertices);
		
		newSubGeoms = GeomUtil.fromVectors(vertices, indices, uvs, normals, null, null, null);
		len = newSubGeoms.length;
		
		for (i in 0...len)
			geometry.addSubGeometry(newSubGeoms[i]);
	}
	
	private function initTransforms(bounds:BoundingVolumeBase):Void
	{
		var ox:Float, oy:Float, oz:Float;
		var sx:Float, sy:Float, sz:Float;
		//var addx : Number, addy : Number, addz : Number;
		
		if (_scaleTransform == null) {
			_scaleTransform = new Matrix3D();
			_fullTransform = new Matrix3D();
		}
		
		// Scale factors
		_fullTransform.identity();
		_scaleTransform.identity();
		sx = ((_axis & X_AXIS) != 0)? -1 : 1;
		sy = ((_axis & Y_AXIS) != 0)? -1 : 1;
		sz = ((_axis & Z_AXIS) != 0)? -1 : 1;
		
		_fullTransform.appendScale(sx, sy, sz);
		_scaleTransform.appendScale(sx, sy, sz);
		switch(_offset) {
			
			case MIN_BOUND:
				ox = ((_axis & X_AXIS) != 0)? 2*bounds.min.x : 0;
				oy = ((_axis & Y_AXIS) != 0)? 2*bounds.min.y : 0;
				oz = ((_axis & Z_AXIS) != 0)? 2*bounds.min.z : 0;
			
			case MAX_BOUND:
				ox = ((_axis & X_AXIS) != 0)? 2*bounds.max.x : 0;
				oy = ((_axis & Y_AXIS) != 0)? 2*bounds.max.y : 0;
				oz = ((_axis & Z_AXIS) != 0)? 2*bounds.max.z : 0;
			
			default:
				ox = oy = oz = 0;
		}
		
		if (_additionalOffset > 0) {
			
			if (ox > 0)
				ox += ((_axis & X_AXIS) != 0)? _additionalOffset : 0;
			
			if (ox < 0)
				ox -= ((_axis & X_AXIS) != 0)? _additionalOffset : 0;
			
			if (oy > 0)
				oy += ((_axis & Y_AXIS) != 0)? _additionalOffset : 0;
			
			if (oy < 0)
				oy -= ((_axis & Y_AXIS) != 0)? _additionalOffset : 0;
			
			if (oz > 0)
				oz += ((_axis & Z_AXIS) != 0)? _additionalOffset : 0;
			
			if (oz < 0)
				oz -= ((_axis & Z_AXIS) != 0)? _additionalOffset : 0;
			
		}
		// Full transform contains both offset and scale, and is the one
		// to use for vertices. Normals should not be affected the same
		// way (i.e. not be offset) which is why these are separate.
		_fullTransform.appendTranslation(ox, oy, oz);
		
		if (_recenter) {
			if (_centerTransform == null)
				_centerTransform = new Matrix3D();
			
			var recenterX:Float = 0;
			var recenterY:Float = 0;
			var recenterZ:Float = 0;
			
			if (ox == 0)
				recenterX = ((bounds.min.x + bounds.max.x)/2)* -1;
			if (oy == 0)
				recenterY = ((bounds.min.y + bounds.max.y)/2)* -1;
			if (oz == 0)
				recenterZ = ((bounds.min.z + bounds.max.z)/2)* -1;
			
			_centerTransform.identity();
			_centerTransform.appendTranslation(-ox*.5 + recenterX, -oy*.5 + recenterY, -oz*.5 + recenterZ);
			
		}
		
		_flipWinding = !((sx*sy*sz) > 0);
	}
	
	private function collectMeshChildren(ctr:ObjectContainer3D, meshes:Vector<Mesh>):Void
	{
		for (i in 0...ctr.numChildren) {
			var child:ObjectContainer3D = ctr.getChildAt(i);
			if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(child, Mesh))
				meshes.push(cast child);
			
			collectMeshChildren(child, meshes);
		}
	}
}