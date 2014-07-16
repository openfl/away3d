/****
* 
****/

package openfl.display3D;
#if display
extern class Program3D {
	function dispose() : Void;
	function upload(vertexProgram : openfl.utils.ByteArray, fragmentProgram : openfl.utils.ByteArray) : Void;
}
#end