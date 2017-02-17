package away3d.textfield.utils;

import flash.display.Bitmap;
import flash.display.BitmapData;
import haxe.io.Bytes;
import openfl.errors.Error;
/**
 * ...
 * @author P.J.Shand
 * @author Thomas Byrne
 */
class FontSize 
{
	public var family:String;
	public var size:Int;
	public var data:Xml;
	public var texture:BitmapData;
	
	public function FontSize(searchClass:Bool=true) 
	{
		if (searchClass) {
			var type:Class<FontSize> = Type.getClass(this);
			try {
				family = Reflect.getProperty(type, "FAMILY");
				size = Reflect.getProperty(type, "SIZE");
				
				var dataType:Class<Dynamic> = Reflect.getProperty(type, "DATA");
				var textureType:Class<Dynamic> = Reflect.getProperty(type, "TEXTURE");
				data = cast(Type.createInstance(dataType, null), Xml);
				//texture = cast(Type.createInstance(textureType, null), Bitmap).bitmapData;
				texture = BitmapData.fromBytes(cast(Type.createInstance(textureType, []), Bytes)); // is this correct?
				
			}catch (e:Error) {
				throw new Error("Class inheriting from FontSize ("+type+") should have PUBLIC static members FAMILY, SIZE, DATA and TEXTURE.");
			}
		}
	}	
}