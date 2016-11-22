package away3d.core.base;


import away3d.core.managers.Stage3DProxy;

import openfl.display3D.Context3D;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.VertexBuffer3D;
import openfl.errors.Error;
import openfl.geom.Matrix3D;
import openfl.Vector;

class CompactSubGeometry extends SubGeometryBase implements ISubGeometry
{
	public var numVertices(get, never):Int;
	public var secondaryUVStride(get, never):Int;
	public var secondaryUVOffset(get, never):Int;
	
	private var _vertexDataInvalid:Vector<Bool> = new Vector<Bool>(8, true);
	private var _vertexBuffer:Vector<VertexBuffer3D> = new Vector<VertexBuffer3D>(8);
	private var _bufferContext:Vector<Context3D> = new Vector<Context3D>(8);
	private var _numVertices:Int;
	private var _contextIndex:Int;
	private var _activeBuffer:VertexBuffer3D;
	private var _activeContext:Context3D;
	private var _activeDataInvalid:Bool;
	private var _isolatedVertexPositionData:Vector<Float>;
	private var _isolatedVertexPositionDataDirty:Bool;
	
	public function new()
	{
		super();
		_autoDeriveVertexNormals = false;
		_autoDeriveVertexTangents = false;
	}
	
	private function get_numVertices():Int
	{
		return _numVertices;
	}
	
	/**
	 * Updates the vertex data. All vertex properties are contained in a single Vector, and the order is as follows:
	 * 0 - 2: vertex position X, Y, Z
	 * 3 - 5: normal X, Y, Z
	 * 6 - 8: tangent X, Y, Z
	 * 9 - 10: U V
	 * 11 - 12: Secondary U V
	 */
	public function updateData(data:Vector<Float>):Void
	{
		if (_autoDeriveVertexNormals)
			_vertexNormalsDirty = true;
		if (_autoDeriveVertexTangents)
			_vertexTangentsDirty = true;
		
		_faceNormalsDirty = true;
		_faceTangentsDirty = true;
		_isolatedVertexPositionDataDirty = true;
		
		_vertexData = data;
		var numVertices:Int = Std.int(_vertexData.length/13);
		if (numVertices != _numVertices)
			disposeVertexBuffers(_vertexBuffer);
		_numVertices = numVertices;
		
		if (_numVertices == 0)
			throw new Error("Bad data: geometry can't have zero triangles");
		
		invalidateBuffers(_vertexDataInvalid);
		
		invalidateBounds();
	}
	
	public function activateVertexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy._stage3DIndex;
		var context:Context3D = stage3DProxy._context3D;
		
		if (contextIndex != _contextIndex)
			updateActiveBuffer(contextIndex);
		
		if (_activeBuffer == null || _activeContext != context)
			createBuffer(contextIndex, context, stage3DProxy);
		if (_activeDataInvalid)
			uploadData(contextIndex);
		
		context.setVertexBufferAt(index, _activeBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
	}
	
	public function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy._stage3DIndex;
		var context:Context3D = stage3DProxy._context3D;
		
		if (_uvsDirty && _autoGenerateUVs) {
			_vertexData = updateDummyUVs(_vertexData);
			invalidateBuffers(_vertexDataInvalid);
		}
		
		if (contextIndex != _contextIndex)
			updateActiveBuffer(contextIndex);
		
		if (_activeBuffer == null || _activeContext != context)
			createBuffer(contextIndex, context, stage3DProxy);
		if (_activeDataInvalid)
			uploadData(contextIndex);
		
