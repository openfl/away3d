package away3d.core.base;

import away3d.*;
import away3d.controllers.*;
import away3d.core.math.*;
import away3d.events.*;
import away3d.library.assets.*;

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * Object3D provides a base class for any 3D object that has a (local) transformation.<br/><br/>
 *
 * Standard Transform:
 * <ul>
 *     <li> The standard order for transformation is [parent transform] * (Translate+Pivot) * (Rotate) * (-Pivot) * (Scale) * [child transform] </li>
 *     <li> This is the order of matrix multiplications, left-to-right. </li>
 *     <li> The order of transformation is right-to-left, however!
 *          (Scale) happens before (-Pivot) happens before (Rotate) happens before (Translate+Pivot)
 *          with no pivot, the above transform works out to [parent transform] * Translate * Rotate * Scale * [child transform]
 *          (Scale) happens before (Rotate) happens before (Translate) </li>
 *     <li> This is based on code in updateTransform and ObjectContainer3D.updateSceneTransform(). </li>
 *     <li> Matrix3D prepend = operator on rhs - e.g. transform' = transform * rhs; </li>
 *     <li> Matrix3D append =  operator on lhr - e.g. transform' = lhs * transform; </li>
 * </ul>
 *
 * To affect Scale:
 * <ul>
 *     <li> set scaleX/Y/Z directly, or call scale(delta) </li>
 * </ul>
 *
 * To affect Pivot:
 * <ul>
 *     <li> set pivotPoint directly, or call movePivot() </li>
 * </ul>
 *
 * To affect Rotate:
 * <ul>
 *    <li> set rotationX/Y/Z individually (using degrees), set eulers [all 3 angles] (using radians), or call rotateTo()</li>
 *    <li> call pitch()/yaw()/roll()/rotate() to add an additional rotation *before* the current transform.
 *         rotationX/Y/Z will be reset based on these operations. </li>
 * </ul>
 *
 * To affect Translate (post-rotate translate):
 *
 * <ul>
 *    <li> set x/y/z/position or call moveTo(). </li>
 *    <li> call translate(), which modifies x/y/z based on a delta vector. </li>
 *    <li> call moveForward()/moveBackward()/moveLeft()/moveRight()/moveUp()/moveDown()/translateLocal() to add an
 *         additional translate *before* the current transform. x/y/z will be reset based on these operations. </li>
 * </ul>
 */
class Object3D extends NamedAssetBase
{
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var z(get, set):Float;
	public var rotationX(get, set):Float;
	public var rotationY(get, set):Float;
	public var rotationZ(get, set):Float;
	public var scaleX(get, set):Float;
	public var scaleY(get, set):Float;
	public var scaleZ(get, set):Float;
	public var eulers(get, set):Vector3D;
	public var transform(get, set):Matrix3D;
	public var pivotPoint(get, set):Vector3D;
	public var position(get, set):Vector3D;
	public var forwardVector(get, never):Vector3D;
	public var rightVector(get, never):Vector3D;
	public var upVector(get, never):Vector3D;
	public var backVector(get, never):Vector3D;
	public var leftVector(get, never):Vector3D;
	public var downVector(get, never):Vector3D;
	public var zOffset(get, set):Int;
	
	/** @private */
	@:allow(away3d) private var _controller:ControllerBase;
	
	private var _smallestNumber:Float = 0.0000000000000000000001;
	private var _transformDirty:Bool = true;
	
	private var _positionDirty:Bool;
	private var _rotationDirty:Bool;
	private var _scaleDirty:Bool;
	
	// TODO: not used
	// private var _positionValuesDirty:Boolean;
	// private var _rotationValuesDirty:Boolean;
	// private var _scaleValuesDirty:Boolean;
	
	private var _positionChanged:Object3DEvent;
	private var _rotationChanged:Object3DEvent;
	private var _scaleChanged:Object3DEvent;
	
	private var _rotationX:Float = 0;
	private var _rotationY:Float = 0;
	private var _rotationZ:Float = 0;
	private var _eulers:Vector3D = new Vector3D();
	
	private var _flipY:Matrix3D = new Matrix3D();
	private var _listenToPositionChanged:Bool;
	private var _listenToRotationChanged:Bool;
	private var _listenToScaleChanged:Bool;
	
	private var _zOffset:Int = 0;
	
	private function invalidatePivot():Void
	{
		_pivotZero = (_pivotPoint.x == 0) && (_pivotPoint.y == 0) && (_pivotPoint.z == 0);
		
		invalidateTransform();
	}
	
