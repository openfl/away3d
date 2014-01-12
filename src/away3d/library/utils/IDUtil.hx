package away3d.library.utils;

	
	class IDUtil
	{
		/**
		 *  @private
		 *  Char codes for 0123456789ABCDEF
		 */
		private static var ALPHA_CHAR_CODES:Array<Dynamic> = [48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69, 70];
		
		/**
		 *  Generates a UID (unique identifier) based on ActionScript's
		 *  pseudo-random number generator and the current time.
		 *
		 *  <p>The UID has the form
		 *  <code>"XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"</code>
		 *  where X is a hexadecimal digit (0-9, A-F).</p>
		 *
		 *  <p>This UID will not be truly globally unique; but it is the best
		 *  we can do without player support for UID generation.</p>
		 *
		 *  @return The newly-generated UID.
		 *
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public static function createUID():String
		{
			var uid:Array<Dynamic> = [];
			var index:Int = 0;
			
			var i:Int;
			var j:Int;
			
			// For loop conversion - 						for (i = 0; i < 8; i++)
			
			for (i in 0...8)
				uid[index++] = ALPHA_CHAR_CODES[Math.floor(Math.random()*16)];
			
			// For loop conversion - 						for (i = 0; i < 3; i++)
			
			for (i in 0...3) {
				uid[index++] = 45; // charCode for "-"
				
				// For loop conversion - 								for (j = 0; j < 4; j++)
				
				for (j in 0...4)
					uid[index++] = ALPHA_CHAR_CODES[Math.floor(Math.random()*16)];
			}
			
			uid[index++] = 45; // charCode for "-"
			
			var time:UInt = flash.Lib.getTimer();
			// Note: time is the number of milliseconds since 1970,
			// which is currently more than one trillion.
			// We use the low 8 hex digits of this number in the UID.
			// Just in case the system clock has been reset to
			// Jan 1-4, 1970 (in which case this number could have only
			// 1-7 hex digits), we pad on the left with 7 zeros
			// before taking the low digits.
			var timeString:String = ("0000000" + StringTools.hex(time).toUpperCase()).substr(-8);
			
			// For loop conversion - 						for (i = 0; i < 8; i++)
			
			for (i in 0...8)
				uid[index++] = timeString.charCodeAt(i);
			
			// For loop conversion - 						for (i = 0; i < 4; i++)
			
			for (i in 0...4)
				uid[index++] = ALPHA_CHAR_CODES[Math.floor(Math.random()*16)];
			
			return generateStringFromCharCodeArray(uid);
		}

		public static function generateStringFromCharCodeArray(chars:Array<Dynamic>) {
			var str = "";
			for (chr in chars)
				str += String.fromCharCode(cast(chr, UInt));
			return str;
		}
		
		/**
		 * Returns the decimal representation of a hex digit.
		 * @private
		 */
		private static function getDigit(hex:String):UInt
		{
			switch (hex) {
				case "A" | "a":
					return 10;
				case "B" | "b":
					return 11;
				case "C" | "c":
					return 12;
				case "D" | "d":
					return 13;
				case "E" | "e":
					return 14;
				case "F" | "f":
					return 15;
				default:
					return Std.parseInt("0x"+hex);
			}
		}
	}

