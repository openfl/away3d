package away3d;

import flash.Lib;
import flash.Vector;
import flash.errors.Error;
import flash.geom.Vector3D; 
import flash.geom.Matrix3D;
class Stage3DUtils {

    static public function fillArray<T>(f:Array<T>, start:Int, len:Int, value:T):Void {
		for (i in start...start + len) {
			f[i] = value;
		}
	  
	}
    static public function fillVector<T>(f:Vector<T>, start:Int, len:Int, value:T):Void {
		for (i in start...start + len) {
			f[i] = value;
		}
	}
    static public function copyColumnTo(mat:Matrix3D, column:Int, vector3D:Vector3D):Void {

// Initial Tests - OK

        switch (column) {
            case 0:
                vector3D.x = mat.rawData[ 0 ];
                vector3D.y = mat.rawData[ 1 ];
                vector3D.z = mat.rawData[ 2 ];
                vector3D.w = mat.rawData[ 3 ];

            case 1:
                vector3D.x = mat.rawData[ 4 ];
                vector3D.y = mat.rawData[ 5 ];
                vector3D.z = mat.rawData[ 6 ];
                vector3D.w = mat.rawData[ 7 ];

            case 2:
                vector3D.x = mat.rawData[ 8 ];
                vector3D.y = mat.rawData[ 9 ];
                vector3D.z = mat.rawData[ 10 ];
                vector3D.w = mat.rawData[ 11 ];

            case 3:
                vector3D.x = mat.rawData[ 12 ];
                vector3D.y = mat.rawData[ 13 ];
                vector3D.z = mat.rawData[ 14 ];
                vector3D.w = mat.rawData[ 15 ];

            default:
                throw new Error("ArgumentError, Column " + column + " out of bounds [0, ..., 3]");
        }
    }

    static public function copyRowFrom(mat:Matrix3D, row:Int, vector3D:Vector3D):Void {

// Initial Tests - OK

        switch (row) {
            case 0:
                mat.rawData[ 0 ] = vector3D.x;
                mat.rawData[ 4 ] = vector3D.y;
                mat.rawData[ 8 ] = vector3D.z;
                mat.rawData[ 12 ] = vector3D.w;

            case 1:
                mat.rawData[ 1 ] = vector3D.x;
                mat.rawData[ 5 ] = vector3D.y;
                mat.rawData[ 9 ] = vector3D.z;
                mat.rawData[ 13 ] = vector3D.w;

            case 2:
                mat.rawData[ 2 ] = vector3D.x;
                mat.rawData[ 6 ] = vector3D.y;
                mat.rawData[ 10 ] = vector3D.z;
                mat.rawData[ 14 ] = vector3D.w;

            case 3:
                mat.rawData[ 3 ] = vector3D.x;
                mat.rawData[ 7 ] = vector3D.y;
                mat.rawData[ 11 ] = vector3D.z;
                mat.rawData[ 15 ] = vector3D.w;

            default:
                throw new Error("ArgumentError, Row " + row + " out of bounds [0, ..., 3]");
        }
    }

    static public function copyRowTo(mat:Matrix3D, row:Int, vector3D:Vector3D) {

// Initial Tests - OK

        switch (row) {
            case 0:
                vector3D.x = mat.rawData[ 0 ];
                vector3D.y = mat.rawData[ 4 ];
                vector3D.z = mat.rawData[ 8 ];
                vector3D.w = mat.rawData[ 12 ];

            case 1:
                vector3D.x = mat.rawData[ 1 ];
                vector3D.y = mat.rawData[ 5 ];
                vector3D.z = mat.rawData[ 9 ];
                vector3D.w = mat.rawData[ 13 ];

            case 2:
                vector3D.x = mat.rawData[ 2 ];
                vector3D.y = mat.rawData[ 6 ];
                vector3D.z = mat.rawData[ 10 ];
                vector3D.w = mat.rawData[ 14 ];

            case 3:
                vector3D.x = mat.rawData[ 3 ];
                vector3D.y = mat.rawData[ 7 ];
                vector3D.z = mat.rawData[ 11 ];
                vector3D.w = mat.rawData[ 15 ];

            default:
                throw new Error("ArgumentError, Row " + row + " out of bounds [0, ..., 3]");
        }
    }

    static public function copyRawDataFrom(mat:Matrix3D, vector:Vector<Float>, ?index:Int = 0, ?transpose:Bool = false):Void {
// Initial Tests - OK
        if (transpose) {
            mat.transpose();
        }

        var l:Int = vector.length - index;
        for (c in 0...l) {
            mat.rawData[c] = vector[c + index];
        }

        if (transpose) {
            mat.transpose();
        }
    }

    static public function copyRawDataTo(mat:Matrix3D, vector:Vector<Float>, ?index:Int = 0, ?transpose:Bool = false):Void {

// Initial Tests - OK
        if (transpose) {
            mat.transpose();
        }
        var l:Int = mat.rawData.length;
        for (c in 0...l) {
            vector[c + index ] = mat.rawData[c];
        }
        if (transpose) {
            mat.transpose();
        }

    }
}