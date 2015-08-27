package away3d.textures;


import openfl.errors.Error;
import away3d.materials.utils.MipmapGenerator;
import away3d.tools.utils.TextureUtils;
import openfl.display.BitmapData;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.TextureBase;
import openfl.utils.UInt8Array;
import openfl.utils.ByteArray;

class BitmapTexture extends Texture2DBase {

    static private var _mipMaps:Array<Dynamic> = [];
    static private var _mipMapUses:Array<Dynamic> = [];
    private var _bitmapData:BitmapData;
    private var _mipMapHolder:BitmapData;
    private var _generateMipmaps:Bool;
    private var _bitmapDataArray:UInt8Array;

    public function new(bitmapData:BitmapData, generateMipmaps:Bool = true) {
        super();
        this.bitmapData = bitmapData;
        setSize(_bitmapData.width, _bitmapData.height);
        _generateMipmaps = _hasMipmaps = generateMipmaps;
    }

    public var bitmapData(get, set):BitmapData;

    private function get_bitmapData():BitmapData {
        return _bitmapData;
    }

    private function set_bitmapData(value:BitmapData):BitmapData {
        if (value == _bitmapData) return null;
        
        if (!TextureUtils.isBitmapDataValid(value)) throw new Error("Invalid bitmapData: Width and height must be power of 2 and cannot exceed 2048");
        
        invalidateContent();
        setSize(value.width, value.height);
        
        _bitmapData = value;
        
        #if flash
        
        if (_generateMipmaps)
            getMipMapHolder();
        
        #elseif (lime_legacy || hybrid)
        
        var data = BitmapData.getRGBAPixels (_bitmapData);
        _bitmapDataArray = new UInt8Array (data);

        #elseif js

        var data = bitmapData.image.data.buffer;
        _bitmapDataArray = new UInt8Array (data);
        
        #else

        // TODO: Implement BGRA directly in GL using BGRA_EXT

        var data = bitmapData.image.data;
        _bitmapDataArray = new UInt8Array (data.length);
        
        var i:Int = 0;
        while (i < data.length) {
            
            _bitmapDataArray[i] = data[i+2];
            _bitmapDataArray[i+1] = data[i+1];
            _bitmapDataArray[i+2] = data[i];
            _bitmapDataArray[i+3] = data[i+3];
            i+=4;
            
        }

        #end
 
        return value;
    }

    override private function uploadContent(texture:TextureBase):Void { 
        #if flash
        if (_generateMipmaps) MipmapGenerator.generateMipMaps(_bitmapData, texture, _mipMapHolder, true)
        else cast((texture), Texture).uploadFromBitmapData(_bitmapData, 0);
        #else
        cast((texture), Texture).uploadFromUInt8Array(_bitmapDataArray, 0);
        #end
    }

    private function getMipMapHolder():Void {
        var newW:Int, newH:Int;

        newW = _bitmapData.width;
        newH = _bitmapData.height;

        if (_mipMapHolder != null) {
            if (_mipMapHolder.width == newW && _bitmapData.height == newH)
                return;

            freeMipMapHolder();
        }

        if (_mipMaps[newW] == null) {
            _mipMaps[newW] = [];
            _mipMapUses[newW] = [];
        }
        if (_mipMaps[newW][newH] == null) {
            _mipMapHolder = _mipMaps[newW][newH] = new BitmapData(newW, newH, true);
            _mipMapUses[newW][newH] = 1;
        }
        else {
            _mipMapUses[newW][newH] = _mipMapUses[newW][newH] + 1;
            _mipMapHolder = _mipMaps[newW][newH];
        }
    }

    private function freeMipMapHolder():Void {
        var holderWidth:Int = _mipMapHolder.width;
        var holderHeight:Int = _mipMapHolder.height;

        if (--_mipMapUses[holderWidth][holderHeight] == 0) {
            _mipMaps[holderWidth][holderHeight].dispose();
            _mipMaps[holderWidth][holderHeight] = null;
        }
    }

    override public function dispose():Void {
        super.dispose();

        if (_mipMapHolder != null)
            freeMipMapHolder();
    }
}

