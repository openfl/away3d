package away3d.textures;

	//import away3d.arcane;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.TextureBase;
	
	//use namespace arcane;
	
	class CubeTextureBase extends TextureProxyBase
	{
		public function new()
		{
			super();
		}
		
		public var size(get, set) : Int;
		
		public function get_size() : Int
		{
			return _width;
		}

		public function set_size(value:Int) : Int
		{
			_width = value;
			return _width;
		}
		
		override private function createTexture(context:Context3D):TextureBase
		{
			return context.createCubeTexture(width, Context3DTextureFormat.BGRA, false);
		}
	}

