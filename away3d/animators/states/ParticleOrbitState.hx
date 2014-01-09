package away3d.animators.states;

	import away3d.geom.Matrix3D;
	
	import away3d.animators.data.ParticlePropertiesMode;
	
	import flash.geom.Vector3D;
	
	//import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleOrbitNode;
	import away3d.animators.ParticleAnimator;
	
	import flash.display3D.Context3DVertexBufferFormat;
	
	//use namespace arcane;
	
	/**
	 * ...
	 */
	class ParticleOrbitState extends ParticleStateBase
	{
		var _particleOrbitNode:ParticleOrbitNode;
		var _usesEulers:Bool;
		var _usesCycle:Bool;
		var _usesPhase:Bool;
		var _radius:Float;
		var _cycleDuration:Float;
		var _cyclePhase:Float;
		var _eulers:Vector3D;
		var _orbitData:Vector3D;
		var _eulersMatrix:Matrix3D;
		
		/**
		 * Defines the radius of the orbit when in global mode. Defaults to 100.
		 */
		public var radius(get, set) : Float;
		public function get_radius() : Float
		{
			return _radius;
		}
		
		public function set_radius(value:Float) : Float
		{
			_radius = value;
			
			updateOrbitData();
		}
		
		/**
		 * Defines the duration of the orbit in seconds, used as a period independent of particle duration when in global mode. Defaults to 1.
		 */
		public var cycleDuration(get, set) : Float;
		public function get_cycleDuration() : Float
		{
			return _cycleDuration;
		}
		
		public function set_cycleDuration(value:Float) : Float
		{
			_cycleDuration = value;
			
			updateOrbitData();
		}
		
		/**
		 * Defines the phase of the orbit in degrees, used as the starting offset of the cycle when in global mode. Defaults to 0.
		 */
		public var cyclePhase(get, set) : Float;
		public function get_cyclePhase() : Float
		{
			return _cyclePhase;
		}
		
		public function set_cyclePhase(value:Float) : Float
		{
			_cyclePhase = value;
			
			updateOrbitData();
		}
		
		/**
		 * Defines the euler rotation in degrees, applied to the orientation of the orbit when in global mode.
		 */
		public var eulers(get, set) : Vector3D;
		public function get_eulers() : Vector3D
		{
			return _eulers;
		}
		
		public function set_eulers(value:Vector3D) : Vector3D
		{
			_eulers = value;
			
			updateOrbitData();
		
		}
		
		public function new(animator:ParticleAnimator, particleOrbitNode:ParticleOrbitNode)
		{
			super(animator, particleOrbitNode);
			
			_particleOrbitNode = particleOrbitNode;
			_usesEulers = _particleOrbitNode._usesEulers;
			_usesCycle = _particleOrbitNode._usesCycle;
			_usesPhase = _particleOrbitNode._usesPhase;
			_eulers = _particleOrbitNode._eulers;
			_radius = _particleOrbitNode._radius;
			_cycleDuration = _particleOrbitNode._cycleDuration;
			_cyclePhase = _particleOrbitNode._cyclePhase;
			updateOrbitData();
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
		{
			var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleOrbitNode.ORBIT_INDEX);
			
			if (_particleOrbitNode.mode == ParticlePropertiesMode.LOCAL_STATIC) {
				if (_usesPhase)
					animationSubGeometry.activateVertexBuffer(index, _particleOrbitNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
				else
					animationSubGeometry.activateVertexBuffer(index, _particleOrbitNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			} else
				animationRegisterCache.setVertexConst(index, _orbitData.x, _orbitData.y, _orbitData.z, _orbitData.w);
			
			if (_usesEulers)
				animationRegisterCache.setVertexConstFromMatrix(animationRegisterCache.getRegisterIndex(_animationNode, ParticleOrbitNode.EULERS_INDEX), _eulersMatrix);
		}
		
		private function updateOrbitData():Void
		{
			if (_usesEulers) {
				_eulersMatrix = new Matrix3D();
				_eulersMatrix.appendRotation(_eulers.x, Vector3D.X_AXIS);
				_eulersMatrix.appendRotation(_eulers.y, Vector3D.Y_AXIS);
				_eulersMatrix.appendRotation(_eulers.z, Vector3D.Z_AXIS);
			}
			if (_particleOrbitNode.mode == ParticlePropertiesMode.GLOBAL) {
				_orbitData = new Vector3D(_radius, 0, _radius*Math.PI*2, _cyclePhase*Math.PI/180);
				if (_usesCycle) {
					if (_cycleDuration <= 0)
						throw(new Error("the cycle duration must be greater than zero"));
					_orbitData.y = Math.PI*2/_cycleDuration;
				} else
					_orbitData.y = Math.PI*2;
			}
		}
	}

