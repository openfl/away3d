package away3d.animators;

	//import away3d.arcane;
	import away3d.animators.states.*;
	import away3d.animators.transitions.*;
	import away3d.animators.data.*;
	import away3d.cameras.Camera3D;
	import away3d.core.base.*;
	import away3d.core.managers.*;
	import away3d.materials.passes.*;
	
	import flash.display3D.*;
	
	//use namespace arcane;
	
	/**
	 * Provides an interface for assigning vertex-based animation data sets to mesh-based entity objects
	 * and controlling the various available states of animation through an interative playhead that can be
	 * automatically updated or manually triggered.
	 */
	class VertexAnimator extends AnimatorBase implements IAnimator
	{
		var _vertexAnimationSet:VertexAnimationSet;
		var _poses:Array<Geometry> = new Array<Geometry>();
		var _weights:Array<Float> = Array<Float>([1, 0, 0, 0]);
		var _numPoses:UInt;
		var _blendMode:String;
		var _activeVertexState:IVertexAnimationState;
		
		/**
		 * Creates a new <code>VertexAnimator</code> object.
		 *
		 * @param vertexAnimationSet The animation data set containing the vertex animations used by the animator.
		 */
		public function new(vertexAnimationSet:VertexAnimationSet)
		{
			super(vertexAnimationSet);
			
			_vertexAnimationSet = vertexAnimationSet;
			_numPoses = vertexAnimationSet.numPoses;
			_blendMode = vertexAnimationSet.blendMode;
		}
		
		/**
		 * @inheritDoc
		 */
		public function clone():IAnimator
		{
			return new VertexAnimator(_vertexAnimationSet);
		}
		
		/**
		 * Plays a sequence with a given name. If the sequence is not found, it may not be loaded yet, and it will retry every frame.
		 * @param sequenceName The name of the clip to be played.
		 */
		public function play(name:String, transition:IAnimationTransition = null, offset:Float = NaN):Void
		{
			if (_activeAnimationName == name)
				return;
			
			_activeAnimationName = name;
			
			//TODO: implement transitions in vertex animator
			
			if (!_animationSet.hasAnimation(name))
				throw new Error("Animation root node " + name + " not found!");
			
			_activeNode = _animationSet.getAnimation(name);
			
			_activeState = getAnimationState(_activeNode);
			
			if (updatePosition) {
				//update straight away to reset position deltas
				_activeState.update(_absoluteTime);
				_activeState.positionDelta;
			}
			
			_activeVertexState = _activeState as IVertexAnimationState;
			
			start();
			
			//apply a time offset if specified
			if (!isNaN(offset))
				reset(name, offset);
		}
		
		/**
		 * @inheritDoc
		 */
		override private function updateDeltaTime(dt:Float):Void
		{
			super.updateDeltaTime(dt);
			
			_poses[uint(0)] = _activeVertexState.currentGeometry;
			_poses[uint(1)] = _activeVertexState.nextGeometry;
			_weights[uint(0)] = 1 - (_weights[uint(1)] = _activeVertexState.blendWeight);
		}
		
		/**
		 * @inheritDoc
		 */
		public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:Int, vertexStreamOffset:Int, camera:Camera3D):Void
		{
			// todo: add code for when running on cpu
			
			// if no poses defined, set temp data
			if (!_poses.length) {
				setNullPose(stage3DProxy, renderable, vertexConstantOffset, vertexStreamOffset);
				return;
			}
			
			// this type of animation can only be SubMesh
			var subMesh:SubMesh = SubMesh(renderable);
			var subGeom:ISubGeometry;
			var i:UInt = 0;
			var len:UInt = _numPoses;
			
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _weights, 1);
			
			if (_blendMode == VertexAnimationMode.ABSOLUTE) {
				i = 1;
				subGeom = _poses[uint(0)].subGeometries[subMesh._index];
				// set the base sub-geometry so the material can simply pick up on this data
				if (subGeom)
					subMesh.subGeometry = subGeom;
			} else
				i = 0;
			
			for (; i < len; ++i) {
				subGeom = _poses[i].subGeometries[subMesh._index] || subMesh.subGeometry;
				
				subGeom.activateVertexBuffer(vertexStreamOffset++, stage3DProxy);
				
				if (_vertexAnimationSet.useNormals)
					subGeom.activateVertexNormalBuffer(vertexStreamOffset++, stage3DProxy);
				
			}
		}
		
		private function setNullPose(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:Int, vertexStreamOffset:Int):Void
		{
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _weights, 1);
			
			if (_blendMode == VertexAnimationMode.ABSOLUTE) {
				var len:UInt = _numPoses;
				// For loop conversion - 				for (var i:UInt = 1; i < len; ++i)
				var i:UInt = 0;
				for (i in 1...len) {
					renderable.activateVertexBuffer(vertexStreamOffset++, stage3DProxy);
					
					if (_vertexAnimationSet.useNormals)
						renderable.activateVertexNormalBuffer(vertexStreamOffset++, stage3DProxy);
				}
			}
			// todo: set temp data for additive?
		}
		
		/**
		 * Verifies if the animation will be used on cpu. Needs to be true for all passes for a material to be able to use it on gpu.
		 * Needs to be called if gpu code is potentially required.
		 */
		public function testGPUCompatibility(pass:MaterialPassBase):Void
		{
		}
	}

