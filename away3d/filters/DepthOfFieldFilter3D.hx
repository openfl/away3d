package away3d.filters;

	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.filters.tasks.Filter3DHDepthOfFFieldTask;
	import away3d.filters.tasks.Filter3DVDepthOfFFieldTask;
	
	import flash.display3D.textures.Texture;
	
	import flash.geom.Vector3D;
	
	class DepthOfFieldFilter3D extends Filter3DBase
	{
		var _focusTarget:ObjectContainer3D;
		var _hDofTask:Filter3DHDepthOfFFieldTask;
		var _vDofTask:Filter3DVDepthOfFFieldTask;
		
		/**
		 * Creates a new DepthOfFieldFilter3D object.
		 * @param blurX The maximum amount of horizontal blur to apply
		 * @param blurY The maximum amount of vertical blur to apply
		 * @param stepSize The distance between samples. Set to -1 to auto-detect with acceptable quality.
		 */
		public function new(maxBlurX:UInt = 3, maxBlurY:UInt = 3, stepSize:Int = -1)
		{
			super();
			_hDofTask = new Filter3DHDepthOfFFieldTask(maxBlurX, stepSize);
			_vDofTask = new Filter3DVDepthOfFFieldTask(maxBlurY, stepSize);
			addTask(_hDofTask);
			addTask(_vDofTask);
		}
		
		/**
		 * The amount of pixels between each sample.
		 */
		public var stepSize(get, set) : Int;
		public function get_stepSize() : Int
		{
			return _hDofTask.stepSize;
		}
		
		public function set_stepSize(value:Int) : Int
		{
			_vDofTask.stepSize = _hDofTask.stepSize = value;
		}
		
		/**
		 * An optional target ObjectContainer3D that will be used to auto-focus on.
		 */
		public var focusTarget(get, set) : ObjectContainer3D;
		public function get_focusTarget() : ObjectContainer3D
		{
			return _focusTarget;
		}
		
		public function set_focusTarget(value:ObjectContainer3D) : ObjectContainer3D
		{
			_focusTarget = value;
		}
		
		/**
		 * The distance from the camera to the point that is in focus.
		 */
		public var focusDistance(get, set) : Float;
		public function get_focusDistance() : Float
		{
			return _hDofTask.focusDistance;
		}
		
		public function set_focusDistance(value:Float) : Float
		{
			_hDofTask.focusDistance = _vDofTask.focusDistance = value;
		}
		
		/**
		 * The distance between the focus point and the maximum amount of blur.
		 */
		public var range(get, set) : Float;
		public function get_range() : Float
		{
			return _hDofTask.range;
		}
		
		public function set_range(value:Float) : Float
		{
			_vDofTask.range = _hDofTask.range = value;
		}
		
		/**
		 * The maximum amount of horizontal blur.
		 */
		public var maxBlurX(get, set) : UInt;
		public function get_maxBlurX() : UInt
		{
			return _hDofTask.maxBlur;
		}
		
		public function set_maxBlurX(value:UInt) : UInt
		{
			_hDofTask.maxBlur = value;
		}
		
		/**
		 * The maximum amount of vertical blur.
		 */
		public var maxBlurY(get, set) : UInt;
		public function get_maxBlurY() : UInt
		{
			return _vDofTask.maxBlur;
		}
		
		public function set_maxBlurY(value:UInt) : UInt
		{
			_vDofTask.maxBlur = value;
		}
		
		override public function update(stage:Stage3DProxy, camera:Camera3D):Void
		{
			if (_focusTarget)
				updateFocus(camera);
		}
		
		private function updateFocus(camera:Camera3D):Void
		{
			var target:Vector3D = camera.inverseSceneTransform.transformVector(_focusTarget.scenePosition);
			_hDofTask.focusDistance = _vDofTask.focusDistance = target.z;
		}
		
		override public function setRenderTargets(mainTarget:Texture, stage3DProxy:Stage3DProxy):Void
		{
			super.setRenderTargets(mainTarget, stage3DProxy);
			_hDofTask.target = _vDofTask.getMainInputTexture(stage3DProxy);
		}
	}

