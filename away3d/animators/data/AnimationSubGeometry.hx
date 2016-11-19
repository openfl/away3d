package away3d.animators.data;

import away3d.core.managers.Stage3DProxy;

import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.Context3D;
import openfl.display3D.VertexBuffer3D;
import openfl.Vector;

/**
 * ...
 */
class AnimationSubGeometry
{
	public var vertexData(get, never):Vector<Float>;
	public var numVertices(get, never):Int;
	public var totalLenOfOneVertex(get, never):Int;
	
	private var _vertexData:Vector<Float>;
	
	private var _vertexBuffer:Vector<VertexBuffer3D> = new Vector<VertexBuffer3D>(8);
	private var _bufferContext:Vector<Context3D> = new Vector<Context3D>(8);
	private var _bufferDirty:Vector<Bool> = new Vector<Bool>(8);
	
	private var _numVertices:Int;
	
	private var _totalLenOfOneVertex:Int;
	
	public var numProcessedVertices:Int = 0;
	
	public var previousTime:Float = Math.NEGATIVE_INFINITY;
	
	public var animationParticles:Vector<ParticleAnimationData> = new Vector<ParticleAnimationData>();
	
	public function new()
	{
		for (i in 0...8)
			_bufferDirty[i] = true;
	}
	
	public function createVertexData(numVertices:Int, totalLenOfOneVertex:Int):Void
	{
		_numVertices = numVertices;
		_totalLenOfOneVertex = totalLenOfOneVertex;
		_vertexData = new Vector<Float>(numVertices*totalLenOfOneVertex);
	}
	
	public function activateVertexBuffer(index:Int, bufferOffset:Int, stage3DProxy:Stage3DProxy, format:Context3DVertexBufferFormat):Void
	{
		var contextIndex:Int = stage3DProxy.stage3DIndex;
		var context:Context3D = stage3DProxy.context3D;
		
		var buffer:VertexBuffer3D = _vertexBuffer[contextIndex];
		if (buffer == null || _bufferContext[contextIndex] != context) {
			buffer = _vertexBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _totalLenOfOneVertex);
			_bufferContext[contextIndex] = context;
			_bufferDirty[contextIndex] = true;
		}
		if (_bufferDirty[contextIndex]) {
			buffer.uploadFromVector(_vertexData, 0, _numVertices);
			_bufferDirty[contextIndex] = false;
		}
		context.setVertexBufferAt(index, buffer, bufferOffset, format);
	}
	
	public function dispose():Void
	{
		while (_vertexBuffer.length > 0) {
			var vertexBuffer:VertexBuffer3D = _vertexBuffer.pop();
			
			if (vertexBuffer != null)
				vertexBuffer.dispose();
		}
	}
	
	public function invalidateBuffer():Void
	{
		for (i in 0...8) 
			_bufferDirty[i] = true;
	}
	
	private function get_vertexData():Vector<Float>
	{
		return _vertexData;
	}
	
	private function get_numVertices():Int
	{
		return _numVertices;
	}
	
	private function get_totalLenOfOneVertex():Int
	{
		return _totalLenOfOneVertex;
	}
}