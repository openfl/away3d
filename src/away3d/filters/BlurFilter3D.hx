package away3d.filters;

	import away3d.core.managers.Stage3DProxy;
	import away3d.filters.tasks.Filter3DHBlurTask;
	import away3d.filters.tasks.Filter3DVBlurTask;
	
	import flash.display3D.textures.Texture;
	
	class BlurFilter3D extends Filter3DBase
	{
		var _hBlurTask:Filter3DHBlurTask;
		var _vBlurTask:Filter3DVBlurTask;
		
		/**
		 * Creates a new BlurFilter3D object
		 * @param blurX The amount of horizontal blur to apply
		 * @param blurY The amount of vertical blur to apply
		 * @param stepSize The distance between samples. Set to -1 to autodetect with acceptable quality.
		 */
		public function new(blurX:UInt = 3, blurY:UInt = 3, stepSize:Int = -1)
		{
			super();
			addTask(_hBlurTask = new Filter3DHBlurTask(blurX, stepSize));
			addTask(_vBlurTask = new Filter3DVBlurTask(blurY, stepSize));
		}
		
		public var blurX(get, set) : UInt;
		
		public function get_blurX() : UInt
		{
			return _hBlurTask.amount;
		}
		
		public function set_blurX(value:UInt) : UInt
		{
			_hBlurTask.amount = value;
		}
		
		public var blurY(get, set) : UInt;
		
		public function get_blurY() : UInt
		{
			return _vBlurTask.amount;
		}
		
		public function set_blurY(value:UInt) : UInt
		{
			_vBlurTask.amount = value;
		}
		
		/**
		 * The distance between two blur samples. Set to -1 to autodetect with acceptable quality (default value).
		 * Higher values provide better performance at the cost of reduces quality.
		 */
		public var stepSize(get, set) : Int;
		public function get_stepSize() : Int
		{
			return _hBlurTask.stepSize;
		}
		
		public function set_stepSize(value:Int) : Int
		{
			_hBlurTask.stepSize = value;
			_vBlurTask.stepSize = value;
		}
		
		override public function setRenderTargets(mainTarget:Texture, stage3DProxy:Stage3DProxy):Void
		{
			_hBlurTask.target = _vBlurTask.getMainInputTexture(stage3DProxy);
			super.setRenderTargets(mainTarget, stage3DProxy);
		}
	}

