package away3d.core.managers;

import away3d.events.Stage3DEvent;
import away3d.tools.utils.TextureUtils;

import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.geom.Rectangle;
import openfl.Vector;

class RTTBufferManager extends EventDispatcher
{
	public var textureRatioX(get, never):Float;
	public var textureRatioY(get, never):Float;
	public var viewWidth(get, set):Int;
	public var viewHeight(get, set):Int;
	public var renderToTextureVertexBuffer(get, never):VertexBuffer3D;
	public var renderToScreenVertexBuffer(get, never):VertexBuffer3D;
	public var indexBuffer(get, never):IndexBuffer3D;
	public var renderToTextureRect(get, never):Rectangle;
	public var textureWidth(get, never):Int;
	public var textureHeight(get, never):Int;
	
	private static var _instances:Map<Stage3DProxy, RTTBufferManager>;
	
	private var _renderToTextureVertexBuffer:VertexBuffer3D;
	private var _renderToScreenVertexBuffer:VertexBuffer3D;
	
	private var _indexBuffer:IndexBuffer3D;
	private var _stage3DProxy:Stage3DProxy;
	private var _viewWidth:Int = -1;
	private var _viewHeight:Int = -1;
	private var _textureWidth:Int = -1;
	private var _textureHeight:Int = -1;
	private var _renderToTextureRect:Rectangle;
	private var _buffersInvalid:Bool = true;
	
	private var _textureRatioX:Float;
	private var _textureRatioY:Float;
	
