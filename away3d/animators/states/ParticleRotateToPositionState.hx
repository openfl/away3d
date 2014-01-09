package away3d.animators.states;

	import away3d.*;
	import away3d.animators.*;
	import away3d.animators.data.*;
	import away3d.animators.nodes.*;
	import away3d.cameras.*;
	import away3d.core.base.*;
	import away3d.core.managers.*;
	
	import flash.display3D.*;
	import flash.geom.*;
	
	//use namespace arcane;
	
	/**
	 * ...
	 */
	class ParticleRotateToPositionState extends ParticleStateBase
	{
		var _particleRotateToPositionNode:ParticleRotateToPositionNode;
		var _position:Vector3D;
		var _matrix:Matrix3D = new Matrix3D;
		var _offset:Vector3D;
		
		/**
		 * Defines the position of the point the particle will rotate to face when in global mode. Defaults to 0,0,0.
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
		
		public function new(animator:ParticleAnimator, particleRotateToPositionNode:ParticleRotateToPositionNode)
		{
			super(animator, particleRotateToPositionNode);
			
			_particleRotateToPositionNode = particleRotateToPositionNode;
			_position = _particleRotateToPositionNode._position;
		}
		
		override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
		{
			var index:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleRotateToPositionNode.POSITION_INDEX);
			
			if (animationRegisterCache.hasBillboard) {
				_matrix.copyFrom(renderable.sceneTransform);
				_matrix.append(camera.inverseSceneTransform);
				animationRegisterCache.setVertexConstFromMatrix(animationRegisterCache.getRegisterIndex(_animationNode, ParticleRotateToPositionNode.MATRIX_INDEX), _matrix);
			}
			
			if (_particleRotateToPositionNode.mode == ParticlePropertiesMode.GLOBAL) {
				_offset = renderable.inverseSceneTransform.transformVector(_position);
				animationRegisterCache.setVertexConst(index, _offset.x, _offset.y, _offset.z);
			} else
				animationSubGeometry.activateVertexBuffer(index, _particleRotateToPositionNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		
		}
	
	}


