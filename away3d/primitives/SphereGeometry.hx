package away3d.primitives;

	//import away3d.arcane;
	import away3d.core.base.CompactSubGeometry;
	
	import away3d.utils.ArrayUtils;

	//use namespace arcane;
	
	/**
	 * A UV Sphere primitive mesh.
	 */
	class SphereGeometry extends PrimitiveBase
	{
		var _radius:Float;
		var _segmentsW:UInt;
		var _segmentsH:UInt;
		var _yUp:Bool;
		
		/**
		 * Creates a new Sphere object.
		 * @param radius The radius of the sphere.
		 * @param segmentsW Defines the number of horizontal segments that make up the sphere.
		 * @param segmentsH Defines the number of vertical segments that make up the sphere.
		 * @param yUp Defines whether the sphere poles should lay on the Y-axis (true) or on the Z-axis (false).
		 */
		public function new(radius:Float = 50, segmentsW:UInt = 16, segmentsH:UInt = 12, yUp:Bool = true)
		{
			super();
			
			_radius = radius;
			_segmentsW = segmentsW;
			_segmentsH = segmentsH;
			_yUp = yUp;
		}
		
		/**
		 * @inheritDoc
		 */
		private override function buildGeometry(target:CompactSubGeometry):Void
		{
			var vertices:Array<Float>;
			var indices:Array<UInt>;
			var i:UInt, j:UInt, triIndex:UInt = 0;
			var numVerts:UInt = (_segmentsH + 1)*(_segmentsW + 1);
			var stride:UInt = target.vertexStride;
			var skip:UInt = stride - 9;
			
			if (numVerts == target.numVertices) {
				vertices = target.vertexData;
				indices = target.indexData!=null ? target.indexData : ArrayUtils.Prefill(new Array<UInt>(), (_segmentsH - 1)*_segmentsW*6, 0);
			} else {
				vertices = ArrayUtils.Prefill(new Array<Float>(), numVerts*stride, 0);
				indices = ArrayUtils.Prefill(new Array<UInt>(), (_segmentsH - 1)*_segmentsW*6, 0);
				invalidateGeometry();
			}
			
			var startIndex:UInt;
			var index:UInt = target.vertexOffset;
			var comp1:Float, comp2:Float, t1:Float, t2:Float;
			
			// For loop conversion - 						for (j = 0; j <= _segmentsH; ++j)
			
			for (j in 0..._segmentsH+1) {
				
				startIndex = index;
				
				var horangle:Float = Math.PI*j/_segmentsH;
				var z:Float = -_radius*Math.cos(horangle);
				var ringradius:Float = _radius*Math.sin(horangle);
				
				// For loop conversion - 								for (i = 0; i <= _segmentsW; ++i)
				
				for (i in 0..._segmentsW+1) {
					var verangle:Float = 2*Math.PI*i/_segmentsW;
					var x:Float = ringradius*Math.cos(verangle);
					var y:Float = ringradius*Math.sin(verangle);
					var normLen:Float = 1/Math.sqrt(x*x + y*y + z*z);
					var tanLen:Float = Math.sqrt(y*y + x*x);
					
					if (_yUp) {
						t1 = 0;
						t2 = tanLen > .007? x/tanLen : 0;
						comp1 = -z;
						comp2 = y;
						
					} else {
						t1 = tanLen > .007? x/tanLen : 0;
						t2 = 0;
						comp1 = y;
						comp2 = z;
					}
					
					if (i == _segmentsW) {
						vertices[index++] = vertices[startIndex];
						vertices[index++] = vertices[startIndex + 1];
						vertices[index++] = vertices[startIndex + 2];
						vertices[index++] = vertices[startIndex + 3] + (x*normLen)*.5;
						vertices[index++] = vertices[startIndex + 4] + ( comp1*normLen)*.5;
						vertices[index++] = vertices[startIndex + 5] + (comp2*normLen)*.5;
						vertices[index++] = tanLen > .007? -y/tanLen : 1;
						vertices[index++] = t1;
						vertices[index++] = t2;
						
					} else {
						vertices[index++] = x;
						vertices[index++] = comp1;
						vertices[index++] = comp2;
						vertices[index++] = x*normLen;
						vertices[index++] = comp1*normLen;
						vertices[index++] = comp2*normLen;
						vertices[index++] = tanLen > .007? -y/tanLen : 1;
						vertices[index++] = t1;
						vertices[index++] = t2;
					}
					
					if (i > 0 && j > 0) {
						var a:Int = (_segmentsW + 1)*j + i;
						var b:Int = (_segmentsW + 1)*j + i - 1;
						var c:Int = (_segmentsW + 1)*(j - 1) + i - 1;
						var d:Int = (_segmentsW + 1)*(j - 1) + i;
						
						if (j == _segmentsH) {
							vertices[index - 9] = vertices[startIndex];
							vertices[index - 8] = vertices[startIndex + 1];
							vertices[index - 7] = vertices[startIndex + 2];
							
							indices[triIndex++] = a;
							indices[triIndex++] = c;
							indices[triIndex++] = d;
							
						} else if (j == 1) {
							indices[triIndex++] = a;
							indices[triIndex++] = b;
							indices[triIndex++] = c;
							
						} else {
							indices[triIndex++] = a;
							indices[triIndex++] = b;
							indices[triIndex++] = c;
							indices[triIndex++] = a;
							indices[triIndex++] = c;
							indices[triIndex++] = d;
						}
					}
					
					index += skip;
				}
			}
			
			target.updateData(vertices);
			target.updateIndexData(indices);
		}
		
		/**
		 * @inheritDoc
		 */
		private override function buildUVs(target:CompactSubGeometry):Void
		{
			var i:Int, j:Int;
			var stride:UInt = target.UVStride;
			var numUvs:UInt = (_segmentsH + 1)*(_segmentsW + 1)*stride;
			var data:Array<Float>;
			var skip:UInt = stride - 2;
			
			if (target.UVData!=null && numUvs == target.UVData.length)
				data = target.UVData;
			else {
				data = new Array<Float>();
				invalidateGeometry();
			}
			
			var index:Int = target.UVOffset;
			// For loop conversion - 			for (j = 0; j <= _segmentsH; ++j)
			for (j in 0..._segmentsH+1) {
				// For loop conversion - 				for (i = 0; i <= _segmentsW; ++i)
				for (i in 0..._segmentsW+1) {
					data[index++] = ( i/_segmentsW )*target.scaleU;
					data[index++] = ( j/_segmentsH )*target.scaleV;
					index += skip;
				}
			}
			
			target.updateData(data);
		}
		
		/**
		 * The radius of the sphere.
		 */
		public var radius(get, set) : Float;
		public function get_radius() : Float
		{
			return _radius;
		}
		
		public function set_radius(value:Float) : Float
		{
			_radius = value;
			invalidateGeometry();
			return value;
		}
		
		/**
		 * Defines the number of horizontal segments that make up the sphere. Defaults to 16.
		 */
		public var segmentsW(get, set) : UInt;
		public function get_segmentsW() : UInt
		{
			return _segmentsW;
		}
		
		public function set_segmentsW(value:UInt) : UInt
		{
			_segmentsW = value;
			invalidateGeometry();
			invalidateUVs();
			return value;
		}
		
		/**
		 * Defines the number of vertical segments that make up the sphere. Defaults to 12.
		 */
		public var segmentsH(get, set) : UInt;
		public function get_segmentsH() : UInt
		{
			return _segmentsH;
		}
		
		public function set_segmentsH(value:UInt) : UInt
		{
			_segmentsH = value;
			invalidateGeometry();
			invalidateUVs();
			return value;
		}
		
		/**
		 * Defines whether the sphere poles should lay on the Y-axis (true) or on the Z-axis (false).
		 */
		public var yUp(get, set) : Bool;
		public function get_yUp() : Bool
		{
			return _yUp;
		}
		
		public function set_yUp(value:Bool) : Bool
		{
			_yUp = value;
			invalidateGeometry();
			return value;
		}
	}

