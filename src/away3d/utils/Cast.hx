/** Helper class for casting assets to usable objects */
package away3d.utils;

import flash.errors.Error;
import flash.geom.Matrix;
import flash.display.DisplayObject;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.xml.XML;
import flash.utils.ByteArray;
import haxe.ds.StringMap;
import away3d.errors.CastError;
import away3d.textures.BitmapTexture;

class Cast {

    static private var _colorNames:StringMap<UInt>;
    static private var _hexChars:String = "0123456789abcdefABCDEF";
    static private var _notClasses:StringMap<Bool> = new StringMap<Bool>();
    static private var _classes:StringMap<Dynamic> = new StringMap<Dynamic>();

    static public function string(data:Dynamic):String {
        if (Std.is(data, Class)) data = Type.createInstance(data, []);
        if (Std.is(data, String)) return data;
        return Std.string(data);
    }

    static public function byteArray(data:Dynamic):ByteArray { 
        if (Std.is(data, Class)) data = Type.createInstance(data, []);
        if (Std.is(data, ByteArray)) return data;
        return cast((data), ByteArray);
    }

    static public function xml(data:Dynamic):XML {
        if (Std.is(data, Class)) data = Type.createInstance(data, []);
        if (Std.is(data, XML)) return data;
        return cast((data), XML);
    }

    static private function isHex(string:String):Bool {
        var length:Int = string.length;
        var i:Int = 0;
        while (i < length) {
            if (_hexChars.indexOf(string.charAt(i)) == -1) return false;
            ++i;
        }
        return true;
    }

