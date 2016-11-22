package away3d.core.base;

import away3d.core.managers.Stage3DProxy;

import openfl.display3D.Context3D;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.VertexBuffer3D;
import openfl.geom.Matrix3D;
import openfl.Vector;

/**
 * The SubGeometry class is a collections of geometric data that describes a triangle mesh. It is owned by a
 * Geometry instance, and wrapped by a SubMesh in the scene graph.
 * Several SubGeometries are grouped so they can be rendered with different materials, but still represent a single
 * object.
 *
 * @see away3d.core.base.Geometry
 * @see away3d.core.base.SubMesh
 */
class SubGeometry extends SubGeometryBase implements ISubGeometry
{
	public var numVertices(get, never):Int;
	public var secondaryUVData(get, never):Vector<Float>;
	public var secondaryUVStride(get, never):Int;
	public var secondaryUVOffset(get, never):Int;
	
	// raw data:
	private var _uvs:Vector<Float>;
	private var _secondaryUvs:Vector<Float>;
	private var _vertexNormals:Vector<Float>;
	private var _vertexTangents:Vector<Float>;
	
	private var _verticesInvalid:Vector<Bool> = new Vector<Bool>(8, true);
	private var _uvsInvalid:Vector<Bool> = new Vector<Bool>(8, true);
	private var _secondaryUvsInvalid:Vector<Bool> = new Vector<Bool>(8, true);
	private var _normalsInvalid:Vector<Bool> = new Vector<Bool>(8, true);
	private var _tangentsInvalid:Vector<Bool> = new Vector<Bool>(8, true);
	
	// buffers:
	private var _vertexBuffer:Vector<VertexBuffer3D> = new Vector<VertexBuffer3D>(8);
	private var _uvBuffer:Vector<VertexBuffer3D> = new Vector<VertexBuffer3D>(8);
	private var _secondaryUvBuffer:Vector<VertexBuffer3D> = new Vector<VertexBuffer3D>(8);
	private var _vertexNormalBuffer:Vector<VertexBuffer3D> = new Vector<VertexBuffer3D>(8);
	private var _vertexTangentBuffer:Vector<VertexBuffer3D> = new Vector<VertexBuffer3D>(8);
	
	// buffer dirty flags, per context:
	private var _vertexBufferContext:Vector<Context3D> = new Vector<Context3D>(8);
	private var _uvBufferContext:Vector<Context3D> = new Vector<Context3D>(8);
	private var _secondaryUvBufferContext:Vector<Context3D> = new Vector<Context3D>(8);
	private var _vertexNormalBufferContext:Vector<Context3D> = new Vector<Context3D>(8);
	private var _vertexTangentBufferContext:Vector<Context3D> = new Vector<Context3D>(8);
	
	private var _numVertices:Int;
	
	/**
	 * Creates a new SubGeometry object.
	 */
	public function new()
	{
		super();
	}
	
	/**
	 * The total amount of vertices in the SubGeometry.
	 */
	private function get_numVertices():Int
	{
		return _numVertices;
	}
	
	/**
	 * @inheritDoc
	 */
	public function activateVertexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy._stage3DIndex;
		var context:Context3D = stage3DProxy._context3D;
		if (_vertexBuffer[contextIndex] == null || _vertexBufferContext[contextIndex] != context) {
			_vertexBuffer[contextIndex] = stage3DProxy.createVertexBuffer(_numVertices, 3);
			_vertexBufferContext[contextIndex] = context;
			_verticesInvalid[contextIndex] = true;
		}
		if (_verticesInvalid[contextIndex]) {
			_vertexBuffer[contextIndex].uploadFromVector(_vertexData, 0, _numVertices);
			_verticesInvalid[contextIndex] = false;
		}
		
