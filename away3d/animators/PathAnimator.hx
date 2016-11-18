package away3d.animators;

import away3d.core.base.Object3D;
import away3d.core.math.Vector3DUtils;
import away3d.events.PathEvent;
import away3d.paths.IPath;
import away3d.paths.IPathSegment;

import openfl.errors.Error;
import openfl.events.EventDispatcher;
import openfl.geom.Vector3D;
import openfl.Vector;

class PathAnimator extends EventDispatcher
{
	public var upAxis(get, set):Vector3D;
	public var alignToPath(get, set):Bool;
	public var position(get, never):Vector3D;
	public var path(get, set):IPath;
	public var progress(get, set):Float;
	public var orientation(get, never):Vector3D;
	public var target(get, set):Object3D;
	public var lookAtObject(get, set):Object3D;
	public var rotations(never, set):Vector<Vector3D>;
	public var index(get, set):Int;
	
	private var _path:IPath;
	private var _time:Float;
	private var _index:Int = 0;
	private var _rotations:Vector<Vector3D>;
	private var _alignToPath:Bool;
	private var _target:Object3D;
	private var _lookAtTarget:Object3D;
	private var _offset:Vector3D;
	private var _tmpOffset:Vector3D;
	private var _position:Vector3D = new Vector3D();
	private var _lastTime:Float;
	private var _from:Float;
	private var _to:Float;
	private var _bRange:Bool;
	private var _bSegment:Bool;
	private var _bCycle:Bool;
	private var _lastSegment:Int = 0;
	private var _rot:Vector3D;
	private var _upAxis:Vector3D = new Vector3D(0, 1, 0);
	private var _basePosition:Vector3D = new Vector3D(0, 0, 0);
	
	/**
	 * Creates a new <code>PathAnimator</code>
	 *
	 * @param                 [optional] path                The QuadraticPath to animate onto.
	 * @param                 [optional] target              An Object3D, the object to animate along the path. It can be Mesh, Camera, ObjectContainer3D...
	 * @param                 [optional] offset              A Vector3D to define the target offset to its location on the path.
	 * @param                 [optional] alignToPath         Defines if the object animated along the path is orientated to the path. Default is true.
	 * @param                 [optional] lookAtTarget        An Object3D that the target will constantly look at during animation.
	 * @param                 [optional] rotations           A Vector.&lt;Vector3D&gt; to define rotations per pathsegments. If PathExtrude is used to simulate the "road", use the very same rotations vector.
	 */
	public function new(path:IPath = null, target:Object3D = null, offset:Vector3D = null, alignToPath:Bool = true, lookAtTarget:Object3D = null, rotations:Vector<Vector3D> = null)
	{
		_index = 0;
		_time = _lastTime = 0;
		
		_path = path;
		
		_target = target;
		_alignToPath = alignToPath;
		_lookAtTarget = lookAtTarget;
		
		super();
		
		if (offset != null)
			setOffset(offset.x, offset.y, offset.z);
		
		this.rotations = rotations;
		
		if (_lookAtTarget != null && _alignToPath)
			_alignToPath = false;
	}
	
	private function get_upAxis():Vector3D
	{
		return _upAxis;
	}
	
	private function set_upAxis(value:Vector3D):Vector3D
	{
		return _upAxis = value;
	}
	
	/**
	 * sets an optional offset to the position on the path, ideal for cameras or reusing the same <code>Path</code> object for parallel animations
	 */
	public function setOffset(x:Float = 0, y:Float = 0, z:Float = 0):Void
	{
		if (_offset == null)
			_offset = new Vector3D();
		
		_offset.x = x;
		_offset.y = y;
		_offset.z = z;
	}
	
