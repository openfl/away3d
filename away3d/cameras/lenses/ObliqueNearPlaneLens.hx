package away3d.cameras.lenses;

import away3d.core.math.Matrix3DUtils;
import away3d.core.math.Plane3D;
import away3d.events.LensEvent;

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.Vector;

class ObliqueNearPlaneLens extends LensBase
{
	public var plane(get, set):Plane3D;
	public var baseLens(never, set):LensBase;
	
	private var _baseLens:LensBase;
	private var _plane:Plane3D;
	
	public function new(baseLens:LensBase, plane:Plane3D)
	{
		this.baseLens = baseLens;
		this.plane = plane;
		super();
	}
	
	override private function get_frustumCorners():Vector<Float>
	{
		return _baseLens.frustumCorners;
	}
	
	override private function get_near():Float
	{
		return _baseLens.near;
	}
	
	override private function set_near(value:Float):Float
	{
		_baseLens.near = value;
		return value;
	}
	
	override private function get_far():Float
	{
		return _baseLens.far;
	}
	
	override private function set_far(value:Float):Float
	{
		_baseLens.far = value;
		return value;
	}
	
	override private function get_aspectRatio():Float
	{
		return _baseLens.aspectRatio;
	}
	
	override private function set_aspectRatio(value:Float):Float
	{
		_baseLens.aspectRatio = value;
		return value;
	}
	
	private function get_plane():Plane3D
	{
		return _plane;
	}
	
	private function set_plane(value:Plane3D):Plane3D
	{
		_plane = value;
		invalidateMatrix();
		return value;
	}
	
	private function set_baseLens(value:LensBase):LensBase
	{
		if (_baseLens != null)
			_baseLens.removeEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);
		
		_baseLens = value;
		
		if (_baseLens != null)
			_baseLens.addEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);
		
		invalidateMatrix();
		return value;
	}
	
	private function onLensMatrixChanged(event:LensEvent):Void
	{
		invalidateMatrix();
	}
	
	private static var signCalculationVector:Vector3D = new Vector3D();
	override private function updateMatrix():Void
	{
		_matrix.copyFrom(_baseLens.matrix);
		
		var cx:Float = _plane.a;
		var cy:Float = _plane.b;
		var cz:Float = _plane.c;
		var cw:Float = -_plane.d + .05;
		var signX:Float = cx >= 0? 1 : -1;
		var signY:Float = cy >= 0? 1 : -1;
		var p:Vector3D = signCalculationVector;
		p.x = signX;
		p.y = signY;
		p.z = 1;
		p.w = 1;
		var inverse:Matrix3D = Matrix3DUtils.CALCULATION_MATRIX;
		inverse.copyFrom(_matrix);
		inverse.invert();
		var q:Vector3D = Matrix3DUtils.transformVector(inverse,p,Matrix3DUtils.CALCULATION_VECTOR3D);
		_matrix.copyRowTo(3, p);
		var a:Float = (q.x*p.x + q.y*p.y + q.z*p.z + q.w*p.w)/(cx*q.x + cy*q.y + cz*q.z + cw*q.w);
		p.x = cx*a;
		p.y = cy*a;
		p.z = cz*a;
		p.w = cw*a;
		_matrix.copyRowFrom(2, p);
	}
}