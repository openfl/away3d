package away3d.animators.states;

	import away3d.animators.ParticleAnimator;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.animators.nodes.ParticlePositionNode;
	//import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	//use namespace arcane;
	
	/**
	 * ...
	 * @author ...
	 */
	class ParticlePositionState extends ParticleStateBase
	{
		var _particlePositionNode:ParticlePositionNode;
		var _position:Vector3D;
		
		/**
		 * Defines the position of the particle when in global mode. Defaults to 0,0,0.
		 */
		public var position(get, set) : Vector3D;
		public function get_position() : Vector3D
		{
			return _position;
		}
		
		public function set_position(value:Vector3D) : Vector3D
		{
			_position = value;
		}
		
		/**
		 *
		 */
		public function getPositions():Array<Vector3D>
		{
			return _dynamicProperties;
		}
		
		public function setPositions(value:Array<Vector3D>):Void
		{
			_dynamicProperties = value;
			
			_dynamicPropertiesDirty = new Dictionary(true);
		}
		
		public function new(animator:ParticleAnimator, particlePositionNode:ParticlePositionNode)
		{
			super(animator, particlePositionNode);
			
			_particlePositionNode = particlePositionNode;
			_position = _particlePositionNode._position;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
		{
			if (_particlePositionNode.mode == ParticlePropertiesMode.LOCAL_DYNAMIC && !_dynamicPropertiesDirty[animationSubGeometry])
				updateDynamicProperties(animationSubGeometry);
			
			var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticlePositionNode.POSITION_INDEX);
			
			if (_particlePositionNode.mode == ParticlePropertiesMode.GLOBAL)
				animationRegisterCache.setVertexConst(index, _position.x, _position.y, _position.z);
			else
				animationSubGeometry.activateVertexBuffer(index, _particlePositionNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		}
	}

