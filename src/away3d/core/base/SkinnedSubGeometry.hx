package away3d.core.base;

	//import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	
	import flash.display3D.Context3D;
	import flash.display3D.VertexBuffer3D;
	import flash.utils.Dictionary;
	
	import flash.display3D.Context3DVertexBufferFormat;

	import flash.Vector;

	//use namespace arcane;
	
	/**
	 * SkinnedSubGeometry provides a SubGeometry extension that contains data needed to skin vertices. In particular,
	 * it provides joint indices and weights.
	 * Important! Joint indices need to be pre-multiplied by 3, since they index the matrix array (and each matrix has 3 float4 elements)
	 */
	class SkinnedSubGeometry extends CompactSubGeometry
	{
		var _bufferFormat:Context3DVertexBufferFormat;
		var _jointWeightsData:Array<Float>;
		var _jointIndexData:Array<Float>;
		var _animatedData:Array<Float>; // used for cpu fallback
		var _jointWeightsBuffer:Array<VertexBuffer3D> ;
		var _jointIndexBuffer:Array<VertexBuffer3D>;
		var _jointWeightsInvalid:Array<Bool>;
		var _jointIndicesInvalid:Array<Bool>;
		var _jointWeightContext:Array<Context3D>;
		var _jointIndexContext:Array<Context3D>;
		var _jointsPerVertex:Int;
		
		var _condensedJointIndexData:Array<Float>;
		var _condensedIndexLookUp:Array<UInt>; // used for linking condensed indices to the real ones
		var _numCondensedJoints:UInt;
		
		/**
		 * Creates a new SkinnedSubGeometry object.
		 * @param jointsPerVertex The amount of joints that can be assigned per vertex.
		 */
		public function new(jointsPerVertex:Int)
		{
			super();
			_jointWeightsBuffer = new Array<VertexBuffer3D>();
			_jointIndexBuffer = new Array<VertexBuffer3D>();
			_jointWeightsInvalid = new Array<Bool>();
			_jointIndicesInvalid = new Array<Bool>();
			_jointWeightContext = new Array<Context3D>();
			_jointIndexContext = new Array<Context3D>();
			
			_jointsPerVertex = jointsPerVertex;
			switch (_jointsPerVertex) {
				case 1: _bufferFormat = Context3DVertexBufferFormat.FLOAT_1;
				case 2: _bufferFormat = Context3DVertexBufferFormat.FLOAT_2;
				case 3: _bufferFormat = Context3DVertexBufferFormat.FLOAT_3;
				default: _bufferFormat = Context3DVertexBufferFormat.FLOAT_4;
			}			
		}
		
		/**
		 * If indices have been condensed, this will contain the original index for each condensed index.
		 */
		public var condensedIndexLookUp(get, null) : Array<UInt>;
		public function get_condensedIndexLookUp() : Array<UInt>
		{
			return _condensedIndexLookUp;
		}
		
		/**
		 * The amount of joints used when joint indices have been condensed.
		 */
		public var numCondensedJoints(get, null) : UInt;
		public function get_numCondensedJoints() : UInt
		{
			return _numCondensedJoints;
		}
		
		/**
		 * The animated vertex positions when set explicitly if the skinning transformations couldn't be performed on GPU.
		 */
		public var animatedData(get, null) : Array<Float>;
		public function get_animatedData() : Array<Float>
		{
			return _animatedData!=null ? _animatedData : Lambda.array(_vertexData);
		}
		
		public function updateAnimatedData(value:Array<Float>):Void
		{
			_animatedData = value;
			invalidateBuffers(_vertexDataInvalid);
		}
		
		/**
		 * Assigns the attribute stream for joint weights
		 * @param index The attribute stream index for the vertex shader
		 * @param stage3DProxy The Stage3DProxy to assign the stream to
		 */
		public function activateJointWeightsBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
			var contextIndex:Int = stage3DProxy._stage3DIndex;
			var context:Context3D = stage3DProxy._context3D;
			if (_jointWeightContext[contextIndex] != context || _jointWeightsBuffer[contextIndex]==null) {
				_jointWeightsBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _jointsPerVertex);
				_jointWeightContext[contextIndex] = context;
				_jointWeightsInvalid[contextIndex] = true;
			}
			if (_jointWeightsInvalid[contextIndex]) {
				_jointWeightsBuffer[contextIndex].uploadFromVector(Vector.ofArray(_jointWeightsData), 0, Std.int(_jointWeightsData.length/_jointsPerVertex));
				_jointWeightsInvalid[contextIndex] = false;
			}
			context.setVertexBufferAt(index, _jointWeightsBuffer[contextIndex], 0, _bufferFormat);
		}
		
		/**
		 * Assigns the attribute stream for joint indices
		 * @param index The attribute stream index for the vertex shader
		 * @param stage3DProxy The Stage3DProxy to assign the stream to
		 */
		public function activateJointIndexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
			var contextIndex:Int = stage3DProxy._stage3DIndex;
			var context:Context3D = stage3DProxy._context3D;
			
			if (_jointIndexContext[contextIndex] != context || _jointIndexBuffer[contextIndex]==null) {
				_jointIndexBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _jointsPerVertex);
				_jointIndexContext[contextIndex] = context;
				_jointIndicesInvalid[contextIndex] = true;
			}
			if (_jointIndicesInvalid[contextIndex]) {
				_jointIndexBuffer[contextIndex].uploadFromVector(_numCondensedJoints > 0? Vector.ofArray(_condensedJointIndexData) : Vector.ofArray(_jointIndexData), 0, Std.int(_jointIndexData.length/_jointsPerVertex));
				_jointIndicesInvalid[contextIndex] = false;
			}
			context.setVertexBufferAt(index, _jointIndexBuffer[contextIndex], 0, _bufferFormat);
		}
		
		override private function uploadData(contextIndex:Int):Void
		{
			if (_animatedData!=null) {
				_activeBuffer.uploadFromVector(Vector.ofArray(_animatedData), 0, _numVertices);
				_vertexDataInvalid[contextIndex] = _activeDataInvalid = false;
			} else
				super.uploadData(contextIndex);
		}
		
		/**
		 * Clones the current object.
		 * @return An exact duplicate of the current object.
		 */
		override public function clone():ISubGeometry
		{
			var clone:SkinnedSubGeometry = new SkinnedSubGeometry(_jointsPerVertex);
			clone.updateData(Lambda.array(_vertexData));
			clone.updateIndexData(Lambda.array(_indices));
			clone.updateJointIndexData(Lambda.array(_jointIndexData));
			clone.updateJointWeightsData(Lambda.array(_jointWeightsData));
			clone._autoDeriveVertexNormals = _autoDeriveVertexNormals;
			clone._autoDeriveVertexTangents = _autoDeriveVertexTangents;
			clone._numCondensedJoints = _numCondensedJoints;
			clone._condensedIndexLookUp = _condensedIndexLookUp;
			clone._condensedJointIndexData = _condensedJointIndexData;
			return clone;
		}
		
		/**
		 * Cleans up any resources used by this object.
		 */
		override public function dispose():Void
		{
			super.dispose();
			disposeVertexBuffers(_jointWeightsBuffer);
			disposeVertexBuffers(_jointIndexBuffer);
		}
		
		/**
		 */
		public function condenseIndexData():Void
		{
			var len:Int = _jointIndexData.length;
			var oldIndex:Int;
			var newIndex:Int = 0;
			var dic: Array<Int> = new Array<UInt>();
			
			_condensedJointIndexData = new Array<Float>();
			_condensedIndexLookUp = new Array<UInt>();
			
			// For loop conversion - 						for (var i:Int = 0; i < len; ++i)
			
			var i:Int;
			
			for (i in 0...len) {
				oldIndex = Std.int(_jointIndexData[i]);
				
				// if we encounter a new index, assign it a new condensed index
				if (dic[oldIndex] != 0) {
					dic[oldIndex] = newIndex;
					_condensedIndexLookUp[newIndex++] = oldIndex;
					_condensedIndexLookUp[newIndex++] = oldIndex + 1;
					_condensedIndexLookUp[newIndex++] = oldIndex + 2;
				}
				_condensedJointIndexData[i] = dic[oldIndex];
			}
			_numCondensedJoints = Std.int(newIndex/3);
			
			invalidateBuffers(_jointIndicesInvalid);
		}
		
		/**
		 * The raw joint weights data.
		 */
		public var jointWeightsData(get, null) : Array<Float>;
		public function get_jointWeightsData() : Array<Float>
		{
			return _jointWeightsData;
		}
		
		public function updateJointWeightsData(value:Array<Float>):Void
		{
			// invalidate condensed stuff
			_numCondensedJoints = 0;
			_condensedIndexLookUp = null;
			_condensedJointIndexData = null;
			
			_jointWeightsData = value;
			invalidateBuffers(_jointWeightsInvalid);
		}
		
		/**
		 * The raw joint index data.
		 */
		public var jointIndexData(get, null) : Array<Float>;
		public function get_jointIndexData() : Array<Float>
		{
			return _jointIndexData;
		}
		
		public function updateJointIndexData(value:Array<Float>):Void
		{
			_jointIndexData = value;
			invalidateBuffers(_jointIndicesInvalid);
		}
	}

