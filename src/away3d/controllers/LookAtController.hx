package away3d.controllers;

	import away3d.containers.*;
	import away3d.entities.*;
	import away3d.events.*;
	
	import flash.geom.Vector3D;

	import flash.events.Event;
	
	/**
	 * Extended camera used to automatically look at a specified target object.
	 *
	 * @see away3d.containers.View3D
	 */
	class LookAtController extends ControllerBase
	{
		private var _lookAtPosition:Vector3D;
		private var _lookAtObject:ObjectContainer3D;
		private var _origin:Vector3D;
		
		/**
		 * Creates a new <code>LookAtController</code> object.
		 */
		public function new(targetObject:Entity = null, lookAtObject:ObjectContainer3D = null)
		{
			_origin = new Vector3D(0.0, 0.0, 0.0);
			
			super(targetObject);
			
			if (lookAtObject!=null)
				this.lookAtObject = lookAtObject;
			else
				this.lookAtPosition = new Vector3D();
		}
		
		/**
		 * The Vector3D object that the target looks at.
		 */
		public var lookAtPosition(get, set) : Vector3D;
		public function get_lookAtPosition() : Vector3D
		{
			return _lookAtPosition;
		}
		
		public function set_lookAtPosition(val:Vector3D) : Vector3D
		{
			if (_lookAtObject!=null) {
				_lookAtObject.removeEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onLookAtObjectChanged);
				_lookAtObject = null;
			}
			
			_lookAtPosition = val;
			
			notifyUpdate();
			return val;
		}
		
		/**
		 * The 3d object that the target looks at.
		 */
		public var lookAtObject(get, set) : ObjectContainer3D;
		public function get_lookAtObject() : ObjectContainer3D
		{
			return _lookAtObject;
		}
		
		public function set_lookAtObject(val:ObjectContainer3D) : ObjectContainer3D
		{
			if (_lookAtPosition!=null)
				_lookAtPosition = null;
			
			if (_lookAtObject == val)
				return val;
			
			if (_lookAtObject!=null)
				_lookAtObject.removeEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onLookAtObjectChanged);
			
			_lookAtObject = val;
			
			if (_lookAtObject!=null)
				_lookAtObject.addEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onLookAtObjectChanged);
			
			notifyUpdate();

			return val;
		}
		
		/**
		 * @inheritDoc
		 */
		public override function update(interpolate:Bool = true):Void
		{
			//interpolate = interpolate; // prevents unused warning
			if (_targetObject!=null) {
				if (_lookAtPosition!=null)
					_targetObject.lookAt(_lookAtPosition);
				else if (_lookAtObject!=null)
					_targetObject.lookAt(_lookAtObject.scene!=null? _lookAtObject.scenePosition : _lookAtObject.position);
			}
		}
		
		private function onLookAtObjectChanged(event:Event):Void
		{
			notifyUpdate();
		}
	}

