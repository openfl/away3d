package away3d.tools.serialize;

import away3d.core.math.Quaternion;

import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * TraceSerializer is a concrete Serializer that will output its results to trace().  It has user settable tabSize and separator vars.
 *
 * @see away3d.tools.serialize.Serialize
 */
class TraceSerializer extends SerializerBase
{
	private var _indent:Int = 0;
	public var separator:String = ": ";
	public var tabSize:Int = 2;
	
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
	override public function beginObject(className:String, instanceName:String):Void
	{
		writeString(className, instanceName);
		_indent += tabSize;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function writeInt(name:String, value:Int):Void
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
	override public function writeUint(name:String, value:Int):Void
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
	override public function writeBoolean(name:String, value:Bool):Void
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
	override public function writeString(name:String, value:String):Void
	{
		var outputString:String = _indentString();
		outputString += name;
		if (value != null) {
			outputString += separator;
			outputString += value;
		}
		trace(outputString);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function writeVector3D(name:String, value:Vector3D):Void
	{
		var outputString:String = _indentString();
		outputString += name;
		if (value != null) {
			outputString += separator;
			outputString += value;
		}
		trace(outputString);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function writeTransform(name:String, value:Vector<Float>):Void
	{
		var outputString:String = _indentString();
		outputString += name;
		if (value != null) {
			outputString += separator;
			
			var matrixIndent:Int = outputString.length;
			
			for (i in 0...value.length) {
				outputString += value[i];
				if ((i < (value.length - 1)) && (((i + 1)%4) == 0)) {
					outputString += "\n";
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
	override public function writeQuaternion(name:String, value:Quaternion):Void
	{
		var outputString:String = _indentString();
		outputString += name;
		if (value != null) {
			outputString += separator;
			outputString += value;
		}
		trace(outputString);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function endObject():Void
	{
		_indent -= tabSize;
	}
	
	private function _indentString():String
	{
		var indentString:String = "";
		for (i in 0..._indent)
			indentString += " ";
		return indentString;
	}
}