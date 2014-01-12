package away3d.filters;

	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.filters.tasks.Filter3DVDepthOfFFieldTask;
	
	import flash.geom.Vector3D;
	
	class VDepthOfFieldFilter3D extends Filter3DBase
	{
		var _dofTask:Filter3DVDepthOfFFieldTask;
		var _focusTarget:ObjectContainer3D;
		
		/**
		 * Creates a new VDepthOfFieldFilter3D object
		 * @param amount The amount of blur to apply in pixels
		 * @param stepSize The distance between samples. Set to -1 to autodetect with acceptable quality.
		 */
		public function new(maxBlur:UInt = 3, stepSize:Int = -1)
		{
			super();
			_dofTask = new Filter3DVDepthOfFFieldTask(maxBlur, stepSize);
			addTask(_dofTask);
		}
		
		public var focusTarget(get, set) : ObjectContainer3D;
		
		public function get_focusTarget() : ObjectContainer3D
		{
			return _focusTarget;
		}
		
		public function set_focusTarget(value:ObjectContainer3D) : ObjectContainer3D
		{
			_focusTarget = value;
		}
		
		public var focusDistance(get, set) : Float;
		
		public function get_focusDistance() : Float
		{
			return _dofTask.focusDistance;
		}
		
		public function set_focusDistance(value:Float) : Float
		{
			_dofTask.focusDistance = value;
		}
		
		public var range(get, set) : Float;
		
		public function get_range() : Float
		{
			return _dofTask.range;
		}
		
		public function set_range(value:Float) : Float
		{
			_dofTask.range = value;
		}
		
		public var maxBlur(get, set) : UInt;
		
		public function get_maxBlur() : UInt
		{
			return _dofTask.maxBlur;
		}
		
		public function set_maxBlur(value:UInt) : UInt
		{
			_dofTask.maxBlur = value;
		}
		
		override public function update(stage:Stage3DProxy, camera:Camera3D):Void
		{
			if (_focusTarget)
				updateFocus(camera);
		}
		
		private function updateFocus(camera:Camera3D):Void
		{
			var target:Vector3D = camera.inverseSceneTransform.transformVector(_focusTarget.scenePosition);
			_dofTask.focusDistance = target.z;
		}
	}

