package away3d.core.base;

import away3d.core.base.data.VertexDefinition;
import away3d.core.managers.Stage3DProxy;

import openfl.display3D.Context3D;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.VertexBuffer3D;
import openfl.errors.Error;
import openfl.geom.Matrix3D;
import openfl.Vector;

class CompactSubGeometry extends SubGeometryBase implements ISubGeometry
{
	public var definition(default, null):VertexDefinition;

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

	public function new(?definition:VertexDefinition)
	{
		super();
		_autoDeriveVertexNormals = false;
		_autoDeriveVertexTangents = false;
		this.definition = definition != null ? definition : VertexDefinition.defaultVertexDefinition;
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
		var numVertices:Int = Std.int(_vertexData.length/definition.length);
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
		activateVertexBufferByName("position", index, stage3DProxy);
	}

	public function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		if (_uvsDirty && _autoGenerateUVs) {
			_vertexData = updateDummyUVs(_vertexData);
			invalidateBuffers(_vertexDataInvalid);
		}

		activateVertexBufferByName("UV", index, stage3DProxy);
	}

	public function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		activateVertexBufferByName("secondaryUV", index, stage3DProxy);
	}

	private function uploadData(contextIndex:Int):Void
	{
		_activeBuffer.uploadFromVector(_vertexData, 0, _numVertices);
		_vertexDataInvalid[contextIndex] = _activeDataInvalid = false;
	}

	public function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		activateVertexBufferByName("normal", index, stage3DProxy);
	}

	public function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		activateVertexBufferByName("tangent", index, stage3DProxy);
	}

	public function activateVertexBufferByName(attributeName:String, index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var attribute:AttributeDefinition = definition.get(attributeName);
		if (attribute == null)
		{
			return;
		}

		var contextIndex:Int = stage3DProxy._stage3DIndex;
		var context:Context3D = stage3DProxy._context3D;

		if (contextIndex != _contextIndex)
			updateActiveBuffer(contextIndex);

		if (_activeBuffer == null || _activeContext != context)
			createBuffer(contextIndex, context, stage3DProxy);
		if (_activeDataInvalid)
			uploadData(contextIndex);

		context.setVertexBufferAt(index, _activeBuffer, attribute.offset, attribute.vertexBufferFormat);
	}

	private function createBuffer(contextIndex:Int, context:Context3D, stage3DProxy:Stage3DProxy):Void
	{
		_vertexBuffer[contextIndex] = _activeBuffer = stage3DProxy.createVertexBuffer(_numVertices, definition.length);
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
		var clone:CompactSubGeometry = new CompactSubGeometry(definition);
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
		return definition.length;
	}

	override private function get_vertexNormalStride():Int
	{
		return definition.length;
	}

	override private function get_vertexTangentStride():Int
	{
		return definition.length;
	}

	override private function get_UVStride():Int
	{
		return definition.length;
	}

	private function get_secondaryUVStride():Int
	{
		return definition.length;
	}

	override private function get_vertexOffset():Int
	{
		return getAttributeOffset("position");
	}

	override private function get_vertexNormalOffset():Int
	{
		return getAttributeOffset("normal");
	}

	override private function get_vertexTangentOffset():Int
	{
		return getAttributeOffset("tangent");
	}

	override private function get_UVOffset():Int
	{
		return getAttributeOffset("UV");
	}

	private function get_secondaryUVOffset():Int
	{
		return getAttributeOffset("secondaryUV");
	}

	private inline function getAttributeOffset(attributeName:String):Int
	{
		var attribute:AttributeDefinition = definition.get(attributeName);
		return attribute != null ? attribute.offset : 0;
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
		clone.updateVertexData(get_vertexPositionData());
		clone.autoDeriveVertexNormals = _autoDeriveVertexNormals;
		clone.autoDeriveVertexTangents = _autoDeriveVertexTangents;
		if (!_autoDeriveVertexNormals)
			clone.updateVertexNormalData(isolateAttribute("normal"));
		if (!_autoDeriveVertexTangents)
			clone.updateVertexTangentData(isolateAttribute("tangent"));
		clone.updateUVData(isolateAttribute("UV"));
		clone.updateSecondaryUVData(isolateAttribute("secondaryUV"));
		clone.updateIndexData(indexData.concat());
		return clone;
	}

	override private function get_vertexPositionData():Vector<Float>
	{
		if (_isolatedVertexPositionDataDirty || _isolatedVertexPositionData == null) {
			_isolatedVertexPositionData = isolateAttribute("position");
			_isolatedVertexPositionDataDirty = false;
		}
		return _isolatedVertexPositionData;
	}

	/**
	 * Isolates and returns all data for the attribute with the given name,
	 * typically one of "position", "normal", "tangent", "UV", or "secondaryUV".
	 */
	public function isolateAttribute(name:String):Vector<Float>
	{
		var attribute:AttributeDefinition = definition.get(name);
		if (attribute != null)
		{
			return stripBuffer(attribute.offset, attribute.length);
		}
		else
		{
			return null;
		}
	}

	/**
	 * Isolates and returns a specific subset of this geometry.
	 * @see `isolateAttribute`
	 */
	public function stripBuffer(offset:Int, numEntries:Int):Vector<Float>
	{
		var data:Vector<Float> = new Vector<Float>(_numVertices*numEntries);
		var i:Int = 0, j:Int = offset;
		var skip:Int = definition.length - numEntries;

		for (v in 0..._numVertices) {
			for (k in 0...numEntries)
				data[i++] = _vertexData[j++];
			j += skip;
		}

		return data;
	}

	public function setAttributeData(attributeName:String, data:Vector<Float>):Void
	{
		if (_setAttributeData(attributeName, data))
		{
			updateData(_vertexData);
		}
	}

	private function _setAttributeData(attributeName:String, data:Vector<Float>):Bool
	{
		var attribute:AttributeDefinition = definition.get(attributeName);
		if (data == null || attribute == null)
		{
			return false;
		}

		if (_vertexData == null)
		{
			_vertexData = new Vector(definition.length * Std.int(data.length / attribute.length));
		}

		var attributeLength:Int = attribute.length;
		var vertexLength:Int = _vertexData.length;

		var inputIndex:Int = 0;
		var outputIndex:Int = attribute.offset;
		while (inputIndex + attributeLength < data.length
			&& outputIndex + attributeLength < _vertexData.length)
		{
			for (i in 0...attributeLength)
			{
				_vertexData[outputIndex + i] = data[inputIndex + i];
			}

			inputIndex += attributeLength;
			outputIndex += vertexLength;
		}

		return true;
	}

	public function fromVectors(positions:Vector<Float>, uvs:Vector<Float>, normals:Vector<Float>, tangents:Vector<Float>):Void
	{
		if (positions != null)
		{
			var newLength:Int = Std.int(positions.length / 3 * definition.length);
			var oldLength:Int = _vertexData != null ? _vertexData.length : 0;
			if (newLength < oldLength)
			{
				_vertexData = _vertexData.slice(0, newLength);
			}
			else if (newLength > oldLength)
			{
				var newData:Vector<Float> = new Vector<Float>(newLength, true);
				for (i in 0...oldLength)
				{
					newData[i] = _vertexData[i];
				}
				_vertexData = newData;
			}

			_setAttributeData("position", positions);
		}

		_setAttributeData("normal", normals);
		autoDeriveVertexNormals = !(normals != null && normals.length > 0);

		_setAttributeData("tangent", tangents);
		autoDeriveVertexTangents = !(tangents != null && tangents.length > 0);

		_setAttributeData("UV", uvs);
		autoGenerateDummyUVs = !(uvs != null && uvs.length > 0);

		updateData(_vertexData);
	}
}