	/**
	 * Calculates the new position and set the object on the path accordingly
	 *
	 * @param t     A Number  from 0 to 1  (less than one to allow alignToPath)
	 */
	public function updateProgress(t:Float):Void
	{
		if (_path == null)
			throw new Error("No Path object set for this class");
		
		if (t <= 0) {
			t = 0;
			_lastSegment = 0;
			
		} else if (t >= 1) {
			t = 1;
			_lastSegment = _path.numSegments - 1;
		}
		
		if (_bCycle && t <= 0.1 && _lastSegment == _path.numSegments - 1)
			dispatchEvent(new PathEvent(PathEvent.CYCLE));
		
		_lastTime = t;
		
		var multi:Float = _path.numSegments*t;
		_index = Std.int(multi);
		
		if (_index == _path.numSegments)
			index--;
		
		if (_offset != null)
			_target.position = _basePosition;
		
		var nT:Float = multi - _index;
		updatePosition(nT, _path.segments[_index]);
		
		var rotate:Bool = false;
		if (_lookAtTarget != null) {
			
			if (_offset != null) {
				_target.moveRight(_offset.x);
				_target.moveUp(_offset.y);
				_target.moveForward(_offset.z);
			}
			_target.lookAt(_lookAtTarget.position);
			
		} else if (_alignToPath) {
			
			if (_rotations != null && _rotations.length > 0) {
				
				if (_rotations[_index + 1] == null) {
					
					_rot.x = _rotations[_rotations.length - 1].x*nT;
					_rot.y = _rotations[_rotations.length - 1].y*nT;
					_rot.z = _rotations[_rotations.length - 1].z*nT;
					
				} else {
					
					_rot.x = _rotations[_index].x + ((_rotations[_index + 1].x - _rotations[_index].x)*nT);
					_rot.y = _rotations[_index].y + ((_rotations[_index + 1].y - _rotations[_index].y)*nT);
					_rot.z = _rotations[_index].z + ((_rotations[_index + 1].z - _rotations[_index].z)*nT);
					
				}
				
				_upAxis.x = 0;
				_upAxis.y = 1;
				_upAxis.z = 0;
				_upAxis = Vector3DUtils.rotatePoint(_upAxis, _rot);
				
				_target.lookAt(_basePosition, _upAxis);
				
				rotate = true;
				
			} else
				_target.lookAt(_position);
			
		}
		
		updateObjectPosition(rotate);
		
		if (_bSegment && _index > 0 && _lastSegment != _index && t < 1) 
			dispatchEvent(new PathEvent(PathEvent.CHANGE_SEGMENT));
		
		if (_bRange && (t >= _from && t <= _to))
			dispatchEvent(new PathEvent(PathEvent.RANGE));
		
		_time = t;
		_lastSegment = _index;
	}
	
	/**
	 * Updates a position Vector3D on the path at a given time. Do not use this handler to animate, it's in there to add dummy's or place camera before or after
	 * the animated object. Use the update() or the automatic tweened animateOnPath() handlers instead.
	 *
	 * @param t      Number. A Number  from 0 to 1
	 * @param out    Vector3D. The Vector3D to update according to the "t" time parameter.
	 */
	public function getPositionOnPath(t:Float, out:Vector3D):Vector3D
	{
		if (_path == null)
			throw new Error("No Path object set for this class");
		
		t = (t < 0) ? 0 : (t > 1) ? 1 : t;
		var m:Float = _path.numSegments*t;
		var i:Int = Std.int(m);
		var ps:IPathSegment = _path.segments[i];
		
		return ps.getPointOnSegment(m - i, out);
	}
	
	/**
	 * Returns a position on the path according to duration/elapsed time. Duration variable must be set.
	 *
	 * @param        ms            Number. A number representing milliseconds.
	 * @param        duration        Number. The total duration in milliseconds.
	 * @param        out            [optional] Vector3D. A Vector3D that will be used to return the position. If none provided, method returns a new Vector3D with this data.
	 *
	 * An example of use of this handler would be cases where a given "lap" must be done in a given amount of time and you would want to retrieve the "ideal" time
	 * based on elapsed time since start of the race. By comparing actual progress to ideal time, you could extract their classement, calculate distance/time between competitors,
	 * abort the race if goal is impossible to be reached in time etc...
	 *
	 *@ returns Vector3D The position at a given elapsed time, compared to total duration.
	 */
	public function getPositionOnPathMS(ms:Float, duration:Float, out:Vector3D):Vector3D
	{
		if (_path == null)
			throw new Error("No Path object set for this class");
		
		var t:Float = Math.abs(ms) / duration;
		t = (t < 0)? 0 : (t > 1)? 1 : t;
		var m:Float = _path.numSegments*t;
		var i:Int = Std.int(m);
		var ps:IPathSegment = _path.segments[i];
		
		return ps.getPointOnSegment(m - i, out);
	}
	
	/**
	 * defines if the object animated along the path must be aligned to the path.
	 */
	private function set_alignToPath(b:Bool):Bool
	{
		return _alignToPath = b;
	}
	
	private function get_alignToPath():Bool
	{
		return _alignToPath;
	}
	
	/**
	 * returns the current interpolated position on the path with no optional offset applied
	 */
	private function get_position():Vector3D
	{
		return _position;
	}
	
	/**
	 * defines the path to follow
	 * @see Path
	 */
	private function set_path(value:IPath):IPath
	{
		return _path = value;
	}
	
	private function get_path():IPath
	{
		return _path;
	}
	
	/**
	 * Represents the progress of the animation playhead from the start (0) to the end (1) of the animation.
	 */
	private function get_progress():Float
	{
		return _time;
	}
	
	private function set_progress(val:Float):Float
	{
		if (_time == val)
			return val;
		
		updateProgress(val);
		return val;
	}
	
