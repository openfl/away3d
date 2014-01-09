package away3d.controllers;

	//import away3d.arcane;
	import away3d.entities.*;
	import away3d.errors.AbstractMethodError;
	
	//use namespace arcane;
	
	class ControllerBase
	{
		var _autoUpdate:Bool = true;
		var _targetObject:Entity;
		
		private function notifyUpdate():Void
		{
			if (_targetObject!=null && _targetObject.implicitPartition!=null && _autoUpdate)
				_targetObject.implicitPartition.markForUpdate(_targetObject);
		}
		
		/**
		 * Target object on which the controller acts. Defaults to null.
		 */
		public var targetObject(get, set) : Entity;
		public function get_targetObject() : Entity
		{
			return _targetObject;
		}
		
		public function set_targetObject(val:Entity) : Entity
		{
			if (_targetObject == val)
				return _targetObject;
			
			if (_targetObject!=null && _autoUpdate)
				_targetObject._controller = null;
			
			_targetObject = val;
			
			if (_targetObject!=null && _autoUpdate)
				_targetObject._controller = this;
			
			notifyUpdate();
			return _targetObject;
		}
		
		/**
		 * Determines whether the controller applies updates automatically. Defaults to true
		 */
		public var autoUpdate(get, set) : Bool;
		public function get_autoUpdate() : Bool
		{
			return _autoUpdate;
		}
		
		public function set_autoUpdate(val:Bool) : Bool
		{
			if (_autoUpdate == val)
				return _autoUpdate;
			
			_autoUpdate = val;
			
			if (_targetObject!=null) {
				if (_autoUpdate)
					_targetObject._controller = this;
				else
					_targetObject._controller = null;
			}
			return _autoUpdate;
		}
		
		/**
		 * Base controller class for dynamically adjusting the propeties of a 3D object.
		 *
		 * @param    targetObject    The 3D object on which to act.
		 */
		public function new(targetObject:Entity = null):Void
		{
			this.targetObject = targetObject;
		}
		
		/**
		 * Manually applies updates to the target 3D object.
		 */
		public function update(interpolate:Bool = true):Void
		{
			throw new AbstractMethodError();
		}
	}

