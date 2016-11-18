package away3d.materials.utils;


import openfl.display.BitmapData;
import away3d.core.base.IMaterialOwner;
import away3d.textures.BitmapTexture;
class DefaultMaterialManager {

	private static var _defaultTextureBitmapData:BitmapData;
	private static var _defaultMaterial:TextureMaterial;
	private static var _defaultTexture:BitmapTexture;
//private static var _defaultMaterialRenderables:Vector.<IMaterialOwner> = new Vector.<IMaterialOwner>();

	public static function getDefaultMaterial(renderable:IMaterialOwner = null):TextureMaterial {
		if (_defaultTexture == null) createDefaultTexture();
		if (_defaultMaterial == null) createDefaultMaterial();
		return _defaultMaterial;
	}

	public static function getDefaultTexture(renderable:IMaterialOwner = null):BitmapTexture {
		if (_defaultTexture == null) createDefaultTexture();
		return _defaultTexture;
	}

	private static function createDefaultTexture():Void {
		_defaultTextureBitmapData = new BitmapData(8, 8, false, 0x0);
//create chekerboard
		var i:Int = 0;
		var j:Int;
		i = 0;
		while (i < 8) {
			j = 0;
			while (j < 8) {
				if ((j & 1) ^ (i & 1) == 1) _defaultTextureBitmapData.setPixel(i, j, 0xFFFFFF);
				j++;
			}
			i++;
		}
		_defaultTexture = new BitmapTexture(_defaultTextureBitmapData);
		_defaultTexture.name = "defaultTexture";
	}

	private static function createDefaultMaterial():Void {
		_defaultMaterial = new TextureMaterial(_defaultTexture);
		_defaultMaterial.mipmap = false;
		_defaultMaterial.smooth = false;
		_defaultMaterial.name = "defaultMaterial";
	}
}

