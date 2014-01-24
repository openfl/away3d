package away3d.utils;
import flash.geom.Matrix3D;

class ArrayUtils {
	inline public static function reSize(array:Dynamic, count:Int, ?defaultValue:Dynamic = null):Dynamic {
		#if flash
        array.length = count;
        #elseif (cpp || neko || js)
			var c:UInt = array.length;		
			while (c < count) {
				array.push(defaultValue);
				c++;
			}				
			while (c > count) {
				array.pop();
				c--;
			}			
		#end
			for (i in 0...array.length) {
				array[i] = defaultValue;
			}
		return array;
	}
	
	inline public static function Prefill(array:Dynamic, count:Int, ?defaultValue:Dynamic = null):Dynamic {
		#if flash
        var c:Int = 0;
		while (c < count) {
			array[c] = (defaultValue);
			c++;
		}
        #elseif (cpp || neko || js)
		var c:Int = 0;
		while (c++ < count) {
			array.push(defaultValue);
	 
		}
		#end
		return array;
	}
	
}