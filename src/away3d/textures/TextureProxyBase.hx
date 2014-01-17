package away3d.textures;


import flash.Vector;
import away3d.core.managers.Stage3DProxy;
import away3d.errors.AbstractMethodError;
import away3d.library.assets.AssetType;
import away3d.library.assets.IAsset;
import away3d.library.assets.NamedAssetBase;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.TextureBase;

class TextureProxyBase extends NamedAssetBase implements IAsset {
    public var hasMipMaps(get_hasMipMaps, never):Bool;
    public var format(get_format, never):Context3DTextureFormat;
    public var assetType(get_assetType, never):String;
    public var width(get_width, never):Int;
    public var height(get_height, never):Int;

    private var _format:Context3DTextureFormat;
    private var _hasMipmaps:Bool;
    private var _textures:Vector<TextureBase>;
    private var _dirty:Vector<Context3D>;
    private var _width:Int;
    private var _height:Int;

    public function new() {
        _format = Context3DTextureFormat.BGRA;
        _hasMipmaps = true;
        _textures = new Vector<TextureBase>(8);
        _dirty = new Vector<Context3D>(8);
        super();
    }

    public function get_hasMipMaps():Bool {
        return _hasMipmaps;
    }

    public function get_format():Context3DTextureFormat {
        return _format;
    }

    public function get_assetType():String {
        return AssetType.TEXTURE;
    }

    public function get_width():Int {
        return _width;
    }

    public function get_height():Int {
        return _height;
    }

    public function set_width(value:Int):Int {
        if (value == _width) return value;
        _width = value;
        return value;
    }

    public function set_height(value:Int):Int {
        if (value == _height) return value;
        _height = value;
        return value;
    }

    public function getTextureForStage3D(stage3DProxy:Stage3DProxy):TextureBase {
        var contextIndex:Int = stage3DProxy._stage3DIndex;
        var tex:TextureBase = _textures[contextIndex];
        var context:Context3D = stage3DProxy._context3D;
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

