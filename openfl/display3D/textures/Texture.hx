package openfl.display3D.textures;

#if display
extern class Texture extends TextureBase {
	function uploadCompressedTextureFromByteArray(data : openfl.utils.ByteArray, byteArrayOffset : UInt, async : Bool = false) : Void;
	function uploadFromBitmapData(source : openfl.display.BitmapData, miplevel : UInt = 0) : Void;
	function uploadFromByteArray(data : openfl.utils.ByteArray, byteArrayOffset : UInt, miplevel : UInt = 0) : Void;
}
#end