	/**
	 * returns the segment index that is used at a given time;
	 * @param     t        [Number]. A Number between 0 and 1. If no params, actual pathanimator time segment index is returned.
	 */
	public function getTimeSegment(?t:Float = null):Float
	{
		t = ((Math.isNaN(t))) ? _time : t;
		return Math.floor(_path.numSegments*t);
	}
	
	/**
	 * returns the actual interpolated rotation along the path.
	 */
	private function get_orientation():Vector3D
	{
		return _rot;
	}
	
	/**
	 * sets the object to be animated along the path.
	 */
	private function set_target(object3d:Object3D):Object3D
	{
		return _target = object3d;
	}
	
	private function get_target():Object3D
	{
		return _target;
	}
	
	/**
	 * sets the object that the animated object will be looking at along the path
	 */
	private function set_lookAtObject(object3d:Object3D):Object3D
	{
		_lookAtTarget = object3d;
		if (_alignToPath)
			_alignToPath = false;
		return object3d;
	}
	
	private function get_lookAtObject():Object3D
	{
		return _lookAtTarget;
	}
	
	/**
	 * sets an optional Vector.&lt;Vector3D&gt; of rotations. if the object3d is animated along a PathExtrude object, use the very same vector to follow the "curves".
	 */
	private function set_rotations(value:Vector<Vector3D>):Vector<Vector3D>
	{
		_rotations = value;
		
		if (_rotations != null && _rot == null) {
			_rot = new Vector3D();
			_tmpOffset = new Vector3D();
		}
		return value;
	}
	
	/**
	 * Set the pointer to a given segment along the path
	 */
	private function set_index(val:Int):Int
	{
		_index = (val > _path.numSegments - 1)? _path.numSegments - 1 : (val > 0)? val : 0;
		return val;
	}
	
	private function get_index():Int
	{
		return _index;
	}
	
	/**
	 * Default method for adding a cycle event listener. Event fired when the time reaches 1.
	 *
	 * @param    listener        The listener function
	 */
	public function addOnCycle(listener:Dynamic -> Void):Void
	{
		_lastTime = 0;
		_bCycle = true;
		this.addEventListener(PathEvent.CYCLE, listener);
	}
	
	/**
	 * Default method for removing a cycle event listener
	 *
	 * @param        listener        The listener function
	 */
	public function removeOnCycle(listener:Dynamic -> Void):Void
	{
		_bCycle = false;
		this.removeEventListener(PathEvent.CYCLE, listener);
	}
	
	/**
	 * Default method for adding a range event listener. Event fired when the time is &gt;= from and &lt;= to variables.
	 *
	 * @param        listener        The listener function
	 */
	//note: If there are requests for this, it could be extended to more than one rangeEvent per path.
	public function addOnRange(listener:Dynamic -> Void, from:Float = 0, to:Float = 0):Void
	{
		_from = from;
		_to = to;
		_bRange = true;
		this.addEventListener(PathEvent.RANGE, listener);
	}
	
	/**
	 * Default method for removing a range event listener
	 *
	 * @param        listener        The listener function
	 */
	public function removeOnRange(listener:Dynamic -> Void):Void
	{
		_from = 0;
		_to = 0;
		_bRange = false;
		this.removeEventListener(PathEvent.RANGE, listener);
	}
	
	/**
	 * Default method for adding a segmentchange event listener. Event fired when the time pointer enters another PathSegment.
	 *
	 * @param        listener        The listener function
	 */
	public function addOnChangeSegment(listener:Dynamic -> Void):Void
	{
		_bSegment = true;
		_lastSegment = 0;
		this.addEventListener(PathEvent.CHANGE_SEGMENT, listener);
	}
	
	/**
	 * Default method for removing a range event listener
	 *
	 * @param        listener        The listener function
	 */
	public function removeOnChangeSegment(listener:Dynamic -> Void):Void
	{
		_bSegment = false;
		_lastSegment = 0;
		this.removeEventListener(PathEvent.CHANGE_SEGMENT, listener, false);
	}
	
	private function updatePosition(t:Float, ps:IPathSegment):Void
	{
		_basePosition = ps.getPointOnSegment(t, _basePosition);
		
		_position.x = _basePosition.x;
		_position.y = _basePosition.y;
		_position.z = _basePosition.z;
	}
	
	private function updateObjectPosition(rotate:Bool = false):Void
	{
		
		if (rotate && _offset != null) {
			
			_tmpOffset.x = _offset.x;
			_tmpOffset.y = _offset.y;
			_tmpOffset.z = _offset.z;
			_tmpOffset = Vector3DUtils.rotatePoint(_tmpOffset, _rot);
			
			_position.x += _tmpOffset.x;
			_position.y += _tmpOffset.y;
			_position.z += _tmpOffset.z;
		
		} else if (_offset != null) {
			
			_position.x += _offset.x;
			_position.y += _offset.y;
			_position.z += _offset.z;
			
		}
		_target.position = _position;
	}
}