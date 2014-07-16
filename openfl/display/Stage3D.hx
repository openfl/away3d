/****
* 
****/

package openfl.display;

#if display
@:require(flash11) extern class Stage3D extends openfl.events.EventDispatcher {
	var context3D(default,null) : openfl.display3D.Context3D;
	var visible : Bool;
	var x : Float;
	var y : Float;
	function requestContext3D(?context3DRenderMode : String, ?profile : openfl.display3D.Context3DProfile) : Void;
}
#end