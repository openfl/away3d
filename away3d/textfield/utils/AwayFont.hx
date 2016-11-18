package away3d.textfield.utils;

import away3d.materials.TextureMaterial;
import away3d.textures.BitmapTexture;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.errors.Error;
import openfl.utils.ByteArray;
/**
 * ...
 * @author P.J.Shand
 * @author Thomas Byrne
 */
class AwayFont 
{
	private static var registeredBitmapFont = new Map<String, BitmapFont>();
	private static var registeredTexture = new Map<String, BitmapTexture>();
	private static var registeredData = new Map<String, Xml>();
	
	public function new()
	{
		
	}
	
	/**
	 * 
	 * @param	type
	 * @param	cacheMaterial - When true performance will improve but text using the same font will all use the samer material.
	 * meaning that color transforms will affect all of them.
	 * @return
	 */
	public static function type(type:Class<FontSize>, cacheMaterial:Bool=false, mipmap:Bool=true):BitmapFont 
	{
		//try {
			
			var family:String = Reflect.getProperty(type, "FAMILY");
			var size:Int = Reflect.getProperty(type, "SIZE");
			var regName:String = family + "_" + size;
			
			var cached:BitmapFont = registeredBitmapFont[regName];
			
			//var lookup:Map<String, Dynamic> = (cacheMaterial ? registeredBitmapFont : registeredTexture);
			if (cacheMaterial == true && cached != null) {
				return cached;
			}
			
			//var cached:Dynamic = lookup[regName];
			if (cached == null) {
				var xmlLocation:String = Reflect.getProperty(type, "DATA");
				var xmlStr:String = Assets.getText(xmlLocation);
				var data:Xml = Xml.parse(xmlStr);
				var bmdLocation:String = Reflect.getProperty(type, "TEXTURE");
				var texture:BitmapData = Assets.getBitmapData(bmdLocation);
				
				return generate(family, size, data, texture, cacheMaterial, mipmap);
				
			/*}else if (cacheMaterial) {
				return cached;
				*/
			}else {
				var fontMaterial:TextureMaterial = new TextureMaterial(registeredTexture[regName], true, false, mipmap);
				fontMaterial.smooth = true;
				fontMaterial.alphaBlending = true;
				fontMaterial.bothSides = true;
				
				return new BitmapFont(fontMaterial, registeredData[regName]);
			}
		/*}catch (e:Error) {
			throw new Error("Class inheriting from FontSize ("+type+") should have PUBLIC static members FAMILY, SIZE, DATA and TEXTURE.");
		}*/
		return null;
		//return gen(new type()); // This approach was horribly inefficient
	}
	
	public static function gen(fontSize:FontSize, cacheMaterial:Bool=false, mipmap:Bool=true):BitmapFont {
		return generate(fontSize.family, fontSize.size, fontSize.data, fontSize.texture, cacheMaterial, mipmap);
	}
	
	public static function generate(family:String, size:Int, data:Xml, texture:BitmapData, cacheMaterial:Bool=false, mipmap:Bool):BitmapFont {
		var regName:String = family + "_" + size;
		var bmTexture:BitmapTexture;
		var fontMaterial:TextureMaterial;
		
		if(cacheMaterial){
			var bitmapFont:BitmapFont = registeredBitmapFont[regName];
			if (bitmapFont == null) {
				
				bmTexture = new BitmapTexture(texture, mipmap);
				
				fontMaterial = new TextureMaterial(bmTexture, true, false, mipmap);
				fontMaterial.smooth = true;
				fontMaterial.alphaBlending = true;
				fontMaterial.bothSides = true;
				
				bitmapFont = new BitmapFont(fontMaterial, data);
				registeredBitmapFont[regName] = bitmapFont;
			}
			return bitmapFont;
		}else {
			bmTexture = registeredTexture[regName];
			if (bmTexture == null) {
				
				bmTexture = new BitmapTexture(texture);
				registeredTexture[regName] = bmTexture;
				registeredData[regName] = data;
			}
			fontMaterial = new TextureMaterial(bmTexture, true, false, true);
			fontMaterial.smooth = true;
			fontMaterial.alphaBlending = true;
			fontMaterial.bothSides = true;
			
			return new BitmapFont(fontMaterial, registeredData[regName]);
		}
	}	
}