    static public function tryColor(data:Dynamic):Int {
        if (Std.is(data, UInt)) return cast(data, UInt);
        if (Std.is(data, Int)) return cast(data, UInt);
        if (Std.is(data, String)) {
            if (data == "random") return Std.int(Math.random() * 0x1000000);
            if (_colorNames == null) {
                _colorNames = new StringMap<UInt>();
                _colorNames.set("steelblue", 0x4682B4);
                _colorNames.set("royalblue", 0x041690);
                _colorNames.set("cornflowerblue", 0x6495ED);
                _colorNames.set("lightsteelblue", 0xB0C4DE);
                _colorNames.set("mediumslateblue", 0x7B68EE);
                _colorNames.set("slateblue", 0x6A5ACD);
                _colorNames.set("darkslateblue", 0x483D8B);
                _colorNames.set("midnightblue", 0x191970);
                _colorNames.set("navy", 0x000080);
                _colorNames.set("darkblue", 0x00008B);
                _colorNames.set("mediumblue", 0x0000CD);
                _colorNames.set("blue", 0x0000FF);
                _colorNames.set("dodgerblue", 0x1E90FF);
                _colorNames.set("deepskyblue", 0x00BFFF);
                _colorNames.set("lightskyblue", 0x87CEFA);
                _colorNames.set("skyblue", 0x87CEEB);
                _colorNames.set("lightblue", 0xADD8E6);
                _colorNames.set("powderblue", 0xB0E0E6);
                _colorNames.set("azure", 0xF0FFFF);
                _colorNames.set("lightcyan", 0xE0FFFF);
                _colorNames.set("paleturquoise", 0xAFEEEE);
                _colorNames.set("mediumturquoise", 0x48D1CC);
                _colorNames.set("lightseagreen", 0x20B2AA);
                _colorNames.set("darkcyan", 0x008B8B);
                _colorNames.set("teal", 0x008080);
                _colorNames.set("cadetblue", 0x5F9EA0);
                _colorNames.set("darkturquoise", 0x00CED1);
                _colorNames.set("aqua", 0x00FFFF);
                _colorNames.set("cyan", 0x00FFFF);
                _colorNames.set("turquoise", 0x40E0D0);
                _colorNames.set("aquamarine", 0x7FFFD4);
                _colorNames.set("mediumaquamarine", 0x66CDAA);
                _colorNames.set("darkseagreen", 0x8FBC8F);
                _colorNames.set("mediumseagreen", 0x3CB371);
                _colorNames.set("seagreen", 0x2E8B57);
                _colorNames.set("darkgreen", 0x006400);
                _colorNames.set("green", 0x008000);
                _colorNames.set("forestgreen", 0x228B22);
                _colorNames.set("limegreen", 0x32CD32);
                _colorNames.set("lime", 0x00FF00);
                _colorNames.set("chartreuse", 0x7FFF00);
                _colorNames.set("lawngreen", 0x7CFC00);
                _colorNames.set("greenyellow", 0xADFF2F);
                _colorNames.set("yellowgreen", 0x9ACD32);
                _colorNames.set("palegreen", 0x98FB98);
                _colorNames.set("lightgreen", 0x90EE90);
                _colorNames.set("springgreen", 0x00FF7F);
                _colorNames.set("mediumspringgreen", 0x00FA9A);
                _colorNames.set("darkolivegreen", 0x556B2F);
                _colorNames.set("olivedrab", 0x6B8E23);
                _colorNames.set("olive", 0x808000);
                _colorNames.set("darkkhaki", 0xBDB76B);
                _colorNames.set("darkgoldenrod", 0xB8860B);
                _colorNames.set("goldenrod", 0xDAA520);
                _colorNames.set("gold", 0xFFD700);
                _colorNames.set("yellow", 0xFFFF00);
                _colorNames.set("khaki", 0xF0E68C);
                _colorNames.set("palegoldenrod", 0xEEE8AA);
                _colorNames.set("blanchedalmond", 0xFFEBCD);
                _colorNames.set("moccasin", 0xFFE4B5);
                _colorNames.set("wheat", 0xF5DEB3);
                _colorNames.set("navajowhite", 0xFFDEAD);
                _colorNames.set("burlywood", 0xDEB887);
                _colorNames.set("tan", 0xD2B48C);
                _colorNames.set("rosybrown", 0xBC8F8F);
                _colorNames.set("sienna", 0xA0522D);
                _colorNames.set("saddlebrown", 0x8B4513);
                _colorNames.set("chocolate", 0xD2691E);
                _colorNames.set("peru", 0xCD853F);
                _colorNames.set("sandybrown", 0xF4A460);
                _colorNames.set("darkred", 0x8B0000);
                _colorNames.set("maroon", 0x800000);
                _colorNames.set("brown", 0xA52A2A);
                _colorNames.set("firebrick", 0xB22222);
                _colorNames.set("indianred", 0xCD5C5C);
                _colorNames.set("lightcoral", 0xF08080);
                _colorNames.set("salmon", 0xFA8072);
                _colorNames.set("darksalmon", 0xE9967A);
                _colorNames.set("lightsalmon", 0xFFA07A);
                _colorNames.set("coral", 0xFF7F50);
                _colorNames.set("tomato", 0xFF6347);
                _colorNames.set("darkorange", 0xFF8C00);
                _colorNames.set("orange", 0xFFA500);
                _colorNames.set("orangered", 0xFF4500);
                _colorNames.set("crimson", 0xDC143C);
                _colorNames.set("red", 0xFF0000);
                _colorNames.set("deeppink", 0xFF1493);
                _colorNames.set("fuchsia", 0xFF00FF);
                _colorNames.set("magenta", 0xFF00FF);
                _colorNames.set("hotpink", 0xFF69B4);
                _colorNames.set("lightpink", 0xFFB6C1);
                _colorNames.set("pink", 0xFFC0CB);
                _colorNames.set("palevioletred", 0xDB7093);
                _colorNames.set("mediumvioletred", 0xC71585);
                _colorNames.set("purple", 0x800080);
                _colorNames.set("darkmagenta", 0x8B008B);
                _colorNames.set("mediumpurple", 0x9370DB);
                _colorNames.set("blueviolet", 0x8A2BE2);
                _colorNames.set("indigo", 0x4B0082);
                _colorNames.set("darkviolet", 0x9400D3);
                _colorNames.set("darkorchid", 0x9932CC);
                _colorNames.set("mediumorchid", 0xBA55D3);
                _colorNames.set("orchid", 0xDA70D6);
                _colorNames.set("violet", 0xEE82EE);
                _colorNames.set("plum", 0xDDA0DD);
                _colorNames.set("thistle", 0xD8BFD8);
                _colorNames.set("lavender", 0xE6E6FA);
                _colorNames.set("ghostwhite", 0xF8F8FF);
                _colorNames.set("aliceblue", 0xF0F8FF);
                _colorNames.set("mintcream", 0xF5FFFA);
                _colorNames.set("honeydew", 0xF0FFF0);
                _colorNames.set("lightgoldenrodyellow", 0xFAFAD2);
                _colorNames.set("lemonchiffon", 0xFFFACD);
                _colorNames.set("cornsilk", 0xFFF8DC);
                _colorNames.set("lightyellow", 0xFFFFE0);
                _colorNames.set("ivory", 0xFFFFF0);
                _colorNames.set("floralwhite", 0xFFFAF0);
                _colorNames.set("linen", 0xFAF0E6);
                _colorNames.set("oldlace", 0xFDF5E6);
                _colorNames.set("antiquewhite", 0xFAEBD7);
                _colorNames.set("bisque", 0xFFE4C4);
                _colorNames.set("peachpuff", 0xFFDAB9);
                _colorNames.set("papayawhip", 0xFFEFD5);
                _colorNames.set("beige", 0xF5F5DC);
                _colorNames.set("seashell", 0xFFF5EE);
                _colorNames.set("lavenderblush", 0xFFF0F5);
                _colorNames.set("mistyrose", 0xFFE4E1);
                _colorNames.set("snow", 0xFFFAFA);
                _colorNames.set("white", 0xFFFFFF);
                _colorNames.set("whitesmoke", 0xF5F5F5);
                _colorNames.set("gainsboro", 0xDCDCDC);
                _colorNames.set("lightgrey", 0xD3D3D3);
                _colorNames.set("silver", 0xC0C0C0);
                _colorNames.set("darkgrey", 0xA9A9A9);
                _colorNames.set("grey", 0x808080);
                _colorNames.set("lightslategrey", 0x778899);
                _colorNames.set("slategrey", 0x708090);
                _colorNames.set("dimgrey", 0x696969);
                _colorNames.set("darkslategrey", 0x2F4F4F);
                _colorNames.set("black", 0x000000);
                _colorNames.set("transparent", 0xFF000000);
            }

            if (_colorNames.exists(data))
                return _colorNames.get(data);
            if ((( cast(data, String) ).length == 6) && isHex(data)) return Std.parseInt("0x" + data);
        }
        return 0xFFFFFF;
    }

