package away3d.entities;

import away3d.animators.IAnimator;
import away3d.bounds.BoundingSphere;
import away3d.bounds.BoundingVolumeBase;
import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.core.partition.EntityNode;
import away3d.core.partition.RenderableNode;
import away3d.materials.MaterialBase;
import away3d.materials.SegmentMaterial;
import away3d.primitives.LineSegment;
import away3d.primitives.data.Segment;
import away3d.library.assets.Asset3DType;

import openfl.display3D.Context3D;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.geom.Matrix;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.Vector;

class SegmentSet extends Entity implements IRenderable
{
	private static var LIMIT:Int = 3*0xFFFF;
	
	public var segmentCount(get, never):Int;
	@:allow(away3d) private var subSetCount(get, never):Int;
	@:allow(away3d) private var hasData(get, never):Bool;
	public var numTriangles(get, never):Int;
	public var sourceEntity(get, never):Entity;
	public var castsShadows(get, never):Bool;
	public var material(get, set):MaterialBase;
	public var animator(get, never):IAnimator;
	public var uvTransform(get, never):Matrix;
	public var uvTransform2(get, never):Matrix;
	public var vertexData(get, never):Vector<Float>;
	public var indexData(get, never):Vector<UInt>;
	public var UVData(get, never):Vector<Float>;
	public var numVertices(get, never):Int;
	public var vertexStride(get, never):Int;
	public var vertexNormalData(get, never):Vector<Float>;
	public var vertexTangentData(get, never):Vector<Float>;
	public var vertexOffset(get, never):Int;
	public var vertexNormalOffset(get, never):Int;
	public var vertexTangentOffset(get, never):Int;
	
	private var _activeSubSet:SubSet;
	private var _subSets:Vector<SubSet>;
	private var _subSetCount:Int = 0;
	private var _numIndices:Int = 0;
	private var _material:MaterialBase;
	private var _animator:IAnimator;
	private var _hasData:Bool;
	
	private var _segments:Map<Int, SegRef>;
	private var _indexSegments:Int = 0;
	
	/**
	 * Creates a new SegmentSet object.
	 */
	public function new()
	{
		super();
		
		_subSetCount = 0;
		_subSets = new Vector<SubSet>();
		addSubSet();
		
		_segments = new Map<Int, SegRef>();
		material = new SegmentMaterial();
	}
	
	/**
	 * Adds a new segment to the SegmentSet.
	 *
	 * @param segment  the segment to add
	 */
	public function addSegment(segment:Segment):Void
	{
		segment.segmentsBase = this;
		
		_hasData = true;
		
		var subSetIndex:Int = _subSets.length - 1;
		var subSet:SubSet = _subSets[subSetIndex];
		
		if (subSet.vertices.length + 44 > LIMIT) {
			subSet = addSubSet();
			subSetIndex++;
		}
		
		segment.index = subSet.vertices.length;
		segment.subSetIndex = subSetIndex;
		
		updateSegment(segment);
		
		var index:Int = subSet.lineCount << 2;
		
		subSet.indices.push(index);
		subSet.indices.push(index + 1);
		subSet.indices.push(index + 2);
		subSet.indices.push(index + 3);
		subSet.indices.push(index + 2);
		subSet.indices.push(index + 1);
		subSet.numVertices = Std.int(subSet.vertices.length / 11);
		subSet.numIndices = subSet.indices.length;
		subSet.lineCount++;
		subSet.indexBufferDirty=true;
		
		var segRef:SegRef = new SegRef();
		segRef.index = index;
		segRef.subSetIndex = subSetIndex;
		segRef.segment = segment;
		
		_segments.set(_indexSegments, segRef);
		
		_indexSegments++;
	}
	
