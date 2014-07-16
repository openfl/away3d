package openfl.display3D;

#if display
extern class IndexBuffer3D {
    function dispose() : Void;
    function uploadFromByteArray(data : openfl.utils.ByteArray, byteArrayOffset : Int, startOffset : Int, count : Int) : Void;
    function uploadFromVector(data : Array<Int>, startOffset : Int, count : Int) : Void;
}
#end