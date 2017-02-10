package away3d.textures;

import openfl.display3D.Context3D;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.TextureBase;
import openfl.utils.ByteArray;

class ATFTexture extends Texture2DBase
{
	public var atfData(get, set):ATFData;
	
	private var _atfData:ATFData;
	
	public function new(byteArray:ByteArray)
	{
		super();
		
		atfData = new ATFData(byteArray);
		_format = atfData.format;
		_hasMipmaps = _atfData.numTextures > 1;
	}
	
	private function get_atfData():ATFData
	{
		return _atfData;
	}
	
	private function set_atfData(value:ATFData):ATFData
	{
		_atfData = value;
		
		invalidateContent();
		
		setSize(value.width, value.height);
		return value;
	}
	
	override private function uploadContent(texture:TextureBase):Void
	{
		cast(texture, Texture).uploadCompressedTextureFromByteArray(_atfData.data, 0, false);
	}
	
	override private function createTexture(context:Context3D):TextureBase
	{
		return context.createTexture(_width, _height, atfData.format, false);
	}
}