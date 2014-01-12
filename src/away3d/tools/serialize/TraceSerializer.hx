package away3d.tools.serialize;

	//import away3d.arcane;
	import away3d.core.math.Quaternion;
	
	import flash.geom.Vector3D;
	
	//use namespace arcane;
	
	/**
	 * TraceSerializer is a concrete Serializer that will output its results to trace().  It has user settable tabSize and separator vars.
	 *
	 * @see away3d.tools.serialize.Serialize
	 */
	class TraceSerializer extends SerializerBase
	{
		var _indent:UInt = 0;
		public var separator:String = ": ";
		public var tabSize:UInt = 2;
		
		/**
		 * Creates a new TraceSerializer object.
		 */
		public function new()
		{
			super();
		}
		
		/**
		 * @inheritDoc
		 */
		public override function beginObject(className:String, instanceName:String):Void
		{
			writeString(className, instanceName);
			_indent += tabSize;
		}
		
		/**
		 * @inheritDoc
		 */
		public override function writeInt(name:String, value:Int):Void
		{
			var outputString:String = _indentString();
			outputString += name;
			outputString += separator;
			outputString += value;
			trace(outputString);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function writeUint(name:String, value:UInt):Void
		{
			var outputString:String = _indentString();
			outputString += name;
			outputString += separator;
			outputString += value;
			trace(outputString);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function writeBoolean(name:String, value:Bool):Void
		{
			var outputString:String = _indentString();
			outputString += name;
			outputString += separator;
			outputString += value;
			trace(outputString);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function writeString(name:String, value:String):Void
		{
			var outputString:String = _indentString();
			outputString += name;
			if (value) {
				outputString += separator;
				outputString += value;
			}
			trace(outputString);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function writeVector3D(name:String, value:Vector3D):Void
		{
			var outputString:String = _indentString();
			outputString += name;
			if (value) {
				outputString += separator;
				outputString += value;
			}
			trace(outputString);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function writeTransform(name:String, value:Array<Float>):Void
		{
			var outputString:String = _indentString();
			outputString += name;
			if (value) {
				outputString += separator;
				
				var matrixIndent:UInt = outputString.length;
				
				// For loop conversion - 								for (var i:UInt = 0; i < value.length; i++)
				
				var i:UInt = 0;
				
				for (i in 0...value.length) {
					outputString += value[i];
					if ((i < (value.length - 1)) && (((i + 1)%4) == 0)) {
						outputString += "\n";
						// For loop conversion - 						for (var j:UInt = 0; j < matrixIndent; j++)
						var j:UInt;
						for (j in 0...matrixIndent)
							outputString += " ";
					} else
						outputString += " ";
				}
			}
			trace(outputString);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function writeQuaternion(name:String, value:Quaternion):Void
		{
			var outputString:String = _indentString();
			outputString += name;
			if (value) {
				outputString += separator;
				outputString += value;
			}
			trace(outputString);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function endObject():Void
		{
			_indent -= tabSize;
		}
		
		private function _indentString():String
		{
			var indentString:String = "";
			// For loop conversion - 			for (var i:UInt = 0; i < _indent; i++)
			var i:UInt = 0;
			for (i in 0..._indent)
				indentString += " ";
			return indentString;
		}
	}

