package away3d.cameras.lenses;

import away3d.core.math.Matrix3DUtils;

import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * The PerspectiveLens object provides a projection matrix that projects 3D geometry isometrically. This entails
 * there is no perspective distortion, and lines that are parallel in the scene will remain parallel on the screen.
 */
class OrthographicLens extends LensBase
{
	public var projectionHeight(get, set):Float;
	
	private var _projectionHeight:Float;
	private var _xMax:Float;
	private var _yMax:Float;
	
	/**
	 * Creates a new OrthogonalLens object.
	 */
	public function new(projectionHeight:Float = 500)
	{
		super();
		_projectionHeight = projectionHeight;
	}
	
	/**
	 * The vertical field of view of the projection.
	 */
	private function get_projectionHeight():Float
	{
		return _projectionHeight;
	}
	
	private function set_projectionHeight(value:Float):Float
	{
		if (value == _projectionHeight)
			return value;
		_projectionHeight = value;
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
		var translation:Vector3D = Matrix3DUtils.CALCULATION_VECTOR3D;
		matrix.copyColumnTo(3, translation);
		v.x = nX + translation.x;
		v.y = -nY + translation.y;
		v.z = sZ;
		v.w = 1;

		Matrix3DUtils.transformVector(unprojectionMatrix, v, v);
		
		//z is unaffected by transform
		v.z = sZ;
		
		return v;
	}
	
	override public function clone():LensBase
	{
		var clone:OrthographicLens = new OrthographicLens();
		clone._near = _near;
		clone._far = _far;
		clone._aspectRatio = _aspectRatio;
		clone.projectionHeight = _projectionHeight;
		return clone;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateMatrix():Void
	{
		var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
		_yMax = _projectionHeight*.5;
		_xMax = _yMax*_aspectRatio;
		
		var left:Float, right:Float, top:Float, bottom:Float;
		
		if (_scissorRect.x == 0 && _scissorRect.y == 0 && _scissorRect.width == _viewPort.width && _scissorRect.height == _viewPort.height) {
			// assume symmetric frustum
			
			left = -_xMax;
			right = _xMax;
			top = -_yMax;
			bottom = _yMax;
			raw[(0)] = 2/(_projectionHeight*_aspectRatio);
			raw[(5)] = 2/_projectionHeight;
			raw[(10)] = 1/(_far - _near);
			raw[(14)] = _near/(_near - _far);
			raw[(1)] = raw[(2)] = raw[(3)] = raw[(4)] =
				raw[(6)] = raw[(7)] = raw[(8)] = raw[(9)] =
				raw[(11)] = raw[(12)] = raw[(13)] = 0;
			raw[(15)] = 1;
			
		} else {
			
			var xWidth:Float = _xMax*(_viewPort.width/_scissorRect.width);
			var yHgt:Float = _yMax*(_viewPort.height/_scissorRect.height);
			var center:Float = _xMax*(_scissorRect.x*2 - _viewPort.width)/_scissorRect.width + _xMax;
			var middle:Float = -_yMax*(_scissorRect.y*2 - _viewPort.height)/_scissorRect.height - _yMax;
			
			left = center - xWidth;
			right = center + xWidth;
			top = middle - yHgt;
			bottom = middle + yHgt;
			
			raw[(0)] = 2*1/(right - left);
			raw[(5)] = -2*1/(top - bottom);
			raw[(10)] = 1/(_far - _near);
			raw[(12)] = (right + left)/(right - left);
			raw[(13)] = (bottom + top)/(bottom - top);
			raw[(14)] = _near/(near - far);
			raw[(1)] = raw[(2)] = raw[(3)] = raw[(4)] =
				raw[(6)] = raw[(7)] = raw[(8)] = raw[(9)] = raw[(11)] = 0;
			raw[(15)] = 1;
		}
		
		_frustumCorners[0] = _frustumCorners[9] = _frustumCorners[12] = _frustumCorners[21] = left;
		_frustumCorners[3] = _frustumCorners[6] = _frustumCorners[15] = _frustumCorners[18] = right;
		_frustumCorners[1] = _frustumCorners[4] = _frustumCorners[13] = _frustumCorners[16] = top;
		_frustumCorners[7] = _frustumCorners[10] = _frustumCorners[19] = _frustumCorners[22] = bottom;
		_frustumCorners[2] = _frustumCorners[5] = _frustumCorners[8] = _frustumCorners[11] = _near;
		_frustumCorners[14] = _frustumCorners[17] = _frustumCorners[20] = _frustumCorners[23] = _far;
		
		_matrix.copyRawDataFrom(raw);
		
		_matrixInvalid = false;
	}
}
