package away3d.controllers;

import away3d.containers.*;
import away3d.core.math.Matrix3DUtils;
import away3d.entities.*;
import away3d.events.*;

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

/**
 * Extended camera used to automatically look at a specified target object.
 *
 * @see away3d.containers.View3D
 */
class LookAtController extends ControllerBase
{
	/**
	* The vector representing the up direction of the target object.
	*/
	public var upAxis(get, set):Vector3D;
	
	/**
	 * The Vector3D object that the target looks at.
	 */
	public var lookAtPosition(get, set):Vector3D;
	public var lookAtObject(get, set):ObjectContainer3D;
	
	private var _lookAtPosition:Vector3D;
	private var _lookAtObject:ObjectContainer3D;
	private var _origin:Vector3D = new Vector3D(0.0, 0.0, 0.0);
	private var _upAxis:Vector3D = Vector3D.Y_AXIS;
	private var _pos:Vector3D = new Vector3D();
	/**
	 * Creates a new <code>LookAtController</code> object.
	 */
	public function new(targetObject:Entity = null, lookAtObject:ObjectContainer3D = null)
	{
		super(targetObject);
		
		if (lookAtObject != null)
			this.lookAtObject = lookAtObject;
		else
			this.lookAtPosition = new Vector3D();
	}
	
	private function get_upAxis():Vector3D
	{
		return _upAxis;
	}
	
	private function set_upAxis(upAxis:Vector3D):Vector3D
	{
		_upAxis = upAxis;
		
		notifyUpdate();
		return upAxis;
	}
	
	private function get_lookAtPosition():Vector3D
	{
		return _lookAtPosition;
	}
	
	private function set_lookAtPosition(val:Vector3D):Vector3D
	{
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
	private function get_lookAtObject():ObjectContainer3D
	{
		return _lookAtObject;
	}
	
	private function set_lookAtObject(val:ObjectContainer3D):ObjectContainer3D
	{
		if (_lookAtPosition != null)
			_lookAtPosition = null;
		
		if (_lookAtObject == val)
			return val;
		
		if (_lookAtObject != null)
			_lookAtObject.removeEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onLookAtObjectChanged);
		
		_lookAtObject = val;
		
		if (_lookAtObject != null)
			_lookAtObject.addEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onLookAtObjectChanged);
		
		notifyUpdate();
		return val;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function update(interpolate:Bool = true):Void
	{
		if (_targetObject != null) {
			if (_lookAtPosition != null) {
				_targetObject.lookAt(_lookAtPosition, _upAxis);
			} else if (_lookAtObject != null) {
				if(_targetObject.parent != null && _lookAtObject.parent != null) {
					if(_targetObject.parent != _lookAtObject.parent) {// different spaces
						_pos.x = _lookAtObject.scenePosition.x;
						_pos.y = _lookAtObject.scenePosition.y;
						_pos.z = _lookAtObject.scenePosition.z;
						Matrix3DUtils.transformVector(_targetObject.parent.inverseSceneTransform, _pos, _pos);
					}else{//one parent
						Matrix3DUtils.getTranslation(_lookAtObject.transform, _pos);
					}
				}else if(_lookAtObject.scene != null){
					_pos.x = _lookAtObject.scenePosition.x;
					_pos.y = _lookAtObject.scenePosition.y;
					_pos.z = _lookAtObject.scenePosition.z;
				}else{
					Matrix3DUtils.getTranslation(_lookAtObject.transform, _pos);
				}
				_targetObject.lookAt(_pos, _upAxis);
			}
		}
	}
	
	private function onLookAtObjectChanged(event:Object3DEvent):Void
	{
		notifyUpdate();
	}
}