	/**
	 * Removes a segment from the SegmentSet by its index in the set.
	 *
	 * @param index        The index of the segment to remove
	 * @param dispose    If the segment must be disposed as well. Default is false;
	 *
	 *    Removing a Segment by an index when segment is unknown
	 *    index of the segment is relative to the order it was added to the segmentSet.
	 *    If a segment was removed from or added to the segmentSet, a segment index may have changed.
	 *    The index of each Segment is updated when one is added or removed.
	 *    If 2 segments are added, segment #1 has index 0, segment #2 has index 1
	 *    if segment #1 is removed, segment#2 will get index 0 instead of 1.
	 */
	public function removeSegmentByIndex(index:Int, dispose:Bool = false):Void
	{
		var segRef:SegRef;
		if (index >= _indexSegments)
			return;
		
		if (_segments.exists(index))
			segRef = _segments[index];
		else
			return;
		
		var subSet:SubSet;
		if (_subSets[segRef.subSetIndex] == null)
			return;
		var subSetIndex:Int = segRef.subSetIndex;
		subSet = _subSets[segRef.subSetIndex];
		
		var segment:Segment = segRef.segment;
		var indices:Vector<UInt> = subSet.indices;
		
		var ind:Int = index*6;
		for (i in ind...indices.length)
			indices[i] -= 4;
		
		subSet.indices.splice(index*6, 6);
		subSet.vertices.splice(index*44, 44);
		subSet.numVertices = Std.int(subSet.vertices.length/11);
		subSet.numIndices = indices.length;
		subSet.vertexBufferDirty = true;
		subSet.indexBufferDirty = true;
		subSet.lineCount--;
		
		if (dispose) {
			segment.dispose();
			segment = null;
			
		} else {
			segment.index = -1;
			segment.segmentsBase = null;
		}
		
		if (subSet.lineCount == 0) {
			
			if (subSetIndex == 0)
				_hasData = false;
			
			else {
				subSet.dispose();
				_subSets[subSetIndex] = null;
				_subSets.splice(subSetIndex, 1);
			}
		}
		
		reOrderIndices(subSetIndex, index);
		
		segRef = null;
		_segments.remove(_indexSegments);
		_indexSegments--;
	}
	
	/**
	 * Removes a segment from the SegmentSet.
	 *
	 * @param segment        The segment to remove
	 * @param dispose        If the segment must be disposed as well. Default is false;
	 */
	public function removeSegment(segment:Segment, dispose:Bool = false):Void
	{
		if (segment.index == -1)
			return;
		removeSegmentByIndex(Std.int(segment.index/44));
	}
	
	/**
	 * Empties the segmentSet from all its segments data
	 */
	public function removeAllSegments():Void
	{
		var subSet:SubSet;
		for (i in 0..._subSetCount) {
			subSet = _subSets[i];
			subSet.vertices = null;
			subSet.indices = null;
			if (subSet.vertexBuffer != null)
				Stage3DProxy.disposeVertexBuffer(subSet.vertexBuffer);
			if (subSet.indexBuffer != null)
				Stage3DProxy.disposeIndexBuffer(subSet.indexBuffer);
			subSet = null;
		}
		
		for (segReg in _segments)
			segReg = null;
		_segments = null;
		
		_subSetCount = 0;
		_activeSubSet = null;
		_indexSegments = 0;
		_subSets = new Vector<SubSet>();
		_segments = new Map();
		
		addSubSet();
		
		_hasData = false;
	}
	
	/**
	 * @returns a segment object from a given index.
	 */
	public function getSegment(index:Int):Segment
	{
		if (index > _indexSegments - 1)
			return null;
		
		return _segments[index].segment;
	}
	
	/**
	 * @returns howmany segments are in the SegmentSet
	 */
	private function get_segmentCount():Int
	{
		return _indexSegments;
	}
	
	private function get_subSetCount():Int {
		return _subSetCount;
	}

	@:allow(away3d) private function updateSegment(segment:Segment):Void
	{
		//to do: add support for curve segment
		var start:Vector3D = segment._start;
		var end:Vector3D = segment._end;
		var startX:Float = start.x, startY:Float = start.y, startZ:Float = start.z;
		var endX:Float = end.x, endY:Float = end.y, endZ:Float = end.z;
		var startR:Float = segment._startR, startG:Float = segment._startG, startB:Float = segment._startB;
		var endR:Float = segment._endR, endG:Float = segment._endG, endB:Float = segment._endB;
		var index:Int = segment.index;
		var t:Float = segment.thickness;
		
		var subSet:SubSet = _subSets[segment.subSetIndex];
		var vertices:Vector<Float> = subSet.vertices;
		
		vertices[index++] = startX;
		vertices[index++] = startY;
		vertices[index++] = startZ;
		vertices[index++] = endX;
		vertices[index++] = endY;
		vertices[index++] = endZ;
		vertices[index++] = t;
		vertices[index++] = startR;
		vertices[index++] = startG;
		vertices[index++] = startB;
		vertices[index++] = 1;
		
		vertices[index++] = endX;
		vertices[index++] = endY;
		vertices[index++] = endZ;
		vertices[index++] = startX;
		vertices[index++] = startY;
		vertices[index++] = startZ;
		vertices[index++] = -t;
		vertices[index++] = endR;
		vertices[index++] = endG;
		vertices[index++] = endB;
		vertices[index++] = 1;
		
		vertices[index++] = startX;
		vertices[index++] = startY;
		vertices[index++] = startZ;
		vertices[index++] = endX;
		vertices[index++] = endY;
		vertices[index++] = endZ;
		vertices[index++] = -t;
		vertices[index++] = startR;
		vertices[index++] = startG;
		vertices[index++] = startB;
		vertices[index++] = 1;
		
		vertices[index++] = endX;
		vertices[index++] = endY;
		vertices[index++] = endZ;
		vertices[index++] = startX;
		vertices[index++] = startY;
		vertices[index++] = startZ;
		vertices[index++] = t;
		vertices[index++] = endR;
		vertices[index++] = endG;
		vertices[index++] = endB;
		vertices[index++] = 1;
		
		subSet.vertexBufferDirty = true;
		
		invalidateBounds();
	}
	
