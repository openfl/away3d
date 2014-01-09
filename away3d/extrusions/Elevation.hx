package away3d.extrusions;

	import away3d.core.base.Geometry;
	import away3d.core.base.SubGeometry;
	import away3d.entities.Mesh;
	import away3d.materials.MaterialBase;
	
	import flash.display.BitmapData;
	
	/**
	 * Class Elevation generates (and becomes) a mesh from an heightmap.
	 */
	
	class Elevation extends Mesh
	{
		var _segmentsW:UInt;
		var _segmentsH:UInt;
		var _width:Float;
		var _height:Float;
		var _depth:Float;
		var _heightMap:BitmapData;
		var _smoothedHeightMap:BitmapData;
		var _activeMap:BitmapData;
		var _minElevation:UInt;
		var _maxElevation:UInt;
		var _geomDirty:Bool = true;
		var _uvDirty:Bool = true;
		var _subGeometry:SubGeometry;
		
		/**
		 * @param    material        MaterialBase. The Mesh (Elevation) material
		 * @param    heightMap        BitmapData. The heightmap to generate the mesh from
		 * @param    width                [optional] Number. The width of the mesh. Default is 1000.
		 * @param    height            [optional] Number. The height of the mesh. Default is 100.
		 * @param    depth            [optional] Number. The depth of the mesh. Default is 1000.
		 * @param    segmentsW    [optional] uint. The subdivision of the mesh along the x axis. Default is 30.
		 * @param    segmentsH        [optional] uint. The subdivision of the mesh along the y axis. Default is 30.
		 * @param    maxElevation    [optional] uint. The maximum color value to be used. Allows canyon like elevations instead of mountainious. Default is 255.
		 * @param    minElevation    [optional] uint. The minimum color value to be used. Default is 0.
		 * @param    smoothMap    [optional] Boolean. If surface tracking is used, an internal smoothed version of the map is generated,
		 * prevents irregular height readings if original map is blowed up or is having noise. Default is false.
		 */
		public function new(material:MaterialBase, heightMap:BitmapData, width:Float = 1000, height:Float = 100, depth:Float = 1000, segmentsW:UInt = 30, segmentsH:UInt = 30, maxElevation:UInt = 255, minElevation:UInt = 0, smoothMap:Bool = false)
		{
			_subGeometry = new SubGeometry();
			super(new Geometry(), material);
			this.geometry.addSubGeometry(_subGeometry);
			
			_heightMap = heightMap;
			_activeMap = _heightMap;
			_segmentsW = segmentsW;
			_segmentsH = segmentsH;
			_width = width;
			_height = height;
			_depth = depth;
			_maxElevation = maxElevation;
			_minElevation = minElevation;
			
			buildUVs();
			buildGeometry();
			
			if (smoothMap)
				generateSmoothedHeightMap();
		}
		
		/**
		 * Locks elevation factor beneath this color reading level. Default is 0;
		 */
		public function set_minElevation(val:UInt) : Void
		{
			if (_minElevation == val)
				return;
			
			_minElevation = val;
			invalidateGeometry();
		}
		
		public var minElevation(get, set) : Void;
		
		public function get_minElevation() : Void
		{
			return _minElevation;
		}
		
		/**
		 * Locks elevation factor above this color reading level. Default is 255;
		 * Allows to build "canyon" like landscapes with no additional work on heightmap source.
		 */
		public function set_maxElevation(val:UInt) : Void
		{
			if (_maxElevation == val)
				return;
			
			_maxElevation = val;
			invalidateGeometry();
		}
		
		public var maxElevation(get, set) : Void;
		
		public function get_maxElevation() : Void
		{
			return _maxElevation;
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
		}
		
		/**
		 * The width of the terrain plane.
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
		}
		
		public var height(get, set) : Float;
		
		public function get_height() : Float
		{
			return _height;
		}
		
		public function set_height(value:Float) : Float
		{
			_height = value;
		}
		
		/**
		 * The depth of the terrain plane.
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
		}
		
		/**
		 * Reading the terrain height from a given x z position
		 * for surface tracking purposes
		 *
		 * @see away3d.extrusions.Elevation.smoothHeightMap
		 */
		public function getHeightAt(x:Float, z:Float):Float
		{
			var col:UInt = _activeMap.getPixel((x/_width + .5)*(_activeMap.width - 1), (-z/_depth + .5)*(_activeMap.height - 1)) & 0xff;
			return (col > _maxElevation)? (_maxElevation/0xff)*_height : ((col < _minElevation)? (_minElevation/0xff)*_height : (col/0xff)*_height);
		}
		
		/**
		 * Generates a smoother representation of the geometry using the original heightmap and subdivision settings.
		 * Allows smoother readings for surface tracking if original heightmap has noise, causing choppy camera movement.
		 *
		 * @see away3d.extrusions.Elevation.getHeightAt
		 */
		public function generateSmoothedHeightMap():BitmapData
		{
			if (_smoothedHeightMap)
				_smoothedHeightMap.dispose();
			_smoothedHeightMap = new BitmapData(_heightMap.width, _heightMap.height, false, 0);
			
			var w:UInt = _smoothedHeightMap.width;
			var h:UInt = _smoothedHeightMap.height;
			var i:UInt = 0;
			var j:UInt;
			var k:UInt;
			var l:UInt;
			
			var px1:UInt;
			var px2:UInt;
			var px3:UInt;
			var px4:UInt;
			
			var lockx:UInt;
			var locky:UInt;
			
			_smoothedHeightMap.lock();
			
			var incXL:Float;
			var incXR:Float;
			var incYL:Float;
			var incYR:Float;
			var pxx:Float;
			var pxy:Float;
			
			// For loop conversion - 						for (i = 0; i < w + 1; i += _segmentsW)
			
			for (i in 0...w + 1) {
				
				if (i + _segmentsW > w - 1)
					lockx = w - 1;
				else
					lockx = i + _segmentsW;
				
				// For loop conversion - 								for (j = 0; j < h + 1; j += _segmentsH)
				
				for (j in 0...h + 1) {
					
					if (j + _segmentsH > h - 1)
						locky = h - 1;
					else
						locky = j + _segmentsH;
					
					if (j == 0) {
						px1 = _heightMap.getPixel(i, j) & 0xFF;
						px1 = (px1 > _maxElevation)? _maxElevation : ((px1 < _minElevation)? _minElevation : px1);
						px2 = _heightMap.getPixel(lockx, j) & 0xFF;
						px2 = (px2 > _maxElevation)? _maxElevation : ((px2 < _minElevation)? _minElevation : px2);
						px3 = _heightMap.getPixel(lockx, locky) & 0xFF;
						px3 = (px3 > _maxElevation)? _maxElevation : ((px3 < _minElevation)? _minElevation : px3);
						px4 = _heightMap.getPixel(i, locky) & 0xFF;
						px4 = (px4 > _maxElevation)? _maxElevation : ((px4 < _minElevation)? _minElevation : px4);
					} else {
						px1 = px4;
						px2 = px3;
						px3 = _heightMap.getPixel(lockx, locky) & 0xFF;
						px3 = (px3 > _maxElevation)? _maxElevation : ((px3 < _minElevation)? _minElevation : px3);
						px4 = _heightMap.getPixel(i, locky) & 0xFF;
						px4 = (px4 > _maxElevation)? _maxElevation : ((px4 < _minElevation)? _minElevation : px4);
					}
					
					// For loop conversion - 										for (k = 0; k < _segmentsW; ++k)
					
					for (k in 0..._segmentsW) {
						incXL = 1/_segmentsW*k;
						incXR = 1 - incXL;
						
						// For loop conversion - 												for (l = 0; l < _segmentsH; ++l)
						
						for (l in 0..._segmentsH) {
							incYL = 1/_segmentsH*l;
							incYR = 1 - incYL;
							
							pxx = ((px1*incXR) + (px2*incXL))*incYR;
							pxy = ((px4*incXR) + (px3*incXL))*incYL;
							
							//_smoothedHeightMap.setPixel(k+i, l+j, pxy+pxx << 16 |  0xFF-(pxy+pxx) << 8 | 0xFF-(pxy+pxx) );
							_smoothedHeightMap.setPixel(k + i, l + j, pxy + pxx << 16 | pxy + pxx << 8 | pxy + pxx);
						}
					}
				}
			}
			_smoothedHeightMap.unlock();
			
			_activeMap = _smoothedHeightMap;
			
			return _smoothedHeightMap;
		}
		
		/*
		 * Returns the smoothed heightmap
		 */
		public var smoothedHeightMap(get, null) : BitmapData;
		public function get_smoothedHeightMap() : BitmapData
		{
			return _smoothedHeightMap;
		}
		
		private function buildGeometry():Void
		{
			var vertices:Array<Float>;
			var indices:Array<UInt>;
			var x:Float, z:Float;
			var numInds:UInt;
			var base:UInt;
			var tw:UInt = _segmentsW + 1;
			var numVerts:UInt = (_segmentsH + 1)*tw;
			var uDiv:Float = (_heightMap.width - 1)/_segmentsW;
			var vDiv:Float = (_heightMap.height - 1)/_segmentsH;
			var u:Float, v:Float;
			var y:Float;
			
			if (numVerts == _subGeometry.numVertices) {
				vertices = _subGeometry.vertexData;
				indices = _subGeometry.indexData;
			} else {
				vertices = new Array<Float>(numVerts*3, true);
				indices = new Array<UInt>(_segmentsH*_segmentsW*6, true);
			}
			
			numVerts = 0;
			var col:UInt;
			
			// For loop conversion - 						for (var zi:UInt = 0; zi <= _segmentsH; ++zi)
			
			var zi:UInt;
			
			for (zi in 0..._segmentsH) {
				// For loop conversion - 				for (var xi:UInt = 0; xi <= _segmentsW; ++xi)
				var xi:UInt;
				for (xi in 0..._segmentsW) {
					x = (xi/_segmentsW - .5)*_width;
					z = (zi/_segmentsH - .5)*_depth;
					u = xi*uDiv;
					v = (_segmentsH - zi)*vDiv;
					
					col = _heightMap.getPixel(u, v) & 0xff;
					y = (col > _maxElevation)? (_maxElevation/0xff)*_height : ((col < _minElevation)? (_minElevation/0xff)*_height : (col/0xff)*_height);
					
					vertices[numVerts++] = x;
					vertices[numVerts++] = y;
					vertices[numVerts++] = z;
					
					if (xi != _segmentsW && zi != _segmentsH) {
						base = xi + zi*tw;
						indices[numInds++] = base;
						indices[numInds++] = base + tw;
						indices[numInds++] = base + tw + 1;
						indices[numInds++] = base;
						indices[numInds++] = base + tw + 1;
						indices[numInds++] = base + 1;
					}
				}
			}
			
			_subGeometry.autoDeriveVertexNormals = true;
			_subGeometry.autoDeriveVertexTangents = true;
			_subGeometry.updateVertexData(vertices);
			_subGeometry.updateIndexData(indices);
		}
		
		/**
		 * @inheritDoc
		 */
		private function buildUVs():Void
		{
			var uvs:Array<Float> = new Array<Float>();
			var numUvs:UInt = (_segmentsH + 1)*(_segmentsW + 1)*2;
			
			if (_subGeometry.UVData && numUvs == _subGeometry.UVData.length)
				uvs = _subGeometry.UVData;
			else
				uvs = new Array<Float>();
			
			numUvs = 0;
			// For loop conversion - 			for (var yi:UInt = 0; yi <= _segmentsH; ++yi)
			var yi:UInt;
			for (yi in 0..._segmentsH) {
				// For loop conversion - 				for (var xi:UInt = 0; xi <= _segmentsW; ++xi)
				var xi:UInt;
				for (xi in 0..._segmentsW) {
					uvs[numUvs++] = xi/_segmentsW;
					uvs[numUvs++] = 1 - yi/_segmentsH;
				}
			}
			
			_subGeometry.updateUVData(uvs);
		}
		
		/**
		 * Invalidates the primitive's geometry, causing it to be updated when requested.
		 */
		private function invalidateGeometry():Void
		{
			_geomDirty = true;
			invalidateBounds();
		}
		
		/**
		 * Invalidates the primitive's uv coordinates, causing them to be updated when requested.
		 */
		private function invalidateUVs():Void
		{
			_uvDirty = true;
		}
	
	/**
	 * Updates the geometry when invalid.
	 */
	/*
	 private function updateGeometry() : Void
	 {
	 buildGeometry();
	 _geomDirty = false;
	 }
	 *
	 */
	
	/**
	 * Updates the uv coordinates when invalid.
	 */
	/*
	 private function updateUVs() : Void
	 {
	 buildUVs();
	 _uvDirty = false;
	 }
	 *
	 */
	}

