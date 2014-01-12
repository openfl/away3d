package away3d.animators;

	//import away3d.arcane;
	import away3d.animators.data.*;
	import away3d.animators.states.ISpriteSheetAnimationState;
	import away3d.animators.states.SpriteSheetAnimationState;
	import away3d.animators.transitions.IAnimationTransition;
	import away3d.core.base.*;
	import away3d.core.managers.*;
	import away3d.materials.*;
	import away3d.materials.passes.*;
	import away3d.cameras.Camera3D;
	
	import flash.display3D.Context3DProgramType;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	//use namespace arcane;
	
	/**
	 * Provides an interface for assigning uv-based sprite sheet animation data sets to mesh-based entity objects
	 * and controlling the various available states of animation through an interative playhead that can be
	 * automatically updated or manually triggered.
	 */
	class SpriteSheetAnimator extends AnimatorBase implements IAnimator
	{
		var _activeSpriteSheetState:ISpriteSheetAnimationState;
		var _spriteSheetAnimationSet:SpriteSheetAnimationSet;
		var _frame:SpriteSheetAnimationFrame = new SpriteSheetAnimationFrame();
		var _vectorFrame:Array<Float>;
		var _fps:UInt = 10;
		var _ms:UInt = 100;
		var _lastTime:UInt;
		var _reverse:Bool;
		var _backAndForth:Bool;
		var _specsDirty:Bool;
		var _mapDirty:Bool;
		
		/**
		 * Creates a new <code>SpriteSheetAnimator</code> object.
		 * @param spriteSheetAnimationSet  The animation data set containing the sprite sheet animation states used by the animator.
		 */
		public function new(spriteSheetAnimationSet:SpriteSheetAnimationSet)
		{
			super(spriteSheetAnimationSet);
			_spriteSheetAnimationSet = spriteSheetAnimationSet;
			_vectorFrame = new Array<Float>();
		}
		
		/* Set the playrate of the animation in frames per second (not depending on player fps)*/
		public function set_fps(val:UInt) : Void
		{
			_ms = 1000/val;
			_fps = val;
		}
		
		public var fps(get, set) : Void;
		
		public function get_fps() : Void
		{
			return _fps;
		}
		
		/* If true, reverse causes the animation to play backwards*/
		public function set_reverse(b:Bool) : Void
		{
			_reverse = b;
			_specsDirty = true;
		}
		
		public var reverse(get, set) : Void;
		
		public function get_reverse() : Void
		{
			return _reverse;
		}
		
		/* If true, backAndForth causes the animation to play backwards and forward alternatively. Starting forward.*/
		public function set_backAndForth(b:Bool) : Void
		{
			_backAndForth = b;
			_specsDirty = true;
		}
		
		public var backAndForth(get, set) : Void;
		
		public function get_backAndForth() : Void
		{
			return _backAndForth;
		}
		
		/* sets the animation pointer to a given frame and plays from there. Equivalent to ActionScript, the first frame is at 1, not 0.*/
		public function gotoAndPlay(frameNumber:UInt):Void
		{
			gotoFrame(frameNumber, true);
		}
		
		/* sets the animation pointer to a given frame and stops there. Equivalent to ActionScript, the first frame is at 1, not 0.*/
		public function gotoAndStop(frameNumber:UInt):Void
		{
			gotoFrame(frameNumber, false);
		}
		
		/* returns the current frame*/
		public var currentFrameNumber(get, null) : UInt;
		public function get_currentFrameNumber() : UInt
		{
			return SpriteSheetAnimationState(_activeState).currentFrameNumber;
		}
		
		/* returns the total amount of frame for the current animation*/
		public var totalFrames(get, null) : UInt;
		public function get_totalFrames() : UInt
		{
			return SpriteSheetAnimationState(_activeState).totalFrames;
		}
		
		/**
		 * @inheritDoc
		 */
		public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:Int, vertexStreamOffset:Int, camera:Camera3D):Void
		{
			var material:MaterialBase = renderable.material;
			if (material==null || !Std.is(material, TextureMaterial))
				return;
			
			var subMesh:SubMesh = renderable as SubMesh;
			if (subMesh==null)
				return;
			
			//because textures are already uploaded, we can't offset the uv's yet
			var swapped:Bool;
			
			if (Std.is(material, SpriteSheetMaterial) && _mapDirty)
				swapped = SpriteSheetMaterial(material).swap(_frame.mapID);
			
			if (!swapped) {
				_vectorFrame[0] = _frame.offsetU;
				_vectorFrame[1] = _frame.offsetV;
				_vectorFrame[2] = _frame.scaleU;
				_vectorFrame[3] = _frame.scaleV;
			}
			
			//vc[vertexConstantOffset]
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _vectorFrame);
		}
		
		/**
		 * @inheritDoc
		 */
		public function play(name:String, transition:IAnimationTransition = null, offset:Float = NaN):Void
		{
			transition = transition;
			offset = offset;
			if (_activeAnimationName == name)
				return;
			
			_activeAnimationName = name;
			
			if (!_animationSet.hasAnimation(name))
				throw new Error("Animation root node " + name + " not found!");
			
			_activeNode = _animationSet.getAnimation(name);
			_activeState = getAnimationState(_activeNode);
			_frame = SpriteSheetAnimationState(_activeState).currentFrameData;
			_activeSpriteSheetState = _activeState as ISpriteSheetAnimationState;
			
			start();
		}
		
		/**
		 * Applies the calculated time delta to the active animation state node.
		 */
		override private function updateDeltaTime(dt:Float):Void
		{
			if (_specsDirty) {
				SpriteSheetAnimationState(_activeSpriteSheetState).reverse = _reverse;
				SpriteSheetAnimationState(_activeSpriteSheetState).backAndForth = _backAndForth;
				_specsDirty = false;
			}
			
			_absoluteTime += dt;
			var now:Int = getTimer();
			
			if ((now - _lastTime) > _ms) {
				_mapDirty = true;
				_activeSpriteSheetState.update(_absoluteTime);
				_frame = SpriteSheetAnimationState(_activeSpriteSheetState).currentFrameData;
				_lastTime = now;
				
			} else
				_mapDirty = false;
		
		}
		
		public function testGPUCompatibility(pass:MaterialPassBase):Void
		{
		}
		
		public function clone():IAnimator
		{
			return new SpriteSheetAnimator(_spriteSheetAnimationSet);
		}
		
		private function gotoFrame(frameNumber:UInt, doPlay:Bool):Void
		{
			if (!_activeState)
				return;
			SpriteSheetAnimationState(_activeState).currentFrameNumber = (frameNumber == 0)? frameNumber : frameNumber - 1;
			var currentMapID:UInt = _frame.mapID;
			_frame = SpriteSheetAnimationState(_activeSpriteSheetState).currentFrameData;
			
			if (doPlay)
				start();
			else {
				if (currentMapID != _frame.mapID) {
					_mapDirty = true;
					setTimeout(stop, _fps);
				} else
					stop();
				
			}
		}
	
	}

