package away3d.entities;

import away3d.cameras.Camera3D;
import away3d.core.base.CompactSubGeometry;
import away3d.core.base.data.VertexDefinition;
import away3d.core.base.Geometry;
import away3d.core.base.ISubGeometry;
import away3d.entities.Entity;
import away3d.entities.Mesh;
import away3d.events.GeometryEvent;
import away3d.library.assets.Asset3DType;
import away3d.materials.methods.SegmentMethod;
import away3d.materials.methods.VertexColorMethod;
import away3d.materials.SinglePassMaterialBase;
import away3d.materials.utils.DefaultMaterialManager;
import away3d.primitives.data.Segment;
import openfl.geom.Matrix;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * A collection of 3D line segments.
 */
class SegmentSet extends Mesh {
	public static var requiredAttributes(get, null):VertexDefinition;
	private static function get_requiredAttributes():VertexDefinition {
		if (requiredAttributes == null) {
			requiredAttributes = new VertexDefinition([
				new AttributeDefinition("position", 3),
				new AttributeDefinition("opposite", 3),
				new AttributeDefinition("halfWidth", 1)
			]);
		}
		return requiredAttributes;
	}

	public var segmentCount(get, never):Int;
	private inline function get_segmentCount():Int {
		var count:Int = 0;
		for (subGeometry in _subGeometries) {
			count += subGeometry.numVertices >> 2;
		}
		return count;
	}

	private var _segments:Array<Segment>;

	private var _subGeometries:Array<CompactSubGeometry>;

	private var _vertexDefinition:VertexDefinition;
	private var _positionOffset:Int;
	private var _oppositeOffset:Int;
	private var _halfWidthOffset:Int;
	private var _colorOffset:Int = -1;

	/**
	 * Creates a new `SegmentSet`.
	 * @param material The material to use.
	 * @param overrideMaterialColors Whether to use individual `Segment` colors
	 * instead of the material's color or texture. If false, `Segment` colors
	 * will be ignored.
	 * @param vertexDefinition A custom vertex definition containing any other
	 * attributes needed by `material`.
	 */
	public function new(?material:SinglePassMaterialBase, ?overrideMaterialColors:Bool = true, ?vertexDefinition:VertexDefinition) {
		if (material == null) {
			material = DefaultMaterialManager.getDefaultMaterial(this);
		}
		if (!material.hasMethodOfType(SegmentMethod)) {
			material.addMethod(new SegmentMethod());
		}

		super(new Geometry(), material);

		_segments = [];
		_subGeometries = [];

		_castsShadows = false;
		_mouseEnabled = false;

		if (vertexDefinition == null) {
			vertexDefinition = VertexDefinition.defaultVertexDefinition;
		}
		_vertexDefinition = vertexDefinition.concatUnique(requiredAttributes.attributes);

		_positionOffset = _vertexDefinition.get("position").offset;
		_oppositeOffset = _vertexDefinition.get("opposite").offset;
		_halfWidthOffset = _vertexDefinition.get("halfWidth").offset;

		if (overrideMaterialColors) {
			_vertexDefinition = _vertexDefinition.concatUnique([VertexColorMethod.COLOR]);

			var color:AttributeDefinition = _vertexDefinition.get("color");
			if (color != null) {
				_colorOffset = color.offset;
			}

			if (!material.hasMethodOfType(VertexColorMethod)) {
				material.addMethod(new VertexColorMethod(color.length > 3));
			}
		}
	}

