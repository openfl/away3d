package away3d.primitives;

	//import away3d.arcane;
	import away3d.core.base.CompactSubGeometry;
	
	//use namespace arcane;
	
	/**
	 * A Plane primitive mesh.
	 */
	class PlaneGeometry extends PrimitiveBase
	{
		var _segmentsW:UInt;
		var _segmentsH:UInt;
		var _yUp:Bool;
		var _width:Float;
		var _height:Float;
		var _doubleSided:Bool;
		
		/**
		 * Creates a new Plane object.
		 * @param width The width of the plane.
		 * @param height The height of the plane.
		 * @param segmentsW The number of segments that make up the plane along the X-axis.
		 * @param segmentsH The number of segments that make up the plane along the Y or Z-axis.
		 * @param yUp Defines whether the normal vector of the plane should point along the Y-axis (true) or Z-axis (false).
		 * @param doubleSided Defines whether the plane will be visible from both sides, with correct vertex normals.
		 */
		public function new(width:Float = 100, height:Float = 100, segmentsW:UInt = 1, segmentsH:UInt = 1, yUp:Bool = true, doubleSided:Bool = false)
		{
			super();
			
			_segmentsW = segmentsW;
			_segmentsH = segmentsH;
			_yUp = yUp;
			_width = width;
			_height = height;
			_doubleSided = doubleSided;
		}
		
		/**
		 * The number of segments that make up the plane along the X-axis. Defaults to 1.
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
			return _segmentsW;
		}
		
		/**
		 * The number of segments that make up the plane along the Y or Z-axis, depending on whether yUp is true or
		 * false, respectively. Defaults to 1.
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
			return _segmentsH;
		}
		
		/**
		 *  Defines whether the normal vector of the plane should point along the Y-axis (true) or Z-axis (false). Defaults to true.
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
			return _yUp;
		}
		
		/**
		 * Defines whether the plane will be visible from both sides, with correct vertex normals (as opposed to bothSides on Material). Defaults to false.
		 */
		public var doubleSided(get, set) : Bool;
		public function get_doubleSided() : Bool
		{
			return _doubleSided;
		}
		
		public function set_doubleSided(value:Bool) : Bool
		{
			_doubleSided = value;
			invalidateGeometry();
			return _doubleSided;
		}
		
		/**
		 * The width of the plane.
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
			return _width;
		}
		
		/**
		 * The height of the plane.
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
			return _height;
		}
		
		/**
		 * @inheritDoc
		 */
		private override function buildGeometry(target:CompactSubGeometry):Void
		{
			var data:Array<Float>;
			var indices:Array<UInt>;
			var x:Float, y:Float;
			var numIndices:UInt;
			var base:UInt;
			var tw:UInt = _segmentsW + 1;
			var numVertices:UInt = (_segmentsH + 1)*tw;
			var stride:UInt = target.vertexStride;
			var skip:UInt = stride - 9;
			if (_doubleSided)
				numVertices *= 2;
			
			numIndices = _segmentsH*_segmentsW*6;
			if (_doubleSided)
				numIndices <<= 1;
			
			if (numVertices == target.numVertices) {
				data = target.vertexData;
				indices = target.indexData!=null ? target.indexData : new Array<UInt>();
			} else {
				data = new Array<Float>();
				for (ctr in 0...numVertices*stride) data[ctr]=0;
				indices = new Array<UInt>();
				for (ctr in 0...numIndices) indices[ctr]=0;
				invalidateUVs();
			}
			
			numIndices = 0;
			var index:UInt = target.vertexOffset;
			// For loop conversion - 			for (var yi:UInt = 0; yi <= _segmentsH; ++yi)
			var yi:UInt;
			for (yi in 0..._segmentsH+1) {
				// For loop conversion - 				for (var xi:UInt = 0; xi <= _segmentsW; ++xi)
				var xi:UInt;
				for (xi in 0..._segmentsW+1) {
					x = (xi/_segmentsW - .5)*_width;
					y = (yi/_segmentsH - .5)*_height;

					data[index++] = x;
					if (_yUp) {
						data[index++] = 0;
						data[index++] = y;
					} else {
						data[index++] = y;
						data[index++] = 0;
					}
					
					data[index++] = 0;
					if (_yUp) {
						data[index++] = 1;
						data[index++] = 0;
					} else {
						data[index++] = 0;
						data[index++] = -1;
					}
					
					data[index++] = 1;
					data[index++] = 0;
					data[index++] = 0;
					
					index += skip;
					
					// add vertex with same position, but with inverted normal & tangent
					if (_doubleSided) {
						// For loop conversion - 						for (var i:Int = 0; i < 3; ++i)
						var i:Int;
						for (i in 0...3) {
							data[index] = data[index - stride];
							++index;
						}
						// For loop conversion - 						for (i = 0; i < 3; ++i)
						for (i in 0...3) {
							data[index] = -data[index - stride];
							++index;
						}
						// For loop conversion - 						for (i = 0; i < 3; ++i)
						for (i in 0...3) {
							data[index] = -data[index - stride];
							++index;
						}
						index += skip;
					}
					
					if (xi != _segmentsW && yi != _segmentsH) {
						base = xi + yi*tw;
						var mult:Int = _doubleSided? 2 : 1;
						
						indices[numIndices++] = base*mult;
						indices[numIndices++] = (base + tw)*mult;
						indices[numIndices++] = (base + tw + 1)*mult;
						indices[numIndices++] = base*mult;
						indices[numIndices++] = (base + tw + 1)*mult;
						indices[numIndices++] = (base + 1)*mult;
						
						if (_doubleSided) {
							indices[numIndices++] = (base + tw + 1)*mult + 1;
							indices[numIndices++] = (base + tw)*mult + 1;
							indices[numIndices++] = base*mult + 1;
							indices[numIndices++] = (base + 1)*mult + 1;
							indices[numIndices++] = (base + tw + 1)*mult + 1;
							indices[numIndices++] = base*mult + 1;
						}
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
			var data:Array<Float>;
			var stride:UInt = target.UVStride;
			var numUvs:UInt = (_segmentsH + 1)*(_segmentsW + 1)*stride;
			var skip:UInt = stride - 2;
			
			if (_doubleSided)
				numUvs *= 2;
			
			if (target.UVData!=null && numUvs == target.UVData.length)
				data = target.UVData;
			else {
				data = new Array<Float>();
				invalidateGeometry();
			}
			
			var index:UInt = target.UVOffset;
			
			// For loop conversion - 						for (var yi:UInt = 0; yi <= _segmentsH; ++yi)
			
			var yi:UInt;
			
			for (yi in 0..._segmentsH+1) {
				// For loop conversion - 				for (var xi:UInt = 0; xi <= _segmentsW; ++xi)
				var xi:UInt;
				for (xi in 0..._segmentsW+1) {
					data[index++] = (xi/_segmentsW)*target.scaleU;
					data[index++] = (1 - yi/_segmentsH)*target.scaleV;
					index += skip;
					
					if (_doubleSided) {
						data[index++] = (xi/_segmentsW)*target.scaleU;
						data[index++] = (1 - yi/_segmentsH)*target.scaleV;
						index += skip;
					}
				}
			}
			
			target.updateData(data);
		}
	}

