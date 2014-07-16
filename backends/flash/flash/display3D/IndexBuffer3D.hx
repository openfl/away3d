package flash.display3D;

extern class IndexBuffer3D {
    function dispose() : Void;
    function uploadFromByteArray(data : openfl.utils.ByteArray, byteArrayOffset : Int, startOffset : Int, count : Int) : Void;
    function uploadFromVector(data : openfl.Vector<UInt>, startOffset : Int, count : Int) : Void;
}