	private function get_hasData():Bool
	{
		return _hasData;
	}
	
	public function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D
	{
		if (_activeSubSet.indexContext3D != stage3DProxy.context3D || _activeSubSet.indexBufferDirty) {
			_activeSubSet.indexBuffer = stage3DProxy.createIndexBuffer(_activeSubSet.numIndices);
			_activeSubSet.indexBuffer.uploadFromVector(_activeSubSet.indices, 0, _activeSubSet.numIndices);
			_activeSubSet.indexBufferDirty = false;
			_activeSubSet.indexContext3D = stage3DProxy.context3D;
		}
		
		return _activeSubSet.indexBuffer;
	}
	
	public function activateVertexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var subSet:SubSet = _subSets[index];
		
		_activeSubSet = subSet;
		_numIndices = subSet.numIndices;
		
		if (subSet.vertexContext3D != stage3DProxy.context3D || subSet.vertexBufferDirty) {
			if (subSet.vertexBuffer != null) Stage3DProxy.disposeVertexBuffer(subSet.vertexBuffer);
			subSet.vertexBuffer = stage3DProxy.createVertexBuffer(subSet.numVertices, 11);
			subSet.vertexBuffer.uploadFromVector(subSet.vertices, 0, subSet.numVertices);
			subSet.vertexBufferDirty = false;
			subSet.vertexContext3D = stage3DProxy.context3D;
		}
		
		var vertexBuffer:VertexBuffer3D = subSet.vertexBuffer;
		var context3d:Context3D = stage3DProxy._context3D;
		
