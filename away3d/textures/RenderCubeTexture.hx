package away3d.textures;

	//import away3d.arcane;
	import away3d.materials.utils.MipmapGenerator;
	import away3d.tools.utils.TextureUtils;
	
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.TextureBase;
	
	import flash.errors.Error;
	
	//use namespace arcane;
	
	class RenderCubeTexture extends CubeTextureBase
	{
		public function new(size:Float)
		{
			super();
			setSize(Std.int(size), Std.int(size));
		}
		
		override public function set_size(value:Int) : Int
		{
			if (value == _width)
				return _width;
			
			if (!TextureUtils.isDimensionValid(value))
				throw new Error("Invalid size: Width and height must be power of 2 and cannot exceed 2048");
			
			invalidateContent();
			setSize(value, value);
			return _width;
		}
		
		override private function uploadContent(texture:TextureBase):Void
		{
			// fake data, to complete texture for sampling
			var bmd:BitmapData = new BitmapData(_width, _height, false, 0);
			// For loop conversion - 			for (var i:Int = 0; i < 6; ++i)
			var i:Int;
			for (i in 0...6)
				MipmapGenerator.generateMipMaps(bmd, texture, null, false, i);
			bmd.dispose();
		}
		
		override private function createTexture(context:Context3D):TextureBase
		{
			return context.createCubeTexture(_width, Context3DTextureFormat.BGRA, true);
		}
	}

