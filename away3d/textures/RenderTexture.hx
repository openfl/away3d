package away3d.textures;

import openfl.errors.Error;
import away3d.materials.utils.MipmapGenerator;
import away3d.tools.utils.TextureUtils;
import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.textures.TextureBase;
import openfl.display3D.textures.Texture;

class RenderTexture extends Texture2DBase {

    public function new(_width:Int, _height:Int) {
        super();
        setSize(_width, _height);
    }

    override private function set_width(value:Int):Int {
        if (value == _width) return value;
        if (!TextureUtils.isDimensionValid(value)) throw new Error("Invalid size: Width and height must be power of 2 and cannot exceed 2048");
        invalidateContent();
        setSize(value, _height);
        return value;
    }

    override private function set_height(value:Int):Int {
        if (value == _height) return value;
        if (!TextureUtils.isDimensionValid(value)) throw new Error("Invalid size: Width and height must be power of 2 and cannot exceed 2048");
        invalidateContent();
        setSize(_width, value);
        return value;
    }

    override private function uploadContent(texture:TextureBase):Void {
        // fake data, to complete texture for sampling
        //var bmp:BitmapData = new BitmapData(width, height, false, 0xff0000);
        //MipmapGenerator.generateMipMaps(bmp, texture);
        //cast((texture), Texture).uploadFromBitmapData(bmp);
        //bmp.dispose();
    }

    override private function createTexture(context:Context3D):TextureBase {
        return context.createTexture(width, height, Context3DTextureFormat.BGRA, true);
    }
}

