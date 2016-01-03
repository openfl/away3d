/**
 */
package away3d.filters.tasks;

import openfl.display3D._shaders.AGLSLShaderUtils;
import away3d.cameras.Camera3D;
import away3d.core.managers.Stage3DProxy;
import away3d.errors.AbstractMethodError;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.Program3D;
import openfl.display3D.textures.Texture;

class Filter3DTaskBase {
    public var textureScale(get, set):Int;
    public var target(get, set):Texture;
    public var textureWidth(get, set):Int;
    public var textureHeight(get, set):Int;
    public var requireDepthRender(get, never):Bool;

    private var _mainInputTexture:Texture;
    private var _scaledTextureWidth:Int;
    private var _scaledTextureHeight:Int;
    private var _textureWidth:Int;
    private var _textureHeight:Int;
    private var _textureDimensionsInvalid:Bool;
    private var _program3DInvalid:Bool;
    private var _program3D:Program3D;
    private var _target:Texture;
    private var _requireDepthRender:Bool;
    private var _textureScale:Int;

    public function new(requireDepthRender:Bool = false) {
        _scaledTextureWidth = -1;
        _scaledTextureHeight = -1;
        _textureWidth = -1;
        _textureHeight = -1;
        _textureDimensionsInvalid = true;
        _program3DInvalid = true;
        _textureScale = 0;
        _requireDepthRender = requireDepthRender;
    }

    /**
	 * The texture scale for the input of this texture. This will define the output of the previous entry in the chain
	 */
    private function get_textureScale():Int {
        return _textureScale;
    }

    private function set_textureScale(value:Int):Int {
        if (_textureScale == value) return value;
        _textureScale = value;
        _scaledTextureWidth = _textureWidth >> _textureScale;
        _scaledTextureHeight = _textureHeight >> _textureScale;
        _textureDimensionsInvalid = true;
        return value;
    }

    private function get_target():Texture {
        return _target;
    }

    private function set_target(value:Texture):Texture {
        _target = value;
        return value;
    }

    private function get_textureWidth():Int {
        return _textureWidth;
    }

    private function set_textureWidth(value:Int):Int {
        if (_textureWidth == value) return value;
        _textureWidth = value;
        _scaledTextureWidth = _textureWidth >> _textureScale;
        _textureDimensionsInvalid = true;
        return value;
    }

    private function get_textureHeight():Int {
        return _textureHeight;
    }

    private function set_textureHeight(value:Int):Int {
        if (_textureHeight == value) return value;
        _textureHeight = value;
        _scaledTextureHeight = _textureHeight >> _textureScale;
        _textureDimensionsInvalid = true;
        return value;
    }

    public function getMainInputTexture(stage:Stage3DProxy):Texture {
        if (_textureDimensionsInvalid) updateTextures(stage);
        return _mainInputTexture;
    }

    public function dispose():Void {
        if (_mainInputTexture != null) _mainInputTexture.dispose();
        if (_program3D != null) _program3D.dispose();
    }

    private function invalidateProgram3D():Void {
        _program3DInvalid = true;
    }

    private function updateProgram3D(stage:Stage3DProxy):Void {
        if (_program3D != null) _program3D.dispose();
        _program3D = stage.context3D.createProgram();

        _program3D.upload(AGLSLShaderUtils.createShader(Context3DProgramType.VERTEX, getVertexCode()), AGLSLShaderUtils.createShader(Context3DProgramType.FRAGMENT, getFragmentCode()));
        _program3DInvalid = false;
    }

    public function getVertexCode():String {
        return "mov op, va0\n" + "mov v0, va1\n";
    }

    public function getFragmentCode():String {
        throw new AbstractMethodError();
        return null;
    }

    private function updateTextures(stage:Stage3DProxy):Void {
        if (_mainInputTexture != null) _mainInputTexture.dispose();
        _mainInputTexture = stage.context3D.createTexture(_scaledTextureWidth, _scaledTextureHeight, Context3DTextureFormat.BGRA, true);
        _textureDimensionsInvalid = false;
    }

    public function getProgram3D(stage3DProxy:Stage3DProxy):Program3D {
        if (_program3DInvalid) updateProgram3D(stage3DProxy);
        return _program3D;
    }

    public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D, depthTexture:Texture):Void {
    }

    public function deactivate(stage3DProxy:Stage3DProxy):Void {
    }

    private function get_requireDepthRender():Bool {
        return _requireDepthRender;
    }
}

