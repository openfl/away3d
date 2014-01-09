package away3d.textures;

	//import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.errors.AbstractMethodError;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.library.assets.NamedAssetBase;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.TextureBase;
	
	//use namespace arcane;
	
	class TextureProxyBase extends NamedAssetBase implements IAsset
	{
		var _format:Context3DTextureFormat;
		var _hasMipmaps:Bool = true;
		
		var _textures:Array<TextureBase>;
		var _dirty:Array<Context3D>;
		
		var _width:Int;
		var _height:Int;
		
		public function new()
		{
			super();
			_format = Context3DTextureFormat.BGRA;
		
			_textures = new Array<TextureBase>();
			_dirty = new Array<Context3D>();
		}
		
		public var hasMipMaps(get, null) : Bool;
		
		public function get_hasMipMaps() : Bool
		{
			return _hasMipmaps;
		}
		
		public var format(get, null) : Context3DTextureFormat;
		
		public function get_format() : Context3DTextureFormat
		{
			return _format;
		}
		
		public var assetType(get, null) : String;
		
		public function get_assetType() : String
		{
			return AssetType.TEXTURE;
		}
		
		public var width(get, set) : Int;
		
		public function get_width() : Int
		{
			return _width;
		}

		public function set_width(value:Int) : Int
		{
			_width = value;
			return _width;
		}
		
		public var height(get, set) : Int;
		
		public function get_height() : Int
		{
			return _height;
		}
		
		public function set_height(value:Int) : Int
		{
			_height = value;
			return _height;
		}

		public function getTextureForStage3D(stage3DProxy:Stage3DProxy):TextureBase
		{
			var contextIndex:Int = stage3DProxy._stage3DIndex;
			var tex:TextureBase = _textures[contextIndex];
			var context:Context3D = stage3DProxy._context3D;
			
			if (tex==null || _dirty[contextIndex] != context) {
				_textures[contextIndex] = tex = createTexture(context);
				_dirty[contextIndex] = context;
				uploadContent(tex);
			}
			
			return tex;
		}
		
		private function uploadContent(texture:TextureBase):Void
		{
			throw new AbstractMethodError();
		}
		
		private function setSize(width:Int, height:Int):Void
		{
			if (_width != width || _height != height)
				invalidateSize();
			
			_width = width;
			_height = height;
		}
		
		public function invalidateContent():Void
		{
			// For loop conversion - 			for (var i:Int = 0; i < 8; ++i)
			var i:Int;
			for (i in 0...8)
				_dirty[i] = null;
		}
		
		private function invalidateSize():Void
		{
			var tex:TextureBase;
			// For loop conversion - 			for (var i:Int = 0; i < 8; ++i)
			var i:Int;
			for (i in 0...8) {
				tex = _textures[i];
				if (tex!=null) {
					tex.dispose();
					_textures[i] = null;
					_dirty[i] = null;
				}
			}
		}
		
		private function createTexture(context:Context3D):TextureBase
		{
			throw new AbstractMethodError();
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispose():Void
		{
			// For loop conversion - 			for (var i:Int = 0; i < 8; ++i)
			var i:Int;
			for (i in 0...8) {
				if (_textures[i]!=null)
					_textures[i].dispose();
			}
		}
	}

