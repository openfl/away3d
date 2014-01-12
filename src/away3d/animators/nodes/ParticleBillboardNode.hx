package away3d.animators.nodes;

	import away3d.*;
	import away3d.animators.*;
	import away3d.animators.data.*;
	import away3d.animators.states.*;
	import away3d.materials.compilation.*;
	import away3d.materials.passes.*;
	
	import flash.geom.Vector3D;
	
	//use namespace arcane;
	
	/**
	 * A particle animation node that controls the rotation of a particle to always face the camera.
	 */
	class ParticleBillboardNode extends ParticleNodeBase
	{
		/** @private */
		arcane static var MATRIX_INDEX:Int = 0;
		
		/** @private */
		/*arcane*/ public var _billboardAxis:Vector3D;
		
		/**
		 * Creates a new <code>ParticleBillboardNode</code>
		 */
		public function new(billboardAxis:Vector3D = null)
		{
			super("ParticleBillboard", ParticlePropertiesMode.GLOBAL, 0, 4);
			
			_stateClass = ParticleBillboardState;
			
			_billboardAxis = billboardAxis;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
		{
			pass = pass;
			var rotationMatrixRegister:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, MATRIX_INDEX, rotationMatrixRegister.index);
			animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.getFreeVertexConstant();
			
			var code:String = "m33 " + animationRegisterCache.scaleAndRotateTarget + ".xyz," + animationRegisterCache.scaleAndRotateTarget + ".xyz," + rotationMatrixRegister + "\n";
			
			var shaderRegisterElement:ShaderRegisterElement;
			for each (shaderRegisterElement in animationRegisterCache.rotationRegisters)
				code += "m33 " + shaderRegisterElement.regName + shaderRegisterElement.index + ".xyz," + shaderRegisterElement + "," + rotationMatrixRegister + "\n";
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAnimationState(animator:IAnimator):ParticleBillboardState
		{
			return animator.getAnimationState(this) as ParticleBillboardState;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):Void
		{
			particleAnimationSet.hasBillboard = true;
		}
	}