	private function invalidatePosition():Void
	{
		if (_positionDirty)
			return;
		
		_positionDirty = true;
		
		invalidateTransform();
		
		if (_listenToPositionChanged)
			notifyPositionChanged();
	}
	
	private function notifyPositionChanged():Void
	{
		if (_positionChanged == null)
			_positionChanged = new Object3DEvent(Object3DEvent.POSITION_CHANGED, this);
		
		dispatchEvent(_positionChanged);
	}
	
	override public function addEventListener(type:String, listener:Dynamic -> Void, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void
	{
		super.addEventListener(type, listener, useCapture, priority, useWeakReference);
		switch (type) {
			case Object3DEvent.POSITION_CHANGED:
				_listenToPositionChanged = true;
			case Object3DEvent.ROTATION_CHANGED:
				_listenToRotationChanged = true;
			case Object3DEvent.SCALE_CHANGED:
				_listenToScaleChanged = true;
		}
	}
	
	override public function removeEventListener(type:String, listener:Dynamic -> Void, useCapture:Bool = false):Void
	{
		super.removeEventListener(type, listener, useCapture);
		
		if (hasEventListener(type))
			return;
		
		switch (type) {
			case Object3DEvent.POSITION_CHANGED:
				_listenToPositionChanged = false;
			case Object3DEvent.ROTATION_CHANGED:
				_listenToRotationChanged = false;
			case Object3DEvent.SCALE_CHANGED:
				_listenToScaleChanged = false;
		}
	}
	
	private function invalidateRotation():Void
	{
		if (_rotationDirty)
			return;
		
		_rotationDirty = true;
		
		invalidateTransform();
		
		if (_listenToRotationChanged)
			notifyRotationChanged();
	}
	
	private function notifyRotationChanged():Void
	{
		if (_rotationChanged == null)
			_rotationChanged = new Object3DEvent(Object3DEvent.ROTATION_CHANGED, this);
		
		dispatchEvent(_rotationChanged);
	}
	
	private function invalidateScale():Void
	{
		if (_scaleDirty)
			return;
		
		_scaleDirty = true;
		
		invalidateTransform();
		
		if (_listenToScaleChanged)
			notifyScaleChanged();
	}
	
	private function notifyScaleChanged():Void
	{
		if (_scaleChanged == null)
			_scaleChanged = new Object3DEvent(Object3DEvent.SCALE_CHANGED, this);
		
		dispatchEvent(_scaleChanged);
	}
	
	private var _transform:Matrix3D = new Matrix3D();
	private var _scaleX:Float = 1;
	private var _scaleY:Float = 1;
	private var _scaleZ:Float = 1;
	private var _x:Float = 0;
	private var _y:Float = 0;
	private var _z:Float = 0;
	private var _pivotPoint:Vector3D = new Vector3D();
	private var _pivotZero:Bool = true;
	private var _pos:Vector3D = new Vector3D();
	private var _rot:Vector3D = new Vector3D();
	private var _sca:Vector3D = new Vector3D();
	private var _transformComponents:Vector<Vector3D>;
	
	/**
	 * An object that can contain any extra data.
	 */
	public var extra:Dynamic;
	
	/**
	 * Defines the x coordinate of the 3d object relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 */
	private function get_x():Float
	{
		return _x;
	}
	
	private function set_x(val:Float):Float
	{
		if (_x == val)
			return val;
		
		_x = val;
		
		invalidatePosition();
		return val;
	}
	
	/**
	 * Defines the y coordinate of the 3d object relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 */
	private function get_y():Float
	{
		return _y;
	}
	
	private function set_y(val:Float):Float
	{
		if (_y == val)
			return val;
		
		_y = val;
		
		invalidatePosition();
		return val;
	}
	
	/**
	 * Defines the z coordinate of the 3d object relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 */
	private function get_z():Float
	{
		return _z;
	}
	
	private function set_z(val:Float):Float
	{
		if (_z == val)
			return val;
		
		_z = val;
		
		invalidatePosition();
		return val;
	}
	
	/**
	 * Defines the euler angle of rotation of the 3d object around the x-axis, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 */
	private function get_rotationX():Float
	{
		return _rotationX*MathConsts.RADIANS_TO_DEGREES;
	}
	
	private function set_rotationX(val:Float):Float
	{
		if (rotationX == val)
			return val;
		
		_rotationX = val*MathConsts.DEGREES_TO_RADIANS;
		
		invalidateRotation();
		return val;
	}
	
	/**
	 * Defines the euler angle of rotation of the 3d object around the y-axis, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 */
	private function get_rotationY():Float
	{
		return _rotationY*MathConsts.RADIANS_TO_DEGREES;
	}
	
	private function set_rotationY(val:Float):Float
	{
		if (rotationY == val)
			return val;
		
		_rotationY = val*MathConsts.DEGREES_TO_RADIANS;
		
		invalidateRotation();
		return val;
	}
	
	/**
	 * Defines the euler angle of rotation of the 3d object around the z-axis, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 */
	private function get_rotationZ():Float
	{
		return _rotationZ*MathConsts.RADIANS_TO_DEGREES;
	}
	
	private function set_rotationZ(val:Float):Float
	{
		if (rotationZ == val)
			return val;
		
		_rotationZ = val*MathConsts.DEGREES_TO_RADIANS;
		
		invalidateRotation();
		return val;
	}
	
	/**
	 * Defines the scale of the 3d object along the x-axis, relative to local coordinates.
	 */
	private function get_scaleX():Float
	{
		return _scaleX;
	}
	
	private function set_scaleX(val:Float):Float
	{
		if (_scaleX == val)
			return val;
		
		_scaleX = val;
		
		invalidateScale();
		return val;
	}
	
	/**
	 * Defines the scale of the 3d object along the y-axis, relative to local coordinates.
	 */
	private function get_scaleY():Float
	{
		return _scaleY;
	}
	
	private function set_scaleY(val:Float):Float
	{
		if (_scaleY == val)
			return val;
		
		_scaleY = val;
		
		invalidateScale();
		return val;
	}
	
	/**
	 * Defines the scale of the 3d object along the z-axis, relative to local coordinates.
	 */
	private function get_scaleZ():Float
	{
		return _scaleZ;
	}
	
	private function set_scaleZ(val:Float):Float
	{
		if (_scaleZ == val)
			return val;
		
		_scaleZ = val;
		
		invalidateScale();
		return val;
	}
	
	/**
	 * Defines the rotation of the 3d object as a <code>Vector3D</code> object containing euler angles for rotation around x, y and z axis.
	 */
	private function get_eulers():Vector3D
	{
		_eulers.x = _rotationX*MathConsts.RADIANS_TO_DEGREES;
		_eulers.y = _rotationY*MathConsts.RADIANS_TO_DEGREES;
		_eulers.z = _rotationZ*MathConsts.RADIANS_TO_DEGREES;
		
		return _eulers;
	}
	
	private function set_eulers(value:Vector3D):Vector3D
	{
		_rotationX = value.x*MathConsts.DEGREES_TO_RADIANS;
		_rotationY = value.y*MathConsts.DEGREES_TO_RADIANS;
		_rotationZ = value.z*MathConsts.DEGREES_TO_RADIANS;
		
		invalidateRotation();
		return value;
	}
	
	/**
	 * The transformation of the 3d object, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 */
	private function get_transform():Matrix3D
	{
		if (_transformDirty)
			updateTransform();
		
		return _transform;
	}
	
	private function set_transform(val:Matrix3D):Matrix3D
	{
		//ridiculous matrix error
		if (val.rawData[0] == 0) {
			var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
			val.copyRawDataTo(raw);
			raw[0] = _smallestNumber;
			val.copyRawDataFrom(raw);
		}
		
		var elements:Vector<Vector3D> = Matrix3DUtils.decompose(val);
		var vec:Vector3D;
		
		vec = elements[0];
		
		if (_x != vec.x || _y != vec.y || _z != vec.z) {
			_x = vec.x;
			_y = vec.y;
			_z = vec.z;
			
			invalidatePosition();
		}
		
		vec = elements[1];
		
		if (_rotationX != vec.x || _rotationY != vec.y || _rotationZ != vec.z) {
			_rotationX = vec.x;
			_rotationY = vec.y;
			_rotationZ = vec.z;
			
			invalidateRotation();
		}
		
		vec = elements[2];
		
		if (_scaleX != vec.x || _scaleY != vec.y || _scaleZ != vec.z) {
			_scaleX = vec.x;
			_scaleY = vec.y;
			_scaleZ = vec.z;
			
			invalidateScale();
		}
		return val;
	}
	
	/**
	 * Defines the local point around which the object rotates.
	 */
	private function get_pivotPoint():Vector3D
	{
		return _pivotPoint;
	}
	
	private function set_pivotPoint(pivot:Vector3D):Vector3D
	{
		if (_pivotPoint == null) _pivotPoint = new Vector3D();
		_pivotPoint.x = pivot.x;
		_pivotPoint.y = pivot.y;
		_pivotPoint.z = pivot.z;

		invalidatePivot();
		return pivot;
	}
	
	/**
	 * Defines the position of the 3d object, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 */
	private function get_position():Vector3D
	{
		transform.copyColumnTo(3, _pos);
		
		return _pos.clone();
	}
	
	private function set_position(value:Vector3D):Vector3D
	{
		_x = value.x;
		_y = value.y;
		_z = value.z;
		
		invalidatePosition();
		return value;
	}

	/**
	 * Defines the position of the 3d object, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 * @param v the destination Vector3D
	 * @return
	 */
	public function getPosition(v:Vector3D = null):Vector3D {
		if (v == null) v = new Vector3D();
		transform.copyColumnTo(3, v);
		return v;
	}
	
	/**
	 *
	 */
	private function get_forwardVector():Vector3D
	{
		return Matrix3DUtils.getForward(transform);
	}
	
	/**
	 *
	 */
	private function get_rightVector():Vector3D
	{
		return Matrix3DUtils.getRight(transform);
	}
	
	/**
	 *
	 */
	private function get_upVector():Vector3D
	{
		return Matrix3DUtils.getUp(transform);
	}
	
	/**
	 *
	 */
	private function get_backVector():Vector3D
	{
		var director:Vector3D = Matrix3DUtils.getForward(transform);
		director.negate();
		
		return director;
	}
	
	/**
	 *
	 */
	private function get_leftVector():Vector3D
	{
		var director:Vector3D = Matrix3DUtils.getRight(transform);
		director.negate();
		
		return director;
	}

	/**
	 *
	 */
	private function get_downVector():Vector3D
	{
		var director:Vector3D = Matrix3DUtils.getUp(transform);
		director.negate();
		
		return director;
	}
	
	/**
	 * Creates an Object3D object.
	 */
	public function new()
	{
		// Cached vector of transformation components used when
		// recomposing the transform matrix in updateTransform()
		_transformComponents = new Vector<Vector3D>(3, true);
		_transformComponents[0] = _pos;
		_transformComponents[1] = _rot;
		_transformComponents[2] = _sca;
		
		_transform.identity();
		
		_flipY.appendScale(1, -1, 1);
		super();
	}
	
	/**
	 * Appends a uniform scale to the current transformation.
	 * @param value The amount by which to scale.
	 */
	public function scale(value:Float):Void
	{
		_scaleX *= value;
		_scaleY *= value;
		_scaleZ *= value;
		
		invalidateScale();
	}
	
	/**
	 * Moves the 3d object forwards along it's local z axis
	 *
	 * @param    distance    The length of the movement
	 */
	public function moveForward(distance:Float):Void
	{
		translateLocal(Vector3D.Z_AXIS, distance);
	}
	
	/**
	 * Moves the 3d object backwards along it's local z axis
	 *
	 * @param    distance    The length of the movement
	 */
	public function moveBackward(distance:Float):Void
	{
		translateLocal(Vector3D.Z_AXIS, -distance);
	}
	
	/**
	 * Moves the 3d object backwards along it's local x axis
	 *
	 * @param    distance    The length of the movement
	 */
	public function moveLeft(distance:Float):Void
	{
		translateLocal(Vector3D.X_AXIS, -distance);
	}
	
	/**
	 * Moves the 3d object forwards along it's local x axis
	 *
	 * @param    distance    The length of the movement
	 */
	public function moveRight(distance:Float):Void
	{
		translateLocal(Vector3D.X_AXIS, distance);
	}
	
	/**
	 * Moves the 3d object forwards along it's local y axis
	 *
	 * @param    distance    The length of the movement
	 */
	public function moveUp(distance:Float):Void
	{
		translateLocal(Vector3D.Y_AXIS, distance);
	}
	
	/**
	 * Moves the 3d object backwards along it's local y axis
	 *
	 * @param    distance    The length of the movement
	 */
	public function moveDown(distance:Float):Void
	{
		translateLocal(Vector3D.Y_AXIS, -distance);
	}
	
	/**
	 * Moves the 3d object directly to a point in space
	 *
	 * @param    dx        The amount of movement along the local x axis.
	 * @param    dy        The amount of movement along the local y axis.
	 * @param    dz        The amount of movement along the local z axis.
	 */
	public function moveTo(dx:Float, dy:Float, dz:Float):Void
	{
		if (_x == dx && _y == dy && _z == dz)
			return;
		_x = dx;
		_y = dy;
		_z = dz;
		
		invalidatePosition();
	}
	
	/**
	 * Moves the local point around which the object rotates.
	 *
	 * @param    dx        The amount of movement along the local x axis.
	 * @param    dy        The amount of movement along the local y axis.
	 * @param    dz        The amount of movement along the local z axis.
	 */
	public function movePivot(dx:Float, dy:Float, dz:Float):Void
	{
		if (_pivotPoint == null) _pivotPoint = new Vector3D();
		_pivotPoint.x += dx;
		_pivotPoint.y += dy;
		_pivotPoint.z += dz;
		
		invalidatePivot();
	}
	
	/**
	 * Moves the 3d object along a vector by a defined length
	 *
	 * @param    axis        The vector defining the axis of movement
	 * @param    distance    The length of the movement
	 */
	public function translate(axis:Vector3D, distance:Float):Void
	{
		var x:Float = axis.x, y:Float = axis.y, z:Float = axis.z;
		var len:Float = distance/Math.sqrt(x*x + y*y + z*z);
		
		_x += x*len;
		_y += y*len;
		_z += z*len;
		
		invalidatePosition();
	}
	
	/**
	 * Moves the 3d object along a vector by a defined length
	 *
	 * @param    axis        The vector defining the axis of movement
	 * @param    distance    The length of the movement
	 */
	public function translateLocal(axis:Vector3D, distance:Float):Void
	{
		var x:Float = axis.x, y:Float = axis.y, z:Float = axis.z;
		var len:Float = distance/Math.sqrt(x*x + y*y + z*z);
		
		transform.prependTranslation(x*len, y*len, z*len);
		
		_transform.copyColumnTo(3, _pos);
		
		_x = _pos.x;
		_y = _pos.y;
		_z = _pos.z;
		
		invalidatePosition();
	}
	
	/**
	 * Rotates the 3d object around it's local x-axis
	 *
	 * @param    angle        The amount of rotation in degrees
	 */
	public function pitch(angle:Float):Void
	{
		rotate(Vector3D.X_AXIS, angle);
	}
	
	/**
	 * Rotates the 3d object around it's local y-axis
	 *
	 * @param    angle        The amount of rotation in degrees
	 */
	public function yaw(angle:Float):Void
	{
		rotate(Vector3D.Y_AXIS, angle);
	}
	
	/**
	 * Rotates the 3d object around it's local z-axis
	 *
	 * @param    angle        The amount of rotation in degrees
	 */
	public function roll(angle:Float):Void
	{
		rotate(Vector3D.Z_AXIS, angle);
	}
	
	public function clone():Object3D
	{
		var clone:Object3D = new Object3D();
		clone.pivotPoint = pivotPoint;
		clone.transform = transform;
		clone.name = name;
		// todo: implement for all subtypes
		return clone;
	}
	
	/**
	 * Rotates the 3d object directly to a euler angle
	 *
	 * @param    ax        The angle in degrees of the rotation around the x axis.
	 * @param    ay        The angle in degrees of the rotation around the y axis.
	 * @param    az        The angle in degrees of the rotation around the z axis.
	 */
	public function rotateTo(ax:Float, ay:Float, az:Float):Void
	{
		_rotationX = ax*MathConsts.DEGREES_TO_RADIANS;
		_rotationY = ay*MathConsts.DEGREES_TO_RADIANS;
		_rotationZ = az*MathConsts.DEGREES_TO_RADIANS;
		
		invalidateRotation();
	}
	
	/**
	 * Rotates the 3d object around an axis by a defined angle
	 *
	 * @param    axis        The vector defining the axis of rotation
	 * @param    angle        The amount of rotation in degrees
	 */
	public function rotate(axis:Vector3D, angle:Float):Void
	{
		var m:Matrix3D = new Matrix3D();
		m.prependRotation(angle, axis);
		
		var vec:Vector3D = m.decompose()[1];
		
		_rotationX += vec.x;
		_rotationY += vec.y;
		_rotationZ += vec.z;
		
		invalidateRotation();
	}

	private static var tempAxeX:Vector3D;
	private static var tempAxeY:Vector3D;
	private static var tempAxeZ:Vector3D;
	/**
	 * Rotates the 3d object around to face a point defined relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 *
	 * @param    target        The vector defining the point to be looked at
	 * @param    upAxis        An optional vector used to define the desired up orientation of the 3d object after rotation has occurred
	 */
	public function lookAt(target:Vector3D, upAxis:Vector3D = null):Void
	{
		if(tempAxeX == null) tempAxeX = new Vector3D();
		if(tempAxeY == null) tempAxeY = new Vector3D();
		if(tempAxeZ == null) tempAxeZ = new Vector3D();
		var xAxis:Vector3D = tempAxeX;
		var yAxis:Vector3D = tempAxeY;
		var zAxis:Vector3D = tempAxeZ;

		var raw:Vector<Float>;
		
		if (upAxis == null) upAxis = Vector3D.Y_AXIS;

		if (_transformDirty) {
			updateTransform();
		}

		zAxis.x = target.x - _x;
		zAxis.y = target.y - _y;
		zAxis.z = target.z - _z;
		zAxis.normalize();

		xAxis.x = upAxis.y*zAxis.z - upAxis.z*zAxis.y;
		xAxis.y = upAxis.z*zAxis.x - upAxis.x*zAxis.z;
		xAxis.z = upAxis.x*zAxis.y - upAxis.y*zAxis.x;
		xAxis.normalize();
		
		if (xAxis.length < .05) {
			xAxis.x = upAxis.y;
			xAxis.y = upAxis.x;
			xAxis.z = 0;
			xAxis.normalize();
		}

		yAxis.x = zAxis.y*xAxis.z - zAxis.z*xAxis.y;
		yAxis.y = zAxis.z*xAxis.x - zAxis.x*xAxis.z;
		yAxis.z = zAxis.x*xAxis.y - zAxis.y*xAxis.x;
		
		raw = Matrix3DUtils.RAW_DATA_CONTAINER;
		
		raw[0] = _scaleX*xAxis.x;
		raw[1] = _scaleX*xAxis.y;
		raw[2] = _scaleX*xAxis.z;
		raw[3] = 0;
		
		raw[4] = _scaleY*yAxis.x;
		raw[5] = _scaleY*yAxis.y;
		raw[6] = _scaleY*yAxis.z;
		raw[7] = 0;
		
		raw[8] = _scaleZ*zAxis.x;
		raw[9] = _scaleZ*zAxis.y;
		raw[10] = _scaleZ*zAxis.z;
		raw[11] = 0;
		
		raw[12] = _x;
		raw[13] = _y;
		raw[14] = _z;
		raw[15] = 1;
		
		_transform.copyRawDataFrom(raw);
		
		transform = transform;
		
		if (zAxis.z < 0) {
			rotationY = (180 - rotationY);
			rotationX -= 180;
			rotationZ -= 180;
		}
	}
	
	/**
	 * Cleans up any resources used by the current object.
	 */
	public function dispose():Void
	{
	}
	
	/**
	 * @inheritDoc
	 */
	public function disposeAsset():Void
	{
		dispose();
	}
	
	/**
	 * Invalidates the transformation matrix, causing it to be updated upon the next request
	 */
	@:allow(away3d) private function invalidateTransform():Void
	{
		_transformDirty = true;
	}
	
	private function updateTransform():Void
	{
		_pos.x = _x;
		_pos.y = _y;
		_pos.z = _z;
		
		_rot.x = _rotationX;
		_rot.y = _rotationY;
		_rot.z = _rotationZ;

		if (!_pivotZero) {
			_sca.x = 1;
			_sca.y = 1;
			_sca.z = 1;

			_transform.recompose(_transformComponents);
			_transform.appendTranslation(_pivotPoint.x, _pivotPoint.y, _pivotPoint.z);
			_transform.prependTranslation(-_pivotPoint.x, -_pivotPoint.y, -_pivotPoint.z);
			_transform.prependScale(_scaleX, _scaleY, _scaleZ);

			_sca.x = _scaleX;
			_sca.y = _scaleY;
			_sca.z = _scaleZ;
		}else{
			_sca.x = _scaleX;
			_sca.y = _scaleY;
			_sca.z = _scaleZ;

			_transform.recompose(_transformComponents);
		}
		
		_transformDirty = false;
		_positionDirty = false;
		_rotationDirty = false;
		_scaleDirty = false;
	}
	
	private function get_zOffset():Int
	{
		return _zOffset;
	}
	
	private function set_zOffset(value:Int):Int
	{
		_zOffset = value;
		return value;
	}
}