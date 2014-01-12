package away3d.primitives;

	//import away3d.arcane;
	import away3d.core.base.CompactSubGeometry;
	
	//use namespace arcane;
	
	/**
	 * A Cylinder primitive mesh.
	 */
	class CylinderGeometry extends PrimitiveBase
	{
		var _topRadius:Float;
		var _bottomRadius:Float;
		var _height:Float;
		var _segmentsW:UInt;
		var _segmentsH:UInt;
		var _topClosed:Bool;
		var _bottomClosed:Bool;
		var _surfaceClosed:Bool;
		var _yUp:Bool;
		var _rawData:Array<Float>;
		var _rawIndices:Array<UInt>;
		var _nextVertexIndex:UInt;
		var _currentIndex:UInt;
		var _currentTriangleIndex:UInt;
		var _numVertices:UInt;
		var _stride:UInt;
		var _vertexOffset:UInt;
		
		private function addVertex(px:Float, py:Float, pz:Float, nx:Float, ny:Float, nz:Float, tx:Float, ty:Float, tz:Float):Void
		{
			var compVertInd:UInt = _vertexOffset + _nextVertexIndex*_stride; // current component vertex index
			_rawData[compVertInd++] = px;
			_rawData[compVertInd++] = py;
			_rawData[compVertInd++] = pz;
			_rawData[compVertInd++] = nx;
			_rawData[compVertInd++] = ny;
			_rawData[compVertInd++] = nz;
			_rawData[compVertInd++] = tx;
			_rawData[compVertInd++] = ty;
			_rawData[compVertInd++] = tz;
			_nextVertexIndex++;
		}
		
		private function addTriangleClockWise(cwVertexIndex0:UInt, cwVertexIndex1:UInt, cwVertexIndex2:UInt):Void
		{
			_rawIndices[_currentIndex++] = cwVertexIndex0;
			_rawIndices[_currentIndex++] = cwVertexIndex1;
			_rawIndices[_currentIndex++] = cwVertexIndex2;
			_currentTriangleIndex++;
		}
		
		/**
		 * @inheritDoc
		 */
		private override function buildGeometry(target:CompactSubGeometry):Void
		{
			var i:UInt, j:UInt;
			var x:Float, y:Float, z:Float, radius:Float, revolutionAngle:Float;
			var dr:Float, latNormElev:Float, latNormBase:Float;
			var numTriangles:UInt = 0;
			
			var comp1:Float, comp2:Float;
			var startIndex:UInt;
			//numvert:UInt = 0;
			var t1:Float, t2:Float;
			
			_stride = target.vertexStride;
			_vertexOffset = target.vertexOffset;
			
			// reset utility variables
			_numVertices = 0;
			_nextVertexIndex = 0;
			_currentIndex = 0;
			_currentTriangleIndex = 0;
			
			// evaluate target number of vertices, triangles and indices
			if (_surfaceClosed) {
				_numVertices += (_segmentsH + 1)*(_segmentsW + 1); // segmentsH + 1 because of closure, segmentsW + 1 because of UV unwrapping
				numTriangles += _segmentsH*_segmentsW*2; // each level has segmentW quads, each of 2 triangles
			}
			if (_topClosed) {
				_numVertices += 2*(_segmentsW + 1); // segmentsW + 1 because of unwrapping
				numTriangles += _segmentsW; // one triangle for each segment
			}
			if (_bottomClosed) {
				_numVertices += 2*(_segmentsW + 1);
				numTriangles += _segmentsW;
			}
			
			// need to initialize raw arrays or can be reused?
			if (_numVertices == target.numVertices) {
				_rawData = target.vertexData;
				_rawIndices = target.indexData || new Array<UInt>(numTriangles*3, true);
			} else {
				var numVertComponents:UInt = _numVertices*_stride;
				_rawData = new Array<Float>();
				_rawIndices = new Array<UInt>(numTriangles*3, true);
			}
			
			// evaluate revolution steps
			var revolutionAngleDelta:Float = 2*Math.PI/_segmentsW;
			
			// top
			if (_topClosed && _topRadius > 0) {
				
				z = -0.5*_height;
				
				// For loop conversion - 								for (i = 0; i <= _segmentsW; ++i)
				
				for (i in 0..._segmentsW) {
					// central vertex
					if (_yUp) {
						t1 = 1;
						t2 = 0;
						comp1 = -z;
						comp2 = 0;
						
					} else {
						t1 = 0;
						t2 = -1;
						comp1 = 0;
						comp2 = z;
					}
					
					addVertex(0, comp1, comp2, 0, t1, t2, 1, 0, 0);
					
					// revolution vertex
					revolutionAngle = i*revolutionAngleDelta;
					x = _topRadius*Math.cos(revolutionAngle);
					y = _topRadius*Math.sin(revolutionAngle);
					
					if (_yUp) {
						comp1 = -z;
						comp2 = y;
					} else {
						comp1 = y;
						comp2 = z;
					}
					
					if (i == _segmentsW)
						addVertex(_rawData[startIndex + _stride], _rawData[startIndex + _stride + 1], _rawData[startIndex + _stride + 2], 0, t1, t2, 1, 0, 0);
					else
						addVertex(x, comp1, comp2, 0, t1, t2, 1, 0, 0);
					
					if (i > 0) // add triangle
						addTriangleClockWise(_nextVertexIndex - 1, _nextVertexIndex - 3, _nextVertexIndex - 2);
				}
			}
			
			// bottom
			if (_bottomClosed && _bottomRadius > 0) {
				
				z = 0.5*_height;
				
				startIndex = _vertexOffset + _nextVertexIndex*_stride;
				
				// For loop conversion - 								for (i = 0; i <= _segmentsW; ++i)
				
				for (i in 0..._segmentsW) {
					if (_yUp) {
						t1 = -1;
						t2 = 0;
						comp1 = -z;
						comp2 = 0;
					} else {
						t1 = 0;
						t2 = 1;
						comp1 = 0;
						comp2 = z;
					}
					
					addVertex(0, comp1, comp2, 0, t1, t2, 1, 0, 0);
					
					// revolution vertex
					revolutionAngle = i*revolutionAngleDelta;
					x = _bottomRadius*Math.cos(revolutionAngle);
					y = _bottomRadius*Math.sin(revolutionAngle);
					
					if (_yUp) {
						comp1 = -z;
						comp2 = y;
					} else {
						comp1 = y;
						comp2 = z;
					}
					
					if (i == _segmentsW)
						addVertex(x, _rawData[startIndex + 1], _rawData[startIndex + 2], 0, t1, t2, 1, 0, 0);
					else
						addVertex(x, comp1, comp2, 0, t1, t2, 1, 0, 0);
					
					if (i > 0) // add triangle
						addTriangleClockWise(_nextVertexIndex - 2, _nextVertexIndex - 3, _nextVertexIndex - 1);
				}
			}
			
			// The normals on the lateral surface all have the same incline, i.e.
			// the "elevation" component (Y or Z depending on yUp) is constant.
			// Same principle goes for the "base" of these vectors, which will be
			// calculated such that a vector [base,elev] will be a unit vector.
			dr = (_bottomRadius - _topRadius);
			latNormElev = dr/_height;
			latNormBase = (latNormElev == 0)? 1 : _height/dr;
			
			// lateral surface
			if (_surfaceClosed) {
				var a:UInt, b:UInt, c:UInt, d:UInt;
				var na0:Float, na1:Float, naComp1:Float, naComp2:Float;
				
				// For loop conversion - 								for (j = 0; j <= _segmentsH; ++j)
				
				for (j in 0..._segmentsH) {
					radius = _topRadius - ((j/_segmentsH)*(_topRadius - _bottomRadius));
					z = -(_height/2) + (j/_segmentsH*_height);
					
					startIndex = _vertexOffset + _nextVertexIndex*_stride;
					
					// For loop conversion - 										for (i = 0; i <= _segmentsW; ++i)
					
					for (i in 0..._segmentsW) {
						// revolution vertex
						revolutionAngle = i*revolutionAngleDelta;
						x = radius*Math.cos(revolutionAngle);
						y = radius*Math.sin(revolutionAngle);
						na0 = latNormBase*Math.cos(revolutionAngle);
						na1 = latNormBase*Math.sin(revolutionAngle);
						
						if (_yUp) {
							t1 = 0;
							t2 = -na0;
							comp1 = -z;
							comp2 = y;
							naComp1 = latNormElev;
							naComp2 = na1;
							
						} else {
							t1 = -na0;
							t2 = 0;
							comp1 = y;
							comp2 = z;
							naComp1 = na1;
							naComp2 = latNormElev;
						}
						
						if (i == _segmentsW) {
							addVertex(_rawData[startIndex], _rawData[startIndex + 1], _rawData[startIndex + 2],
								na0, latNormElev, na1,
								na1, t1, t2);
						} else {
							addVertex(x, comp1, comp2,
								na0, naComp1, naComp2,
								-na1, t1, t2);
						}
						
						// close triangle
						if (i > 0 && j > 0) {
							a = _nextVertexIndex - 1; // current
							b = _nextVertexIndex - 2; // previous
							c = b - _segmentsW - 1; // previous of last level
							d = a - _segmentsW - 1; // current of last level
							addTriangleClockWise(a, b, c);
							addTriangleClockWise(a, c, d);
						}
					}
				}
			}
			
			// build real data from raw data
			target.updateData(_rawData);
			target.updateIndexData(_rawIndices);
		}
		
		/**
		 * @inheritDoc
		 */
		private override function buildUVs(target:CompactSubGeometry):Void
		{
			var i:Int, j:Int;
			var x:Float, y:Float, revolutionAngle:Float;
			var stride:UInt = target.UVStride;
			var skip:UInt = stride - 2;
			var UVData:Array<Float>;
			
			// evaluate num uvs
			var numUvs:UInt = _numVertices*stride;
			
			// need to initialize raw array or can be reused?
			if (target.UVData && numUvs == target.UVData.length)
				UVData = target.UVData;
			else {
				UVData = new Array<Float>();
				invalidateGeometry();
			}
			
			// evaluate revolution steps
			var revolutionAngleDelta:Float = 2*Math.PI/_segmentsW;
			
			// current uv component index
			var currentUvCompIndex:UInt = target.UVOffset;
			
			// top
			if (_topClosed) {
				// For loop conversion - 				for (i = 0; i <= _segmentsW; ++i)
				for (i in 0..._segmentsW) {
					
					revolutionAngle = i*revolutionAngleDelta;
					x = 0.5 + 0.5* -Math.cos(revolutionAngle);
					y = 0.5 + 0.5*Math.sin(revolutionAngle);
					
					UVData[currentUvCompIndex++] = 0.5*target.scaleU; // central vertex
					UVData[currentUvCompIndex++] = 0.5*target.scaleV;
					currentUvCompIndex += skip;
					UVData[currentUvCompIndex++] = x*target.scaleU; // revolution vertex
					UVData[currentUvCompIndex++] = y*target.scaleV;
					currentUvCompIndex += skip;
				}
			}
			
			// bottom
			if (_bottomClosed) {
				// For loop conversion - 				for (i = 0; i <= _segmentsW; ++i)
				for (i in 0..._segmentsW) {
					
					revolutionAngle = i*revolutionAngleDelta;
					x = 0.5 + 0.5*Math.cos(revolutionAngle);
					y = 0.5 + 0.5*Math.sin(revolutionAngle);
					
					UVData[currentUvCompIndex++] = 0.5*target.scaleU; // central vertex
					UVData[currentUvCompIndex++] = 0.5*target.scaleV;
					currentUvCompIndex += skip;
					UVData[currentUvCompIndex++] = x*target.scaleU; // revolution vertex
					UVData[currentUvCompIndex++] = y*target.scaleV;
					currentUvCompIndex += skip;
				}
			}
			
			// lateral surface
			if (_surfaceClosed) {
				// For loop conversion - 				for (j = 0; j <= _segmentsH; ++j)
				for (j in 0..._segmentsH) {
					// For loop conversion - 					for (i = 0; i <= _segmentsW; ++i)
					for (i in 0..._segmentsW) {
						// revolution vertex
						UVData[currentUvCompIndex++] = ( i/_segmentsW )*target.scaleU;
						UVData[currentUvCompIndex++] = ( j/_segmentsH )*target.scaleV;
						currentUvCompIndex += skip;
					}
				}
			}
			
			// build real data from raw data
			target.updateData(UVData);
		}
		
		/**
		 * The radius of the top end of the cylinder.
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
		 * The radius of the bottom end of the cylinder.
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
		 * The radius of the top end of the cylinder.
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
		}
		
		/**
		 * Defines the number of horizontal segments that make up the cylinder. Defaults to 16.
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
		}
		
		/**
		 * Defines the number of vertical segments that make up the cylinder. Defaults to 1.
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
		}
		
		/**
		 * Defines whether the top end of the cylinder is closed (true) or open.
		 */
		public var topClosed(get, set) : Bool;
		public function get_topClosed() : Bool
		{
			return _topClosed;
		}
		
		public function set_topClosed(value:Bool) : Bool
		{
			_topClosed = value;
			invalidateGeometry();
		}
		
		/**
		 * Defines whether the bottom end of the cylinder is closed (true) or open.
		 */
		public var bottomClosed(get, set) : Bool;
		public function get_bottomClosed() : Bool
		{
			return _bottomClosed;
		}
		
		public function set_bottomClosed(value:Bool) : Bool
		{
			_bottomClosed = value;
			invalidateGeometry();
		}
		
		/**
		 * Defines whether the cylinder poles should lay on the Y-axis (true) or on the Z-axis (false).
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
		}
		
		/**
		 * Creates a new Cylinder object.
		 * @param topRadius The radius of the top end of the cylinder.
		 * @param bottomRadius The radius of the bottom end of the cylinder
		 * @param height The radius of the bottom end of the cylinder
		 * @param segmentsW Defines the number of horizontal segments that make up the cylinder. Defaults to 16.
		 * @param segmentsH Defines the number of vertical segments that make up the cylinder. Defaults to 1.
		 * @param topClosed Defines whether the top end of the cylinder is closed (true) or open.
		 * @param bottomClosed Defines whether the bottom end of the cylinder is closed (true) or open.
		 * @param yUp Defines whether the cone poles should lay on the Y-axis (true) or on the Z-axis (false).
		 */
		public function new(topRadius:Float = 50, bottomRadius:Float = 50, height:Float = 100, segmentsW:UInt = 16, segmentsH:UInt = 1, topClosed:Bool = true, bottomClosed:Bool = true, surfaceClosed:Bool = true, yUp:Bool = true)
		{
			super();
			
			_topRadius = topRadius;
			_bottomRadius = bottomRadius;
			_height = height;
			_segmentsW = segmentsW;
			_segmentsH = segmentsH;
			_topClosed = topClosed;
			_bottomClosed = bottomClosed;
			_surfaceClosed = surfaceClosed;
			_yUp = yUp;
		}
	}

