/****
* 
****/

package openfl.display3D.textures;

import openfl.display.BitmapData;
import openfl.gl.GL;
import openfl.gl.GLTexture;
import openfl.utils.ByteArray;

class RectangleTexture extends TextureBase 
{
    public function new(glTexture:GLTexture) 
    {
        super(glTexture);
    }

   public function uploadFromBitmapData(source:BitmapData):Void 
   {
      // TODO
   }

   public function uploadFromByteArray(data:ByteArray, byteArrayOffset:Int):Void 
   {
      // TODO
   }
}
