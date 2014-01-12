package away3d.primitives;

	import away3d.core.base.CompactSubGeometry;
	//import away3d.arcane;
	import away3d.primitives.data.NURBSVertex;
	
	import flash.geom.Vector3D;
	
	//use namespace arcane;
	
	/**
	 * A NURBS primitive geometry.
	 */
	class NURBSGeometry extends PrimitiveBase
	{
		var _controlNet:Array<NURBSVertex>;
		var _uOrder:Float;
		var _vOrder:Float;
		var _numVContolPoints:Int;
		var _numUContolPoints:Int;
		var _uSegments:Int;
		var _vSegments:Int;
		var _uKnotSequence:Array<Float>;
		var _vKnotSequence:Array<Float>;
		var _mbasis:Array<Float> = new Array<Float>();
		var _nbasis:Array<Float> = new Array<Float>();
		var _nplusc:Int;
		var _mplusc:Int;
		var _uRange:Float;
		var _vRange:Float;
		var _autoGenKnotSeq:Bool = false;
		var _invert:Bool;
		var _tmpPM:Vector3D = new Vector3D();
		var _tmpP1:Vector3D = new Vector3D();
		var _tmpP2:Vector3D = new Vector3D();
		var _tmpN1:Vector3D = new Vector3D();
		var _tmpN2:Vector3D = new Vector3D();
		var _rebuildUVs:Bool;
		
		/**
		 * Defines the control point net to describe the NURBS surface
		 */
		public var controlNet(get, set) : Array<NURBSVertex>;
		public function get_controlNet() : Array<NURBSVertex>
		{
			return _controlNet;
		}
		
		public function set_controlNet(value:Array<NURBSVertex>) : Array<NURBSVertex>
		{
			if (_controlNet == value)
				return;
			
			_controlNet = value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * Defines the number of control points along the U splines that influence any given point on the curve
		 */
		public var uOrder(get, set) : Int;
		public function get_uOrder() : Int
		{
			return _uOrder;
		}
		
		public function set_uOrder(value:Int) : Int
		{
			if (_uOrder == value)
				return;
			
			_uOrder = value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * Defines the number of control points along the V splines that influence any given point on the curve
		 */
		public var vOrder(get, set) : Int;
		public function get_vOrder() : Int
		{
			return _vOrder;
		}
		
		public function set_vOrder(value:Int) : Int
		{
			if (_vOrder == value)
				return;
			
			_vOrder = value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * Defines the number of control points along the U splines
		 */
		public var uControlPoints(get, set) : Int;
		public function get_uControlPoints() : Int
		{
			return _numUContolPoints;
		}
		
		public function set_uControlPoints(value:Int) : Int
		{
			if (_numUContolPoints == value)
				return;
			
			_numUContolPoints = value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * Defines the number of control points along the V splines
		 */
		public var vControlPoints(get, set) : Int;
		public function get_vControlPoints() : Int
		{
			return _numVContolPoints;
		}
		
		public function set_vControlPoints(value:Int) : Int
		{
			if (_numVContolPoints == value)
				return;
			
			_numVContolPoints = value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * Defines the knot sequence in the U direction that determines where and how the control points
		 * affect the NURBS curve.
		 */
		public var uKnot(get, set) : Array<Float>;
		public function get_uKnot() : Array<Float>
		{
			return _uKnotSequence;
		}
		
		public function set_uKnot(value:Array<Float>) : Array<Float>
		{
			if (_uKnotSequence == value)
				return;
			
			_uKnotSequence = value;
			
			_autoGenKnotSeq = ((!_uKnotSequence || _uKnotSequence.length == 0) || (!_vKnotSequence || _vKnotSequence.length == 0));
			
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * Defines the knot sequence in the V direction that determines where and how the control points
		 * affect the NURBS curve.
		 */
		public var vKnot(get, set) : Array<Float>;
		public function get_vKnot() : Array<Float>
		{
			return _vKnotSequence;
		}
		
		public function set_vKnot(value:Array<Float>) : Array<Float>
		{
			if (_vKnotSequence == value)
				return;
			
			_vKnotSequence = value;
			
			_autoGenKnotSeq = ((!_uKnotSequence || _uKnotSequence.length == 0) || (!_vKnotSequence || _vKnotSequence.length == 0));
			
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * Defines the number segments (triangle pair) the final curve will be divided into in the U direction
		 */
		public var uSegments(get, set) : Int;
		public function get_uSegments() : Int
		{
			return _uSegments;
		}
		
		public function set_uSegments(value:Int) : Int
		{
			if (_uSegments == value)
				return;
			
			_uSegments = value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * Defines the number segments (triangle pair) the final curve will be divided into in the V direction
		 */
		public var vSegments(get, set) : Int;
		public function get_vSegments() : Int
		{
			return _vSegments;
		}
		
		public function set_vSegments(value:Int) : Int
		{
			if (_vSegments == value)
				return;
			
			_vSegments = value;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/**
		 * NURBS primitive generates a segmented mesh that fits the curved surface defined by the specified
		 * control points based on weighting, order influence and knot sequence
		 *
		 * @param cNet Array of control points (WeightedVertex array)
		 * @param uCtrlPnts Number of control points in the U direction
		 * @param vCtrlPnts Number of control points in the V direction
		 * @param init Init object for the mesh
		 *
		 */
		public function new(cNet:Array<NURBSVertex>, uCtrlPnts:Int, vCtrlPnts:Int, uOrder:Int = 4, vOrder:Int = 4, uSegments:Int = 10, vSegments:Int = 10, uKnot:Array<Float> = null, vKnot:Array<Float> = null)
		{
			
			super();
			
			_controlNet = cNet;
			_numUContolPoints = uCtrlPnts;
			_numVContolPoints = vCtrlPnts;
			_uOrder = uOrder;
			_vOrder = vOrder;
			_uKnotSequence = uKnot;
			_vKnotSequence = vKnot;
			_uSegments = uSegments;
			_vSegments = vSegments;
			_nplusc = uCtrlPnts + _uOrder;
			_mplusc = vCtrlPnts + _vOrder;
			
			// Generate the open uniform knot vectors if not already defined
			_autoGenKnotSeq = ((!_uKnotSequence || _uKnotSequence.length == 0) || (!_vKnotSequence || _vKnotSequence.length == 0));
			
			_rebuildUVs = true;
			invalidateGeometry();
			invalidateUVs();
		}
		
		/** @private */
		private function nurbPoint(nU:Float, nV:Float, target:Vector3D = null):Vector3D
		{
			var pbasis:Float;
			var jbas:Int;
			var j1:Int;
			var u:Float = _uKnotSequence[1] + (_uRange*nU);
			var v:Float = _vKnotSequence[1] + (_vRange*nV);
			
			if (target)
				target.setTo(0, 0, 0);
			else
				target = new Vector3D();
			
			if (_vKnotSequence[_mplusc] - v < 0.00005)
				v = _vKnotSequence[_mplusc];
			_mbasis = basis(_vOrder, v, _numVContolPoints, _vKnotSequence);
			/* basis function for this value of w */
			if (_uKnotSequence[_nplusc] - u < 0.00005)
				u = _uKnotSequence[_nplusc];
			_nbasis = basis(_uOrder, u, _numUContolPoints, _uKnotSequence);
			/* basis function for this value of u */
			
			var sum:Float = sumrbas();
			// For loop conversion - 			for (var i:Int = 1; i <= _numVContolPoints; i++)
			var i:Int;
			for (i in 1..._numVContolPoints) {
				if (_mbasis[i] != 0) {
					jbas = _numUContolPoints*(i - 1);
					// For loop conversion - 					for (var j:Int = 1; j <= _numUContolPoints; j++)
					var j:Int;
					for (j in 1..._numUContolPoints) {
						if (_nbasis[j] != 0) {
							j1 = jbas + j - 1;
							pbasis = _controlNet[j1].w*_mbasis[i]*_nbasis[j]/sum;
							target.x += _controlNet[j1].x*pbasis;
							/* calculate surface point */
							target.y += _controlNet[j1].y*pbasis;
							target.z += _controlNet[j1].z*pbasis;
						}
					}
				}
			}
			
			return target;
		}
		
		/**
		 * Return a 3d point representing the surface point at the required U(0-1) and V(0-1) across the
		 * NURBS curved surface.
		 *
		 * @param uS                U position on the surface
		 * @param vS                V position on the surface
		 * @param vecOffset            Offset the point on the surface by this vector
		 * @param scale                Scale of the surface point - should match the Mesh scaling
		 * @param uTol                U tolerance for adjacent surface sample to calculate normal
		 * @param vTol                V tolerance for adjacent surface sample to calculate normal
		 * @return                    The offset surface point being returned
		 *
		 */
		public function getSurfacePoint(uS:Float, vS:Float, vecOffset:Float = 0, scale:Float = 1, uTol:Float = 0.01, vTol:Float = 0.01):Vector3D
		{
			_tmpPM = nurbPoint(uS, vS);
			_tmpP1 = uS + uTol >= 1? nurbPoint(uS - uTol, vS) : nurbPoint(uS + uTol, vS);
			_tmpP2 = vS + vTol >= 1? nurbPoint(uS, vS - vTol) : nurbPoint(uS, vS + vTol);
			
			_tmpN1 = new Vector3D(_tmpP1.x - _tmpPM.x, _tmpP1.y - _tmpPM.y, _tmpP1.z - _tmpPM.z);
			_tmpN2 = new Vector3D(_tmpP2.x - _tmpPM.x, _tmpP2.y - _tmpPM.y, _tmpP2.z - _tmpPM.z);
			var sP:Vector3D = _tmpN2.crossProduct(_tmpN1);
			sP.normalize();
			sP.scaleBy(vecOffset);
			
			sP.x += _tmpPM.x*scale;
			sP.y += _tmpPM.y*scale;
			sP.z += _tmpPM.z*scale;
			
			return sP;
		
		}
		
		/** @private */
		private function sumrbas():Float
		{
			var i:Int;
			var j:Int;
			var jbas:Int = 0;
			var j1:Int = 0;
			var sum:Float;
			
			sum = 0;
			
			// For loop conversion - 						for (i = 1; i <= _numVContolPoints; i++)
			
			for (i in 1..._numVContolPoints) {
				if (_mbasis[i] != 0) {
					jbas = _numUContolPoints*(i - 1);
					// For loop conversion - 					for (j = 1; j <= _numUContolPoints; j++)
					for (j in 1..._numUContolPoints) {
						if (_nbasis[j] != 0) {
							j1 = jbas + j - 1;
							sum = sum + _controlNet[j1].w*_mbasis[i]*_nbasis[j];
						}
					}
				}
			}
			return sum;
		}
		
		/** @private */
		private function knot(n:Int, c:Int):Array<Float>
		{
			var nplusc:Int = n + c;
			var nplus2:Int = n + 2;
			var x:Array<Float> = new Array<Float>();
			
			x[1] = 0;
			// For loop conversion - 			for (var i:Int = 2; i <= nplusc; i++)
			var i:Int;
			for (i in 2...nplusc) {
				if ((i > c) && (i < nplus2))
					x[i] = x[i - 1] + 1;
				else
					x[i] = x[i - 1];
			}
			return x;
		}
		
		/** @private */
		private function basis(nurbOrder:Int, t:Float, numPoints:Int, knot:Array<Float>):Array<Float>
		{
			var nPlusO:Int;
			var i:Int;
			var k:Int;
			var d:Float;
			var e:Float;
			var temp:Array<Float> = new Array<Float>();
			
			nPlusO = numPoints + nurbOrder;
			
			// calculate the first order basis functions n[i][1]
			// For loop conversion - 			for (i = 1; i <= nPlusO - 1; i++)
			for (i in 1...nPlusO - 1)
				temp[i] = (( t >= knot[i]) && (t < knot[i + 1]))? 1 : 0;
			
			// calculate the higher order basis functions 
			// For loop conversion - 			for (k = 2; k <= nurbOrder; k++)
			for (k in 2...nurbOrder) {
				// For loop conversion - 				for (i = 1; i <= nPlusO - k; i++)
				for (i in 1...nPlusO - k) {
					// if the lower order basis function is zero skip the calculation
					d = (temp[i] != 0)? ((t - knot[i])*temp[i])/(knot[i + k - 1] - knot[i]) : 0;
					
					// if the lower order basis function is zero skip the calculation
					e = (temp[i + 1] != 0)? ((knot[i + k] - t)*temp[i + 1])/(knot[i + k] - knot[i + 1]) : 0;
					
					temp[i] = d + e;
				}
			}
			
			// pick up last point
			if (t == knot[nPlusO])
				temp[numPoints] = 1;
			
			return temp;
		}
		
		/**
		 *  Rebuild the mesh as there is significant change to the structural parameters
		 *
		 */
		override private function buildGeometry(target:CompactSubGeometry):Void
		{
			var data:Array<Float>;
			var stride:Int = target.vertexStride;
			
			_nplusc = _numUContolPoints + _uOrder;
			_mplusc = _numVContolPoints + _vOrder;
			
			target.autoDeriveVertexNormals = true;
			target.autoDeriveVertexTangents = true;
			
			// Generate the open uniform knot vectors if not already defined
			if (_autoGenKnotSeq)
				_uKnotSequence = knot(_numUContolPoints, _uOrder);
			if (_autoGenKnotSeq)
				_vKnotSequence = knot(_numVContolPoints, _vOrder);
			_uRange = (_uKnotSequence[_nplusc] - _uKnotSequence[1]);
			_vRange = (_vKnotSequence[_mplusc] - _uKnotSequence[1]);
			
			// Define presets
			var numVertices:Int = (_uSegments + 1)*(_vSegments + 1);
			var i:Int;
			//var icount:Int = 0;
			var j:Int;
			
			var indices:Array<UInt>;
			var numIndices:UInt = target.vertexOffset;
			
			if (numVertices == target.numVertices) {
				data = target.vertexData;
				indices = target.indexData;
			} else {
				data = new Array<Float>(numVertices*stride, true);
				numIndices = (_uSegments)*(_vSegments)*6;
				indices = new Array<UInt>();
				invalidateUVs();
			}
			
			// Iterate through the surface points (u=>0-1, v=>0-1)
			var stepuinc:Float = 1/_uSegments;
			var stepvinc:Float = 1/_vSegments;
			
			var vBase:Int = 0;
			var nV:Vector3D;
			// For loop conversion - 			for (var vinc:Float = 0; vinc < (1 + (stepvinc/2)); vinc += stepvinc)
			var vinc:Float;
			for (vinc in 0...(1 + (stepvinc/2))) {
				// For loop conversion - 				for (var uinc:Float = 0; uinc < (1 + (stepuinc/2)); uinc += stepuinc)
				var uinc:Float;
				for (uinc in 0...(1 + (stepuinc/2))) {
					nV = nurbPoint(uinc, vinc);
					
					data[vBase] = nV.x;
					data[uint(vBase + 1)] = nV.y;
					data[uint(vBase + 2)] = nV.z;
					vBase += stride;
				}
			}
			
			// Render the mesh faces
			var vPos:Int = 0;
			var iBase:Int;
			
			// For loop conversion - 						for (i = 1; i <= _vSegments; i++)
			
			for (i in 1..._vSegments) {
				// For loop conversion - 				for (j = 1; j <= _uSegments; j++)
				for (j in 1..._uSegments) {
					if (_invert) {
						indices[iBase++] = vPos;
						indices[iBase++] = vPos + 1;
						indices[iBase++] = vPos + _uSegments + 1;
						
						indices[iBase++] = vPos + _uSegments + 1;
						indices[iBase++] = vPos + 1;
						indices[iBase++] = vPos + _uSegments + 2;
					} else {
						indices[iBase++] = vPos + 1;
						indices[iBase++] = vPos;
						indices[iBase++] = vPos + _uSegments + 1;
						
						indices[iBase++] = vPos + 1;
						indices[iBase++] = vPos + _uSegments + 1;
						indices[iBase++] = vPos + _uSegments + 2;
					}
					vPos++;
				}
				vPos++;
			}
			target.updateData(data);
			target.updateIndexData(indices);
		}
		
		/**
		 *  Rebuild the UV coordinates as there is significant change to the structural parameters
		 *
		 */
		override private function buildUVs(target:CompactSubGeometry):Void
		{
			// Define presets
			var data:Array<Float>;
			var stride:UInt = target.UVStride;
			var numVertices:Int = (_uSegments + 1)*(_vSegments + 1);
			var uvLen:Int = numVertices*stride;
			var i:Int;
			var j:Int;
			
			if (target.UVData && uvLen == target.UVData.length)
				data = target.UVData;
			else {
				data = new Array<Float>();
				invalidateGeometry();
			}
			
			var uvBase:Int = target.UVOffset;
			// For loop conversion - 			for (i = _vSegments; i >= 0; i--)
			for (i in _vSegments...0) {
				// For loop conversion - 				for (j = _uSegments; j >= 0; j--)
				for (j in _uSegments...0) {
					data[uint(uvBase)] = j/_uSegments;
					data[uint(uvBase + 1)] = i/_vSegments;
					uvBase += stride;
				}
			}
			target.updateData(data);
			_rebuildUVs = false;
		}
		
		/**
		 *  Refresh the mesh without reconstructing all the supporting data. This should be used only
		 *  when the control point positions change.
		 *
		 */
		public function refreshNURBS():Void
		{
			var nV:Vector3D = new Vector3D();
			var subGeom:CompactSubGeometry = CompactSubGeometry(subGeometries[0]);
			var data:Array<Float> = subGeom.vertexData;
			var len:Int = data.length;
			var vertexStride:Int = subGeom.vertexStride;
			var uvIndex:Int = subGeom.UVOffset;
			var uvStride:Int = subGeom.UVStride;
			
			// For loop conversion - 						for (var vBase:UInt = subGeom.vertexOffset; vBase < len; vBase += vertexStride)
			
			var vBase:UInt;
			
			for (vBase in subGeom.vertexOffset...len) {
				nurbPoint(data[uvIndex], data[uint(uvIndex + 1)], nV);
				data[vBase] = nV.x;
				data[uint(vBase + 1)] = nV.y;
				data[uint(vBase + 2)] = nV.z;
				uvIndex += uvStride;
			}
			
			subGeom.updateData(data);
		}
	}

