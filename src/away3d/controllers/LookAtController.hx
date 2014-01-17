/**
 * Extended camera used to automatically look at a specified target object.
 *
 * @see away3d.containers.View3D
 */
package away3d.controllers;

import away3d.events.Object3DEvent;
import away3d.entities.Entity;
import away3d.containers.ObjectContainer3D;
import flash.geom.Vector3D;

class LookAtController extends ControllerBase {
    public var upAxis(get_upAxis, set_upAxis):Vector3D;
    public var lookAtPosition(get_lookAtPosition, set_lookAtPosition):Vector3D;
    public var lookAtObject(get_lookAtObject, set_lookAtObject):ObjectContainer3D;

    private var _lookAtPosition:Vector3D;
    private var _lookAtObject:ObjectContainer3D;
    private var _origin:Vector3D;
    private var _upAxis:Vector3D;
/**
	 * Creates a new <code>LookAtController</code> object.
	 */

    public function new(targetObject:Entity = null, lookAtObject:ObjectContainer3D = null) {
        _origin = new Vector3D(0.0, 0.0, 0.0);
        _upAxis = Vector3D.Y_AXIS;
        super(targetObject);
        if (lookAtObject != null) this.lookAtObject = lookAtObject
        else this.lookAtPosition = new Vector3D();
    }

/**
        * The vector representing the up direction of the target object.
        */

    public function get_upAxis():Vector3D {
        return _upAxis;
    }

    public function set_upAxis(upAxis:Vector3D):Vector3D {
        _upAxis = upAxis;
        notifyUpdate();
        return upAxis;
    }

/**
	 * The Vector3D object that the target looks at.
	 */

    public function get_lookAtPosition():Vector3D {
        return _lookAtPosition;
    }

    public function set_lookAtPosition(val:Vector3D):Vector3D {
        if (_lookAtObject != null) {
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

    public function get_lookAtObject():ObjectContainer3D {
        return _lookAtObject;
    }

    public function set_lookAtObject(val:ObjectContainer3D):ObjectContainer3D {
        if (_lookAtPosition != null) _lookAtPosition = null;
        if (_lookAtObject == val) return val;
        if (_lookAtObject != null) _lookAtObject.removeEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onLookAtObjectChanged);
        _lookAtObject = val;
        if (_lookAtObject != null) _lookAtObject.addEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onLookAtObjectChanged);
        notifyUpdate();
        return val;
    }

/**
	 * @inheritDoc
	 */

    override public function update(interpolate:Bool = true):Void {

// prevents unused warning
        if (_targetObject != null) {
            if (_lookAtPosition != null) {
                _targetObject.lookAt(_lookAtPosition, _upAxis);
            }

            else if (_lookAtObject != null) {
                _targetObject.lookAt((_lookAtObject.scene != null) ? _lookAtObject.scenePosition : _lookAtObject.position, _upAxis);
            }
        }
    }

    private function onLookAtObjectChanged(event:Object3DEvent):Void {
        notifyUpdate();
    }

}

