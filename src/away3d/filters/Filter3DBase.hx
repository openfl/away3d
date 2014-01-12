package away3d.filters;

	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.filters.tasks.Filter3DTaskBase;
	
	import flash.display3D.textures.Texture;
	
	class Filter3DBase
	{
		var _tasks:Array<Filter3DTaskBase>;
		var _requireDepthRender:Bool;
		var _textureWidth:Int;
		var _textureHeight:Int;
		
		public function new()
		{
			_tasks = new Array<Filter3DTaskBase>();
		}
		
		public var requireDepthRender(get, null) : Bool;
		
		public function get_requireDepthRender() : Bool
		{
			return _requireDepthRender;
		}
		
		private function addTask(filter:Filter3DTaskBase):Void
		{
			_tasks.push(filter);
			if (!_requireDepthRender) _requireDepthRender = filter.requireDepthRender;
		}
		
		public var tasks(get, null) : Array<Filter3DTaskBase>;
		
		public function get_tasks() : Array<Filter3DTaskBase>
		{
			return _tasks;
		}
		
		public function getMainInputTexture(stage3DProxy:Stage3DProxy):Texture
		{
			return _tasks[0].getMainInputTexture(stage3DProxy);
		}
		
		public var textureWidth(get, set) : Int;
		
		public function get_textureWidth() : Int
		{
			return _textureWidth;
		}
		
		public function set_textureWidth(value:Int) : Int
		{
			_textureWidth = value;
			
			// For loop conversion - 						for (var i:Int = 0; i < _tasks.length; ++i)
			
			var i:Int;
			
			for (i in 0..._tasks.length)
				_tasks[i].textureWidth = value;
			return value;
		}
		
		public var textureHeight(get, set) : Int;
		
		public function get_textureHeight() : Int
		{
			return _textureHeight;
		}
		
		public function set_textureHeight(value:Int) : Int
		{
			_textureHeight = value;
			// For loop conversion - 			for (var i:Int = 0; i < _tasks.length; ++i)
			var i:Int;
			for (i in 0..._tasks.length)
				_tasks[i].textureHeight = value;
			return value;
		}
		
		// link up the filters correctly with the next filter
		public function setRenderTargets(mainTarget:Texture, stage3DProxy:Stage3DProxy):Void
		{
			_tasks[_tasks.length - 1].target = mainTarget;
		}
		
		public function dispose():Void
		{
			// For loop conversion - 			for (var i:Int = 0; i < _tasks.length; ++i)
			var i:Int;
			for (i in 0..._tasks.length)
				_tasks[i].dispose();
		}
		
		public function update(stage:Stage3DProxy, camera:Camera3D):Void
		{
		
		}
	}