	public function addSegment(segment:Segment):Void
	{
		var subGeometry:CompactSubGeometry = _subGeometries[_subGeometries.length - 1];

		if (subGeometry == null || subGeometry.numVertices + 4 * _vertexDefinition.length >= CompactSubGeometry.MAX_NUM_VERTICES) {
			subGeometry = new CompactSubGeometry(_vertexDefinition);
			_subGeometries.push(subGeometry);
			geometry.addSubGeometry(subGeometry);
		}

		var index:Int = subGeometry.numVertices;

		segment.index = _segments.length;
		_segments.push(segment);
		segment.segmentsBase = this;
		segment.subSetIndex = _subGeometries.length - 1;

		updateSegment(segment);

		var indices:Vector<UInt> = subGeometry.indexData;
		if (indices == null) indices = new Vector<UInt>();
		indices.push(index + 0);
		indices.push(index + 1);
		indices.push(index + 2);
		indices.push(index + 3);
		indices.push(index + 2);
		indices.push(index + 1);
		subGeometry.updateIndexData(indices);
	}

	override public function dispose():Void
	{
		removeAllSegments();
		super.dispose();
		_segments = null;
		_material = null;
		_subGeometries = null;
	}

	override private function onSubGeometryRemoved(event:GeometryEvent):Void
	{
		for (i in 0..._subGeometries.length) {
			var subGeometry:CompactSubGeometry = _subGeometries[i];
			if (subGeometry == event.subGeometry) {
				_subGeometries.splice(i, 1);
				break;
			}
		}

		super.onSubGeometryRemoved(event);
	}

	public function getSegment(index:Int):Segment
	{
		return _segments[index];
	}

	/**
	 * Removes all line segments from this set.
	 */
	public function removeAllSegments():Void
	{
		var subGeometries:Vector<ISubGeometry> = geometry.subGeometries;
		while (subGeometries.length > 0) {
			subGeometries.pop().dispose();
		}
		_subGeometries = [];

		while (_subMeshes.length > 0) {
			_subMeshes.pop().dispose();
		}

		invalidateBounds();
	}

	/**
	 * Removes a segment from the SegmentSet.
	 *
	 * @param segment        The segment to remove
	 * @param dispose        Whether to dispose the segment
	 */
	public function removeSegment(segment:Segment, dispose:Bool = false):Void
	{
		if (segment.index >= 0)
		{
			removeSegmentByIndex(Std.int(segment.index / (4 * _vertexDefinition.length)), dispose);
		}
	}

	/**
	 * Removes a segment from the SegmentSet by its index in the set. All
	 * following segments will have their index decreased.
	 *
	 * @param index        The index of the segment to remove
	 * @param dispose      Whether to dispose the removed segment
	 */
	public function removeSegmentByIndex(index:Int, dispose:Bool = false):Void
	{
		var subGeometry:CompactSubGeometry = null;
		for (s in _subGeometries) {
			var segmentCount:Int = s.numVertices >> 2;
			if (index < segmentCount) {
				subGeometry = s;
				break;
			} else {
				index -= segmentCount;
			}
		}
		if (subGeometry == null)
			return;

		var verticesPerSegment:Int = 4 * _vertexDefinition.length;
		var vertices:Vector<Float> = subGeometry.vertexData;
		vertices.splice(index * verticesPerSegment, verticesPerSegment);
		subGeometry.updateData(vertices);

		var indices:Vector<UInt> = subGeometry.indexData;
		indices.length -= 6;
		subGeometry.updateIndexData(indices);

		var segment:Segment = _segments[index];
		segment.index = -1;
		segment.segmentsBase = null;
		if (dispose) {
			segment.dispose();
		}

		_segments.splice(index, 1);
		for (i in index..._segments.length) {
			_segments[i].index = i * verticesPerSegment;
		}

		if (subGeometry.numVertices == 0) {
			geometry.removeSubGeometry(subGeometry);

			for (i in index..._segments.length) {
				_segments[i].subSetIndex--;
			}
		}
	}

