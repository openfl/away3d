/****
* 
****/

package flash.display3D;
#if (flash || display)
@:fakeEnum(String) extern enum Context3DVertexBufferFormat {
	BYTES_4;
	FLOAT_1;
	FLOAT_2;
	FLOAT_3;
	FLOAT_4;
}
#else
enum Context3DVertexBufferFormat {
    BYTES_4;
    FLOAT_1;
    FLOAT_2;
    FLOAT_3;
    FLOAT_4;
}

#end