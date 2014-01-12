package away3d.animators.states;

	//import away3d.arcane;
	import away3d.animators.data.ParticleAnimationData;
	
	import flash.utils.Dictionary;
	import flash.geom.Vector3D;
	
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.cameras.Camera3D;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.AnimationSubGeometry;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	
	//use namespace arcane;
	
	/**
	 * ...
	 */
	class ParticleStateBase extends AnimationStateBase
	{
		var _particleNode:ParticleNodeBase;
		
		var _dynamicProperties:Array<Vector3D> = new Array<Vector3D>();
		var _dynamicPropertiesDirty:Dictionary = new Dictionary(true);
		
		var _needUpdateTime:Bool;
		
		public function new(animator:ParticleAnimator, particleNode:ParticleNodeBase, needUpdateTime:Bool = false)
		{
			super(animator, particleNode);
			
			_particleNode = particleNode;
			_needUpdateTime = needUpdateTime;
		}
		
		public var needUpdateTime(get, null) : Bool;
		
		public function get_needUpdateTime() : Bool
		{
			return _needUpdateTime;
		}
		
		public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
		{
		
		}
		
		private function updateDynamicProperties(animationSubGeometry:AnimationSubGeometry):Void
		{
			_dynamicPropertiesDirty[animationSubGeometry] = true;
			
			var animationParticles:Array<ParticleAnimationData> = animationSubGeometry.animationParticles;
			var vertexData:Array<Float> = animationSubGeometry.vertexData;
			var totalLenOfOneVertex:UInt = animationSubGeometry.totalLenOfOneVertex;
			var dataLength:UInt = _particleNode.dataLength;
			var dataOffset:UInt = _particleNode.dataOffset;
			var vertexLength:UInt;
			//			var particleOffset:UInt;
			var startingOffset:UInt;
			var vertexOffset:UInt;
			var data:Vector3D;
			var animationParticle:ParticleAnimationData;
			
			//			var numParticles:UInt = _positions.length/dataLength;
			var numParticles:UInt = _dynamicProperties.length;
			var i:UInt = 0;
			var j:UInt = 0;
			var k:UInt = 0;
			
			//loop through all particles
			while (i < numParticles) {
				//loop through each particle data for the current particle
				while (j < numParticles && (animationParticle = animationParticles[j]).index == i) {
					data = _dynamicProperties[i];
					vertexLength = animationParticle.numVertices*totalLenOfOneVertex;
					startingOffset = animationParticle.startVertexIndex*totalLenOfOneVertex + dataOffset;
					//loop through each vertex in the particle data
					// For loop conversion - 					for (k = 0; k < vertexLength; k += totalLenOfOneVertex)
					for (k in 0...vertexLength) {
						vertexOffset = startingOffset + k;
						//						particleOffset = i * dataLength;
						//loop through all vertex data for the current particle data
						// For loop conversion - 						for (k = 0; k < vertexLength; k += totalLenOfOneVertex)
						for (k in 0...vertexLength) {
							vertexOffset = startingOffset + k;
							vertexData[vertexOffset++] = data.x;
							vertexData[vertexOffset++] = data.y;
							vertexData[vertexOffset++] = data.z;
							
							if (dataLength == 4)
								vertexData[vertexOffset++] = data.w;
						}
							//loop through each value in the particle vertex
							//						switch(dataLength) {
							//							case 4:
							//								vertexData[vertexOffset++] = _positions[particleOffset++];
							//							case 3:
							//								vertexData[vertexOffset++] = _positions[particleOffset++];
							//							case 2:
							//								vertexData[vertexOffset++] = _positions[particleOffset++];
							//							case 1:
							//								vertexData[vertexOffset++] = _positions[particleOffset++];
							//						}
					}
					j++;
				}
				i++;
			}
			
			animationSubGeometry.invalidateBuffer();
		}
	
	}


