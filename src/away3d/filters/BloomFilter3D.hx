package away3d.filters;

	import away3d.core.managers.Stage3DProxy;
	import away3d.filters.tasks.Filter3DBloomCompositeTask;
	import away3d.filters.tasks.Filter3DBrightPassTask;
	import away3d.filters.tasks.Filter3DHBlurTask;
	import away3d.filters.tasks.Filter3DVBlurTask;
	
	import flash.display3D.textures.Texture;
	
	class BloomFilter3D extends Filter3DBase
	{
		var _brightPassTask:Filter3DBrightPassTask;
		var _vBlurTask:Filter3DVBlurTask;
		var _hBlurTask:Filter3DHBlurTask;
		var _compositeTask:Filter3DBloomCompositeTask;
		
		public function new(blurX:UInt = 15, blurY:UInt = 15, threshold:Float = .75, exposure:Float = 2, quality:Int = 3)
		{
			super();
			_brightPassTask = new Filter3DBrightPassTask(threshold);
			_hBlurTask = new Filter3DHBlurTask(blurX);
			_vBlurTask = new Filter3DVBlurTask(blurY);
			_compositeTask = new Filter3DBloomCompositeTask(exposure);
			
			if (quality > 4)
				quality = 4;
			else if (quality < 0)
				quality = 0;
			
			_hBlurTask.textureScale = (4 - quality);
			_vBlurTask.textureScale = (4 - quality);
			// composite's main input texture is from vBlur, so needs to be scaled down
			_compositeTask.textureScale = (4 - quality);
			
			addTask(_brightPassTask);
			addTask(_hBlurTask);
			addTask(_vBlurTask);
			addTask(_compositeTask);
		}
		
		override public function setRenderTargets(mainTarget:Texture, stage3DProxy:Stage3DProxy):Void
		{
			_brightPassTask.target = _hBlurTask.getMainInputTexture(stage3DProxy);
			_hBlurTask.target = _vBlurTask.getMainInputTexture(stage3DProxy);
			_vBlurTask.target = _compositeTask.getMainInputTexture(stage3DProxy);
			// use bright pass's input as composite's input
			_compositeTask.overlayTexture = _brightPassTask.getMainInputTexture(stage3DProxy);
			
			super.setRenderTargets(mainTarget, stage3DProxy);
		}
		
		public var exposure(get, set) : Float;
		
		public function get_exposure() : Float
		{
			return _compositeTask.exposure;
		}
		
		public function set_exposure(value:Float) : Float
		{
			_compositeTask.exposure = value;
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
		
		public var threshold(get, set) : Float;
		
		public function get_threshold() : Float
		{
			return _brightPassTask.threshold;
		}
		
		public function set_threshold(value:Float) : Float
		{
			_brightPassTask.threshold = value;
		}
	}

