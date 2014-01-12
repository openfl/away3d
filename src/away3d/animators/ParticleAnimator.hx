package away3d.animators;

	import flash.display3D.*;
	import flash.utils.*;
	
	import away3d.*;
	import away3d.animators.data.*;
	import away3d.animators.nodes.*;
	import away3d.animators.states.*;
	import away3d.cameras.*;
	import away3d.core.base.*;
	import away3d.core.managers.*;
	import away3d.materials.passes.*;
	
	//use namespace arcane;
	
	/**
	 * Provides an interface for assigning paricle-based animation data sets to mesh-based entity objects
	 * and controlling the various available states of animation through an interative playhead that can be
	 * automatically updated or manually triggered.
	 *
	 * Requires that the containing geometry of the parent mesh is particle geometry
	 *
	 * @see away3d.core.base.ParticleGeometry
	 */
	class ParticleAnimator extends AnimatorBase implements IAnimator
	{
		
		var _particleAnimationSet:ParticleAnimationSet;
		var _animationParticleStates:Array<ParticleStateBase> = new Array<ParticleStateBase>;
		var _animatorParticleStates:Array<ParticleStateBase> = new Array<ParticleStateBase>;
		var _timeParticleStates:Array<ParticleStateBase> = new Array<ParticleStateBase>;
		var _totalLenOfOneVertex:UInt = 0;
		var _animatorSubGeometries:Dictionary = new Dictionary(true);
		
		/**
		 * Creates a new <code>ParticleAnimator</code> object.
		 *
		 * @param particleAnimationSet The animation data set containing the particle animations used by the animator.
		 */
		public function new(particleAnimationSet:ParticleAnimationSet)
		{
			super(particleAnimationSet);
			_particleAnimationSet = particleAnimationSet;
			
			var state:ParticleStateBase;
			var node:ParticleNodeBase;
			for each (node in _particleAnimationSet.particleNodes) {
				state = getAnimationState(node) as ParticleStateBase;
				if (node.mode == ParticlePropertiesMode.LOCAL_DYNAMIC) {
					_animatorParticleStates.push(state);
					node.dataOffset = _totalLenOfOneVertex;
					_totalLenOfOneVertex += node.dataLength;
				} else
					_animationParticleStates.push(state);
				if (state.needUpdateTime)
					_timeParticleStates.push(state);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function clone():IAnimator
		{
			return new ParticleAnimator(_particleAnimationSet);
		}
		
		/**
		 * @inheritDoc
		 */
		public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:Int, vertexStreamOffset:Int, camera:Camera3D):Void
		{
			var animationRegisterCache:AnimationRegisterCache = _particleAnimationSet._animationRegisterCache;
			
			var subMesh:SubMesh = cast(renderable, SubMesh);
			var state:ParticleStateBase;
			
			if (subMesh==null)
				throw(new Error("Must be subMesh"));
			
			//process animation sub geometries
			if (!subMesh.animationSubGeometry)
				_particleAnimationSet.generateAnimationSubGeometries(subMesh.parentMesh);
			
			var animationSubGeometry:AnimationSubGeometry = subMesh.animationSubGeometry;
			
			for each (state in _animationParticleStates)
				state.setRenderState(stage3DProxy, renderable, animationSubGeometry, animationRegisterCache, camera);
			
			//process animator subgeometries
			if (subMesh.animatorSubGeometry==null && _animatorParticleStates.length)
				generateAnimatorSubGeometry(subMesh);
			
			var animatorSubGeometry:AnimationSubGeometry = subMesh.animatorSubGeometry;
			
			for each (state in _animatorParticleStates)
				state.setRenderState(stage3DProxy, renderable, animatorSubGeometry, animationRegisterCache, camera);
			
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, animationRegisterCache.vertexConstantOffset, animationRegisterCache.vertexConstantData, animationRegisterCache.numVertexConstant);
			
			if (animationRegisterCache.numFragmentConstant > 0)
				stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, animationRegisterCache.fragmentConstantOffset, animationRegisterCache.fragmentConstantData, animationRegisterCache.numFragmentConstant);
		}
		
		/**
		 * @inheritDoc
		 */
		public function testGPUCompatibility(pass:MaterialPassBase):Void
		{
		
		}
		
		/**
		 * @inheritDoc
		 */
		override public function start():Void
		{
			super.start();
			for each (var state:ParticleStateBase in _timeParticleStates)
				state.offset(_absoluteTime);
		}
		
		/**
		 * @inheritDoc
		 */
		override private function updateDeltaTime(dt:Float):Void
		{
			_absoluteTime += dt;
			
			for each (var state:ParticleStateBase in _timeParticleStates)
				state.update(_absoluteTime);
		}
		
		/**
		 * @inheritDoc
		 */
		public function resetTime(offset:Int = 0):Void
		{
			for each (var state:ParticleStateBase in _timeParticleStates)
				state.offset(_absoluteTime + offset);
			update(time);
		}
		
		override public function dispose():Void
		{
			var subGeometry:AnimationSubGeometry;
			for each (subGeometry in _animatorSubGeometries)
				subGeometry.dispose();
		}
		
		private function generateAnimatorSubGeometry(subMesh:SubMesh):Void
		{
			var subGeometry:ISubGeometry = subMesh.subGeometry;
			var animatorSubGeometry:AnimationSubGeometry = subMesh.animatorSubGeometry = _animatorSubGeometries[subGeometry] = new AnimationSubGeometry();
			
			//create the vertexData vector that will be used for local state data
			animatorSubGeometry.createVertexData(subGeometry.numVertices, _totalLenOfOneVertex);
			
			//pass the particles data to the animator subGeometry
			animatorSubGeometry.animationParticles = subMesh.animationSubGeometry.animationParticles;
		}
	}


