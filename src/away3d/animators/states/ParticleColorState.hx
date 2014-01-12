package away3d.animators.states;

	import flash.geom.ColorTransform;
	
	import away3d.animators.data.ParticlePropertiesMode;
	
	import flash.geom.Vector3D;
	import flash.display3D.Context3DVertexBufferFormat;
	
	//import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.animators.nodes.ParticleColorNode;
	import away3d.animators.ParticleAnimator;
	
	//use namespace arcane;
	
	/**
	 * ...
	 * @author ...
	 */
	class ParticleColorState extends ParticleStateBase
	{
		var _particleColorNode:ParticleColorNode;
		var _usesMultiplier:Bool;
		var _usesOffset:Bool;
		var _usesCycle:Bool;
		var _usesPhase:Bool;
		var _startColor:ColorTransform;
		var _endColor:ColorTransform;
		var _cycleDuration:Float;
		var _cyclePhase:Float;
		var _cycleData:Vector3D;
		var _startMultiplierData:Vector3D;
		var _deltaMultiplierData:Vector3D;
		var _startOffsetData:Vector3D;
		var _deltaOffsetData:Vector3D;
		
		/**
		 * Defines the start color transform of the state, when in global mode.
		 */
		public var startColor(get, set) : ColorTransform;
		public function get_startColor() : ColorTransform
		{
			return _startColor;
		}
		
		public function set_startColor(value:ColorTransform) : ColorTransform
		{
			_startColor = value;
			
			updateColorData();
		}
		
		/**
		 * Defines the end color transform of the state, when in global mode.
		 */
		public var endColor(get, set) : ColorTransform;
		public function get_endColor() : ColorTransform
		{
			return _endColor;
		}
		
		public function set_endColor(value:ColorTransform) : ColorTransform
		{
			_endColor = value;
			
			updateColorData();
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
			
			updateColorData();
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
			
			updateColorData();
		}
		
		public function new(animator:ParticleAnimator, particleColorNode:ParticleColorNode)
		{
			super(animator, particleColorNode);
			
			_particleColorNode = particleColorNode;
			_usesMultiplier = _particleColorNode._usesMultiplier;
			_usesOffset = _particleColorNode._usesOffset;
			_usesCycle = _particleColorNode._usesCycle;
			_usesPhase = _particleColorNode._usesPhase;
			_startColor = _particleColorNode._startColor;
			_endColor = _particleColorNode._endColor;
			_cycleDuration = _particleColorNode._cycleDuration;
			_cyclePhase = _particleColorNode._cyclePhase;
			
			updateColorData();
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
		{
			// TODO: not used
			renderable = renderable;
			camera = camera;
			
			if (animationRegisterCache.needFragmentAnimation) {
				var dataOffset:UInt = _particleColorNode.dataOffset;
				if (_usesCycle)
					animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.CYCLE_INDEX), _cycleData.x, _cycleData.y, _cycleData.z, _cycleData.w);
				
				if (_usesMultiplier) {
					if (_particleColorNode.mode == ParticlePropertiesMode.LOCAL_STATIC) {
						animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.START_MULTIPLIER_INDEX), dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
						dataOffset += 4;
						animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.DELTA_MULTIPLIER_INDEX), dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
						dataOffset += 4;
					} else {
						animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.START_MULTIPLIER_INDEX), _startMultiplierData.x, _startMultiplierData.y, _startMultiplierData.z, _startMultiplierData.w);
						animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.DELTA_MULTIPLIER_INDEX), _deltaMultiplierData.x, _deltaMultiplierData.y, _deltaMultiplierData.z, _deltaMultiplierData.w);
					}
				}
				if (_usesOffset) {
					if (_particleColorNode.mode == ParticlePropertiesMode.LOCAL_STATIC) {
						animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.START_OFFSET_INDEX), dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
						dataOffset += 4;
						animationSubGeometry.activateVertexBuffer(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.DELTA_OFFSET_INDEX), dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
						dataOffset += 4;
					} else {
						animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.START_OFFSET_INDEX), _startOffsetData.x, _startOffsetData.y, _startOffsetData.z, _startOffsetData.w);
						animationRegisterCache.setVertexConst(animationRegisterCache.getRegisterIndex(_animationNode, ParticleColorNode.DELTA_OFFSET_INDEX), _deltaOffsetData.x, _deltaOffsetData.y, _deltaOffsetData.z, _deltaOffsetData.w);
					}
				}
			}
		}
		
		private function updateColorData():Void
		{
			if (_usesCycle) {
				if (_cycleDuration <= 0)
					throw(new Error("the cycle duration must be greater than zero"));
				_cycleData = new Vector3D(Math.PI*2/_cycleDuration, _cyclePhase*Math.PI/180, 0, 0);
			}
			if (_particleColorNode.mode == ParticlePropertiesMode.GLOBAL) {
				if (_usesCycle) {
					if (_usesMultiplier) {
						_startMultiplierData = new Vector3D((_startColor.redMultiplier + _endColor.redMultiplier)/2, (_startColor.greenMultiplier + _endColor.greenMultiplier)/2, (_startColor.blueMultiplier + _endColor.blueMultiplier)/2, (_startColor.alphaMultiplier + _endColor.alphaMultiplier)/2);
						_deltaMultiplierData = new Vector3D((_endColor.redMultiplier - _startColor.redMultiplier)/2, (_endColor.greenMultiplier - _startColor.greenMultiplier)/2, (_endColor.blueMultiplier - _startColor.blueMultiplier)/2, (_endColor.alphaMultiplier - _startColor.alphaMultiplier)/2);
					}
					
					if (_usesOffset) {
						_startOffsetData = new Vector3D((_startColor.redOffset + _endColor.redOffset)/(255*2), (_startColor.greenOffset + _endColor.greenOffset)/(255*2), (_startColor.blueOffset + _endColor.blueOffset)/(255*2), (_startColor.alphaOffset + _endColor.alphaOffset)/(255*2));
						_deltaOffsetData = new Vector3D((_endColor.redOffset - _startColor.redOffset)/(255*2), (_endColor.greenOffset - _startColor.greenOffset)/(255*2), (_endColor.blueOffset - _startColor.blueOffset)/(255*2), (_endColor.alphaOffset - _startColor.alphaOffset)/(255*2));
					}
				} else {
					if (_usesMultiplier) {
						_startMultiplierData = new Vector3D(_startColor.redMultiplier, _startColor.greenMultiplier, _startColor.blueMultiplier, _startColor.alphaMultiplier);
						_deltaMultiplierData = new Vector3D((_endColor.redMultiplier - _startColor.redMultiplier), (_endColor.greenMultiplier - _startColor.greenMultiplier), (_endColor.blueMultiplier - _startColor.blueMultiplier), (_endColor.alphaMultiplier - _startColor.alphaMultiplier));
					}
					
					if (_usesOffset) {
						_startOffsetData = new Vector3D(_startColor.redOffset/255, _startColor.greenOffset/255, _startColor.blueOffset/255, _startColor.alphaOffset/255);
						_deltaOffsetData = new Vector3D((_endColor.redOffset - _startColor.redOffset)/255, (_endColor.greenOffset - _startColor.greenOffset)/255, (_endColor.blueOffset - _startColor.blueOffset )/255, (_endColor.alphaOffset - _startColor.alphaOffset)/255);
					}
				}
			}
		}
	}

