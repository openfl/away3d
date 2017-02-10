/**
 *
 */
package away3d.textures;

import away3d.textures.BitmapTexture;

import openfl.display.BitmapData;
import openfl.errors.Error;

/**
 * DEPRECRATED along with BitmapMaterial. Will be removed along with BitmapMaterial
 */
@:deprecated class BitmapTextureCache
{
	private static var _instance:BitmapTextureCache;
	
	private var _textures:Map<BitmapData, BitmapTexture>;
	private var _usages:Map<BitmapTexture, Int>;
	
	private function new()
	{
		_textures = new Map<BitmapData, BitmapTexture>();
		_usages = new Map<BitmapTexture, Int>();
	}
	
	public static function getInstance():BitmapTextureCache
	{
		if (_instance == null) _instance = new BitmapTextureCache();
		return _instance;
	}
	
	public function getTexture(bitmapData:BitmapData):BitmapTexture
	{
		var texture:BitmapTexture = null;
		if (!_textures.exists(bitmapData)) {
			texture = new BitmapTexture(bitmapData);
			_textures[bitmapData] = texture;
			_usages[texture] = 0;
		}
		_usages[texture] += 1;
		return _textures[bitmapData];
	}
	
	public function freeTexture(texture:BitmapTexture):Void
	{
		_usages[texture] -= 1;
		if (_usages[texture] == 0) {
			_textures[cast(texture, BitmapTexture).bitmapData] = null;
			texture.dispose();
		}
	}
}