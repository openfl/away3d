package away3d.cameras.lenses;

import away3d.core.math.*;

import openfl.geom.*; 
import openfl.Vector;

/**
 * The PerspectiveLens object provides a projection matrix that projects 3D geometry with perspective distortion.
 */
class PerspectiveLens extends LensBase
{
	public var coordinateSystem(get, set):Int;
	public var fieldOfView(get, set):Float;
	public var focalLength(get, set):Float;
	
	private var _fieldOfView:Float;
	private var _focalLength:Float;
	private var _focalLengthInv:Float;
	private var _yMax:Float;
	private var _xMax:Float;
	private var _coordinateSystem:Int;
	
	/**
	 * Creates a new PerspectiveLens object.
	 *
	 * @param fieldOfView The vertical field of view of the projection.
	 */
	public function new(fieldOfView:Float = 60, coordinateSystem:Int = 0)
	{
		super();
		
		this.fieldOfView = fieldOfView;
		this.coordinateSystem = coordinateSystem;
	}
	
	/**
	 * The vertical field of view of the projection in degrees.
	 */
	private function get_fieldOfView():Float
	{
		return _fieldOfView;
	}
	
	private function set_fieldOfView(value:Float):Float
	{
		if (value == _fieldOfView)
			return value;
		
		_fieldOfView = value;
		
		_focalLengthInv = Math.tan(_fieldOfView*Math.PI/360);
		_focalLength = 1/_focalLengthInv;
		
		invalidateMatrix();
		return value;
	}
	
	/**
	 * The focal length of the projection in units of viewport height.
	 */
	private function get_focalLength():Float
	{
		return _focalLength;
	}
	
	private function set_focalLength(value:Float):Float
	{
		if (value == _focalLength)
			return value;
		
		_focalLength = value;
		
		_focalLengthInv = 1/_focalLength;
		_fieldOfView = Math.atan(_focalLengthInv)*360/Math.PI;
		
		invalidateMatrix();
		return value;
	}
	
	/**
	 * Calculates the scene position relative to the camera of the given normalized coordinates in screen space.
	 *
	 * @param nX The normalised x coordinate in screen space, -1 corresponds to the left edge of the viewport, 1 to the right.
	 * @param nY The normalised y coordinate in screen space, -1 corresponds to the top edge of the viewport, 1 to the bottom.
	 * @param sZ The z coordinate in screen space, representing the distance into the screen.
	 * @param v The destination Vector3D object
	 * @return The scene position relative to the camera of the given screen coordinates.
	 */
	override public function unproject(nX:Float, nY:Float, sZ:Float, v:Vector3D = null):Vector3D
	{
		if (v == null) v = new Vector3D();
		v.x = nX;
		v.y = -nY;
		v.z = sZ;
		v.w = 1;
		
		v.x *= sZ;
		v.y *= sZ;
		
		Matrix3DUtils.transformVector(unprojectionMatrix, v, v);
		
		//z is unaffected by transform
		v.z = sZ;
		
		return v;
	}
	
	override public function clone():LensBase
	{
		var clone:PerspectiveLens = new PerspectiveLens(_fieldOfView);
		clone._near = _near;
		clone._far = _far;
		clone._aspectRatio = _aspectRatio;
		clone._coordinateSystem = _coordinateSystem;
		return clone;
	}
	
	/**
	 * The handedness of the coordinate system projection. The default is LEFT_HANDED.
	 */
	private function get_coordinateSystem():Int
	{
		return _coordinateSystem;
	}

	private function set_coordinateSystem(value:Int):Int
	{
		if (value == _coordinateSystem)
			return value;
		
		_coordinateSystem = value;
		
		invalidateMatrix();
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateMatrix():Void
	{
		var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
		
		_yMax = _near*_focalLengthInv;
		_xMax = _yMax*_aspectRatio;
		
		var left:Float, right:Float, top:Float, bottom:Float;
		
		if (_scissorRect.x == 0 && _scissorRect.y == 0 && _scissorRect.width == _viewPort.width && _scissorRect.height == _viewPort.height) {
			// assume unscissored frustum
			left = -_xMax;
			right = _xMax;
			top = -_yMax;
			bottom = _yMax;
			
			// assume unscissored frustum
			raw[0] = _near/_xMax;
			raw[5] = _near/_yMax;
			raw[10] = _far/(_far - _near);
			raw[11] = 1;
			raw[1] = raw[(2)] = raw[(3)] = raw[(4)] =
				raw[(6)] = raw[(7)] = raw[(8)] = raw[(9)] =
				raw[(12)] = raw[(13)] = raw[(15)] = 0;
			raw[14] = -_near * raw[(10)];
		} else {
			// assume scissored frustum
			var xWidth:Float = _xMax*(_viewPort.width/_scissorRect.width);
			var yHgt:Float = _yMax*(_viewPort.height/_scissorRect.height);
			var center:Float = _xMax*(_scissorRect.x*2 - _viewPort.width)/_scissorRect.width + _xMax;
			var middle:Float = -_yMax*(_scissorRect.y*2 - _viewPort.height)/_scissorRect.height - _yMax;
			
			left = center - xWidth;
			right = center + xWidth;
			top = middle - yHgt;
			bottom = middle + yHgt;
			
			raw[0] = 2*_near/(right - left);
			raw[5] = 2*_near/(bottom - top);
			raw[8] = (right + left)/(right - left);
			raw[9] = (bottom + top)/(bottom - top);
			raw[10] = (_far + _near)/(_far - _near);
			raw[11] = 1;
			raw[1] = raw[2] = raw[3] = raw[4] =
				raw[6] = raw[7] = raw[12] = raw[13] = raw[15] = 0;
			raw[14] = -2*_far*_near/(_far - _near);
		}

		// Switch projection transform from left to right handed.
		if (_coordinateSystem == CoordinateSystem.RIGHT_HANDED)
			raw[(5)] = -raw[(5)];

		_matrix.copyRawDataFrom(raw);
		
		var yMaxFar:Float = _far*_focalLengthInv;
		var xMaxFar:Float = yMaxFar*_aspectRatio;
		
		_frustumCorners[0] = _frustumCorners[9] = left;
		_frustumCorners[3] = _frustumCorners[6] = right;
		_frustumCorners[1] = _frustumCorners[4] = top;
		_frustumCorners[7] = _frustumCorners[10] = bottom;
		
		_frustumCorners[12] = _frustumCorners[21] = -xMaxFar;
		_frustumCorners[15] = _frustumCorners[18] = xMaxFar;
		_frustumCorners[13] = _frustumCorners[16] = -yMaxFar;
		_frustumCorners[19] = _frustumCorners[22] = yMaxFar;
		
		_frustumCorners[2] = _frustumCorners[5] = _frustumCorners[8] = _frustumCorners[11] = _near;
		_frustumCorners[14] = _frustumCorners[17] = _frustumCorners[20] = _frustumCorners[23] = _far;
		
		_matrixInvalid = false;
	}
}