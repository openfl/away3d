package away3d.materials.utils;

	import away3d.core.base.*;
	import away3d.materials.*;
	import away3d.textures.*;
	
	import flash.display.*;
	
	class DefaultMaterialManager
	{
		public static var _defaultTextureBitmapData:BitmapData;
		public static var _defaultMaterial:TextureMaterial;
		public static var _defaultTexture:BitmapTexture;
		
		//private static var _defaultMaterialRenderables:Array<IMaterialOwner> = new Array<IMaterialOwner>();
		
		public static function getDefaultMaterial(renderable:IMaterialOwner = null):TextureMaterial
		{
			if (_defaultTexture==null)
				createDefaultTexture();
			
			if (_defaultMaterial==null)
				createDefaultMaterial();
			
			//_defaultMaterialRenderables.push(renderable);
			
			return _defaultMaterial;
		}
		
		public static function getDefaultTexture(renderable:IMaterialOwner = null):BitmapTexture
		{
			if (_defaultTexture==null)
				createDefaultTexture();
			
			//_defaultMaterialRenderables.push(renderable);
			
			return _defaultTexture;
		}
		
		private static function createDefaultTexture():Void
		{
			_defaultTextureBitmapData = new BitmapData(8, 8, false, 0x0);
			
			//create chekerboard
			var i:UInt, j:UInt;
			// For loop conversion - 			for (i = 0; i < 8; i++)
			for (i in 0...8) {
				// For loop conversion - 				for (j = 0; j < 8; j++)
				for (j in 0...8) {
					if ((j & 1) ^ (i & 1)==0)
						_defaultTextureBitmapData.setPixel(i, j, 0xFFFFFF);
				}
			}
			
			_defaultTexture = new BitmapTexture(_defaultTextureBitmapData);
			_defaultTexture.name = "defaultTexture";
		}
		
		private static function createDefaultMaterial():Void
		{
			_defaultMaterial = new TextureMaterial(_defaultTexture);
			_defaultMaterial.mipmap = false;
			_defaultMaterial.smooth = false;
			_defaultMaterial.name = "defaultMaterial";
		}
	}

