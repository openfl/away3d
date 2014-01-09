package away3d.cameras.lenses;

	//import away3d.arcane;
	import away3d.core.math.Plane3D;
	import away3d.events.LensEvent;
	
	import away3d.geom.Matrix3D;
	
	import flash.geom.Vector3D;
	
	//use namespace arcane;
	
	class ObliqueNearPlaneLens extends LensBase
	{
		var _baseLens:LensBase;
		var _plane:Plane3D;
		
		public function new(baseLens:LensBase, plane:Plane3D)
		{
			this.baseLens = baseLens;
			this.plane = plane;
		}
		
		public var frustumCorners(get, null) : Array<Float>;
		
		override public function get_frustumCorners() : Array<Float>
		{
			return _baseLens.frustumCorners;
		}
		
		public var near(get, set) : Float;
		
		override public function get_near() : Float
		{
			return _baseLens.near;
		}
		
		override public function set_near(value:Float) : Float
		{
			_baseLens.near = value;
		}
		
		public var far(get, set) : Float;
		
		override public function get_far() : Float
		{
			return _baseLens.far;
		}
		
		override public function set_far(value:Float) : Float
		{
			_baseLens.far = value;
		}
		
		public var aspectRatio(get, set) : Float;
		
		override public function get_aspectRatio() : Float
		{
			return _baseLens.aspectRatio;
		}
		
		override public function set_aspectRatio(value:Float) : Float
		{
			_baseLens.aspectRatio = value;
		}
		
		public var plane(get, set) : Plane3D;
		
		public function get_plane() : Plane3D
		{
			return _plane;
		}
		
		public function set_plane(value:Plane3D) : Plane3D
		{
			_plane = value;
			invalidateMatrix();
		}
		
		public var baseLens(null, set) : Void;
		
		public function set_baseLens(value:LensBase) : Void
		{
			if (_baseLens)
				_baseLens.removeEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);
			
			_baseLens = value;
			
			if (_baseLens)
				_baseLens.addEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);
			
			invalidateMatrix();
		}
		
		private function onLensMatrixChanged(event:LensEvent):Void
		{
			invalidateMatrix();
		}
		
		override private function updateMatrix():Void
		{
			_matrix.copyFrom(_baseLens.matrix);
			
			var cx:Float = _plane.a;
			var cy:Float = _plane.b;
			var cz:Float = _plane.c;
			var cw:Float = -_plane.d + .05;
			var signX:Float = cx >= 0? 1 : -1;
			var signY:Float = cy >= 0? 1 : -1;
			var p:Vector3D = new Vector3D(signX, signY, 1, 1);
			var inverse:Matrix3D = _matrix.clone();
			inverse.invert();
			var q:Vector3D = inverse.transformVector(p);
			_matrix.copyRowTo(3, p);
			var a:Float = (q.x*p.x + q.y*p.y + q.z*p.z + q.w*p.w)/(cx*q.x + cy*q.y + cz*q.z + cw*q.w);
			_matrix.copyRowFrom(2, new Vector3D(cx*a, cy*a, cz*a, cw*a));
		}
	}