		context.setVertexBufferAt(index, _activeBuffer, 9, Context3DVertexBufferFormat.FLOAT_2);
	}
	
	public function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy._stage3DIndex;
		var context:Context3D = stage3DProxy._context3D;
		
		if (contextIndex != _contextIndex)
			updateActiveBuffer(contextIndex);
		
		if (_activeBuffer == null || _activeContext != context)
			createBuffer(contextIndex, context, stage3DProxy);
		if (_activeDataInvalid)
			uploadData(contextIndex);
		
		context.setVertexBufferAt(index, _activeBuffer, 11, Context3DVertexBufferFormat.FLOAT_2);
	}
	
	private function uploadData(contextIndex:Int):Void
	{
		_activeBuffer.uploadFromVector(_vertexData, 0, _numVertices);
		_vertexDataInvalid[contextIndex] = _activeDataInvalid = false;
	}
	
	public function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy._stage3DIndex;
		var context:Context3D = stage3DProxy._context3D;
		
		if (contextIndex != _contextIndex)
			updateActiveBuffer(contextIndex);
		
		if (_activeBuffer == null || _activeContext != context)
			createBuffer(contextIndex, context, stage3DProxy);
		if (_activeDataInvalid)
			uploadData(contextIndex);
		
		context.setVertexBufferAt(index, _activeBuffer, 3, Context3DVertexBufferFormat.FLOAT_3);
	}
	
	public function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy._stage3DIndex;
		var context:Context3D = stage3DProxy._context3D;
		
		if (contextIndex != _contextIndex)
			updateActiveBuffer(contextIndex);
		
		if (_activeBuffer == null || _activeContext != context)
			createBuffer(contextIndex, context, stage3DProxy);
		if (_activeDataInvalid)
			uploadData(contextIndex);
		
		context.setVertexBufferAt(index, _activeBuffer, 6, Context3DVertexBufferFormat.FLOAT_3);
	}
	
	private function createBuffer(contextIndex:Int, context:Context3D, stage3DProxy:Stage3DProxy):Void
	{
		_vertexBuffer[contextIndex] = _activeBuffer = stage3DProxy.createVertexBuffer(_numVertices, 13);
		_bufferContext[contextIndex] = _activeContext = context;
		_vertexDataInvalid[contextIndex] = _activeDataInvalid = true;
	}
	
	private function updateActiveBuffer(contextIndex:Int):Void
	{
		_contextIndex = contextIndex;
		_activeDataInvalid = _vertexDataInvalid[contextIndex];
		_activeBuffer = _vertexBuffer[contextIndex];
		_activeContext = _bufferContext[contextIndex];
	}
	
	override private function get_vertexData():Vector<Float>
	{
		if (_autoDeriveVertexNormals && _vertexNormalsDirty)
			_vertexData = updateVertexNormals(_vertexData);
		if (_autoDeriveVertexTangents && _vertexTangentsDirty)
			_vertexData = updateVertexTangents(_vertexData);
		if (_uvsDirty && _autoGenerateUVs)
			_vertexData = updateDummyUVs(_vertexData);
		return _vertexData;
	}
	
	override private function updateVertexNormals(target:Vector<Float>):Vector<Float>
	{
		invalidateBuffers(_vertexDataInvalid);
		return super.updateVertexNormals(target);
	}
	
	override private function updateVertexTangents(target:Vector<Float>):Vector<Float>
	{
		if (_vertexNormalsDirty)
			_vertexData = updateVertexNormals(_vertexData);
		invalidateBuffers(_vertexDataInvalid);
		return super.updateVertexTangents(target);
	}
	
	override private function get_vertexNormalData():Vector<Float>
	{
		if (_autoDeriveVertexNormals && _vertexNormalsDirty)
			_vertexData = updateVertexNormals(_vertexData);
		
		return _vertexData;
	}
	
	override private function get_vertexTangentData():Vector<Float>
	{
		if (_autoDeriveVertexTangents && _vertexTangentsDirty)
			_vertexData = updateVertexTangents(_vertexData);
		return _vertexData;
	}
	
	override private function get_UVData():Vector<Float>
	{
		if (_uvsDirty && _autoGenerateUVs) {
			_vertexData = updateDummyUVs(_vertexData);
			invalidateBuffers(_vertexDataInvalid);
		}
		return _vertexData;
	}
	
	override public function applyTransformation(transform:Matrix3D):Void
	{
		super.applyTransformation(transform);
		invalidateBuffers(_vertexDataInvalid);
	}
	
	override public function scale(scale:Float):Void
	{
		super.scale(scale);
		invalidateBuffers(_vertexDataInvalid);
	}
	
	public function clone():ISubGeometry
	{
		var clone:CompactSubGeometry = new CompactSubGeometry();
		clone._autoDeriveVertexNormals = _autoDeriveVertexNormals;
		clone._autoDeriveVertexTangents = _autoDeriveVertexTangents;
		clone.updateData(_vertexData.concat());
		clone.updateIndexData(_indices.concat());
		return clone;
	}
	
	override public function scaleUV(scaleU:Float = 1, scaleV:Float = 1):Void
	{
		super.scaleUV(scaleU, scaleV);
		invalidateBuffers(_vertexDataInvalid);
	}
	
	override private function get_vertexStride():Int
	{
		return 13;
	}
	
	override private function get_vertexNormalStride():Int
	{
		return 13;
	}
	
	override private function get_vertexTangentStride():Int
	{
		return 13;
	}
	
	override private function get_UVStride():Int
	{
		return 13;
	}
	
	private function get_secondaryUVStride():Int
	{
		return 13;
	}
	
	override private function get_vertexOffset():Int
	{
		return 0;
	}
	
	override private function get_vertexNormalOffset():Int
	{
		return 3;
	}
	
	override private function get_vertexTangentOffset():Int
	{
		return 6;
	}
	
	override private function get_UVOffset():Int
	{
		return 9;
	}
	
	private function get_secondaryUVOffset():Int
	{
		return 11;
	}
	
	override public function dispose():Void
	{
		super.dispose();
		disposeVertexBuffers(_vertexBuffer);
		_vertexBuffer = null;
	}
	
	override private function disposeVertexBuffers(buffers:Vector<VertexBuffer3D>):Void
	{
		super.disposeVertexBuffers(buffers);
		_activeBuffer = null;
	}
	
	override private function invalidateBuffers(invalid:Vector<Bool>):Void
	{
		super.invalidateBuffers(invalid);
		_activeDataInvalid = true;
	}
	
	public function cloneWithSeperateBuffers():SubGeometry
	{
		var clone:SubGeometry = new SubGeometry();
		clone.updateVertexData(_isolatedVertexPositionData != null? _isolatedVertexPositionData : _isolatedVertexPositionData = stripBuffer(0, 3));
		clone.autoDeriveVertexNormals = _autoDeriveVertexNormals;
		clone.autoDeriveVertexTangents = _autoDeriveVertexTangents;
		if (!_autoDeriveVertexNormals)
			clone.updateVertexNormalData(stripBuffer(3, 3));
		if (!_autoDeriveVertexTangents)
			clone.updateVertexTangentData(stripBuffer(6, 3));
		clone.updateUVData(stripBuffer(9, 2));
		clone.updateSecondaryUVData(stripBuffer(11, 2));
		clone.updateIndexData(indexData.concat());
		return clone;
	}
	
	override private function get_vertexPositionData():Vector<Float>
	{
		if (_isolatedVertexPositionDataDirty || _isolatedVertexPositionData == null) {
			_isolatedVertexPositionData = stripBuffer(0, 3);
			_isolatedVertexPositionDataDirty = false;
		}
		return _isolatedVertexPositionData;
	}
	
	/**
	 * Isolate and returns a Vector.Number of a specific buffer type
	 *
	 * - stripBuffer(0, 3), return only the vertices
	 * - stripBuffer(3, 3): return only the normals
	 * - stripBuffer(6, 3): return only the tangents
	 * - stripBuffer(9, 2): return only the uv's
	 * - stripBuffer(11, 2): return only the secondary uv's
	 */
	public function stripBuffer(offset:Int, numEntries:Int):Vector<Float>
	{
		var data:Vector<Float> = new Vector<Float>(_numVertices*numEntries);
		var i:Int = 0, j:Int = offset;
		var skip:Int = 13 - numEntries;
		
		for (v in 0..._numVertices) {
			for (k in 0...numEntries)
				data[i++] = _vertexData[j++];
			j += skip;
		}
		
		return data;
	}
	
	public function fromVectors(verts:Vector<Float>, uvs:Vector<Float>, normals:Vector<Float>, tangents:Vector<Float>):Void
	{
		var vertLen:Int = Std.int(verts.length/3*13);
		
		var index:Int = 0;
		var v:Int = 0;
		var n:Int = 0;
		var t:Int = 0;
		var u:Int = 0;
		
		var data:Vector<Float> = new Vector<Float>(vertLen, true);
		
		while (index < vertLen) {
			data[index++] = verts[v++];
			data[index++] = verts[v++];
			data[index++] = verts[v++];
			
			if (normals != null && normals.length > 0) {
				data[index++] = normals[n++];
				data[index++] = normals[n++];
				data[index++] = normals[n++];
			} else {
				data[index++] = 0;
				data[index++] = 0;
				data[index++] = 0;
			}
			
			if (tangents != null && tangents.length > 0) {
				data[index++] = tangents[t++];
				data[index++] = tangents[t++];
				data[index++] = tangents[t++];
			} else {
				data[index++] = 0;
				data[index++] = 0;
				data[index++] = 0;
			}
			
			if (uvs != null && uvs.length > 0) {
				data[index++] = uvs[u];
				data[index++] = uvs[u + 1];
				// use same secondary uvs as primary
				data[index++] = uvs[u++];
				data[index++] = uvs[u++];
			} else {
				data[index++] = 0;
				data[index++] = 0;
				data[index++] = 0;
				data[index++] = 0;
			}
		}
		
		autoDeriveVertexNormals = !(normals != null && normals.length > 0);
		autoDeriveVertexTangents = !(tangents != null && tangents.length > 0);
		autoGenerateDummyUVs = !(uvs != null && uvs.length > 0);
		updateData(data);
	}
}