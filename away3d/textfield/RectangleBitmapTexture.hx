package away3d.textfield;

import away3d.textures.Texture2DBase;
import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.textures.RectangleTexture;
import openfl.display3D.textures.TextureBase;

class RectangleBitmapTexture extends Texture2DBase {
	private var _bitmapData:BitmapData;

	public function new(bitmapData:BitmapData) {
		this.bitmapData = bitmapData;
		super();
	}
	
	public var bitmapData(get, set):BitmapData;
	private function get_bitmapData():BitmapData {
		return _bitmapData;
	}

	private function set_bitmapData(value:BitmapData):BitmapData {
		if (value == _bitmapData)
			return value;

		invalidateContent();
		setSize(value.width, value.height);

		_bitmapData = value;
		return value;
	}
	
	override private function uploadContent(texture:TextureBase):Void {
		cast(texture, RectangleTexture).uploadFromBitmapData(_bitmapData);
	}
	
	override private function createTexture(context:Context3D):TextureBase {
		return context.createRectangleTexture(_width, _height, Context3DTextureFormat.BGRA, false);
	}
}
