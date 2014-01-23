/**
 * MipmapGenerator is a helper class that uploads BitmapData to a Texture including mipmap levels.
 */
package away3d.materials.utils;

import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.display3D.textures.CubeTexture;
import flash.display3D.textures.Texture;
import flash.display3D.textures.TextureBase;
class MipmapGenerator {

    static private var _matrix:Matrix = new Matrix();
    static private var _rect:Rectangle = new Rectangle();
/**
	 * Uploads a BitmapData with mip maps to a target Texture object.
	 * @param source The source BitmapData to upload.
	 * @param target The target Texture to upload to.
	 * @param mipmap An optional mip map holder to avoids creating new instances for fe animated materials.
	 * @param alpha Indicate whether or not the uploaded bitmapData is transparent.
	 */

    static public function generateMipMaps(source:BitmapData, target:TextureBase, mipmap:BitmapData = null, alpha:Bool = false, side:Int = -1):Void {
        var w:Int = source.width;
        var h:Int = source.height;
        var i:Int = 0;
        var regen:Bool = mipmap != null;
        if (mipmap == null)
            mipmap = new BitmapData(w, h, alpha);
        _rect.width = w;
        _rect.height = h;
        while (w >= 1 || h >= 1) {
            if (alpha) mipmap.fillRect(_rect, 0);
            _matrix.a = _rect.width / source.width;
            _matrix.d = _rect.height / source.height;
            mipmap.draw(source, _matrix, null, null, null, true);
            if (Std.is(target, Texture)) cast((target), Texture).uploadFromBitmapData(mipmap, i++)
            else cast((target), CubeTexture).uploadFromBitmapData(mipmap, side, i++);
            w >>= 1;
            h >>= 1;
            _rect.width = w > (1) ? w : 1;
            _rect.height = h > (1) ? h : 1;
        }

        if (!regen) mipmap.dispose();
    }

}

