package away3d.lights.shadowmaps;

import away3d.cameras.Camera3D;

import openfl.Vector;

class NearDirectionalShadowMapper extends DirectionalShadowMapper
{
	public var coverageRatio(get, set):Float;
	
	private var _coverageRatio:Float;
	
	public function new(coverageRatio:Float = .5)
	{
		super();
		this.coverageRatio = coverageRatio;
	}
	
	/**
	 * A value between 0 and 1 to indicate the ratio of the view frustum that needs to be covered by the shadow map.
	 */
	private function get_coverageRatio():Float
	{
		return _coverageRatio;
	}
	
	private function set_coverageRatio(value:Float):Float
	{
		if (value > 1)
			value = 1;
		else if (value < 0)
			value = 0;
		
		_coverageRatio = value;
		return value;
	}
	
	override private function updateDepthProjection(viewCamera:Camera3D):Void
	{
		var corners:Vector<Float> = viewCamera.lens.frustumCorners;
		
		for (i in 0...12) {
			var v:Float = corners[i];
			_localFrustum[i] = v;
			_localFrustum[i + 12] = v + (corners[i + 12] - v)*_coverageRatio;
		}
		
		updateProjectionFromFrustumCorners(viewCamera, _localFrustum, _matrix);
		_overallDepthLens.matrix = _matrix;
	}
}