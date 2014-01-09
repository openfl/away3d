package away3d.animators;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	//import away3d.arcane;
	import away3d.animators.nodes.AnimationNodeBase;
	import away3d.animators.states.AnimationStateBase;
	import away3d.animators.states.IAnimationState;
	import away3d.entities.Mesh;
	import away3d.events.AnimatorEvent;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.library.assets.NamedAssetBase;
	
	//use namespace arcane;
	
	/**
	 * Dispatched when playback of an animation inside the animator object starts.
	 *
	 * @eventType away3d.events.AnimatorEvent
	 */
	//[Event(name="start", type="away3d.events.AnimatorEvent")]
	
	/**
	 * Dispatched when playback of an animation inside the animator object stops.
	 *
	 * @eventType away3d.events.AnimatorEvent
	 */
	//[Event(name="stop", type="away3d.events.AnimatorEvent")]
	
	/**
	 * Dispatched when playback of an animation reaches the end of an animation.
	 *
	 * @eventType away3d.events.AnimatorEvent
	 */
	//[Event(name="cycle_complete", type="away3d.events.AnimatorEvent")]
	
	/**
	 * Provides an abstract base class for animator classes that control animation output from a data set subtype of <code>AnimationSetBase</code>.
	 *
	 * @see away3d.animators.AnimationSetBase
	 */
	class AnimatorBase extends NamedAssetBase implements IAsset
	{
		var _broadcaster:Sprite = new Sprite();
		var _isPlaying:Bool;
		var _autoUpdate:Bool = true;
		var _startEvent:AnimatorEvent;
		var _stopEvent:AnimatorEvent;
		var _cycleEvent:AnimatorEvent;
		var _time:Int;
		var _playbackSpeed:Float = 1;
		
		var _animationSet:IAnimationSet;
		var _owners:Array<Mesh> = new Array<Mesh>();
		var _activeNode:AnimationNodeBase;
		var _activeState:IAnimationState;
		var _activeAnimationName:String;
		var _absoluteTime:Float = 0;
		var _animationStates:Dictionary = new Dictionary(true);
		
		/**
		 * Enables translation of the animated mesh from data returned per frame via the positionDelta property of the active animation node. Defaults to true.
		 *
		 * @see away3d.animators.states.IAnimationState#positionDelta
		 */
		public var updatePosition:Bool = true;
		
		public function getAnimationState(node:AnimationNodeBase):AnimationStateBase
		{
			var className = node.stateClass;
			if (_animationStates[node]==null) _animationStates[node] = new className(this, node);
			return _animationStates[node];
		}
		
		public function getAnimationStateByName(name:String):AnimationStateBase
		{
			return getAnimationState(_animationSet.getAnimation(name));
		}
		
		/**
		 * Returns the internal absolute time of the animator, calculated by the current time and the playback speed.
		 *
		 * @see #time
		 * @see #playbackSpeed
		 */
		public var absoluteTime(get, null) : Float;
		public function get_absoluteTime() : Float
		{
			return _absoluteTime;
		}
		
		/**
		 * Returns the animation data set in use by the animator.
		 */
		public var animationSet(get, null) : IAnimationSet;
		public function get_animationSet() : IAnimationSet
		{
			return _animationSet;
		}
		
		/**
		 * Returns the current active animation state.
		 */
		public var activeState(get, null) : IAnimationState;
		public function get_activeState() : IAnimationState
		{
			return _activeState;
		}
		
		/**
		 * Returns the current active animation node.
		 */
		public var activeAnimation(get, null) : AnimationNodeBase;
		public function get_activeAnimation() : AnimationNodeBase
		{
			return _animationSet.getAnimation(_activeAnimationName);
		}
		
		/**
		 * Returns the current active animation node.
		 */
		public var activeAnimationName(get, null) : String;
		public function get_activeAnimationName() : String
		{
			return _activeAnimationName;
		}
		
		/**
		 * Determines whether the animators internal update mechanisms are active. Used in cases
		 * where manual updates are required either via the <code>time</code> property or <code>update()</code> method.
		 * Defaults to true.
		 *
		 * @see #time
		 * @see #update()
		 */
		public var autoUpdate(get, set) : Bool;
		public function get_autoUpdate() : Bool
		{
			return _autoUpdate;
		}
		
		public function set_autoUpdate(value:Bool) : Bool
		{
			if (_autoUpdate == value)
				return;
			
			_autoUpdate = value;
			
			if (_autoUpdate)
				start();
			else
				stop();
		}
		
		/**
		 * Gets and sets the internal time clock of the animator.
		 */
		public var time(get, set) : Int;
		public function get_time() : Int
		{
			return _time;
		}
		
		public function set_time(value:Int) : Int
		{
			if (_time == value)
				return;
			
			update(value);
		}
		
		/**
		 * Sets the animation phase of the current active state's animation clip(s).
		 *
		 * @param value The phase value to use. 0 represents the beginning of an animation clip, 1 represents the end.
		 */
		public function phase(value:Float):Void
		{
			_activeState.phase(value);
		}
		
		/**
		 * Creates a new <code>AnimatorBase</code> object.
		 *
		 * @param animationSet The animation data set to be used by the animator object.
		 */
		public function new(animationSet:IAnimationSet)
		{
			_animationSet = animationSet;
		}
		
		/**
		 * The amount by which passed time should be scaled. Used to slow down or speed up animations. Defaults to 1.
		 */
		public var playbackSpeed(get, set) : Float;
		public function get_playbackSpeed() : Float
		{
			return _playbackSpeed;
		}
		
		public function set_playbackSpeed(value:Float) : Float
		{
			_playbackSpeed = value;
		}
		
		/**
		 * Resumes the automatic playback clock controling the active state of the animator.
		 */
		public function start():Void
		{
			if (_isPlaying || !_autoUpdate)
				return;
			
			_time = _absoluteTime = getTimer();
			
			_isPlaying = true;
			
			if (!_broadcaster.hasEventListener(Event.ENTER_FRAME))
				_broadcaster.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			if (!hasEventListener(AnimatorEvent.START))
				return;
			
			if (_startEvent==null) _startEvent = new AnimatorEvent(AnimatorEvent.START, this)
			dispatchEvent(_startEvent);
		}
		
		/**
		 * Pauses the automatic playback clock of the animator, in case manual updates are required via the
		 * <code>time</code> property or <code>update()</code> method.
		 *
		 * @see #time
		 * @see #update()
		 */
		public function stop():Void
		{
			if (!_isPlaying)
				return;
			
			_isPlaying = false;
			
			if (_broadcaster.hasEventListener(Event.ENTER_FRAME)!=null)
				_broadcaster.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			if (!hasEventListener(AnimatorEvent.STOP))
				return;
			
			dispatchEvent(_stopEvent || (_stopEvent = new AnimatorEvent(AnimatorEvent.STOP, this)));
		}
		
		/**
		 * Provides a way to manually update the active state of the animator when automatic
		 * updates are disabled.
		 *
		 * @see #stop()
		 * @see #autoUpdate
		 */
		public function update(time:Int):Void
		{
			var dt:Float = (time - _time)*playbackSpeed;
			
			updateDeltaTime(dt);
			
			_time = time;
		}
		
		public function reset(name:String, offset:Float = 0):Void
		{
			getAnimationState(_animationSet.getAnimation(name)).offset(offset + _absoluteTime);
		}
		
		/**
		 * Used by the mesh object to which the animator is applied, registers the owner for internal use.
		 *
		 * @private
		 */
		public function addOwner(mesh:Mesh):Void
		{
			_owners.push(mesh);
		}
		
		/**
		 * Used by the mesh object from which the animator is removed, unregisters the owner for internal use.
		 *
		 * @private
		 */
		public function removeOwner(mesh:Mesh):Void
		{
			_owners.splice(_owners.indexOf(mesh), 1);
		}
		
		/**
		 * Internal abstract method called when the time delta property of the animator's contents requires updating.
		 *
		 * @private
		 */
		private function updateDeltaTime(dt:Float):Void
		{
			_absoluteTime += dt;
			
			_activeState.update(_absoluteTime);
			
			if (updatePosition)
				applyPositionDelta();
		}
		
		/**
		 * Enter frame event handler for automatically updating the active state of the animator.
		 */
		private function onEnterFrame(event:Event = null):Void
		{
			update(getTimer());
		}
		
		private function applyPositionDelta():Void
		{
			var delta:Vector3D = _activeState.positionDelta;
			var dist:Float = delta.length;
			var len:UInt;
			if (dist > 0) {
				len = _owners.length;
				// For loop conversion - 				for (var i:UInt = 0; i < len; ++i)
				var i:UInt = 0;
				for (i in 0...len)
					_owners[i].translateLocal(delta, dist);
			}
		}
		
		/**
		 *  for internal use.
		 *
		 * @private
		 */
		public function dispatchCycleEvent():Void
		{
			if (hasEventListener(AnimatorEvent.CYCLE_COMPLETE))
				dispatchEvent(_cycleEvent || (_cycleEvent = new AnimatorEvent(AnimatorEvent.CYCLE_COMPLETE, this)));
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispose():Void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public var assetType(get, null) : String;
		public function get_assetType() : String
		{
			return AssetType.ANIMATOR;
		}
	}

