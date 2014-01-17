/**
 *
 */
/**
 * DEPRECRATED along with BitmapMaterial. Will be removed along with BitmapMaterial
 */
package away3d.textures;

import flash.errors.Error;
import away3d.textures.BitmapTexture;
import flash.display.BitmapData;
import haxe.ds.WeakMap;

class BitmapTextureCache {

    static private var _instance:BitmapTextureCache;
    private var _textures:WeakMap<BitmapData, BitmapTexture>;
    private var _usages:WeakMap<BitmapTexture, Int>;

    public function new(singletonEnforcer:SingletonEnforcer) {
        if (singletonEnforcer == null) throw new Error("Cannot instantiate a singleton class. Use static getInstance instead.");
        _textures = new WeakMap<BitmapData, BitmapTexture>();
        _usages = new WeakMap<BitmapTexture, Int>();

    }

    static public function getInstance():BitmapTextureCache {
        if (_instance == null) _instance = new BitmapTextureCache(new SingletonEnforcer());
        return _instance ;
    }

    public function getTexture(bitmapData:BitmapData):BitmapTexture {
        var texture:BitmapTexture = null;

        if (!_textures.exists(bitmapData)) {
            texture = new BitmapTexture(bitmapData);
            _textures.set(bitmapData, texture);
            _usages.set(texture, 0);
        }
        _usages.set(texture, _usages.get(texture) + 1);
        return _textures.get(bitmapData);
    }

    public function freeTexture(texture:BitmapTexture):Void {
        _usages.set(texture, _usages.get(texture) - 1);
        if (_usages.get(texture) == 0) {
            _textures.set(cast((texture), BitmapTexture).bitmapData, null);
            texture.dispose();
        }
    }

}

class SingletonEnforcer {
    public function new() {}
}

