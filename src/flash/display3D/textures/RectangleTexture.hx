/****
* 
****/

package flash.display3D.textures;

#if (flash || display)
@:final extern class RectangleTexture extends TextureBase {
	function new() : Void;
	function uploadFromBitmapData(source : flash.display.BitmapData) : Void;
	function uploadFromByteArray(data : flash.utils.ByteArray, byteArrayOffset : UInt) : Void;
}
#else

import flash.display.BitmapData;
import openfl.gl.GL;
import openfl.gl.GLTexture;
import flash.utils.ByteArray;

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

#end