package away3d.entities;

	//import away3d.arcane;
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
	import away3d.library.assets.AssetType;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix;
	import away3d.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	import flash.Vector;

	//use namespace arcane;
	
	class SegmentSet extends Entity implements IRenderable
	{
		private var LIMIT:UInt = 3*0xFFFF;
		var _activeSubSet:SubSet;
		var _subSets:Array<SubSet>;
		var _subSetCount:UInt;
		var _numIndices:UInt;
		var _material:MaterialBase;
		var _animator:IAnimator;
		var _hasData:Bool;
		
		var _segments:Array<SegRef>;
		var _indexSegments:UInt;
		
		/**
		 * Creates a new SegmentSet object.
		 */
		public function new()
		{
			super();
			
			_subSetCount = 0;
			_subSets = new Array<SubSet>();
			addSubSet();
			
			_segments = new Array<SegRef>();
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
			
			var subSetIndex:UInt = _subSets.length - 1;
			var subSet:SubSet = _subSets[subSetIndex];
			
			if (subSet.vertices.length + 44 > LIMIT) {
				subSet = addSubSet();
				subSetIndex++;
			}
			
			segment.index = subSet.vertices.length;
			segment.subSetIndex = subSetIndex;
			
			updateSegment(segment);
			
			var index:UInt = subSet.lineCount << 2;
			
			subSet.indices = subSet.indices.concat([ index, index + 1, index + 2, index + 3, index + 2, index + 1 ]);
			subSet.numVertices = cast(subSet.vertices.length/11, UInt);
			subSet.numIndices = cast(subSet.indices.length, Int);
			subSet.lineCount++;
			
			var segRef:SegRef = new SegRef();
			segRef.index = index;
			segRef.subSetIndex = subSetIndex;
			segRef.segment = segment;
			
			_segments[_indexSegments] = segRef;
			
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
		public function removeSegmentByIndex(index:UInt, dispose:Bool = false):Void
		{
			var segRef:SegRef;
			if (index >= _indexSegments)
				return;
			
			if (_segments[index]!=null)
				segRef = _segments[index];
			else
				return;
			
			var subSet:SubSet;
			if (_subSets[segRef.subSetIndex]==null)
				return;
			var subSetIndex:Int = segRef.subSetIndex;
			subSet = _subSets[segRef.subSetIndex];
			
			var segment:Segment = segRef.segment;
			var indices:Array<UInt> = subSet.indices;
			
			var ind:UInt = index*6;
			// For loop conversion - 			for (var i:UInt = ind; i < indices.length; ++i)
			var i:UInt = 0;
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
			_segments[_indexSegments] = null;
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
			// For loop conversion - 			for (var i:UInt = 0; i < _subSetCount; ++i)
			var i:UInt = 0;
			for (i in 0..._subSetCount) {
				subSet = _subSets[i];
				subSet.vertices = null;
				subSet.indices = null;
				if (subSet.vertexBuffer!=null)
					subSet.vertexBuffer.dispose();
				if (subSet.indexBuffer!=null)
					subSet.indexBuffer.dispose();
				subSet = null;
			}
			
			Lambda.foreach(_segments, function (segRef:SegRef):Bool {
				segRef = null;
				return true;
			});
			_segments = null;
			
			_subSetCount = 0;
			_activeSubSet = null;
			_indexSegments = 0;
			_subSets = new Array<SubSet>();
			_segments = new Array<SegRef>();
			
			addSubSet();
			
			_hasData = false;
		}
		
		/**
		 * @returns a segment object from a given index.
		 */
		public function getSegment(index:UInt):Segment
		{
			if (index > _indexSegments - 1)
				return null;
			
			return _segments[index].segment;
		}
		
		/**
		 * @returns howmany segments are in the SegmentSet
		 */
		public var segmentCount(get, null) : UInt;
		public function get_segmentCount() : UInt
		{
			return _indexSegments;
		}
		
		public var subSetCount(get, null) : UInt;
		
		public function get_subSetCount() : UInt
		{
			return _subSetCount;
		}
		
		public function updateSegment(segment:Segment):Void
		{
			//to do: add support for curve segment
			var start:Vector3D = segment._start;
			var end:Vector3D = segment._end;
			var startX:Float = start.x, startY:Float = start.y, startZ:Float = start.z;
			var endX:Float = end.x, endY:Float = end.y, endZ:Float = end.z;
			var startR:Float = segment._startR, startG:Float = segment._startG, startB:Float = segment._startB;
			var endR:Float = segment._endR, endG:Float = segment._endG, endB:Float = segment._endB;
			var index:UInt = segment.index;
			var t:Float = segment.thickness;
			
			var subSet:SubSet = _subSets[segment.subSetIndex];
			var vertices:Array<Float> = subSet.vertices;
			
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
			
			_boundsInvalid = true;
		}
		
		public var hasData(get, null) : Bool;
		
		public function get_hasData() : Bool
		{
			return _hasData;
		}
		
		public function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D
		{
			if (_activeSubSet.indexContext3D != stage3DProxy.context3D || _activeSubSet.indexBufferDirty) {
				_activeSubSet.indexBuffer = stage3DProxy._context3D.createIndexBuffer(_activeSubSet.numIndices);
				_activeSubSet.indexBuffer.uploadFromVector(Vector.ofArray(_activeSubSet.indices), 0, _activeSubSet.numIndices);
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
			
			var vertexBuffer:VertexBuffer3D = subSet.vertexBuffer;
			
			if (subSet.vertexContext3D != stage3DProxy.context3D || subSet.vertexBufferDirty) {
				subSet.vertexBuffer = stage3DProxy._context3D.createVertexBuffer(subSet.numVertices, 11);
				subSet.vertexBuffer.uploadFromVector(Vector.ofArray(subSet.vertices), 0, subSet.numVertices);
				subSet.vertexBufferDirty = false;
				subSet.vertexContext3D = stage3DProxy.context3D;
			}
			
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
		
		private function reOrderIndices(subSetIndex:UInt, index:Int):Void
		{
			var segRef:SegRef;
			
			// For loop conversion - 						for (var i:UInt = index; i < _indexSegments - 1; ++i)
			
			var i:UInt = 0;
			
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
			
			subSet.vertices = new Array<Float>();
			subSet.numVertices = 0;
			subSet.indices = new Array<UInt>();
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
		override public function get_mouseEnabled() : Bool
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
			var len:UInt;
			var v:Float;
			var index:UInt;
			
			var minX:Float = Math.POSITIVE_INFINITY;
			var minY:Float = Math.POSITIVE_INFINITY;
			var minZ:Float = Math.POSITIVE_INFINITY;
			var maxX:Float = Math.NEGATIVE_INFINITY;
			var maxY:Float = Math.NEGATIVE_INFINITY;
			var maxZ:Float = Math.NEGATIVE_INFINITY;
			var vertices:Array<Float>;
			
			// For loop conversion - 						for (var i:UInt = 0; i < _subSetCount; ++i)
			
			var i:UInt = 0;
			
			for (i in 0..._subSetCount) {
				subSet = _subSets[i];
				index = 0;
				vertices = subSet.vertices;
				len = vertices.length;
				
				if (len == 0)
					continue;
				
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
		
		public var numTriangles(get, null) : UInt;
		
		public function get_numTriangles() : UInt
		{
			return Std.int(_numIndices/3);
		}
		
		public var sourceEntity(get, null) : Entity;
		
		public function get_sourceEntity() : Entity
		{
			return this;
		}
		
		public var castsShadows(get, null) : Bool;
		
		public function get_castsShadows() : Bool
		{
			return false;
		}
		
		public var material(get, set) : MaterialBase;
		
		public function get_material() : MaterialBase
		{
			return _material;
		}
		
		public var animator(get, null) : IAnimator;
		
		public function get_animator() : IAnimator
		{
			return _animator;
		}
		
		public function set_material(value:MaterialBase) : MaterialBase
		{
			if (value == _material)
				return _material;
			if (_material!=null)
				_material.removeOwner(this);
			_material = value;
			if (_material!=null)
				_material.addOwner(this);
			return _material;	
		}
		
		public var uvTransform(get, null) : Matrix;
		
		public function get_uvTransform() : Matrix
		{
			return null;
		}
		
		public var vertexData(get, null) : Array<Float>;
		public function get_vertexData() : Array<Float>
		{
			return null;
		}
		
		public var indexData(get, null) : Array<UInt>;		
		public function get_indexData() : Array<UInt>
		{
			return null;
		}
		
		public var UVData(get, null) : Array<Float>;
		public function get_UVData() : Array<Float>
		{
			return null;
		}
		
		public var numVertices(get, null) : UInt;		
		public function get_numVertices() : UInt
		{
			return 0;
		}
		
		public var vertexStride(get, null) : UInt;		
		public function get_vertexStride() : UInt
		{
			return 11;
		}
		
		public var vertexNormalData(get, null) : Array<Float>;
		public function get_vertexNormalData() : Array<Float>
		{
			return null;
		}
		
		public var vertexTangentData(get, null) : Array<Float>;
		public function get_vertexTangentData() : Array<Float>
		{
			return null;
		}
		
		public var vertexOffset(get, null) : Int;		
		public function get_vertexOffset() : Int
		{
			return 0;
		}
		
		public var vertexNormalOffset(get, null) : Int;		
		public function get_vertexNormalOffset() : Int
		{
			return 0;
		}
		
		public var vertexTangentOffset(get, null) : Int;		
		public function get_vertexTangentOffset() : Int
		{
			return 0;
		}
		
		override public function get_assetType() : String
		{
			return AssetType.SEGMENT_SET;
		}
		
		public function getRenderSceneTransform(camera:Camera3D):Matrix3D
		{
			return _sceneTransform;
		}
	}

class SegRef
{
	public function new() {}
	
	public var index:UInt;
	public var subSetIndex:UInt;
	public var segment:Segment;
}

class SubSet
{
	public function new() {}
	
	public var vertices:Array<Float>;
	public var numVertices:UInt;
	
	public var indices:Array<UInt>;
	public var numIndices:UInt;
	
	public var vertexBufferDirty:Bool;
	public var indexBufferDirty:Bool;
	
	public var vertexContext3D:Context3D;
	public var indexContext3D:Context3D;
	
	public var vertexBuffer:VertexBuffer3D;
	public var indexBuffer:IndexBuffer3D;
	public var lineCount:UInt;
	
	public function dispose():Void
	{
		vertices = null;
		if (vertexBuffer!=null)
			vertexBuffer.dispose();
		if (indexBuffer!=null)
			indexBuffer.dispose();
	}
}

