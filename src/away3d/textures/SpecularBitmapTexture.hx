package away3d.textures;

	//import away3d.arcane;
	
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	//use namespace arcane;
	
	/**
	 * A convenience texture that encodes a specular map in the red channel, and the gloss map in the green channel, as expected by BasicSpecularMapMethod
	 */
	class SpecularBitmapTexture extends BitmapTexture
	{
		var _specularMap:BitmapData;
		var _glossMap:BitmapData;
		
		public function new(specularMap:BitmapData = null, glossMap:BitmapData = null)
		{
			var bmd:BitmapData;
			
			if (specularMap)
				bmd = specularMap;
			else
				bmd = glossMap;
			bmd = bmd? new BitmapData(bmd.width, bmd.height, false, 0xffffff) : new BitmapData(1, 1, false, 0xffffff);
			
			super(bmd);
			
			this.specularMap = specularMap;
			this.glossMap = glossMap;
		}
		
		public var specularMap(get, set) : BitmapData;
		
		public function get_specularMap() : BitmapData
		{
			return _specularMap;
		}
		
		public function set_specularMap(value:BitmapData) : BitmapData
		{
			_specularMap = value;
			invalidateContent();
			
			testSize();
		}
		
		public var glossMap(get, set) : BitmapData;
		
		public function get_glossMap() : BitmapData
		{
			return _glossMap;
		}
		
		public function set_glossMap(value:BitmapData) : BitmapData
		{
			_glossMap = value;
			invalidateContent();
			
			testSize();
		}
		
		private function testSize():Void
		{
			var w:Float, h:Float;
			
			if (_specularMap) {
				w = _specularMap.width;
				h = _specularMap.height;
			} else if (_glossMap) {
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
			
			if (_glossMap)
				bitmapData.copyChannel(_glossMap, rect, origin, BitmapDataChannel.GREEN, BitmapDataChannel.GREEN);
			
			if (_specularMap)
				bitmapData.copyChannel(_specularMap, rect, origin, BitmapDataChannel.RED, BitmapDataChannel.RED);
			
			super.uploadContent(texture);
		}
		
		override public function dispose():Void
		{
			bitmapData.dispose();
			bitmapData = null;
		}
	}

