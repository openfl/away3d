package away3d.animators.data;

	import away3d.core.managers.Stage3DProxy;
	
	import flash.display3D.Context3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.Context3DVertexBufferFormat;

	import flash.Vector;

	import away3d.utils.ArrayUtils;
	
	/**
	 * ...
	 */
	class AnimationSubGeometry
	{
		var _vertexData:Array<Float>;
		
		var _vertexBuffer:Array<VertexBuffer3D>;
		var _bufferContext:Array<Context3D>;
		var _bufferDirty:Array<Bool>;
		
		var _numVertices:UInt;
		
		var _totalLenOfOneVertex:UInt;
		
		public var numProcessedVertices:Int;
		
		public var previousTime:Float;
		
		public var animationParticles:Array<ParticleAnimationData>;
		
		public function new()
		{
			_vertexBuffer = ArrayUtils.Prefill(new Array<VertexBuffer3D>(), 8);
			_bufferContext = ArrayUtils.Prefill(new Array<Context3D>(), 8);
			_bufferDirty = ArrayUtils.Prefill(new Array<Bool>(), 8);

			numProcessedVertices = 0;
		
			previousTime = Math.NEGATIVE_INFINITY;
		
			animationParticles = new Array<ParticleAnimationData>();

			// For loop conversion - 			for (var i:Int = 0; i < 8; i++)
			var i:Int;
			for (i in 0...8)
				_bufferDirty[i] = true;
		}
		
		public function createVertexData(numVertices:UInt, totalLenOfOneVertex:UInt):Void
		{
			_numVertices = numVertices;
			_totalLenOfOneVertex = totalLenOfOneVertex;
			_vertexData = new Array<Float>();
		}
		
		public function activateVertexBuffer(index:Int, bufferOffset:Int, stage3DProxy:Stage3DProxy, format:Context3DVertexBufferFormat):Void
		{
			var contextIndex:Int = stage3DProxy.stage3DIndex;
			var context:Context3D = stage3DProxy.context3D;
			
			var buffer:VertexBuffer3D = _vertexBuffer[contextIndex];
			if (buffer==null || _bufferContext[contextIndex] != context) {
				buffer = _vertexBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _totalLenOfOneVertex);
				_bufferContext[contextIndex] = context;
				_bufferDirty[contextIndex] = true;
			}
			if (_bufferDirty[contextIndex]) {
				buffer.uploadFromVector(Vector.ofArray(_vertexData), 0, _numVertices);
				_bufferDirty[contextIndex] = false;
			}
			context.setVertexBufferAt(index, buffer, bufferOffset, format);
		}
		
		public function dispose():Void
		{
			while (_vertexBuffer.length>0) {
				var vertexBuffer:VertexBuffer3D = _vertexBuffer.pop();
				
				if (vertexBuffer!=null)
					vertexBuffer.dispose();
			}
		}
		
		public function invalidateBuffer():Void
		{
			// For loop conversion - 			for (var i:Int = 0; i < 8; i++)
			var i:Int;
			for (i in 0...8)
				_bufferDirty[i] = true;
		}
		
		public var vertexData(get, null) : Array<Float>;
		
		public function get_vertexData() : Array<Float>
		{
			return _vertexData;
		}
		
		public var numVertices(get, null) : UInt;
		
		public function get_numVertices() : UInt
		{
			return _numVertices;
		}
		
		public var totalLenOfOneVertex(get, null) : UInt;
		
		public function get_totalLenOfOneVertex() : UInt
		{
			return _totalLenOfOneVertex;
		}
	}

