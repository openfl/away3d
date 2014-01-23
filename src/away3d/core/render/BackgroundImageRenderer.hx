package away3d.core.render;

import flash.display3D.shaders.AGLSLShaderUtils;
import flash.Vector;
import away3d.core.managers.Stage3DProxy;
import away3d.textures.Texture2DBase;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;

class BackgroundImageRenderer {
    public var stage3DProxy(get_stage3DProxy, set_stage3DProxy):Stage3DProxy;
    public var texture(get_texture, set_texture):Texture2DBase;

    private var _program3d:Program3D;
    private var _texture:Texture2DBase;
    private var _indexBuffer:IndexBuffer3D;
    private var _vertexBuffer:VertexBuffer3D;
    private var _stage3DProxy:Stage3DProxy;
    private var _context:Context3D;

    public function new(stage3DProxy:Stage3DProxy) {
        this.stage3DProxy = stage3DProxy;
    }

    public function get_stage3DProxy():Stage3DProxy {
        return _stage3DProxy;
    }

    public function set_stage3DProxy(value:Stage3DProxy):Stage3DProxy {
        if (value == _stage3DProxy) return value;
        _stage3DProxy = value;
        removeBuffers();
        return value;
    }

    private function removeBuffers():Void {
        if (_vertexBuffer != null) {
            _vertexBuffer.dispose();
            _vertexBuffer = null;
            _program3d.dispose();
            _program3d = null;
            _indexBuffer.dispose();
            _indexBuffer = null;
        }
    }

    public function getVertexCode():String {
        return "mov op, va0\n" + "mov v0, va1";
    }

    public function getFragmentCode():String {
        var format:String;
        var _sw0_ = (_texture.format);
        switch(_sw0_) {
            case Context3DTextureFormat.COMPRESSED:
                format = "dxt1,";
            case Context3DTextureFormat.COMPRESSED_ALPHA:
                format = "dxt5,";
            default:
                format = "";
        }
        return "tex ft0, v0, fs0 <2d, " + format + "linear>	\n" + "mov oc, ft0";
    }

    public function dispose():Void {
        removeBuffers();
    }

    public function render():Void {
		//todo 
		/*
        var context:Context3D = _stage3DProxy.context3D;
        if (context != _context) {
            removeBuffers();
            _context = context;
        }
        if (context == null) return;
        if (_vertexBuffer == null) initBuffers(context);
		
        context.setProgram(_program3d);
        context.setTextureAt(0, _texture.getTextureForStage3D(_stage3DProxy));
        context.setVertexBufferAt(0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
        context.setVertexBufferAt(1, _vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
        context.drawTriangles(_indexBuffer, 0, 2);
        context.setVertexBufferAt(0, null);
        context.setVertexBufferAt(1, null);
        context.setTextureAt(0, null);
		*/
    }

    private function initBuffers(context:Context3D):Void {
        _vertexBuffer = context.createVertexBuffer(4, 4);
        _program3d = context.createProgram();
        _indexBuffer = context.createIndexBuffer(6);
        _indexBuffer.uploadFromVector(flash.Vector.ofArray(cast [2, 1, 0, 3, 2, 0]), 0, 6);
        _program3d.upload(AGLSLShaderUtils.createShader(Context3DProgramType.VERTEX, getVertexCode()), AGLSLShaderUtils.createShader(Context3DProgramType.FRAGMENT, getFragmentCode()));
        var w:Float = 2;
        var h:Float = 2;
        var x:Float = -1;
        var y:Float = 1;
        if (_stage3DProxy.scissorRect != null) {
            x = (_stage3DProxy.scissorRect.x * 2 - _stage3DProxy.viewPort.width) / _stage3DProxy.viewPort.width;
            y = (_stage3DProxy.scissorRect.y * 2 - _stage3DProxy.viewPort.height) / _stage3DProxy.viewPort.height * -1;
            w = 2 / (_stage3DProxy.viewPort.width / _stage3DProxy.scissorRect.width);
            h = 2 / (_stage3DProxy.viewPort.height / _stage3DProxy.scissorRect.height);
        }
        _vertexBuffer.uploadFromVector(Vector.ofArray(cast [x, y - h, 0, 1, x + w, y - h, 1, 1, x + w, y, 1, 0, x, y, 0, 0]), 0, 4);
    }

    public function get_texture():Texture2DBase {
        return _texture;
    }

    public function set_texture(value:Texture2DBase):Texture2DBase {
        _texture = value;
        return value;
    }

}

