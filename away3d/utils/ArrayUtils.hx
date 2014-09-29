package away3d.utils;
import openfl.geom.Matrix3D;
import openfl.Vector;

class ArrayUtils {
	// inline public static function reSize(arr:Dynamic, count:Int, ?defaultValue:Dynamic = null) {
	// 	#if flash
 //        arr.length = count;
 //        #else
	// 	var c:UInt = arr.length;		
	// 	while (c < count) {
	// 		arr.push(defaultValue);
	// 		c++;
	// 	}				
	// 	while (c > count) {
	// 		arr.pop();
	// 		c--;
	// 	}			
	// 	for (i in 0...arr.length) {
	// 		arr[i] = defaultValue;
	// 	}
	// 	#end
	// }
	
	// inline public static function Prefill<T>(arr:T, count:Int, ?defaultValue:Dynamic = null):Dynamic {
	// 	#if flash
 //        var c:Int = 0;
	// 	while (c < count) {
	// 		arr[c] = defaultValue;
	// 		c++;
	// 	}
 //        #else
	// 	arr.splice(0, arr.length);

	// 	var c:Int = 0;
	// 	while (c++ < count) {
	// 		arr.push(defaultValue);
	 
	// 	}
	// 	#end
	// 	return arr;
	// }	

	#if flash
	inline public static function reSize(arr:Dynamic, count:Int, ?defaultValue:Dynamic = null) {
		arr.length = count;
	}

	inline public static function Prefill(arr:Dynamic, count:Int, ?defaultValue:Dynamic = null):Dynamic {
		var c:Int = 0;
		while (c < count) {
			arr[c] = defaultValue;
			c++;
		}
		return arr;
	}
	#else
	public static function reSize<T>( either:AcceptEither<Array<T>,Vector<T>>, count:Int, ?defaultValue:Dynamic = null) {
		switch either.type {
        	case Left(arr):
				var c = arr.length;		
				while (c < count) {
					arr.push(defaultValue);
					c++;
				}				
				while (c > count) {
					arr.pop();
					c--;
				}			
        	case Right(arr):
				var c = arr.length;		
				while (c < count) {
					arr.push(defaultValue);
					c++;
				}				
				while (c > count) {
					arr.pop();
					c--;
				}			
		}
	}


	public static function Prefill<T>( either:AcceptEither<Array<T>,Vector<T>>, count:Int, ?elem:T ):Dynamic {
		switch either.type {
        	case Left(arr):
				arr.splice(0, arr.length);
				var c:Int = 0;
				while (c++ < count) {
					arr.push(elem);
				}
				return arr;
        	case Right(vec): 
				vec.splice(0, vec.length);
				var c:Int = 0;
				while (c++ < count) {
					vec.push(elem);
				}
				return vec;
     	}
	}
	#end
}

abstract AcceptEither<A,B> (Either<A,B>) {
	
	public inline function new( e:Either<A,B> ) this = e;
	
	public var value(get,never):Dynamic;
	public var type(get,never):Either<A,B>;

	inline function get_value() switch this { case Left(v) | Right(v): return v; }
	@:to inline function get_type() return this;
	
	@:from static function fromA( v:A ):AcceptEither<A,B> return new AcceptEither( Left(v) );
	@:from static function fromB( v:B ):AcceptEither<A,B> return new AcceptEither( Right(v) );
}

enum Either<A,B> {
	Left( v:A );
	Right( v:B );
}