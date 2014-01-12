package away3d.primitives;

	//import away3d.arcane;
	import away3d.core.base.CompactSubGeometry;
	
	import away3d.utils.ArrayUtils;

	//use namespace arcane;
	
	/**
	 * A Cube primitive mesh.
	 */
	class CubeGeometry extends PrimitiveBase
	{
		var _width:Float;
		var _height:Float;
		var _depth:Float;
		var _tile6:Bool;
		
		var _segmentsW:UInt;
		var _segmentsH:UInt;
		var _segmentsD:UInt;
		
		/**
		 * Creates a new Cube object.
		 * @param width The size of the cube along its X-axis.
		 * @param height The size of the cube along its Y-axis.
		 * @param depth The size of the cube along its Z-axis.
		 * @param segmentsW The number of segments that make up the cube along the X-axis.
		 * @param segmentsH The number of segments that make up the cube along the Y-axis.
		 * @param segmentsD The number of segments that make up the cube along the Z-axis.
		 * @param tile6 The type of uv mapping to use. When true, a texture will be subdivided in a 2x3 grid, each used for a single face. When false, the entire image is mapped on each face.
		 */
		public function new(width:Float = 100, height:Float = 100, depth:Float = 100, segmentsW:UInt = 1, segmentsH:UInt = 1, segmentsD:UInt = 1, tile6:Bool = true)
		{
			super();
			
			_width = width;
			_height = height;
			_depth = depth;
			_segmentsW = segmentsW;
			_segmentsH = segmentsH;
			_segmentsD = segmentsD;
			_tile6 = tile6;
		}
		
		/**
		 * The size of the cube along its X-axis.
		 */
		public var width(get, set) : Float;
		public function get_width() : Float
		{
			return _width;
		}
		
		public function set_width(value:Float) : Float
		{
			_width = value;
			invalidateGeometry();
			return value;
		}
		
		/**
		 * The size of the cube along its Y-axis.
		 */
		public var height(get, set) : Float;
		public function get_height() : Float
		{
			return _height;
		}
		
		public function set_height(value:Float) : Float
		{
			_height = value;
			invalidateGeometry();
			return value;
		}
		
		/**
		 * The size of the cube along its Z-axis.
		 */
		public var depth(get, set) : Float;
		public function get_depth() : Float
		{
			return _depth;
		}
		
		public function set_depth(value:Float) : Float
		{
			_depth = value;
			invalidateGeometry();
			return value;
		}
		
		/**
		 * The type of uv mapping to use. When false, the entire image is mapped on each face.
		 * When true, a texture will be subdivided in a 3x2 grid, each used for a single face.
		 * Reading the tiles from left to right, top to bottom they represent the faces of the
		 * cube in the following order: bottom, top, back, left, front, right. This creates
		 * several shared edges (between the top, front, left and right faces) which simplifies
		 * texture painting.
		 */
		public var tile6(get, set) : Bool;
		public function get_tile6() : Bool
		{
			return _tile6;
		}
		
		public function set_tile6(value:Bool) : Bool
		{
			_tile6 = value;
			invalidateUVs();
			return value;
		}
		
		/**
		 * The number of segments that make up the cube along the X-axis. Defaults to 1.
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
		 * The number of segments that make up the cube along the Y-axis. Defaults to 1.
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
		 * The number of segments that make up the cube along the Z-axis. Defaults to 1.
		 */
		public var segmentsD(get, set) : UInt;
		public function get_segmentsD() : UInt
		{
			return _segmentsD;
		}
		
		public function set_segmentsD(value:UInt) : UInt
		{
			_segmentsD = value;
			invalidateGeometry();
			invalidateUVs();
			return value;
		}
		
		/**
		 * @inheritDoc
		 */
		private override function buildGeometry(target:CompactSubGeometry):Void
		{
			var data:Array<Float>;
			var indices:Array<UInt>;
			
			var tl:UInt, tr:UInt, bl:UInt, br:UInt;
			var i:UInt, j:UInt, inc:UInt = 0;
			
			var vidx:UInt, fidx:UInt; // indices
			var hw:Float, hh:Float, hd:Float; // halves
			var dw:Float, dh:Float, dd:Float; // deltas
			
			var outer_pos:Float;
			
			var numVerts:UInt = Std.int(((_segmentsW + 1)*(_segmentsH + 1) +
				(_segmentsW + 1)*(_segmentsD + 1) +
				(_segmentsH + 1)*(_segmentsD + 1))*2);
			
			var stride:UInt = target.vertexStride;
			var skip:UInt = stride - 9;
			
			if (numVerts == target.numVertices) {
				data = target.vertexData;
				indices = target.indexData!=null ? target.indexData : ArrayUtils.Prefill(new Array<UInt>(), (_segmentsW*_segmentsH + _segmentsW*_segmentsD + _segmentsH*_segmentsD)*12, 0);
			} else {
				data = ArrayUtils.Prefill(new Array<Float>(), numVerts*stride, 0);
				indices = ArrayUtils.Prefill(new Array<UInt>(), (_segmentsW*_segmentsH + _segmentsW*_segmentsD + _segmentsH*_segmentsD)*12, 0);
				invalidateUVs();
			}
			
			// Indices
			vidx = target.vertexOffset;
			fidx = 0;
			
			// half cube dimensions
			hw = _width/2;
			hh = _height/2;
			hd = _depth/2;
			
			// Segment dimensions
			dw = _width/_segmentsW;
			dh = _height/_segmentsH;
			dd = _depth/_segmentsD;
			
			// For loop conversion - 						for (i = 0; i <= _segmentsW; i++)
			
			for (i in 0..._segmentsW+1) {
				outer_pos = -hw + i*dw;
				
				// For loop conversion - 								for (j = 0; j <= _segmentsH; j++)
				
				for (j in 0..._segmentsH+1) {
					// front
					data[vidx++] = outer_pos;
					data[vidx++] = -hh + j*dh;
					data[vidx++] = -hd;
					data[vidx++] = 0;
					data[vidx++] = 0;
					data[vidx++] = -1;
					data[vidx++] = 1;
					data[vidx++] = 0;
					data[vidx++] = 0;
					vidx += skip;
					
					// back
					data[vidx++] = outer_pos;
					data[vidx++] = -hh + j*dh;
					data[vidx++] = hd;
					data[vidx++] = 0;
					data[vidx++] = 0;
					data[vidx++] = 1;
					data[vidx++] = -1;
					data[vidx++] = 0;
					data[vidx++] = 0;
					vidx += skip;
					
					if (i>0 && j>0) {
						tl = 2*((i - 1)*(_segmentsH + 1) + (j - 1));
						tr = 2*(i*(_segmentsH + 1) + (j - 1));
						bl = tl + 2;
						br = tr + 2;
						
						indices[fidx++] = tl;
						indices[fidx++] = bl;
						indices[fidx++] = br;
						indices[fidx++] = tl;
						indices[fidx++] = br;
						indices[fidx++] = tr;
						indices[fidx++] = tr + 1;
						indices[fidx++] = br + 1;
						indices[fidx++] = bl + 1;
						indices[fidx++] = tr + 1;
						indices[fidx++] = bl + 1;
						indices[fidx++] = tl + 1;
					}
				}
			}
			
			inc += 2*(_segmentsW + 1)*(_segmentsH + 1);
			
			// For loop conversion - 						for (i = 0; i <= _segmentsW; i++)
			
			for (i in 0..._segmentsW+1) {
				outer_pos = -hw + i*dw;
				
				// For loop conversion - 								for (j = 0; j <= _segmentsD; j++)
				
				for (j in 0..._segmentsD+1) {
					// top
					data[vidx++] = outer_pos;
					data[vidx++] = hh;
					data[vidx++] = -hd + j*dd;
					data[vidx++] = 0;
					data[vidx++] = 1;
					data[vidx++] = 0;
					data[vidx++] = 1;
					data[vidx++] = 0;
					data[vidx++] = 0;
					vidx += skip;
					
					// bottom
					data[vidx++] = outer_pos;
					data[vidx++] = -hh;
					data[vidx++] = -hd + j*dd;
					data[vidx++] = 0;
					data[vidx++] = -1;
					data[vidx++] = 0;
					data[vidx++] = 1;
					data[vidx++] = 0;
					data[vidx++] = 0;
					vidx += skip;
					
					if (i>0 && j>0) {
						tl = inc + 2*((i - 1)*(_segmentsD + 1) + (j - 1));
						tr = inc + 2*(i*(_segmentsD + 1) + (j - 1));
						bl = tl + 2;
						br = tr + 2;
						
						indices[fidx++] = tl;
						indices[fidx++] = bl;
						indices[fidx++] = br;
						indices[fidx++] = tl;
						indices[fidx++] = br;
						indices[fidx++] = tr;
						indices[fidx++] = tr + 1;
						indices[fidx++] = br + 1;
						indices[fidx++] = bl + 1;
						indices[fidx++] = tr + 1;
						indices[fidx++] = bl + 1;
						indices[fidx++] = tl + 1;
					}
				}
			}
			
			inc += 2*(_segmentsW + 1)*(_segmentsD + 1);
			
			// For loop conversion - 						for (i = 0; i <= _segmentsD; i++)
			
			for (i in 0..._segmentsD+1) {
				outer_pos = hd - i*dd;
				
				// For loop conversion - 								for (j = 0; j <= _segmentsH; j++)
				
				for (j in 0..._segmentsH+1) {
					// left
					data[vidx++] = -hw;
					data[vidx++] = -hh + j*dh;
					data[vidx++] = outer_pos;
					data[vidx++] = -1;
					data[vidx++] = 0;
					data[vidx++] = 0;
					data[vidx++] = 0;
					data[vidx++] = 0;
					data[vidx++] = -1;
					vidx += skip;
					
					// right
					data[vidx++] = hw;
					data[vidx++] = -hh + j*dh;
					data[vidx++] = outer_pos;
					data[vidx++] = 1;
					data[vidx++] = 0;
					data[vidx++] = 0;
					data[vidx++] = 0;
					data[vidx++] = 0;
					data[vidx++] = 1;
					vidx += skip;
					
					if (i>0 && j>0) {
						tl = inc + 2*((i - 1)*(_segmentsH + 1) + (j - 1));
						tr = inc + 2*(i*(_segmentsH + 1) + (j - 1));
						bl = tl + 2;
						br = tr + 2;
						
						indices[fidx++] = tl;
						indices[fidx++] = bl;
						indices[fidx++] = br;
						indices[fidx++] = tl;
						indices[fidx++] = br;
						indices[fidx++] = tr;
						indices[fidx++] = tr + 1;
						indices[fidx++] = br + 1;
						indices[fidx++] = bl + 1;
						indices[fidx++] = tr + 1;
						indices[fidx++] = bl + 1;
						indices[fidx++] = tl + 1;
					}
				}
			}
			
			target.updateData(data);
			target.updateIndexData(indices);
		}
		
		/**
		 * @inheritDoc
		 */
		override private function buildUVs(target:CompactSubGeometry):Void
		{
			var i:UInt, j:UInt, uidx:UInt;
			var data:Array<Float>;
			
			var u_tile_dim:Float, v_tile_dim:Float;
			var u_tile_step:Float, v_tile_step:Float;
			var tl0u:Float, tl0v:Float;
			var tl1u:Float, tl1v:Float;
			var du:Float, dv:Float;
			var stride:UInt = target.UVStride;
			var numUvs:UInt = ((_segmentsW + 1)*(_segmentsH + 1) +
				(_segmentsW + 1)*(_segmentsD + 1) +
				(_segmentsH + 1)*(_segmentsD + 1))*2*stride;
			var skip:UInt = stride - 2;
			
			if (target.UVData!=null && numUvs == target.UVData.length)
				data = target.UVData;
			else {
				data = ArrayUtils.Prefill(new Array<Float>(), numUvs, 0);
				invalidateGeometry();
			}
			
			if (_tile6) {
				u_tile_dim = u_tile_step = 1/3;
				v_tile_dim = v_tile_step = 1/2;
			} else {
				u_tile_dim = v_tile_dim = 1;
				u_tile_step = v_tile_step = 0;
			}
			
			// Create planes two and two, the same way that they were
			// constructed in the buildGeometry() function. First calculate
			// the top-left UV coordinate for both planes, and then loop
			// over the points, calculating the UVs from these numbers.
			
			// When tile6 is true, the layout is as follows:
			//       .-----.-----.-----. (1,1)
			//       | Bot |  T  | Bak |
			//       |-----+-----+-----|
			//       |  L  |  F  |  R  |
			// (0,0)'-----'-----'-----'
			
			uidx = target.UVOffset;
			
			// FRONT / BACK
			tl0u = 1*u_tile_step;
			tl0v = 1*v_tile_step;
			tl1u = 2*u_tile_step;
			tl1v = 0*v_tile_step;
			du = u_tile_dim/_segmentsW;
			dv = v_tile_dim/_segmentsH;
			// For loop conversion - 			for (i = 0; i <= _segmentsW; i++)
			for (i in 0..._segmentsW+1) {
				// For loop conversion - 				for (j = 0; j <= _segmentsH; j++)
				for (j in 0..._segmentsH+1) {
					data[uidx++] = ( tl0u + i*du )*target.scaleU;
					data[uidx++] = ( tl0v + (v_tile_dim - j*dv))*target.scaleV;
					uidx += skip;
					data[uidx++] = ( tl1u + (u_tile_dim - i*du))*target.scaleU;
					data[uidx++] = ( tl1v + (v_tile_dim - j*dv))*target.scaleV;
					uidx += skip;
				}
			}
			
			// TOP / BOTTOM
			tl0u = 1*u_tile_step;
			tl0v = 0*v_tile_step;
			tl1u = 0*u_tile_step;
			tl1v = 0*v_tile_step;
			du = u_tile_dim/_segmentsW;
			dv = v_tile_dim/_segmentsD;
			// For loop conversion - 			for (i = 0; i <= _segmentsW; i++)
			for (i in 0..._segmentsW+1) {
				// For loop conversion - 				for (j = 0; j <= _segmentsD; j++)
				for (j in 0..._segmentsD+1) {
					data[uidx++] = ( tl0u + i*du)*target.scaleU;
					data[uidx++] = ( tl0v + (v_tile_dim - j*dv))*target.scaleV;
					uidx += skip;
					data[uidx++] = ( tl1u + i*du)*target.scaleU;
					data[uidx++] = ( tl1v + j*dv)*target.scaleV;
					uidx += skip;
				}
			}
			
			// LEFT / RIGHT
			tl0u = 0*u_tile_step;
			tl0v = 1*v_tile_step;
			tl1u = 2*u_tile_step;
			tl1v = 1*v_tile_step;
			du = u_tile_dim/_segmentsD;
			dv = v_tile_dim/_segmentsH;
			// For loop conversion - 			for (i = 0; i <= _segmentsD; i++)
			for (i in 0..._segmentsD+1) {
				// For loop conversion - 				for (j = 0; j <= _segmentsH; j++)
				for (j in 0..._segmentsH+1) {
					data[uidx++] = ( tl0u + i*du)*target.scaleU;
					data[uidx++] = ( tl0v + (v_tile_dim - j*dv))*target.scaleV;
					uidx += skip;
					data[uidx++] = ( tl1u + (u_tile_dim - i*du))*target.scaleU;
					data[uidx++] = ( tl1v + (v_tile_dim - j*dv))*target.scaleV;
					uidx += skip;
				}
			}
			
			target.updateData(data);
		}
	}

