package away3d.animators.states;

	import away3d.animators.data.ParticlePropertiesMode;
	
	import flash.geom.Vector3D;
	import flash.display3D.Context3DVertexBufferFormat;
	
	//import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleScaleNode;
	import away3d.animators.ParticleAnimator;
	
	//use namespace arcane;
	
	/**
	 * ...
	 */
	class ParticleScaleState extends ParticleStateBase
	{
		var _particleScaleNode:ParticleScaleNode;
		var _usesCycle:Bool;
		var _usesPhase:Bool;
		var _minScale:Float;
		var _maxScale:Float;
		var _cycleDuration:Float;
		var _cyclePhase:Float;
		var _scaleData:Vector3D;
		
		/**
		 * Defines the end scale of the state, when in global mode. Defaults to 1.
		 */
		public var minScale(get, set) : Float;
		public function get_minScale() : Float
		{
			return _minScale;
		}
		
		public function set_minScale(value:Float) : Float
		{
			_minScale = value;
			
			updateScaleData();
		}
		
		/**
		 * Defines the end scale of the state, when in global mode. Defaults to 1.
		 */
		public var maxScale(get, set) : Float;
		public function get_maxScale() : Float
		{
			return _maxScale;
		}
		
		public function set_maxScale(value:Float) : Float
		{
			_maxScale = value;
			
			updateScaleData();
		}
		
		/**
		 * Defines the duration of the animation in seconds, used as a period independent of particle duration when in global mode. Defaults to 1.
		 */
		public var cycleDuration(get, set) : Float;
		public function get_cycleDuration() : Float
		{
			return _cycleDuration;
		}
		
		public function set_cycleDuration(value:Float) : Float
		{
			_cycleDuration = value;
			
			updateScaleData();
		}
		
		/**
		 * Defines the phase of the cycle in degrees, used as the starting offset of the cycle when in global mode. Defaults to 0.
		 */
		public var cyclePhase(get, set) : Float;
		public function get_cyclePhase() : Float
		{
			return _cyclePhase;
		}
		
		public function set_cyclePhase(value:Float) : Float
		{
			_cyclePhase = value;
			
			updateScaleData();
		}
		
		public function new(animator:ParticleAnimator, particleScaleNode:ParticleScaleNode)
		{
			super(animator, particleScaleNode);
			
			_particleScaleNode = particleScaleNode;
			_usesCycle = _particleScaleNode._usesCycle;
			_usesPhase = _particleScaleNode._usesPhase;
			_minScale = _particleScaleNode._minScale;
			_maxScale = _particleScaleNode._maxScale;
			_cycleDuration = _particleScaleNode._cycleDuration;
			_cyclePhase = _particleScaleNode._cyclePhase;
			
			updateScaleData();
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
		{
			var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleScaleNode.SCALE_INDEX);
			
			if (_particleScaleNode.mode == ParticlePropertiesMode.LOCAL_STATIC) {
				if (_usesCycle) {
					if (_usesPhase)
						animationSubGeometry.activateVertexBuffer(index, _particleScaleNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
					else
						animationSubGeometry.activateVertexBuffer(index, _particleScaleNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
				} else
					animationSubGeometry.activateVertexBuffer(index, _particleScaleNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_2);
			} else
				animationRegisterCache.setVertexConst(index, _scaleData.x, _scaleData.y, _scaleData.z, _scaleData.w);
		}
		
		private function updateScaleData():Void
		{
			if (_particleScaleNode.mode == ParticlePropertiesMode.GLOBAL) {
				if (_usesCycle) {
					if (_cycleDuration <= 0)
						throw(new Error("the cycle duration must be greater than zero"));
					_scaleData = new Vector3D((_minScale + _maxScale)/2, Math.abs(_minScale - _maxScale)/2, Math.PI*2/_cycleDuration, _cyclePhase*Math.PI/180);
				} else
					_scaleData = new Vector3D(_minScale, _maxScale - _minScale, 0, 0);
			}
		}
	}

