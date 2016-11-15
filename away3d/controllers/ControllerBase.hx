package away3d.controllers;


import away3d.entities.Entity;
import away3d.errors.AbstractMethodError;

class ControllerBase {
	public var targetObject(get, set):Entity;
	public var autoUpdate(get, set):Bool;

	private var _autoUpdate:Bool;
	private var _targetObject:Entity;

	private function notifyUpdate():Void {
		if (_targetObject != null && _targetObject.implicitPartition != null && _autoUpdate) _targetObject.implicitPartition.markForUpdate(_targetObject);
	}

	/**
	 * Target object on which the controller acts. Defaults to null.
	 */
	private function get_targetObject():Entity {
		return _targetObject;
	}

	private function set_targetObject(val:Entity):Entity {
		if (_targetObject == val) return val;
		if (_targetObject != null && _autoUpdate) _targetObject._controller = null;
		_targetObject = val;
		if (_targetObject != null && _autoUpdate) _targetObject._controller = this;
		notifyUpdate();
		return val;
	}

	/**
	 * Determines whether the controller applies updates automatically. Defaults to true
	 */
	private function get_autoUpdate():Bool {
		return _autoUpdate;
	}

	private function set_autoUpdate(val:Bool):Bool {
		if (_autoUpdate == val) return val;
		_autoUpdate = val;
		if (_targetObject != null) {
			if (_autoUpdate) _targetObject._controller = this
			else _targetObject._controller = null;
		}
		return val;
	}

	/**
	 * Base controller class for dynamically adjusting the propeties of a 3D object.
	 *
	 * @param	targetObject	The 3D object on which to act.
	 */
	public function new(targetObject:Entity = null) {
		_autoUpdate = true;
		this.targetObject = targetObject;

	}

	/**
	 * Manually applies updates to the target 3D object.
	 */
	public function update(interpolate:Bool = true):Void {
		throw new AbstractMethodError();
	}
}

