package away3d.tools.utils;

	import flash.display.BitmapData;
	
	class TextureUtils
	{
		private static var MAX_SIZE:UInt = 2048;
		
		public static function isBitmapDataValid(bitmapData:BitmapData):Bool
		{
			if (bitmapData == null)
				return true;
			
			return isDimensionValid(bitmapData.width) && isDimensionValid(bitmapData.height);
		}
		
		public static function isDimensionValid(d:UInt):Bool
		{
			return d >= 1 && d <= MAX_SIZE && isPowerOfTwo(d);
		}
		
		public static function isPowerOfTwo(value:Int):Bool
		{
			return (value!=0 ? ((value & -value) == value) : false);
		}
		
		public static function getBestPowerOf2(value:UInt):UInt
		{
			var p:UInt = 1;
			
			while (p < value)
				p <<= 1;
			
			if (p > MAX_SIZE)
				p = MAX_SIZE;
			
			return p;
		}
	}

