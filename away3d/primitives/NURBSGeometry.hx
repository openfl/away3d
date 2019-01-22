package away3d.primitives;

import away3d.core.base.CompactSubGeometry;
import away3d.primitives.data.NURBSVertex;

import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * A NURBS primitive geometry.
 */
class NURBSGeometry extends PrimitiveBase
{
	public var controlNet(get, set):Vector<NURBSVertex>;
	public var uOrder(get, set):Int;
	public var vOrder(get, set):Int;
	public var uControlPoints(get, set):Int;
	public var vControlPoints(get, set):Int;
	public var uKnot(get, set):Vector<Float>;
	public var vKnot(get, set):Vector<Float>;
	public var uSegments(get, set):Int;
	public var vSegments(get, set):Int;
	
	private var _controlNet:Vector<NURBSVertex>;
	private var _uOrder:Int;
	private var _vOrder:Int;
	private var _numVContolPoints:Int;
	private var _numUContolPoints:Int;
	private var _uSegments:Int;
	private var _vSegments:Int;
	private var _uKnotSequence:Vector<Float>;
	private var _vKnotSequence:Vector<Float>;
	private var _mbasis:Vector<Float> = new Vector<Float>();
	private var _nbasis:Vector<Float> = new Vector<Float>();
	private var _nplusc:Int;
	private var _mplusc:Int;
	private var _uRange:Float;
	private var _vRange:Float;
	private var _autoGenKnotSeq:Bool = true;
	private var _invert:Bool;
	private var _tmpPM:Vector3D = new Vector3D();
	private var _tmpP1:Vector3D = new Vector3D();
	private var _tmpP2:Vector3D = new Vector3D();
	private var _tmpN1:Vector3D = new Vector3D();
	private var _tmpN2:Vector3D = new Vector3D();
	private var _rebuildUVs:Bool;
	
	/**
	 * Defines the control point net to describe the NURBS surface
	 */
	private function get_controlNet():Vector<NURBSVertex>
	{
		return _controlNet;
	}
	
	private function set_controlNet(value:Vector<NURBSVertex>):Vector<NURBSVertex>
	{
		if (_controlNet == value)
			return value;
		
		_controlNet = value;
		invalidateGeometry();
		invalidateUVs();
		return value;
	}
	
	/**
	 * Defines the number of control points along the U splines that influence any given point on the curve
	 */
	private function get_uOrder():Int
	{
		return _uOrder;
	}
	
	private function set_uOrder(value:Int):Int
	{
		if (_uOrder == value)
			return value;
		
		_uOrder = value;
		invalidateGeometry();
		invalidateUVs();
		return value;
	}
	
	/**
	 * Defines the number of control points along the V splines that influence any given point on the curve
	 */
	private function get_vOrder():Int
	{
		return _vOrder;
	}
	
	private function set_vOrder(value:Int):Int
	{
		if (_vOrder == value)
			return value;
		
		_vOrder = value;
		invalidateGeometry();
		invalidateUVs();
		return value;
	}
	
	/**
	 * Defines the number of control points along the U splines
	 */
	private function get_uControlPoints():Int
	{
		return _numUContolPoints;
	}
	
	private function set_uControlPoints(value:Int):Int
	{
		if (_numUContolPoints == value)
			return value;
		
		_numUContolPoints = value;
		invalidateGeometry();
		invalidateUVs();
		return value;
	}
	
	/**
	 * Defines the number of control points along the V splines
	 */
	private function get_vControlPoints():Int
	{
		return _numVContolPoints;
	}
	
	private function set_vControlPoints(value:Int):Int
	{
		if (_numVContolPoints == value)
			return value;
		
		_numVContolPoints = value;
		invalidateGeometry();
		invalidateUVs();
		return value;
	}
	
	/**
	 * Defines the knot sequence in the U direction that determines where and how the control points
	 * affect the NURBS curve.
	 */
	private function get_uKnot():Vector<Float>
	{
		return _uKnotSequence;
	}
	
	private function set_uKnot(value:Vector<Float>):Vector<Float>
	{
		if (_uKnotSequence == value)
			return value;
		
		_uKnotSequence = value;
		
		_autoGenKnotSeq = ((_uKnotSequence == null || _uKnotSequence.length == 0) || (_vKnotSequence == null || _vKnotSequence.length == 0));
		
		invalidateGeometry();
		invalidateUVs();
		return value;
	}
	
	/**
	 * Defines the knot sequence in the V direction that determines where and how the control points
	 * affect the NURBS curve.
	 */
	private function get_vKnot():Vector<Float>
	{
		return _vKnotSequence;
	}
	
	private function set_vKnot(value:Vector<Float>):Vector<Float>
	{
		if (_vKnotSequence == value)
			return value;
		
		_vKnotSequence = value;
		
		_autoGenKnotSeq = ((_uKnotSequence == null || _uKnotSequence.length == 0) || (_vKnotSequence == null || _vKnotSequence.length == 0));
		
		invalidateGeometry();
		invalidateUVs();
		return value;
	}
	
	/**
	 * Defines the number segments (triangle pair) the final curve will be divided into in the U direction
	 */
	private function get_uSegments():Int
	{
		return _uSegments;
	}
	
	private function set_uSegments(value:Int):Int
	{
		if (_uSegments == value)
			return value;
		
		_uSegments = value;
		invalidateGeometry();
		invalidateUVs();
		return value;
	}
	
	/**
	 * Defines the number segments (triangle pair) the final curve will be divided into in the V direction
	 */
	private function get_vSegments():Int
	{
		return _vSegments;
	}
	
