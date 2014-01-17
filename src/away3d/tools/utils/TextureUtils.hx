package away3d.tools.utils;

import flash.display.BitmapData;

class TextureUtils {

    static private var MAX_SIZE:Int = 4096;

    static public function isBitmapDataValid(bitmapData:BitmapData):Bool {
        if (bitmapData == null) return true;
        return isDimensionValid(bitmapData.width) && isDimensionValid(bitmapData.height);
    }

    static public function isDimensionValid(d:Int):Bool {
        return d >= 1 && d <= MAX_SIZE && isPowerOfTwo(d);
    }

    static public function isPowerOfTwo(value:Int):Bool {
        return (value > 0) ? ((value & -value) == value) : false;
    }

    static public function getBestPowerOf2(value:Int):Int {
        var p:Int = 1;
        while (p < value)p <<= 1;
        if (p > MAX_SIZE) p = MAX_SIZE;
        return p;
    }

}

