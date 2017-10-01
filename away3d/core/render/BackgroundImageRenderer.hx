package away3d.core.render;

import away3d.core.managers.Stage3DProxy;
import away3d.debug.Debug;
import away3d.textures.Texture2DBase;

import openfl.display3D.Context3D;
import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.utils.AGALMiniAssembler;
import openfl.Vector;

class BackgroundImageRenderer
{
	public var stage3DProxy(get, set):Stage3DProxy;
	public var texture(get, set):Texture2DBase;
	
	private var _program3d:Program3D;
	private var _texture:Texture2DBase;
	private var _indexBuffer:IndexBuffer3D;
	private var _vertexBuffer:VertexBuffer3D;
	private var _stage3DProxy:Stage3DProxy;
	private var _context:Context3D;
	
	public function new(stage3DProxy:Stage3DProxy)
	{
		this.stage3DProxy = stage3DProxy;
	}
	
	private function get_stage3DProxy():Stage3DProxy
	{
		return _stage3DProxy;
	}
	
	private function set_stage3DProxy(value:Stage3DProxy):Stage3DProxy
	{
		if (value == _stage3DProxy)
			return value;
		_stage3DProxy = value;
		
		removeBuffers();
		return value;
	}
	
	private function removeBuffers():Void
	{
		if (_vertexBuffer != null) {
			Stage3DProxy.disposeVertexBuffer(_vertexBuffer);
			_vertexBuffer = null;
			_program3d.dispose();
			_program3d = null;
			Stage3DProxy.disposeIndexBuffer(_indexBuffer);
			_indexBuffer = null;
		}
	}
	
	private function getVertexCode():String
	{
		return "mov op, va0\n" +
			"mov v0, va1";
	}
	
	private function getFragmentCode():String
	{
		var format:String;
		switch(_texture.format) {
			case Context3DTextureFormat.COMPRESSED:
				format = "dxt1,";
			case Context3DTextureFormat.COMPRESSED_ALPHA:
				format = "dxt5,";
			default:
				format = "";
		}
		return "tex ft0, v0, fs0 <2d, " + format + "linear>	\n" +
			"mov oc, ft0";
	}
	
	public function dispose():Void
	{
		removeBuffers();
	}
	
	public function render():Void
	{
		var context:Context3D = _stage3DProxy.context3D;
		
		if (context != _context) {
			removeBuffers();
			_context = context;
		}
		
		if (context == null)
			return;
		
		if (_vertexBuffer == null)
			initBuffers(context);
		
		context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		context.setProgram(_program3d);
		context.setTextureAt(0, _texture.getTextureForStage3D(_stage3DProxy));
		context.setVertexBufferAt(0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
		context.setVertexBufferAt(1, _vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
		context.drawTriangles(_indexBuffer, 0, 2);
		context.setVertexBufferAt(0, null);
		context.setVertexBufferAt(1, null);
		context.setTextureAt(0, null);
	}
	
	private function initBuffers(context:Context3D):Void
	{
		_vertexBuffer = _stage3DProxy.createVertexBuffer(4, 4);
		_program3d = context.createProgram();
		_indexBuffer = _stage3DProxy.createIndexBuffer(6);
		var v:Vector<UInt> = Vector.ofArray([ 2, 1, 0, 3, 2, 0 ]);
		_indexBuffer.uploadFromVector(v, 0, 6);
		_program3d.upload(new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, getVertexCode()),
			new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, getFragmentCode())
			);
		
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
		
		_vertexBuffer.uploadFromVector(Vector.ofArray([x, y-h, 0, 1,
		x+w, y-h, 1, 1,
		x+w, y, 1, 0,
		x, y, 0, 0
		]), 0, 4);
	}
	
	private function get_texture():Texture2DBase
	{
		return _texture;
	}
	
	private function set_texture(value:Texture2DBase):Texture2DBase
	{
		_texture = value;
		return value;
	}
}