	private function set_vSegments(value:Int):Int
	{
		if (_vSegments == value)
			return value;
		
		_vSegments = value;
		invalidateGeometry();
		invalidateUVs();
		return value;
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
	public function new(cNet:Vector<NURBSVertex>, uCtrlPnts:Int, vCtrlPnts:Int, uOrder:Int = 4, vOrder:Int = 4, uSegments:Int = 10, vSegments:Int = 10, uKnot:Vector<Float> = null, vKnot:Vector<Float> = null)
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
		_autoGenKnotSeq = ((_uKnotSequence == null || _uKnotSequence.length == 0) || (_vKnotSequence == null || _vKnotSequence.length == 0));
		
		_rebuildUVs = true;
		invalidateGeometry();
		invalidateUVs();
	}
	
	/** @private */
	@:allow(away3d) private function nurbPoint(nU:Float, nV:Float, target:Vector3D = null):Vector3D
	{
		var pbasis:Float;
		var jbas:Int;
		var j1:Int;
		var u:Float = _uKnotSequence[1] + (_uRange*nU);
		var v:Float = _vKnotSequence[1] + (_vRange*nV);
		
		if (target != null)
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
		for (i in 1..._numVContolPoints + 1) {
			if (_mbasis[i] != 0) {
				jbas = _numUContolPoints*(i - 1);
				for (j in 1..._numUContolPoints + 1) {
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
	@:allow(away3d) private function sumrbas():Float
	{
		var i:Int;
		var j:Int;
		var jbas:Int = 0;
		var j1:Int = 0;
		var sum:Float;
		
		sum = 0;
		
		for (i in 1..._numVContolPoints + 1) {
			if (_mbasis[i] != 0) {
				jbas = _numUContolPoints*(i - 1);
				for (j in 1..._numUContolPoints + 1) {
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
	@:allow(away3d) private function knot(n:Int, c:Int):Vector<Float>
	{
		var nplusc:Int = n + c;
		var nplus2:Int = n + 2;
		var x:Vector<Float> = new Vector<Float>(36);
		
		x[1] = 0;
		for (i in 2...nplusc + 1) {
			if ((i > c) && (i < nplus2))
				x[i] = x[i - 1] + 1;
			else
				x[i] = x[i - 1];
		}
		return x;
	}
	
	/** @private */
	@:allow(away3d) private function basis(nurbOrder:Int, t:Float, numPoints:Int, knot:Vector<Float>):Vector<Float>
	{
		var nPlusO:Int;
		var i:Int;
		var k:Int;
		var d:Float;
		var e:Float;
		var temp:Vector<Float> = new Vector<Float>(36);
		
		nPlusO = numPoints + nurbOrder;
		
		// calculate the first order basis functions n[i][1]
		for (i in 1...nPlusO)
			temp[i] = (( t >= knot[i]) && (t < knot[i + 1]))? 1 : 0;
		
		// calculate the higher order basis functions 
		for (k in 2...nurbOrder + 1) {
			for (i in 1...nPlusO - k + 1) {
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
		var data:Vector<Float>;
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
		//var icount:int = 0;
		var j:Int;
		
		var indices:Vector<UInt>;
		var numIndices:Int = target.vertexOffset;
		
		if (numVertices == target.numVertices) {
			data = target.vertexData;
			indices = target.indexData;
		} else {
			data = new Vector<Float>(numVertices*stride, true);
			numIndices = (_uSegments)*(_vSegments)*6;
			indices = new Vector<UInt>(numIndices, true);
			invalidateUVs();
		}
		
		// Iterate through the surface points (u=>0-1, v=>0-1)
		var stepuinc:Float = 1/_uSegments;
		var stepvinc:Float = 1/_vSegments;
		
		var vBase:Int = 0;
		var nV:Vector3D;
		var vinc:Float = 0;
		while (vinc < (1 + (stepvinc / 2))) {
			var uinc:Float = 0;
			while (uinc < (1 + (stepuinc / 2))) {
				nV = nurbPoint(uinc, vinc);
				
				data[vBase] = nV.x;
				data[(vBase + 1)] = nV.y;
				data[(vBase + 2)] = nV.z;
				vBase += stride;
				uinc += stepuinc;
			}
			vinc += stepvinc;
		}
		
		// Render the mesh faces
		var vPos:Int = 0;
		var iBase:Int = 0;
		
		for (i in 0..._vSegments + 1) {
			for (j in 0..._uSegments + 1) {
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
		var data:Vector<Float>;
		var stride:Int = target.UVStride;
		var numVertices:Int = (_uSegments + 1)*(_vSegments + 1);
		var uvLen:Int = numVertices*stride;
		var i:Int;
		var j:Int;
		
		if (target.UVData != null && uvLen == target.UVData.length)
			data = target.UVData;
		else {
			data = new Vector<Float>(uvLen, true);
			invalidateGeometry();
		}
		
		var uvBase:Int = target.UVOffset;
		i = _vSegments;
		while (i >= 0) {
			j = _uSegments;
			while (j >= 0) {
				data[(uvBase)] = j/_uSegments;
				data[(uvBase + 1)] = i/_vSegments;
				uvBase += stride;
				j--;
			}
			i--;
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
		var subGeom:CompactSubGeometry = cast(subGeometries[0], CompactSubGeometry);
		var data:Vector<Float> = subGeom.vertexData;
		var len:Int = data.length;
		var vertexStride:Int = subGeom.vertexStride;
		var uvIndex:Int = subGeom.UVOffset;
		var uvStride:Int = subGeom.UVStride;
		
		var vBase:Int = subGeom.vertexOffset;
		while (vBase < len) {
			nurbPoint(data[uvIndex], data[(uvIndex + 1)], nV);
			data[vBase] = nV.x;
			data[(vBase + 1)] = nV.y;
			data[(vBase + 2)] = nV.z;
			uvIndex += uvStride;
			vBase += vertexStride;
		}
		
		subGeom.updateData(data);
	}
}