		context.setVertexBufferAt(index, _vertexBuffer[contextIndex], 0, Context3DVertexBufferFormat.FLOAT_3);
	}
	
	/**
	 * @inheritDoc
	 */
	public function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy._stage3DIndex;
		var context:Context3D = stage3DProxy._context3D;
		
		if (_autoGenerateUVs && _uvsDirty)
			_uvs = updateDummyUVs(_uvs);
		
		if (_uvBuffer[contextIndex] == null || _uvBufferContext[contextIndex] != context) {
			_uvBuffer[contextIndex] = stage3DProxy.createVertexBuffer(_numVertices, 2);
			_uvBufferContext[contextIndex] = context;
			_uvsInvalid[contextIndex] = true;
		}
		if (_uvsInvalid[contextIndex]) {
			_uvBuffer[contextIndex].uploadFromVector(_uvs, 0, _numVertices);
			_uvsInvalid[contextIndex] = false;
		}
		
		context.setVertexBufferAt(index, _uvBuffer[contextIndex], 0, Context3DVertexBufferFormat.FLOAT_2);
	}
	
	/**
	 * @inheritDoc
	 */
	public function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy._stage3DIndex;
		var context:Context3D = stage3DProxy._context3D;
		
		if (_secondaryUvBuffer[contextIndex] == null || _secondaryUvBufferContext[contextIndex] != context) {
			_secondaryUvBuffer[contextIndex] = stage3DProxy.createVertexBuffer(_numVertices, 2);
			_secondaryUvBufferContext[contextIndex] = context;
			_secondaryUvsInvalid[contextIndex] = true;
		}
		if (_secondaryUvsInvalid[contextIndex]) {
			_secondaryUvBuffer[contextIndex].uploadFromVector(_secondaryUvs, 0, _numVertices);
			_secondaryUvsInvalid[contextIndex] = false;
		}
		
		context.setVertexBufferAt(index, _secondaryUvBuffer[contextIndex], 0, Context3DVertexBufferFormat.FLOAT_2);
	}
	
	/**
	 * Retrieves the VertexBuffer3D object that contains vertex normals.
	 * @param context The Context3D for which we request the buffer
	 * @return The VertexBuffer3D object that contains vertex normals.
	 */
	public function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy._stage3DIndex;
		var context:Context3D = stage3DProxy._context3D;
		
		if (_autoDeriveVertexNormals && _vertexNormalsDirty)
			_vertexNormals = updateVertexNormals(_vertexNormals);
		
		if (_vertexNormalBuffer[contextIndex] == null || _vertexNormalBufferContext[contextIndex] != context) {
			_vertexNormalBuffer[contextIndex] = stage3DProxy.createVertexBuffer(_numVertices, 3);
			_vertexNormalBufferContext[contextIndex] = context;
			_normalsInvalid[contextIndex] = true;
		}
		if (_normalsInvalid[contextIndex]) {
			_vertexNormalBuffer[contextIndex].uploadFromVector(_vertexNormals, 0, _numVertices);
			_normalsInvalid[contextIndex] = false;
		}
		
		context.setVertexBufferAt(index, _vertexNormalBuffer[contextIndex], 0, Context3DVertexBufferFormat.FLOAT_3);
	}
	
	/**
	 * Retrieves the VertexBuffer3D object that contains vertex tangents.
	 * @param context The Context3D for which we request the buffer
	 * @return The VertexBuffer3D object that contains vertex tangents.
	 */
	public function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy._stage3DIndex;
		var context:Context3D = stage3DProxy._context3D;
		
		if (_vertexTangentsDirty)
			_vertexTangents = updateVertexTangents(_vertexTangents);
		
		if (_vertexTangentBuffer[contextIndex] == null || _vertexTangentBufferContext[contextIndex] != context) {
			_vertexTangentBuffer[contextIndex] = stage3DProxy.createVertexBuffer(_numVertices, 3);
			_vertexTangentBufferContext[contextIndex] = context;
			_tangentsInvalid[contextIndex] = true;
		}
		if (_tangentsInvalid[contextIndex]) {
			_vertexTangentBuffer[contextIndex].uploadFromVector(_vertexTangents, 0, _numVertices);
			_tangentsInvalid[contextIndex] = false;
		}
		context.setVertexBufferAt(index, _vertexTangentBuffer[contextIndex], 0, Context3DVertexBufferFormat.FLOAT_3);
	}
	
	override public function applyTransformation(transform:Matrix3D):Void
	{
		super.applyTransformation(transform);
		invalidateBuffers(_verticesInvalid);
		invalidateBuffers(_normalsInvalid);
		invalidateBuffers(_tangentsInvalid);
	}
	
	/**
	 * Clones the current object
	 * @return An exact duplicate of the current object.
	 */
	public function clone():ISubGeometry
	{
		var clone:SubGeometry = new SubGeometry();
		clone.updateVertexData(_vertexData.concat());
		clone.updateUVData(_uvs.concat());
		clone.updateIndexData(_indices.concat());
		if (_secondaryUvs != null)
			clone.updateSecondaryUVData(_secondaryUvs.concat());
		if (!_autoDeriveVertexNormals)
			clone.updateVertexNormalData(_vertexNormals.concat());
		if (!_autoDeriveVertexTangents)
			clone.updateVertexTangentData(_vertexTangents.concat());
		return clone;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function scale(scale:Float):Void
	{
		super.scale(scale);
		invalidateBuffers(_verticesInvalid);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function scaleUV(scaleU:Float = 1, scaleV:Float = 1):Void
	{
		super.scaleUV(scaleU, scaleV);
		invalidateBuffers(_uvsInvalid);
	}
	
	/**
	 * Clears all resources used by the SubGeometry object.
	 */
	override public function dispose():Void
	{
		super.dispose();
		disposeAllVertexBuffers();
		_vertexBuffer = null;
		_vertexNormalBuffer = null;
		_uvBuffer = null;
		_secondaryUvBuffer = null;
		_vertexTangentBuffer = null;
		_indexBuffer = null;
		_uvs = null;
		_secondaryUvs = null;
		_vertexNormals = null;
		_vertexTangents = null;
		_vertexBufferContext = null;
		_uvBufferContext = null;
		_secondaryUvBufferContext = null;
		_vertexNormalBufferContext = null;
		_vertexTangentBufferContext = null;
	}
	
	private function disposeAllVertexBuffers():Void
	{
		disposeVertexBuffers(_vertexBuffer);
		disposeVertexBuffers(_vertexNormalBuffer);
		disposeVertexBuffers(_uvBuffer);
		disposeVertexBuffers(_secondaryUvBuffer);
		disposeVertexBuffers(_vertexTangentBuffer);
	}
	
	/**
	 * The raw vertex position data.
	 */
	override private function get_vertexData():Vector<Float>
	{
		return _vertexData;
	}
	
	override private function get_vertexPositionData():Vector<Float>
	{
		return _vertexData;
	}
	
	/**
	 * Updates the vertex data of the SubGeometry.
	 * @param vertices The new vertex data to upload.
	 */
	public function updateVertexData(vertices:Vector<Float>):Void
	{
		if (_autoDeriveVertexNormals)
			_vertexNormalsDirty = true;
		if (_autoDeriveVertexTangents)
			_vertexTangentsDirty = true;
		
		_faceNormalsDirty = true;
		
		_vertexData = vertices;
		var numVertices:Int = Std.int(vertices.length/3);
		if (numVertices != _numVertices)
			disposeAllVertexBuffers();
		_numVertices = numVertices;
		
		invalidateBuffers(_verticesInvalid);
		
		invalidateBounds();
	}
	
	/**
	 * The raw texture coordinate data.
	 */
	override private function get_UVData():Vector<Float>
	{
		if (_uvsDirty && _autoGenerateUVs)
			_uvs = updateDummyUVs(_uvs);
		return _uvs;
	}
	
	private function get_secondaryUVData():Vector<Float>
	{
		return _secondaryUvs;
	}
	
	/**
	 * Updates the uv coordinates of the SubGeometry.
	 * @param uvs The uv coordinates to upload.
	 */
	public function updateUVData(uvs:Vector<Float>):Void
	{
		// normals don't get dirty from this
		if (_autoDeriveVertexTangents)
			_vertexTangentsDirty = true;
		_faceTangentsDirty = true;
		_uvs = uvs;
		invalidateBuffers(_uvsInvalid);
	}
	
	public function updateSecondaryUVData(uvs:Vector<Float>):Void
	{
		_secondaryUvs = uvs;
		invalidateBuffers(_secondaryUvsInvalid);
	}
	
	/**
	 * The raw vertex normal data.
	 */
	override private function get_vertexNormalData():Vector<Float>
	{
		if (_autoDeriveVertexNormals && _vertexNormalsDirty)
			_vertexNormals = updateVertexNormals(_vertexNormals);
		return _vertexNormals;
	}
	
	/**
	 * Updates the vertex normals of the SubGeometry. When updating the vertex normals like this,
	 * autoDeriveVertexNormals will be set to false and vertex normals will no longer be calculated automatically.
	 * @param vertexNormals The vertex normals to upload.
	 */
	public function updateVertexNormalData(vertexNormals:Vector<Float>):Void
	{
		_vertexNormalsDirty = false;
		_autoDeriveVertexNormals = (vertexNormals == null);
		_vertexNormals = vertexNormals;
		invalidateBuffers(_normalsInvalid);
	}
	
	/**
	 * The raw vertex tangent data.
	 *
	 * @private
	 */
	override private function get_vertexTangentData():Vector<Float>
	{
		if (_autoDeriveVertexTangents && _vertexTangentsDirty)
			_vertexTangents = updateVertexTangents(_vertexTangents);
		return _vertexTangents;
	}
	
	/**
	 * Updates the vertex tangents of the SubGeometry. When updating the vertex tangents like this,
	 * autoDeriveVertexTangents will be set to false and vertex tangents will no longer be calculated automatically.
	 * @param vertexTangents The vertex tangents to upload.
	 */
	public function updateVertexTangentData(vertexTangents:Vector<Float>):Void
	{
		_vertexTangentsDirty = false;
		_autoDeriveVertexTangents = (vertexTangents == null);
		_vertexTangents = vertexTangents;
		invalidateBuffers(_tangentsInvalid);
	}
	
	public function fromVectors(vertices:Vector<Float>, uvs:Vector<Float>, normals:Vector<Float>, tangents:Vector<Float>):Void
	{
		updateVertexData(vertices);
		updateUVData(uvs);
		updateVertexNormalData(normals);
		updateVertexTangentData(tangents);
	}
	
	override private function updateVertexNormals(target:Vector<Float>):Vector<Float>
	{
		invalidateBuffers(_normalsInvalid);
		return super.updateVertexNormals(target);
	}
	
	override private function updateVertexTangents(target:Vector<Float>):Vector<Float>
	{
		if (_vertexNormalsDirty)
			_vertexNormals = updateVertexNormals(_vertexNormals);
		invalidateBuffers(_tangentsInvalid);
		return super.updateVertexTangents(target);
	}
	
	override private function updateDummyUVs(target:Vector<Float>):Vector<Float>
	{
		invalidateBuffers(_uvsInvalid);
		return super.updateDummyUVs(target);
	}
	
	private function disposeForStage3D(stage3DProxy:Stage3DProxy):Void
	{
		var index:Int = stage3DProxy._stage3DIndex;
		if (_vertexBuffer[index] != null) {
			Stage3DProxy.disposeVertexBuffer(_vertexBuffer[index]);
			_vertexBuffer[index] = null;
		}
		if (_uvBuffer[index] != null) {
			Stage3DProxy.disposeVertexBuffer(_uvBuffer[index]);
			_uvBuffer[index] = null;
		}
		if (_secondaryUvBuffer[index] != null) {
			Stage3DProxy.disposeVertexBuffer(_secondaryUvBuffer[index]);
			_secondaryUvBuffer[index] = null;
		}
		if (_vertexNormalBuffer[index] != null) {
			Stage3DProxy.disposeVertexBuffer(_vertexNormalBuffer[index]);
			_vertexNormalBuffer[index] = null;
		}
		if (_vertexTangentBuffer[index] != null) {
			Stage3DProxy.disposeVertexBuffer(_vertexTangentBuffer[index]);
			_vertexTangentBuffer[index] = null;
		}
		if (_indexBuffer[index] != null) {
			Stage3DProxy.disposeIndexBuffer(_indexBuffer[index]);
			_indexBuffer[index] = null;
		}
	}
	
	override private function get_vertexStride():Int
	{
		return 3;
	}
	
	override private function get_vertexTangentStride():Int
	{
		return 3;
	}
	
	override private function get_vertexNormalStride():Int
	{
		return 3;
	}
	
	override private function get_UVStride():Int
	{
		return 2;
	}
	
	private function get_secondaryUVStride():Int
	{
		return 2;
	}
	
	override private function get_vertexOffset():Int
	{
		return 0;
	}
	
	override private function get_vertexNormalOffset():Int
	{
		return 0;
	}
	
	override private function get_vertexTangentOffset():Int
	{
		return 0;
	}
	
	override private function get_UVOffset():Int
	{
		return 0;
	}
	
	private function get_secondaryUVOffset():Int
	{
		return 0;
	}
	
	public function cloneWithSeperateBuffers():SubGeometry
	{
		return cast(clone(), SubGeometry);
	}
}