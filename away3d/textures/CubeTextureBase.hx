package away3d.textures;

import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.textures.TextureBase;

class CubeTextureBase extends TextureProxyBase
{
	public var size(get, never):Int;
	
	public function new()
	{
		super();
	}
	
	private function get_size():Int
	{
		return _width;
	}
	
	override private function createTexture(context:Context3D):TextureBase
	{
		return context.createCubeTexture(width, Context3DTextureFormat.BGRA, false);
	}
}