	private function new(stage3DProxy:Stage3DProxy)
	{
		_renderToTextureRect = new Rectangle();
		
		_stage3DProxy = stage3DProxy;
		_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContextRecreated);
		super();
	}

	public static function getInstance(stage3DProxy:Stage3DProxy):RTTBufferManager
	{
		if (stage3DProxy == null)
			throw new Error("stage3DProxy key cannot be null!");
		if (_instances == null)
			_instances = new Map<Stage3DProxy, RTTBufferManager>();
		var rttb:RTTBufferManager = _instances[stage3DProxy];
		if (rttb == null) {
			rttb = new RTTBufferManager(stage3DProxy);
			_instances[stage3DProxy] = rttb;
		}
		return rttb;
	}
	
	private function get_textureRatioX():Float
	{
		if (_buffersInvalid)
			updateRTTBuffers();
		return _textureRatioX;
	}
	
	private function get_textureRatioY():Float
	{
		if (_buffersInvalid)
			updateRTTBuffers();
		return _textureRatioY;
	}
	
	private function get_viewWidth():Int
	{
		return _viewWidth;
	}
	
	private function set_viewWidth(value:Int):Int
	{
		if (value == _viewWidth)
			return value;
		_viewWidth = value;
		
		_buffersInvalid = true;
		
		_textureWidth = TextureUtils.getBestPowerOf2(_viewWidth);
		
		if (_textureWidth > _viewWidth) {
			_renderToTextureRect.x = Std.int((_textureWidth - _viewWidth) * .5);
			_renderToTextureRect.width = _viewWidth;
		} else {
			_renderToTextureRect.x = 0;
			_renderToTextureRect.width = _textureWidth;
		}
		
		dispatchEvent(new Event(Event.RESIZE));
		return value;
	}
	
	private function get_viewHeight():Int
	{
		return _viewHeight;
	}
	
	private function set_viewHeight(value:Int):Int
	{
		if (value == _viewHeight)
			return value;
		_viewHeight = value;
		
		_buffersInvalid = true;
		
		_textureHeight = TextureUtils.getBestPowerOf2(_viewHeight);
		
		if (_textureHeight > _viewHeight) {
			_renderToTextureRect.y = Std.int((_textureHeight - _viewHeight) * .5);
			_renderToTextureRect.height = _viewHeight;
		} else {
			_renderToTextureRect.y = 0;
			_renderToTextureRect.height = _textureHeight;
		}
		
		dispatchEvent(new Event(Event.RESIZE));
		return value;
	}
	
	private function get_renderToTextureVertexBuffer():VertexBuffer3D
	{
		if (_buffersInvalid)
			updateRTTBuffers();
		
		return _renderToTextureVertexBuffer;
	}
	
	private function get_renderToScreenVertexBuffer():VertexBuffer3D
	{
		if (_buffersInvalid)
			updateRTTBuffers();
		
		return _renderToScreenVertexBuffer;
	}
	
	private function get_indexBuffer():IndexBuffer3D
	{
		return _indexBuffer;
	}
	
	private function get_renderToTextureRect():Rectangle
	{
		if (_buffersInvalid)
			updateRTTBuffers();
		
		return _renderToTextureRect;
	}
	
	private function get_textureWidth():Int
	{
		return _textureWidth;
	}
	
	private function get_textureHeight():Int
	{
		return _textureHeight;
	}
	
	public function dispose():Void
	{
		_instances.remove(_stage3DProxy);
		_stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContextRecreated);
		if (_indexBuffer != null) {
			Stage3DProxy.disposeIndexBuffer(_indexBuffer);
			Stage3DProxy.disposeVertexBuffer(_renderToScreenVertexBuffer);
			Stage3DProxy.disposeVertexBuffer(_renderToTextureVertexBuffer);
			_renderToScreenVertexBuffer = null;
			_renderToTextureVertexBuffer = null;
			_indexBuffer = null;
		}
	}


	private function onContextRecreated(event:Stage3DEvent):Void {
		_indexBuffer = null;
		_renderToTextureVertexBuffer = null;
		_renderToScreenVertexBuffer = null;
		updateRTTBuffers();
	}
	
	// todo: place all this in a separate model, since it's used all over the place
	// maybe it even has a place in the core (together with screenRect etc)?
	// needs to be stored per view of course
	private function updateRTTBuffers():Void
	{
		var context:Context3D = _stage3DProxy.context3D;
		var textureVerts:Vector<Float>;
		var screenVerts:Vector<Float>;
		var x:Float, y:Float;
		
		if (_renderToTextureVertexBuffer == null)
			_renderToTextureVertexBuffer = _stage3DProxy.createVertexBuffer(4, 5);
		
		if (_renderToScreenVertexBuffer == null)
			_renderToScreenVertexBuffer = _stage3DProxy.createVertexBuffer(4, 5);
		
		if (_indexBuffer == null) {
			_indexBuffer = _stage3DProxy.createIndexBuffer(6);
			var v:Vector<UInt> = Vector.ofArray([2, 1, 0, 3, 2, 0]);
			_indexBuffer.uploadFromVector(v, 0, 6);
		}
		
		_textureRatioX = x = Math.min(_viewWidth/_textureWidth, 1);
		_textureRatioY = y = Math.min(_viewHeight/_textureHeight, 1);
		
		var u1:Float = (1 - x)*.5;
		var u2:Float = (x + 1)*.5;
		var v1:Float = (y + 1)*.5;
		var v2:Float = (1 - y)*.5;
		
		// last element contains indices for data per vertex that can be passed to the vertex shader if necessary (ie: frustum corners for deferred rendering)
		textureVerts = Vector.ofArray([    -x, -y, u1, v1, 0,
			x, -y, u2, v1, 1,
			x, y, u2, v2, 2,
			-x, y, u1, v2, 3 ]);
		
		screenVerts = Vector.ofArray([        -1, -1, u1, v1, 0,
			1, -1, u2, v1, 1,
			1, 1, u2, v2, 2,
			-1, 1, u1, v2, 3 ]);
		
		_renderToTextureVertexBuffer.uploadFromVector(textureVerts, 0, 4);
		_renderToScreenVertexBuffer.uploadFromVector(screenVerts, 0, 4);
		
		_buffersInvalid = false;
	}
}