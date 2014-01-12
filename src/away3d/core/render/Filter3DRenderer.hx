/**
 */
package away3d.core.render;

	import away3d.cameras.*;
	import away3d.core.managers.*;
	import away3d.filters.*;
	import away3d.filters.tasks.*;
	
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.events.*;
	
	class Filter3DRenderer
	{
		var _filters:Array<Dynamic>;
		var _tasks:Array<Filter3DTaskBase>;
		var _filterTasksInvalid:Bool;
		var _mainInputTexture:Texture;
		
		var _requireDepthRender:Bool;
		
		var _rttManager:RTTBufferManager;
		var _stage3DProxy:Stage3DProxy;
		var _filterSizesInvalid:Bool = true;
		
		public function new(stage3DProxy:Stage3DProxy)
		{
			_stage3DProxy = stage3DProxy;
			_rttManager = RTTBufferManager.getInstance(stage3DProxy);
			_rttManager.addEventListener(Event.RESIZE, onRTTResize);
		}
		
		private function onRTTResize(event:Event):Void
		{
			_filterSizesInvalid = true;
		}
		
		public var requireDepthRender(get, null) : Bool;
		
		public function get_requireDepthRender() : Bool
		{
			return _requireDepthRender;
		}
		
		public function getMainInputTexture(stage3DProxy:Stage3DProxy):Texture
		{
			if (_filterTasksInvalid)
				updateFilterTasks(stage3DProxy);
			return _mainInputTexture;
		}
		
		public var filters(get, set) : Array<Dynamic>;
		
		public function get_filters() : Array<Dynamic>
		{
			return _filters;
		}
		
		public function set_filters(value:Array<Dynamic>) : Array<Dynamic>
		{
			_filters = value;
			_filterTasksInvalid = true;
			
			_requireDepthRender = false;
			if (_filters==null)
				return value;
			
			// For loop conversion - 						for (var i:Int = 0; i < _filters.length; ++i)
			
			var i:Int;
			
			for (i in 0..._filters.length)
				if (!_requireDepthRender) _requireDepthRender = cast(_filters[i].requireDepthRender, Bool);
			
			_filterSizesInvalid = true;
			return value;
		}
		
		private function updateFilterTasks(stage3DProxy:Stage3DProxy):Void
		{
			var len:UInt;
			
			if (_filterSizesInvalid)
				updateFilterSizes();
			
			if (_filters==null) {
				_tasks = null;
				return;
			}
			
			_tasks = new Array<Filter3DTaskBase>();
			
			len = _filters.length - 1;
			
			var filter:Filter3DBase;
			
			// For loop conversion - 						for (var i:UInt = 0; i <= len; ++i)
			
			var i:UInt = 0;
			
			for (i in 0...len) {
				// make sure all internal tasks are linked together
				filter = _filters[i];
				filter.setRenderTargets(i == len ? null : cast(_filters[i + 1], Filter3DBase).getMainInputTexture(stage3DProxy), stage3DProxy);
				_tasks = _tasks.concat(filter.tasks);
			}
			
			_mainInputTexture = _filters[0].getMainInputTexture(stage3DProxy);
		}
		
		public function render(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:Texture):Void
		{
			var len:Int;
			var i:Int;
			var task:Filter3DTaskBase;
			var context:Context3D = stage3DProxy.context3D;
			var indexBuffer:IndexBuffer3D = _rttManager.indexBuffer;
			var vertexBuffer:VertexBuffer3D = _rttManager.renderToTextureVertexBuffer;
			
			if (_filters==null)
				return;
			if (_filterSizesInvalid)
				updateFilterSizes();
			if (_filterTasksInvalid)
				updateFilterTasks(stage3DProxy);
			
			len = _filters.length;
			// For loop conversion - 			for (i = 0; i < len; ++i)
			for (i in 0...len)
				_filters[i].update(stage3DProxy, camera3D);
			
			len = _tasks.length;
			
			if (len > 1) {
				context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
				context.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
			}
			
			// For loop conversion - 						for (i = 0; i < len; ++i)
			
			for (i in 0...len) {
				task = _tasks[i];
				stage3DProxy.setRenderTarget(task.target);
				
				if (task.target==null) {
					stage3DProxy.scissorRect = null;
					vertexBuffer = _rttManager.renderToScreenVertexBuffer;
					context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
					context.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
				}
				context.setTextureAt(0, task.getMainInputTexture(stage3DProxy));
				context.setProgram(task.getProgram3D(stage3DProxy));
				context.clear(0.0, 0.0, 0.0, 0.0);
				task.activate(stage3DProxy, camera3D, depthTexture);
				context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
				context.drawTriangles(indexBuffer, 0, 2);
				task.deactivate(stage3DProxy);
			}
			
			context.setTextureAt(0, null);
			context.setVertexBufferAt(0, null);
			context.setVertexBufferAt(1, null);
		}
		
		private function updateFilterSizes():Void
		{
			// For loop conversion - 			for (var i:Int = 0; i < _filters.length; ++i)
			var i:Int;
			for (i in 0..._filters.length) {
				_filters[i].textureWidth = _rttManager.textureWidth;
				_filters[i].textureHeight = _rttManager.textureHeight;
			}
			
			_filterSizesInvalid = true;
		}
		
		public function dispose():Void
		{
			_rttManager.removeEventListener(Event.RESIZE, onRTTResize);
			_rttManager = null;
			_stage3DProxy = null;
		}
	}

