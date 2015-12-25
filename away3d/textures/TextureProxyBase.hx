package away3d.textures;

import away3d.core.managers.Stage3DProxy;
import away3d.errors.AbstractMethodError;
import away3d.library.assets.Asset3DType;
import away3d.library.assets.IAsset;
import away3d.library.assets.NamedAssetBase;
import away3d.utils.ArrayUtils;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.textures.TextureBase;
import openfl.Vector;

class TextureProxyBase extends NamedAssetBase implements IAsset {
    public var hasMipMaps(get, never):Bool;
    public var format(get, never):Context3DTextureFormat;
    public var assetType(get, never):String;
    public var width(get, never):Int;
    public var height(get, never):Int;

    private var _format:Context3DTextureFormat;
    private var _hasMipmaps:Bool;
    private var _textures:Vector<TextureBase>;
    private var _dirty:Vector<Context3D>;
    private var _width:Int;
    private var _height:Int;

    public function new() {
        _format = Context3DTextureFormat.BGRA;
        _hasMipmaps = true;
        _textures = ArrayUtils.Prefill( new Vector<TextureBase>(), 8 );
        _dirty = ArrayUtils.Prefill( new Vector<Context3D>(), 8 );
        super();
    }

    private function get_hasMipMaps():Bool {
        return _hasMipmaps;
    }

    private function get_format():Context3DTextureFormat {
        return _format;
    }

    private function get_assetType():String {
        return Asset3DType.TEXTURE;
    }

    private function get_width():Int {
        return _width;
    }

    private function get_height():Int {
        return _height;
    }

    private function set_width(value:Int):Int {
        if (value == _width) return value;
        _width = value;
        return value;
    }

    private function set_height(value:Int):Int {
        if (value == _height) return value;
        _height = value;
        return value;
    }

    public function getTextureForStage3D(stage3DProxy:Stage3DProxy):TextureBase {
        var contextIndex:Int = stage3DProxy.stage3DIndex;
        var tex:TextureBase = _textures[contextIndex];
        var context:Context3D = stage3DProxy.context3D;
        
        if (tex == null || _dirty[contextIndex] != context) {
            _textures[contextIndex] = tex = createTexture(context);
            _dirty[contextIndex] = context;
            uploadContent(tex);
                
        } 
        return tex;
    }

    private function uploadContent(texture:TextureBase):Void {
        throw new AbstractMethodError();
    }

    private function setSize(width:Int, height:Int):Void {
        if (_width != width || _height != height) invalidateSize();
        _width = width;
        _height = height;
    }

    public function invalidateContent():Void {
        var i:Int = 0;
        while (i < 8) {
            _dirty[i] = null;
            ++i;
        }
    }

    private function invalidateSize():Void {
        var tex:TextureBase;
        var i:Int = 0;
        while (i < 8) {
            tex = _textures[i];
            if (tex != null) {
                tex.dispose();
                _textures[i] = null;
                _dirty[i] = null;
            }
            ++i;
        }
    }

    private function createTexture(context:Context3D):TextureBase {
        throw new AbstractMethodError();
        return null;
    }

    /**
     * @inheritDoc
     */
    public function dispose():Void {
        var i:Int = 0;
        while (i < 8) {
            if (_textures[i] != null) _textures[i].dispose();
            ++i;
        }
    }
}

