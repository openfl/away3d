package away3d.textures;


import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.TextureBase;

class Texture2DBase extends TextureProxyBase {

    public function new() {
        super();
    }

    override private function createTexture(context:Context3D):TextureBase {
        return context.createTexture(_width, _height, Context3DTextureFormat.BGRA, false);
    }

}

