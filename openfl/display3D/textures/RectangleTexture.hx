/****
* 
****/

package openfl.display3D.textures;

#if display
extern class RectangleTexture extends TextureBase {
	function new() : Void;
	function uploadFromBitmapData(source : openfl.display.BitmapData) : Void;
	function uploadFromByteArray(data : openfl.utils.ByteArray, byteArrayOffset : UInt) : Void;
}
#end