package away3d.materials.utils;

import away3d.core.base.IMaterialOwner;
import away3d.textures.BitmapTexture;

import openfl.display.BitmapData;

class DefaultMaterialManager
{
	private static var _defaultTextureBitmapData:BitmapData;
	private static var _defaultMaterial:TextureMaterial;
	private static var _defaultTexture:BitmapTexture;
	
	//private static var _defaultMaterialRenderables:Vector.<IMaterialOwner> = new Vector.<IMaterialOwner>();
	
	public static function getDefaultMaterial(renderable:IMaterialOwner = null):TextureMaterial
	{
		if (_defaultTexture == null)
			createDefaultTexture();
		
		if (_defaultMaterial == null)
			createDefaultMaterial();
		
		//_defaultMaterialRenderables.push(renderable);
		
		return _defaultMaterial;
	}
	
	public static function getDefaultTexture(renderable:IMaterialOwner = null):BitmapTexture
	{
		if (_defaultTexture == null)
			createDefaultTexture();
		
		//_defaultMaterialRenderables.push(renderable);
		
		return _defaultTexture;
	}
	
	private static function createDefaultTexture():Void
	{
		_defaultTextureBitmapData = new BitmapData(8, 8, false, 0x0);
		
		//create chekerboard
		for (i in 0...8) {
			for (j in 0...8) {
				if ((j & 1) ^ (i & 1) != 0)
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