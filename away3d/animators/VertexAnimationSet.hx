package away3d.animators;

	import away3d.animators.data.VertexAnimationMode;
	//import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	
	import flash.display3D.Context3D;
	
	import flash.utils.Dictionary;
	
	//use namespace arcane;
	
	/**
	 * The animation data set used by vertex-based animators, containing vertex animation state data.
	 *
	 * @see away3d.animators.VertexAnimator
	 */
	class VertexAnimationSet extends AnimationSetBase implements IAnimationSet
	{
		var _numPoses:UInt;
		var _blendMode:BlendMode;
		var _streamIndices:Dictionary = new Dictionary(true);
		var _useNormals:Dictionary = new Dictionary(true);
		var _useTangents:Dictionary = new Dictionary(true);
		var _uploadNormals:Bool;
		var _uploadTangents:Bool;
		
		/**
		 * Returns the number of poses made available at once to the GPU animation code.
		 */
		public var numPoses(get, null) : UInt;
		public function get_numPoses() : UInt
		{
			return _numPoses;
		}
		
		/**
		 * Returns the active blend mode of the vertex animator object.
		 */
		public var blendMode(get, null) : BlendMode;
		public function get_blendMode() : BlendMode
		{
			return _blendMode;
		}
		
		/**
		 * Returns whether or not normal data is used in last set GPU pass of the vertex shader.
		 */
		public var useNormals(get, null) : Bool;
		public function get_useNormals() : Bool
		{
			return _uploadNormals;
		}
		
		/**
		 * Creates a new <code>VertexAnimationSet</code> object.
		 *
		 * @param numPoses The number of poses made available at once to the GPU animation code.
		 * @param blendMode Optional value for setting the animation mode of the vertex animator object.
		 *
		 * @see away3d.animators.data.VertexAnimationMode
		 */
		public function new(numPoses:UInt = 2, blendMode:String = "absolute")
		{
			super();
			_numPoses = numPoses;
			_blendMode = blendMode;
		
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAGALVertexCode(pass:MaterialPassBase, sourceRegisters:Array<String>, targetRegisters:Array<String>, profile:String):String
		{
			if (_blendMode == VertexAnimationMode.ABSOLUTE)
				return getAbsoluteAGALCode(pass, sourceRegisters, targetRegisters);
			else
				return getAdditiveAGALCode(pass, sourceRegisters, targetRegisters);
		}
		
		/**
		 * @inheritDoc
		 */
		public function activate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):Void
		{
			_uploadNormals = Boolean(_useNormals[pass]);
			_uploadTangents = Boolean(_useTangents[pass]);
		}
		
		/**
		 * @inheritDoc
		 */
		public function deactivate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):Void
		{
			var index:Int = _streamIndices[pass];
			var context:Context3D = stage3DProxy._context3D;
			context.setVertexBufferAt(index, null);
			if (_uploadNormals)
				context.setVertexBufferAt(index + 1, null);
			if (_uploadTangents)
				context.setVertexBufferAt(index + 2, null);
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAGALFragmentCode(pass:MaterialPassBase, shadedTarget:String, profile:String):String
		{
			return "";
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAGALUVCode(pass:MaterialPassBase, UVSource:String, UVTarget:String):String
		{
			return "mov " + UVTarget + "," + UVSource + "\n";
		}
		
		/**
		 * @inheritDoc
		 */
		public function doneAGALCode(pass:MaterialPassBase):Void
		{
		
		}
		
		/**
		 * Generates the vertex AGAL code for absolute blending.
		 */
		private function getAbsoluteAGALCode(pass:MaterialPassBase, sourceRegisters:Array<String>, targetRegisters:Array<String>):String
		{
			var code:String = "";
			var temp1:String = findTempReg(targetRegisters);
			var temp2:String = findTempReg(targetRegisters, temp1);
			var regs:Array<Dynamic> = ["x", "y", "z", "w"];
			var len:UInt = sourceRegisters.length;
			var constantReg:String = "vc" + pass.numUsedVertexConstants;
			var useTangents:Bool = Boolean(_useTangents[pass] = len > 2);
			_useNormals[pass] = len > 1;
			
			if (len > 2)
				len = 2;
			var streamIndex:UInt = _streamIndices[pass] = pass.numUsedStreams;
			
			// For loop conversion - 						for (var i:UInt = 0; i < len; ++i)
			
			var i:UInt = 0;
			
			for (i in 0...len) {
				code += "mul " + temp1 + ", " + sourceRegisters[i] + ", " + constantReg + "." + regs[0] + "\n";
				
				// For loop conversion - 								for (var j:UInt = 1; j < _numPoses; ++j)
				
				var j:UInt;
				
				for (j in 1..._numPoses) {
					code += "mul " + temp2 + ", va" + streamIndex + ", " + constantReg + "." + regs[j] + "\n";
					
					if (j < _numPoses - 1)
						code += "add " + temp1 + ", " + temp1 + ", " + temp2 + "\n";
					
					++streamIndex;
				}
				
				code += "add " + targetRegisters[i] + ", " + temp1 + ", " + temp2 + "\n";
			}
			
			// add code for bitangents if tangents are used
			if (useTangents) {
				code += "dp3 " + temp1 + ".x, " + sourceRegisters[uint(2)] + ", " + targetRegisters[uint(1)] + "\n" +
					"mul " + temp1 + ", " + targetRegisters[uint(1)] + ", " + temp1 + ".x			 \n" +
					"sub " + targetRegisters[uint(2)] + ", " + sourceRegisters[uint(2)] + ", " + temp1 + "\n";
			}
			return code;
		}
		
		/**
		 * Generates the vertex AGAL code for additive blending.
		 */
		private function getAdditiveAGALCode(pass:MaterialPassBase, sourceRegisters:Array<String>, targetRegisters:Array<String>):String
		{
			var code:String = "";
			var len:UInt = sourceRegisters.length;
			var regs:Array<Dynamic> = ["x", "y", "z", "w"];
			var temp1:String = findTempReg(targetRegisters);
			var k:UInt;
			var useTangents:Bool = Boolean(_useTangents[pass] = len > 2);
			var useNormals:Bool = Boolean(_useNormals[pass] = len > 1);
			var streamIndex:UInt = _streamIndices[pass] = pass.numUsedStreams;
			
			if (len > 2)
				len = 2;
			
			code += "mov  " + targetRegisters[0] + ", " + sourceRegisters[0] + "\n";
			if (useNormals)
				code += "mov " + targetRegisters[1] + ", " + sourceRegisters[1] + "\n";
			
			// For loop conversion - 						for (var i:UInt = 0; i < len; ++i)
			
			var i:UInt = 0;
			
			for (i in 0...len) {
				// For loop conversion - 				for (var j:UInt = 0; j < _numPoses; ++j)
				var j:UInt;
				for (j in 0..._numPoses) {
					code += "mul " + temp1 + ", va" + (streamIndex + k) + ", vc" + pass.numUsedVertexConstants + "." + regs[j] + "\n" +
						"add " + targetRegisters[i] + ", " + targetRegisters[i] + ", " + temp1 + "\n";
					k++;
				}
			}
			
			if (useTangents) {
				code += "dp3 " + temp1 + ".x, " + sourceRegisters[uint(2)] + ", " + targetRegisters[uint(1)] + "\n" +
					"mul " + temp1 + ", " + targetRegisters[uint(1)] + ", " + temp1 + ".x			 \n" +
					"sub " + targetRegisters[uint(2)] + ", " + sourceRegisters[uint(2)] + ", " + temp1 + "\n";
			}
			
			return code;
		}
	}

