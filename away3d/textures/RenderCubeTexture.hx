package away3d.textures;


import openfl.errors.Error;
import away3d.materials.utils.MipmapGenerator;
import away3d.tools.utils.TextureUtils;
import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.textures.TextureBase;
import openfl.display3D.textures.CubeTexture;

class RenderCubeTexture extends CubeTextureBase {


    public function new(size:Int) {
        super();
        setSize(size, size);
    }

    public function set_size(value:Int):Int {
        if (value == _width) return value;
        if (!TextureUtils.isDimensionValid(value)) throw new Error("Invalid size: Width and height must be power of 2 and cannot exceed 2048");
        invalidateContent();
        setSize(value, value);
        return value;
    }

    override private function uploadContent(texture:TextureBase):Void {
        // fake data, to complete texture for sampling
        var bmd:BitmapData = new BitmapData(_width, _height, false, 0);
        var i:Int = 0;
        while (i < 6) {
            #if flash
            MipmapGenerator.generateMipMaps(bmd, texture, null, false, i);
            #else
            cast((texture), CubeTexture).uploadFromBitmapData(bmd, i, 0);
            #end
            ++i;
        }
        bmd.dispose();
    }

    override private function createTexture(context:Context3D):TextureBase {
        return context.createCubeTexture(_width, Context3DTextureFormat.BGRA, true);
    }
}

