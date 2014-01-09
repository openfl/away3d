package away3d.lights.shadowmaps;

	//import away3d.arcane;
	import away3d.cameras.Camera3D;
	
	//use namespace arcane;
	
	class NearDirectionalShadowMapper extends DirectionalShadowMapper
	{
		var _coverageRatio:Float;
		
		public function new(coverageRatio:Float = .5)
		{
			super();
			this.coverageRatio = coverageRatio;
		}
		
		/**
		 * A value between 0 and 1 to indicate the ratio of the view frustum that needs to be covered by the shadow map.
		 */
		public var coverageRatio(get, set) : Float;
		public function get_coverageRatio() : Float
		{
			return _coverageRatio;
		}
		
		public function set_coverageRatio(value:Float) : Float
		{
			if (value > 1)
				value = 1;
			else if (value < 0)
				value = 0;
			
			_coverageRatio = value;
		}
		
		override private function updateDepthProjection(viewCamera:Camera3D):Void
		{
			var corners:Array<Float> = viewCamera.lens.frustumCorners;
			
			// For loop conversion - 						for (var i:Int = 0; i < 12; ++i)
			
			var i:Int;
			
			for (i in 0...12) {
				var v:Float = corners[i];
				_localFrustum[i] = v;
				_localFrustum[uint(i + 12)] = v + (corners[uint(i + 12)] - v)*_coverageRatio;
			}
			
			updateProjectionFromFrustumCorners(viewCamera, _localFrustum, _matrix);
			_overallDepthLens.matrix = _matrix;
		}
	}