	@:allow(away3d) private function updateSegment(segment:Segment):Void
	{
		var position:Vector3D = segment._start;
		var opposite:Vector3D = segment._end;

		#if away3d_double_line_width
		//Previous versions of `SegmentSet` implicitly doubled the line width.
		//This can be re-enabled to ease the transition, but is deprecated.
		var halfWidth:Float = segment.thickness;
		#else
		var halfWidth:Float = segment._halfThickness;
		#end

		var subGeometry:CompactSubGeometry = _subGeometries[segment.subSetIndex];
		var index:Int = segment.index;
		for (i in 0...segment.subSetIndex) {
			index -= _subGeometries[i].numVertices >> 2;
		}

		var vertices:Vector<Float> = subGeometry.vertexData;
		if (vertices == null) vertices = new Vector<Float>();
		var stride:Int = _vertexDefinition.length;
		var startIndex:Int = index * 4 * stride;
		index = startIndex;

		for (i in 0...4) {
			if (i == 2) {
				position = segment._end;
				opposite = segment._start;
			}

			vertices[index + _positionOffset + 0] = position.x;
			vertices[index + _positionOffset + 1] = position.y;
			vertices[index + _positionOffset + 2] = position.z;

			vertices[index + _oppositeOffset + 0] = opposite.x;
			vertices[index + _oppositeOffset + 1] = opposite.y;
			vertices[index + _oppositeOffset + 2] = opposite.z;

			index += stride;
		}

		index = startIndex;
		vertices[index + _halfWidthOffset] = halfWidth;
		vertices[index + stride + _halfWidthOffset] = -halfWidth;
		vertices[index + stride * 2 + _halfWidthOffset] = -halfWidth;
		vertices[index + stride * 3 + _halfWidthOffset] = halfWidth;

		if (_colorOffset >= 0) {
			for (_ in 0...2) {
				vertices[index + _colorOffset + 0] = segment._startR;
				vertices[index + _colorOffset + 1] = segment._startG;
				vertices[index + _colorOffset + 2] = segment._startB;
				index += stride;
			}
			for (_ in 0...2) {
				vertices[index + _colorOffset + 0] = segment._endR;
				vertices[index + _colorOffset + 1] = segment._endG;
				vertices[index + _colorOffset + 2] = segment._endB;
				index += stride;
			}
		}

		subGeometry.updateData(vertices);
	}

	override private function get_assetType():String
	{
		return Asset3DType.SEGMENT_SET;
	}

	// Backwards compatibility

	@:noCompletion @:dox(hide) public var numTriangles(get, never):Int;
	@:noCompletion @:dox(hide) public var sourceEntity(get, never):Entity;
	@:noCompletion @:dox(hide) public var uvTransform(get, never):Matrix;
	@:noCompletion @:dox(hide) public var uvTransform2(get, never):Matrix;
	@:noCompletion @:dox(hide) public var vertexData(get, never):Vector<Float>;
	@:noCompletion @:dox(hide) public var indexData(get, never):Vector<UInt>;
	@:noCompletion @:dox(hide) public var UVData(get, never):Vector<Float>;
	@:noCompletion @:dox(hide) public var numVertices(get, never):Int;
	@:noCompletion @:dox(hide) public var vertexStride(get, never):Int;
	@:noCompletion @:dox(hide) public var vertexNormalData(get, never):Vector<Float>;
	@:noCompletion @:dox(hide) public var vertexTangentData(get, never):Vector<Float>;
	@:noCompletion @:dox(hide) public var vertexOffset(get, never):Int;
	@:noCompletion @:dox(hide) public var vertexNormalOffset(get, never):Int;
	@:noCompletion @:dox(hide) public var vertexTangentOffset(get, never):Int;

	private function get_numTriangles():Int
	{
		var count:Int = 0;
		for (subMesh in _subMeshes) {
			count += subMesh.numTriangles;
		}
		return count;
	}

	private function get_sourceEntity():Entity
	{
		return this;
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
		var count:Int = 0;
		for (subMesh in _subMeshes) {
			count += subMesh.numVertices;
		}
		return count;
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

	@:noCompletion @:dox(hide)
	public function getRenderSceneTransform(camera:Camera3D):Matrix3D
	{
		return _sceneTransform;
	}
}
