package away3d.textures;

import openfl.display.BitmapData;
import openfl.display.BitmapDataChannel;
import openfl.display3D.textures.TextureBase;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * A convenience texture that encodes a specular map in the red channel, and the gloss map in the green channel, as expected by BasicSpecularMapMethod
 */
class SpecularBitmapTexture extends BitmapTexture
{
	public var specularMap(get, set):BitmapData;
	public var glossMap(get, set):BitmapData;
	
	private var _specularMap:BitmapData;
	private var _glossMap:BitmapData;
	
	public function new(specularMap:BitmapData = null, glossMap:BitmapData = null)
	{
		var bmd:BitmapData;
		
		if (specularMap != null)
			bmd = specularMap;
		else
			bmd = glossMap;
		bmd = (bmd != null)? new BitmapData(bmd.width, bmd.height, false, 0xffffff) : new BitmapData(1, 1, false, 0xffffff);
		
		super(bmd);
		
		this.specularMap = specularMap;
		this.glossMap = glossMap;
	}
	
	private function get_specularMap():BitmapData
	{
		return _specularMap;
	}
	
	private function set_specularMap(value:BitmapData):BitmapData
	{
		_specularMap = value;
		invalidateContent();
		
		testSize();
		return value;
	}
	
	private function get_glossMap():BitmapData
	{
		return _glossMap;
	}
	
	private function set_glossMap(value:BitmapData):BitmapData
	{
		_glossMap = value;
		invalidateContent();
		
		testSize();
		return value;
	}
	
	private function testSize():Void
	{
		var w:Float, h:Float;
		
		if (_specularMap != null) {
			w = _specularMap.width;
			h = _specularMap.height;
		} else if (_glossMap != null) {
			w = _glossMap.width;
			h = _glossMap.height;
		} else {
			w = 1;
			h = 1;
		}
		
		if (w != bitmapData.width && h != bitmapData.height) {
			var oldBitmap:BitmapData = bitmapData;
			super.bitmapData = new BitmapData(_specularMap.width, specularMap.height, false, 0xffffff);
			oldBitmap.dispose();
		}
	}
	
	override private function uploadContent(texture:TextureBase):Void
	{
		var rect:Rectangle = _specularMap.rect;
		var origin:Point = new Point();
		
		bitmapData.fillRect(rect, 0xffffff);
		
		if (_glossMap != null)
			bitmapData.copyChannel(_glossMap, rect, origin, BitmapDataChannel.GREEN, BitmapDataChannel.GREEN);
		
		if (_specularMap != null)
			bitmapData.copyChannel(_specularMap, rect, origin, BitmapDataChannel.RED, BitmapDataChannel.RED);
		
		super.uploadContent(texture);
	}
	
	override public function dispose():Void
	{
		bitmapData.dispose();
		bitmapData = null;
	}
}