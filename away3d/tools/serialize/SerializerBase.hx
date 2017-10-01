package away3d.tools.serialize;

import away3d.core.math.Quaternion;
import away3d.errors.AbstractMethodError;

import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * SerializerBase is the abstract class for all Serializers. It provides an interface for basic data type writing.
 * It is not intended for reading.
 *
 * @see away3d.tools.serialize.Serialize
 */
class SerializerBase
{
	/**
	 * Creates a new SerializerBase object.
	 */
	public function new()
	{
	}
	
	/**
	 * Begin object serialization. Output className and instanceName.
	 * @param className name of class being serialized
	 * @param instanceName name of instance being serialized
	 */
	public function beginObject(className:String, instanceName:String):Void
	{
		throw new AbstractMethodError();
	}
	
	/**
	 * Serialize int
	 * @param name name of value being serialized
	 * @param value value being serialized
	 */
	public function writeInt(name:String, value:Int):Void
	{
		throw new AbstractMethodError();
	}
	
	/**
	 * Serialize uint
	 * @param name name of value being serialized
	 * @param value value being serialized
	 */
	public function writeUint(name:String, value:Int):Void
	{
		throw new AbstractMethodError();
	}
	
	/**
	 * Serialize Boolean
	 * @param name name of value being serialized
	 * @param value value being serialized
	 */
	public function writeBoolean(name:String, value:Bool):Void
	{
		throw new AbstractMethodError();
	}
	
	/**
	 * Serialize String
	 * @param name name of value being serialized
	 * @param value value being serialized
	 */
	public function writeString(name:String, value:String):Void
	{
		throw new AbstractMethodError();
	}
	
	/**
	 * Serialize Vector3D
	 * @param name name of value being serialized
	 * @param value value being serialized
	 */
	public function writeVector3D(name:String, value:Vector3D):Void
	{
		throw new AbstractMethodError();
	}
	
	/**
	 * Serialize Transform, in the form of Vector.&lt;Number&gt;
	 * @param name name of value being serialized
	 * @param value value being serialized
	 */
	public function writeTransform(name:String, value:Vector<Float>):Void
	{
		throw new AbstractMethodError();
	}
	
	/**
	 * Serialize Quaternion
	 * @param name name of value being serialized
	 * @param value value being serialized
	 */
	public function writeQuaternion(name:String, value:Quaternion):Void
	{
		throw new AbstractMethodError();
	}
	
	/**
	 * End object serialization
	 */
	public function endObject():Void
	{
		throw new AbstractMethodError();
	}
}