    static public function color(data:Dynamic):Int {
        var result:Int = tryColor(data);
        if (result == 0xFFFFFFFF) throw new CastError("Can't cast to color: " + data);
        return result;
    }

    public static function tryClass(name:String):Dynamic {
        if (_notClasses.exists(name))
            return name;

        var result = _classes.get(name);

        if (result != null)
            return result;

        try {
            result = Type.resolveClass(name);
            _classes.set(name, result);
            return result;
        }
        catch (error:Dynamic) {
        }

        _notClasses.set(name, true);

        return name;
    }

    static public function bitmapData(data:Dynamic):BitmapData {
        if (data == null) return null;
        if (Std.is(data, String)) data = tryClass(data);
        if (Std.is(data, Class)) {
            try {
                data = Type.createInstance(data, []);
            }
            catch (bitmapError:Dynamic) {
                data = Type.createInstance(data, [0, 0]);
            }

        }
        if (Std.is(data, BitmapData)) return data;
        if (Std.is(data, Bitmap)) {
            if (cast(data, Bitmap).bitmapData != null) // if (data is BitmapAsset)
                return ( cast(data, Bitmap) ).bitmapData;
        }
        if (Std.is(data, DisplayObject)) {
            var ds:DisplayObject = cast(data, DisplayObject) ;
            var bmd:BitmapData = new BitmapData(Std.int(ds.width), Std.int(ds.height), true, 0x00FFFF);
            var mat:Matrix = ds.transform.matrix.clone();
            mat.tx = 0;
            mat.ty = 0;
            bmd.draw(ds, mat, ds.transform.colorTransform, ds.blendMode, bmd.rect, true);
            return bmd;
        }
        throw new CastError("Can't cast to BitmapData: " + data);
    }

    static public function bitmapTexture(data:Dynamic):BitmapTexture {
        if (data == null) return null;
        if (Std.is(data, String)) data = tryClass(data);
        if (Std.is(data, Class)) {
            try {
                data = Type.createInstance(data, []);
            }
            catch (materialError:Dynamic) {
                data = Type.createInstance(data, [0, 0]);
            }

        }
        if (Std.is(data, BitmapTexture)) return data;
        try {
            var bmd:BitmapData = Cast.bitmapData(data);
            return new BitmapTexture(bmd);
        }
        catch (error:CastError) { };
        throw new CastError("Can't cast to BitmapTexture: " + data);
    }

}

