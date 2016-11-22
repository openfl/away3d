package away3d.cameras.lenses;

import away3d.core.math.Matrix3DUtils;

import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * The PerspectiveLens object provides a projection matrix that projects 3D geometry isometrically. This entails
 * there is no perspective distortion, and lines that are parallel in the scene will remain parallel on the screen.
 */
class OrthographicOffCenterLens extends LensBase
{
	public var minX(get, set):Float;
	public var maxX(get, set):Float;
	public var minY(get, set):Float;
	public var maxY(get, set):Float;
	
	private var _minX:Float;
	private var _maxX:Float;
	private var _minY:Float;
	private var _maxY:Float;
	
	/**
	 * Creates a new OrthogonalLens object.
	 * @param fieldOfView The vertical field of view of the projection.
	 */
	public function new(minX:Float, maxX:Float, minY:Float, maxY:Float)
	{
		super();
		_minX = minX;
		_maxX = maxX;
		_minY = minY;
		_maxY = maxY;
	}
	
	private function get_minX():Float
	{
		return _minX;
	}
	
	private function set_minX(value:Float):Float
	{
		_minX = value;
		invalidateMatrix();
		return value;
	}
	
	private function get_maxX():Float
	{
		return _maxX;
	}
	
	private function set_maxX(value:Float):Float
	{
		_maxX = value;
		invalidateMatrix();
		return value;
	}
	
	private function get_minY():Float
	{
		return _minY;
	}
	
	private function set_minY(value:Float):Float
	{
		_minY = value;
		invalidateMatrix();
		return value;
	}
	
	private function get_maxY():Float
	{
		return _maxY;
	}
	
	private function set_maxY(value:Float):Float
	{
		_maxY = value;
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

		Matrix3DUtils.transformVector(unprojectionMatrix,v,v);
		
		//z is unaffected by transform
		v.z = sZ;
		
		return v;
	}
	
	override public function clone():LensBase
	{
		var clone:OrthographicOffCenterLens = new OrthographicOffCenterLens(_minX, _maxX, _minY, _maxY);
		clone._near = _near;
		clone._far = _far;
		clone._aspectRatio = _aspectRatio;
		return clone;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateMatrix():Void
	{
		var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
		var w:Float = 1/(_maxX - _minX);
		var h:Float = 1/(_maxY - _minY);
		var d:Float = 1/(_far - _near);
		
		raw[0] = 2*w;
		raw[5] = 2*h;
		raw[10] = d;
		raw[12] = -(_maxX + _minX)*w;
		raw[13] = -(_maxY + _minY)*h;
		raw[14] = -_near*d;
		raw[15] = 1;
		raw[1] = raw[2] = raw[3] = raw[4] =
			raw[6] = raw[7] = raw[8] = raw[9] = raw[11] = 0;
		_matrix.copyRawDataFrom(raw);
		
		_frustumCorners[0] = _frustumCorners[9] = _frustumCorners[12] = _frustumCorners[21] = _minX;
		_frustumCorners[3] = _frustumCorners[6] = _frustumCorners[15] = _frustumCorners[18] = _maxX;
		_frustumCorners[1] = _frustumCorners[4] = _frustumCorners[13] = _frustumCorners[16] = _minY;
		_frustumCorners[7] = _frustumCorners[10] = _frustumCorners[19] = _frustumCorners[22] = _maxY;
		_frustumCorners[2] = _frustumCorners[5] = _frustumCorners[8] = _frustumCorners[11] = _near;
		_frustumCorners[14] = _frustumCorners[17] = _frustumCorners[20] = _frustumCorners[23] = _far;
		
		_matrixInvalid = false;
	}
}