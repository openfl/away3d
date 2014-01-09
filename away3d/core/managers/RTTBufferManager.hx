package away3d.core.managers;

	import away3d.tools.utils.TextureUtils;
	
	import flash.display3D.Context3D;
	
	import flash.display3D.IndexBuffer3D;
	
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	
	import haxe.ds.ObjectMap;

	import flash.errors.Error;

	import flash.Vector;
	
	class RTTBufferManager extends EventDispatcher
	{
		public static var _instances:ObjectMap<Stage3DProxy, RTTBufferManager>;
		
		var _renderToTextureVertexBuffer:VertexBuffer3D;
		var _renderToScreenVertexBuffer:VertexBuffer3D;
		
		var _indexBuffer:IndexBuffer3D;
		var _stage3DProxy:Stage3DProxy;
		var _viewWidth:Int;
		var _viewHeight:Int;
		var _textureWidth:Int;
		var _textureHeight:Int;
		var _renderToTextureRect:Rectangle;
		var _buffersInvalid:Bool;
		
		var _textureRatioX:Float;
		var _textureRatioY:Float;
		
		public function new(se:SingletonEnforcer, stage3DProxy:Stage3DProxy)
		{
			super();
			_viewWidth = -1;
			_viewHeight = -1;
			_textureWidth = -1;
			_textureHeight = -1;
			
			_buffersInvalid = true;

			if (se==null)
				throw new Error("No cheating the multiton!");
			
			_renderToTextureRect = new Rectangle();
			
			_stage3DProxy = stage3DProxy;
		}
		
		public static function getInstance(stage3DProxy:Stage3DProxy):RTTBufferManager
		{
			if (stage3DProxy==null)
				throw new Error("stage3DProxy key cannot be null!");
			if (_instances==null) _instances = new ObjectMap<Stage3DProxy, RTTBufferManager>();
			if (_instances.get(stage3DProxy)==null) _instances.set(stage3DProxy,  new RTTBufferManager(new SingletonEnforcer(), stage3DProxy));
			return _instances.get(stage3DProxy);
		}
		
		public var textureRatioX(get, null) : Float;
		
		public function get_textureRatioX() : Float
		{
			if (_buffersInvalid)
				updateRTTBuffers();
			return _textureRatioX;
		}
		
		public var textureRatioY(get, null) : Float;
		
		public function get_textureRatioY() : Float
		{
			if (_buffersInvalid)
				updateRTTBuffers();
			return _textureRatioY;
		}
		
		public var viewWidth(get, set) : Int;
		
		public function get_viewWidth() : Int
		{
			return _viewWidth;
		}
		
		public function set_viewWidth(value:Int) : Int
		{
			if (value == _viewWidth)
				return value;
			_viewWidth = value;
			
			_buffersInvalid = true;
			
			_textureWidth = TextureUtils.getBestPowerOf2(Std.int(_viewWidth));
			
			if (_textureWidth > _viewWidth) {
				_renderToTextureRect.x = Std.int((_textureWidth - _viewWidth)*.5);
				_renderToTextureRect.width = _viewWidth;
			} else {
				_renderToTextureRect.x = 0;
				_renderToTextureRect.width = _textureWidth;
			}
			
			dispatchEvent(new Event(Event.RESIZE));
			return value;
		}
		
		public var viewHeight(get, set) : Int;
		
		public function get_viewHeight() : Int
		{
			return _viewHeight;
		}
		
		public function set_viewHeight(value:Int) : Int
		{
			if (value == _viewHeight)
				return value;
			_viewHeight = value;
			
			_buffersInvalid = true;
			
			_textureHeight = TextureUtils.getBestPowerOf2(Std.int(_viewHeight));
			
			if (_textureHeight > _viewHeight) {
				_renderToTextureRect.y = Std.int((_textureHeight - _viewHeight)*.5);
				_renderToTextureRect.height = _viewHeight;
			} else {
				_renderToTextureRect.y = 0;
				_renderToTextureRect.height = _textureHeight;
			}
			
			dispatchEvent(new Event(Event.RESIZE));
			return value;
		}
		
		public var renderToTextureVertexBuffer(get, null) : VertexBuffer3D;
		
		public function get_renderToTextureVertexBuffer() : VertexBuffer3D
		{
			if (_buffersInvalid)
				updateRTTBuffers();
			return _renderToTextureVertexBuffer;
		}
		
		public var renderToScreenVertexBuffer(get, null) : VertexBuffer3D;
		
		public function get_renderToScreenVertexBuffer() : VertexBuffer3D
		{
			if (_buffersInvalid)
				updateRTTBuffers();
			return _renderToScreenVertexBuffer;
		}
		
		public var indexBuffer(get, null) : IndexBuffer3D;
		
		public function get_indexBuffer() : IndexBuffer3D
		{
			return _indexBuffer;
		}
		
		public var renderToTextureRect(get, null) : Rectangle;
		
		public function get_renderToTextureRect() : Rectangle
		{
			if (_buffersInvalid)
				updateRTTBuffers();
			return _renderToTextureRect;
		}
		
		public var textureWidth(get, null) : Int;
		
		public function get_textureWidth() : Int
		{
			return _textureWidth;
		}
		
		public var textureHeight(get, null) : Int;
		
		public function get_textureHeight() : Int
		{
			return _textureHeight;
		}
		
		public function dispose():Void
		{
			//delete _instances[_stage3DProxy];
			if (_indexBuffer!=null) {
				_indexBuffer.dispose();
				_renderToScreenVertexBuffer.dispose();
				_renderToTextureVertexBuffer.dispose();
				_renderToScreenVertexBuffer = null;
				_renderToTextureVertexBuffer = null;
				_indexBuffer = null;
			}
		}
		
		// todo: place all this in a separate model, since it's used all over the place
		// maybe it even has a place in the core (together with screenRect etc)?
		// needs to be stored per view of course
		private function updateRTTBuffers():Void
		{
			var context:Context3D = _stage3DProxy.context3D;
			var textureVerts:Array<Float>;
			var screenVerts:Array<Float>;
			var x:Float, y:Float;
			
			if (_renderToTextureVertexBuffer==null) _renderToTextureVertexBuffer = context.createVertexBuffer(4, 5);
			if (_renderToScreenVertexBuffer==null) _renderToScreenVertexBuffer = context.createVertexBuffer(4, 5);
			
			if (_indexBuffer==null) {
				_indexBuffer = context.createIndexBuffer(6);
				_indexBuffer.uploadFromVector(Vector.ofArray([2, 1, 0, 3, 2, 0]), 0, 6);
			}
			
			_textureRatioX = x = Math.min(_viewWidth/_textureWidth, 1);
			_textureRatioY = y = Math.min(_viewHeight/_textureHeight, 1);
			
			var u1:Float = (1 - x)*.5;
			var u2:Float = (x + 1)*.5;
			var v1:Float = (y + 1)*.5;
			var v2:Float = (1 - y)*.5;
			
			// last element contains indices for data per vertex that can be passed to the vertex shader if necessary (ie: frustum corners for deferred rendering)
			textureVerts = [    -x, -y, u1, v1, 0,
				x, -y, u2, v1, 1,
				x, y, u2, v2, 2,
				-x, y, u1, v2, 3 ];
			
			screenVerts = [        -1, -1, u1, v1, 0,
				1, -1, u2, v1, 1,
				1, 1, u2, v2, 2,
				-1, 1, u1, v2, 3 ];
			
			_renderToTextureVertexBuffer.uploadFromVector(Vector.ofArray(textureVerts), 0, 4);
			_renderToScreenVertexBuffer.uploadFromVector(Vector.ofArray(screenVerts), 0, 4);
			
			_buffersInvalid = false;
		}
	}
class SingletonEnforcer
{
	public function new() {}
}
