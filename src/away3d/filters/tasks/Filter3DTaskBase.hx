/**
 */
package away3d.filters.tasks;

import flash.display3D.shaders.AGLSLShaderUtils;
import away3d.cameras.Camera3D;
import away3d.core.managers.Stage3DProxy;
import away3d.errors.AbstractMethodError;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.Program3D;
import flash.display3D.textures.Texture;

class Filter3DTaskBase {
    public var textureScale(get_textureScale, set_textureScale):Int;
    public var target(get_target, set_target):Texture;
    public var textureWidth(get_textureWidth, set_textureWidth):Int;
    public var textureHeight(get_textureHeight, set_textureHeight):Int;
    public var requireDepthRender(get_requireDepthRender, never):Bool;

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

    public function get_textureScale():Int {
        return _textureScale;
    }

    public function set_textureScale(value:Int):Int {
        if (_textureScale == value) return value;
        _textureScale = value;
        _scaledTextureWidth = _textureWidth >> _textureScale;
        _scaledTextureHeight = _textureHeight >> _textureScale;
        _textureDimensionsInvalid = true;
        return value;
    }

    public function get_target():Texture {
        return _target;
    }

    public function set_target(value:Texture):Texture {
        _target = value;
        return value;
    }

    public function get_textureWidth():Int {
        return _textureWidth;
    }

    public function set_textureWidth(value:Int):Int {
        if (_textureWidth == value) return value;
        _textureWidth = value;
        _scaledTextureWidth = _textureWidth >> _textureScale;
        _textureDimensionsInvalid = true;
        return value;
    }

    public function get_textureHeight():Int {
        return _textureHeight;
    }

    public function set_textureHeight(value:Int):Int {
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

    public function get_requireDepthRender():Bool {
        return _requireDepthRender;
    }

}

