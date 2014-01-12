package away3d.primitives;

	import flash.geom.Vector3D;
	
	/**
	 * Generates a wireframd cylinder primitive.
	 */
	class WireframeCylinder extends WireframePrimitiveBase
	{
		private static var TWO_PI:Float = 2*Math.PI;
		
		var _topRadius:Float;
		var _bottomRadius:Float;
		var _height:Float;
		var _segmentsW:UInt;
		var _segmentsH:UInt;
		
		/**
		 * Creates a new WireframeCylinder instance
		 * @param topRadius Top radius of the cylinder
		 * @param bottomRadius Bottom radius of the cylinder
		 * @param height The height of the cylinder
		 * @param segmentsW Number of radial segments
		 * @param segmentsH Number of vertical segments
		 * @param color The color of the wireframe lines
		 * @param thickness The thickness of the wireframe lines
		 */
		public function new(topRadius:Float = 50, bottomRadius:Float = 50, height:Float = 100, segmentsW:UInt = 16, segmentsH:UInt = 1, color:UInt = 0xFFFFFF, thickness:Float = 1)
		{
			super(color, thickness);
			_topRadius = topRadius;
			_bottomRadius = bottomRadius;
			_height = height;
			_segmentsW = segmentsW;
			_segmentsH = segmentsH;
		}
		
		override private function buildGeometry():Void
		{
			
			var i:UInt, j:UInt;
			var radius:Float = _topRadius;
			var revolutionAngle:Float;
			var revolutionAngleDelta:Float = TWO_PI/_segmentsW;
			var nextVertexIndex:Int = 0;
			var x:Float, y:Float, z:Float;
			var lastLayer:Array<Array<Vector3D>> = new Array<Array<Vector3D>>(_segmentsH + 1, true);
			
			// For loop conversion - 						for (j = 0; j <= _segmentsH; ++j)
			
			for (j in 0..._segmentsH) {
				lastLayer[j] = new Array<Vector3D>(_segmentsW + 1, true);
				
				radius = _topRadius - ((j/_segmentsH)*(_topRadius - _bottomRadius));
				z = -(_height/2) + (j/_segmentsH*_height);
				
				var previousV:Vector3D = null;
				
				// For loop conversion - 								for (i = 0; i <= _segmentsW; ++i)
				
				for (i in 0..._segmentsW) {
					// revolution vertex
					revolutionAngle = i*revolutionAngleDelta;
					x = radius*Math.cos(revolutionAngle);
					y = radius*Math.sin(revolutionAngle);
					var vertex:Vector3D;
					if (previousV) {
						vertex = new Vector3D(x, -z, y);
						updateOrAddSegment(nextVertexIndex++, vertex, previousV);
						previousV = vertex;
					} else
						previousV = new Vector3D(x, -z, y);
					
					if (j > 0)
						updateOrAddSegment(nextVertexIndex++, vertex, lastLayer[j - 1][i]);
					lastLayer[j][i] = previousV;
				}
			}
		}
		
		/**
		 * Top radius of the cylinder
		 */
		public var topRadius(get, set) : Float;
		public function get_topRadius() : Float
		{
			return _topRadius;
		}
		
		public function set_topRadius(value:Float) : Float
		{
			_topRadius = value;
			invalidateGeometry();
		}
		
		/**
		 * Bottom radius of the cylinder
		 */
		public var bottomRadius(get, set) : Float;
		public function get_bottomRadius() : Float
		{
			return _bottomRadius;
		}
		
		public function set_bottomRadius(value:Float) : Float
		{
			_bottomRadius = value;
			invalidateGeometry();
		}
		
		/**
		 * The height of the cylinder
		 */
		public var height(get, set) : Float;
		public function get_height() : Float
		{
			return _height;
		}
		
		public function set_height(value:Float) : Float
		{
			if (height <= 0)
				throw new Error('Height must be a value greater than zero.');
			_height = value;
			invalidateGeometry();
		}
	}

