package away3d.textures;

	//import away3d.arcane;
	import away3d.materials.utils.MipmapGenerator;
	import away3d.tools.utils.TextureUtils;
	
	import flash.display.BitmapData;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	
	import flash.errors.Error;

	//use namespace arcane;
	
	class BitmapTexture extends Texture2DBase
	{
		private static var _mipMaps:Array<Dynamic> = [];
		private static var _mipMapUses:Array<Dynamic> = [];
		
		var _bitmapData:BitmapData;
		var _mipMapHolder:BitmapData;
		var _generateMipmaps:Bool;
		
		public function new(bitmapData:BitmapData, generateMipmaps:Bool = true)
		{
			super();
			
			this.bitmapData = bitmapData;
			_generateMipmaps = generateMipmaps;
		}
		
		public var bitmapData(get, set) : BitmapData;
		
		public function get_bitmapData() : BitmapData
		{
			return _bitmapData;
		}
		
		public function set_bitmapData(value:BitmapData) : BitmapData
		{
			if (value == _bitmapData)
				return _bitmapData;
			
			if (!TextureUtils.isBitmapDataValid(value))
				throw new Error("Invalid bitmapData: Width and height must be power of 2 and cannot exceed 2048");
			
			invalidateContent();
			setSize(value.width, value.height);
			
			_bitmapData = value;
			
			if (_generateMipmaps)
				getMipMapHolder();

			return _bitmapData;
		}
		
		override private function uploadContent(texture:TextureBase):Void
		{
			if (_generateMipmaps)
				MipmapGenerator.generateMipMaps(_bitmapData, texture, _mipMapHolder, true);
			else
				cast(texture, Texture).uploadFromBitmapData(_bitmapData, 0);
		}
		
		private function getMipMapHolder():Void
		{
			var newW:UInt, newH:UInt;
			
			newW = _bitmapData.width;
			newH = _bitmapData.height;
			
			if (_mipMapHolder!=null) {
				if (_mipMapHolder.width == newW && _bitmapData.height == newH)
					return;
				
				freeMipMapHolder();
			}
			
			if (_mipMaps[newW]==null) {
				_mipMaps[newW] = [];
				_mipMapUses[newW] = [];
			}
			if (_mipMaps[newW][newH]==null) {
				_mipMapHolder = _mipMaps[newW][newH] = new BitmapData(newW, newH, true);
				_mipMapUses[newW][newH] = 1;
			} else {
				_mipMapUses[newW][newH] = _mipMapUses[newW][newH] + 1;
				_mipMapHolder = _mipMaps[newW][newH];
			}
		}
		
		private function freeMipMapHolder():Void
		{
			var holderWidth:UInt = _mipMapHolder.width;
			var holderHeight:UInt = _mipMapHolder.height;
			
			if (--_mipMapUses[holderWidth][holderHeight] == 0) {
				_mipMaps[holderWidth][holderHeight].dispose();
				_mipMaps[holderWidth][holderHeight] = null;
			}
		}
		
		override public function dispose():Void
		{
			super.dispose();
			
			if (_mipMapHolder!=null)
				freeMipMapHolder();
		}
	}