		context3d.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
		context3d.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_3);
		context3d.setVertexBufferAt(2, vertexBuffer, 6, Context3DVertexBufferFormat.FLOAT_1);
		context3d.setVertexBufferAt(3, vertexBuffer, 7, Context3DVertexBufferFormat.FLOAT_4);
	}
	
	public function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
	}
	
	public function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
	}
	
	public function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
	}
	
	public function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
	}
	
	private function reOrderIndices(subSetIndex:Int, index:Int):Void
	{
		var segRef:SegRef;
		
		for (i in index..._indexSegments - 1) {
			segRef = _segments[i + 1];
			segRef.index = i;
			if (segRef.subSetIndex == subSetIndex)
				segRef.segment.index -= 44;
			_segments[i] = segRef;
		}
	
	}
	
	private function addSubSet():SubSet
	{
		var subSet:SubSet = new SubSet();
		_subSets.push(subSet);
		
		subSet.vertices = new Vector<Float>();
		subSet.numVertices = 0;
		subSet.indices = new Vector<UInt>();
		subSet.numIndices = 0;
		subSet.vertexBufferDirty = true;
		subSet.indexBufferDirty = true;
		subSet.lineCount = 0;
		
		_subSetCount++;
		
		return subSet;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function dispose():Void
	{
		super.dispose();
		removeAllSegments();
		_segments = null;
		_material = null;
		var subSet:SubSet = _subSets[0];
		subSet.vertices = null;
		subSet.indices = null;
		_subSets = null;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function get_mouseEnabled():Bool
	{
		return false;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getDefaultBoundingVolume():BoundingVolumeBase
	{
		return new BoundingSphere();
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateBounds():Void
	{
		var subSet:SubSet;
		var len:Int;
		var v:Float;
		var index:Int;
		
		var minX:Float = Math.POSITIVE_INFINITY;
		var minY:Float = Math.POSITIVE_INFINITY;
		var minZ:Float = Math.POSITIVE_INFINITY;
		var maxX:Float = Math.NEGATIVE_INFINITY;
		var maxY:Float = Math.NEGATIVE_INFINITY;
		var maxZ:Float = Math.NEGATIVE_INFINITY;
		var vertices:Vector<Float>;
		
		var i:Int = 0;
		while (i < _subSetCount) {
			subSet = _subSets[i];
			index = 0;
			vertices = subSet.vertices;
			len = vertices.length;
			
			if (len == 0) {
				++i;
				continue;
			}
			
			while (index < len) {
				
				v = vertices[index++];
				if (v < minX)
					minX = v;
				else if (v > maxX)
					maxX = v;
				
				v = vertices[index++];
				if (v < minY)
					minY = v;
				else if (v > maxY)
					maxY = v;
				
				v = vertices[index++];
				if (v < minZ)
					minZ = v;
				else if (v > maxZ)
					maxZ = v;
				
				index += 8;
			}
			++i;
		}
		
		if (minX != Math.POSITIVE_INFINITY)
			_bounds.fromExtremes(minX, minY, minZ, maxX, maxY, maxZ);
		
		else {
			var min:Float = .5;
			_bounds.fromExtremes(-min, -min, -min, min, min, min);
		}
		
		_boundsInvalid = false;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function createEntityPartitionNode():EntityNode
	{
		return new RenderableNode(this);
	}
	
	private function get_numTriangles():Int
	{
		return Std.int(_numIndices/3);
	}
	
	private function get_sourceEntity():Entity
	{
		return this;
	}
	
	private function get_castsShadows():Bool
	{
		return false;
	}
	
	private function get_material():MaterialBase
	{
		return _material;
	}
	
	private function get_animator():IAnimator
	{
		return _animator;
	}
	
	private function set_material(value:MaterialBase):MaterialBase
	{
		if (value == _material)
			return value;
		if (_material != null)
			_material.removeOwner(this);
		_material = value;
		if (_material != null)
			_material.addOwner(this);
		return value;
	}
	
	private function get_uvTransform():Matrix
	{
		return null;
	}
	
	private function get_uvTransform2():Matrix
	{
		return null;
	}
	
	private function get_vertexData():Vector<Float>
	{
		return null;
	}
	
	private function get_indexData():Vector<UInt>
	{
		return null;
	}
	
	private function get_UVData():Vector<Float>
	{
		return null;
	}
	
	private function get_numVertices():Int
	{
		return 0;
	}
	
	private function get_vertexStride():Int
	{
		return 11;
	}
	
	private function get_vertexNormalData():Vector<Float>
	{
		return null;
	}
	
	private function get_vertexTangentData():Vector<Float>
	{
		return null;
	}
	
	private function get_vertexOffset():Int
	{
		return 0;
	}
	
	private function get_vertexNormalOffset():Int
	{
		return 0;
	}
	
	private function get_vertexTangentOffset():Int
	{
		return 0;
	}
	
	override private function get_assetType():String
	{
		return Asset3DType.SEGMENT_SET;
	}
	
	public function getRenderSceneTransform(camera:Camera3D):Matrix3D
	{
		return _sceneTransform;
	}
}

@:final class SegRef
{

	public var index:Int;
	public var subSetIndex:Int;
	public var segment:Segment;

	public function new() {}

}

@:final class SubSet
{

	public var vertices:Vector<Float>;
	public var numVertices:Int;
	
	public var indices:Vector<UInt>;
	public var numIndices:Int;
	
	public var vertexBufferDirty:Bool;
	public var indexBufferDirty:Bool;
	
	public var vertexContext3D:Context3D;
	public var indexContext3D:Context3D;
	
	public var vertexBuffer:VertexBuffer3D;
	public var indexBuffer:IndexBuffer3D;
	public var lineCount:Int;
	
	public function new() {}

	public function dispose():Void
	{
		vertices = null;
		if (vertexBuffer != null) 
			Stage3DProxy.disposeVertexBuffer(vertexBuffer);
		if (indexBuffer != null) 
			Stage3DProxy.disposeIndexBuffer(indexBuffer);
	}

}