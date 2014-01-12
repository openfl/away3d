package away3d.textures;

	//import away3d.arcane;
	import away3d.materials.utils.MipmapGenerator;
	import away3d.tools.utils.TextureUtils;
	
	import flash.display.BitmapData;
	import flash.display3D.textures.TextureBase;

	import flash.errors.Error;
	
	//use namespace arcane;
	
	class BitmapCubeTexture extends CubeTextureBase
	{
		var _bitmapDatas:Array<BitmapData>;
		
		//var _useAlpha : Bool;
		
		public function new(posX:BitmapData, negX:BitmapData, posY:BitmapData, negY:BitmapData, posZ:BitmapData, negZ:BitmapData)
		{
			super();
			
			_bitmapDatas = new Array<BitmapData>();
			testSize(_bitmapDatas[0] = posX);
			testSize(_bitmapDatas[1] = negX);
			testSize(_bitmapDatas[2] = posY);
			testSize(_bitmapDatas[3] = negY);
			testSize(_bitmapDatas[4] = posZ);
			testSize(_bitmapDatas[5] = negZ);
			
			setSize(posX.width, posX.height);
		}
		
		/**
		 * The texture on the cube's right face.
		 */
		public var positiveX(get, set) : BitmapData;
		public function get_positiveX() : BitmapData
		{
			return _bitmapDatas[0];
		}
		
		public function set_positiveX(value:BitmapData) : BitmapData
		{
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
			_bitmapDatas[0] = value;
			return value;
		}
		
		/**
		 * The texture on the cube's left face.
		 */
		public var negativeX(get, set) : BitmapData;
		public function get_negativeX() : BitmapData
		{
			return _bitmapDatas[1];
		}
		
		public function set_negativeX(value:BitmapData) : BitmapData
		{
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
			_bitmapDatas[1] = value;
			return value;
		}
		
		/**
		 * The texture on the cube's top face.
		 */
		public var positiveY(get, set) : BitmapData;
		public function get_positiveY() : BitmapData
		{
			return _bitmapDatas[2];
		}
		
		public function set_positiveY(value:BitmapData) : BitmapData
		{
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
			_bitmapDatas[2] = value;
			return value;
		}
		
		/**
		 * The texture on the cube's bottom face.
		 */
		public var negativeY(get, set) : BitmapData;
		public function get_negativeY() : BitmapData
		{
			return _bitmapDatas[3];
		}
		
		public function set_negativeY(value:BitmapData) : BitmapData
		{
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
			_bitmapDatas[3] = value;
			return value;
		}
		
		/**
		 * The texture on the cube's far face.
		 */
		public var positiveZ(get, set) : BitmapData;
		public function get_positiveZ() : BitmapData
		{
			return _bitmapDatas[4];
		}
		
		public function set_positiveZ(value:BitmapData) : BitmapData
		{
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
			_bitmapDatas[4] = value;
			return value;
		}
		
		/**
		 * The texture on the cube's near face.
		 */
		public var negativeZ(get, set) : BitmapData;
		public function get_negativeZ() : BitmapData
		{
			return _bitmapDatas[5];
		}
		
		public function set_negativeZ(value:BitmapData) : BitmapData
		{
			testSize(value);
			invalidateContent();
			setSize(value.width, value.height);
			_bitmapDatas[5] = value;
			return value;
		}
		
		private function testSize(value:BitmapData):Void
		{
			if (value.width != value.height)
				throw new Error("BitmapData should have equal width and height!");
			if (!TextureUtils.isBitmapDataValid(value))
				throw new Error("Invalid bitmapData: Width and height must be power of 2 and cannot exceed 2048");
		}
		
		override private function uploadContent(texture:TextureBase):Void
		{
			// For loop conversion - 			for (var i:Int = 0; i < 6; ++i)
			var i:Int;
			for (i in 0...6)
				MipmapGenerator.generateMipMaps(_bitmapDatas[i], texture, null, _bitmapDatas[i].transparent, i);
		}
	}

