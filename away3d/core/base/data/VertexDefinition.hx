package away3d.core.base.data;

import openfl.display3D.Context3DVertexBufferFormat;

#if haxe4
import haxe.ds.ReadOnlyArray;
#end

using Lambda;

/**
 * The contents of a single vertex in a `CompactSubGeometry`.
 */
class VertexDefinition
{
	/**
	 * The default attributes used by `CompactSubGeometry`: position, normal,
	 * tangent, UV, and secondaryUV.
	 */
	public static var defaultAttributes(default, null):ReadOnlyArray<AttributeDefinition> = [
		new AttributeDefinition("position", 3),
		new AttributeDefinition("normal", 3),
		new AttributeDefinition("tangent", 3),
		new AttributeDefinition("UV", 2),
		new AttributeDefinition("secondaryUV", 2)
	];

	/**
	 * A definition using `defaultAttributes`: position, normal, tangent, UV,
	 * and secondaryUV.
	 */
	public static var defaultVertexDefinition(default, null):VertexDefinition = new VertexDefinition(defaultAttributes);

	public var attributes(default, null):ReadOnlyArray<AttributeDefinition>;

	/**
	 * The combined length of all attributes; the total number of float values
	 * stored per vertex.
	 */
	public var length(default, null):Int;

	public function new(attributes:ReadOnlyArray<AttributeDefinition>)
	{
		var attributes:Array<AttributeDefinition> = attributes.copy();
		var length:Int = 0;

		for (index in 0...attributes.length) {
			var attribute:AttributeDefinition = attributes[index];

			// If an offset was already set, the attribute is most likely in use
			// elsewhere. Instead of modifying it, make a copy.
			if (attribute.offset != -1 && attribute.offset != length) {
				attributes[index] = attribute = attribute.clone();
			}

			attribute.offset = length;
			length += attribute.length;
		}

		this.length = length;
		this.attributes = attributes;
	}

	/**
	 * Returns a vertex definition containing this definition's attributes plus
	 * all unique attributes from the given array(s). If the same attribute is
	 * found multiple times, only the longer version will be included. If this
	 * already contains everything from `attributes`, it is returned unchanged.
	 */
	public function concatUnique(attributes:ReadOnlyArray<AttributeDefinition>):VertexDefinition
	{
		var result:Array<AttributeDefinition> = null;
		for (newAttribute in attributes) {
			var existing:AttributeDefinition = get(newAttribute.name);
			if (existing != null && existing.length >= newAttribute.length) {
				continue;
			}
			if (result == null) {
				result = this.attributes.copy();
			}
			if (existing == null) {
				result.push(newAttribute);
			} else {
				var index:Int = result.indexOf(existing);
				result[index >= 0 ? index : result.length] = newAttribute;
			}
		}
		return result == null ? this : new VertexDefinition(result);
	}

	public function get(attributeName:String):AttributeDefinition
	{
		for (attribute in attributes) {
			if (attribute.name == attributeName) {
				return attribute;
			}
		}
		return null;
	}

	public inline function toString():String
	{
		return Std.string(attributes);
	}
}

class AttributeDefinition
{
	public var length(default, null):Int;

	@:allow(away3d.core.base.data.VertexDefinition)
	public var offset(default, null):Int = -1;

	public var name(default, null):String;

	public var vertexBufferFormat(default, null):Context3DVertexBufferFormat;

	public inline function new(name:String, length:Int)
	{
		this.name = name;
		this.length = length;

		vertexBufferFormat = switch (length) {
			case 1:
				FLOAT_1;
			case 2:
				FLOAT_2;
			case 3:
				FLOAT_3;
			case 4:
				FLOAT_4;
			default:
				throw length + " should be 1-4";
		};
	}

	public inline function clone():AttributeDefinition
	{
		return new AttributeDefinition(name, length);
	}
	
	public inline function toString():String
	{
		return name + ":FLOAT_" + length;
	}
}

#if !haxe4
@:forward(copy, filter, indexOf, iterator, join, lastIndexOf, map, slice, toString)
abstract ReadOnlyArray<T>(Array<T>) from Array<T> to Iterable<T>
{
	public var length(get, never):Int;

	inline function get_length()
		return this.length;

	@:arrayAccess inline function get(i:Int)
		return this[i];

	public inline function concat(a:ReadOnlyArray<T>):Array<T>
		return this.concat(cast a);
}
#end
