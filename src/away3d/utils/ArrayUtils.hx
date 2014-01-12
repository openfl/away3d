package away3d.utils;

class ArrayUtils {
	public static function Prefill(array:Dynamic, count:UInt, ?defaultValue:Dynamic = null):Dynamic {
		var c:UInt = 0;
		while (c++ < count) {
			array.push(defaultValue);
		}
		return array;
	}
}