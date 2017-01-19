package away3d.core.base.data;

import openfl.geom.Point;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * Face value object.
 */
class Face
{
	public var faceIndex(get, set):Int;
	public var uv0Index(get, set):Int;
	public var uv0u(get, never):Float;
	public var uv0v(get, never):Float;
	public var uv1Index(get, set):Int;
	public var uv1u(get, never):Float;
	public var uv1v(get, never):Float;
	public var uv2Index(get, set):Int;
	public var uv2u(get, never):Float;
	public var uv2v(get, never):Float;
	public var v0Index(get, set):Int;
	public var v0(get, never):Vector<Float>;
	public var v0x(get, never):Float;
	public var v0y(get, never):Float;
	public var v0z(get, never):Float;
	public var v1Index(get, set):Int;
	public var v1(get, never):Vector<Float>;
	public var v1x(get, never):Float;
	public var v1y(get, never):Float;
	public var v1z(get, never):Float;
	public var v2Index(get, set):Int;
	public var v2(get, never):Vector<Float>;
	public var v2x(get, never):Float;
	public var v2y(get, never):Float;
	public var v2z(get, never):Float;
	
	private static var _calcPoint:Point;
	
	private var _vertices:Vector<Float>;
	private var _uvs:Vector<Float>;
	private var _faceIndex:Int;
	private var _v0Index:Int;
	private var _v1Index:Int;
	private var _v2Index:Int;
	private var _uv0Index:Int;
	private var _uv1Index:Int;
	private var _uv2Index:Int;
	
	/**
	 * Creates a new <code>Face</code> value object.
	 *
	 * @param    vertices        [optional] 9 entries long Vector.&lt;Number&gt; representing the x, y and z of v0, v1, and v2 of a face
	 * @param    uvs            [optional] 6 entries long Vector.&lt;Number&gt; representing the u and v of uv0, uv1, and uv2 of a face
	 */
	public function new(vertices:Vector<Float> = null, uvs:Vector<Float> = null)
	{
		_vertices = vertices;
		if (_vertices == null) _vertices = Vector.ofArray([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]);
		_uvs = uvs;
		if (_uvs == null) _uvs = Vector.ofArray([0.0, 0.0, 0.0, 0.0, 0.0, 0.0]);
	}
	
	//uvs
	/**
	 * To set uv values for either uv0, uv1 or uv2.
	 * @param    index        The id of the uv (0, 1 or 2)
	 * @param    u            The horizontal coordinate of the texture value.
	 * @param    v            The vertical coordinate of the texture value.
	 */
	public function setUVat(index:Int, u:Float, v:Float):Void
	{
		var ind:Int = (index*2);
		_uvs[ind] = u;
		_uvs[ind + 1] = v;
	}
	
	/**
	 * To store a temp index of a face during a loop
	 * @param    ind        The index
	 */
	private function set_faceIndex(ind:Int):Int
	{
		_faceIndex = ind;
		return ind;
	}
	
	/**
	 * @return            Returns the tmp index set for this Face object
	 */
	private function get_faceIndex():Int
	{
		return _faceIndex;
	}
	
	//uv0
	/**
	 * the index set for uv0 in this Face value object
	 * @param    ind        The index
	 */
	private function set_uv0Index(ind:Int):Int
	{
		_uv0Index = ind;
		return ind;
	}
	
	/**
	 * @return return the index set for uv0 in this Face value object
	 */
	private function get_uv0Index():Int
	{
		return _uv0Index;
	}
	
	/**
	 * uv0 u and v values
	 * @param    u        The u value
	 * @param    v        The v value
	 */
	public function setUv0Value(u:Float, v:Float):Void
	{
		_uvs[0] = u;
		_uvs[1] = v;
	}
	
	/**
	 * @return return the u value of the uv0 of this Face value object
	 */
	private function get_uv0u():Float
	{
		return _uvs[0];
	}
	
	/**
	 * @return return the v value of the uv0 of this Face value object
	 */
	private function get_uv0v():Float
	{
		return _uvs[1];
	}
	
	//uv1
	/**
	 * the index set for uv1 in this Face value object
	 * @param    ind        The index
	 */
	private function set_uv1Index(ind:Int):Int
	{
		_uv1Index = ind;
		return ind;
	}
	
	/**
	 * @return Returns the index set for uv1 in this Face value object
	 */
	private function get_uv1Index():Int
	{
		return _uv1Index;
	}
	
	/**
	 * uv1 u and v values
	 * @param    u        The u value
	 * @param    v        The v value
	 */
	public function setUv1Value(u:Float, v:Float):Void
	{
		_uvs[2] = u;
		_uvs[3] = v;
	}
	
	/**
	 * @return Returns the u value of the uv1 of this Face value object
	 */
	private function get_uv1u():Float
	{
		return _uvs[2];
	}
	
	/**
	 * @return Returns the v value of the uv1 of this Face value object
	 */
	private function get_uv1v():Float
	{
		return _uvs[3];
	}
	
	//uv2
	/**
	 * the index set for uv2 in this Face value object
	 * @param    ind        The index
	 */
	private function set_uv2Index(ind:Int):Int
	{
		_uv2Index = ind;
		return ind;
	}
	
	/**
	 * @return return the index set for uv2 in this Face value object
	 */
	private function get_uv2Index():Int
	{
		return _uv2Index;
	}
	
	/**
	 * uv2 u and v values
	 * @param    u        The u value
	 * @param    v        The v value
	 */
	public function setUv2Value(u:Float, v:Float):Void
	{
		_uvs[4] = u;
		_uvs[5] = v;
	}
	
	/**
	 * @return return the u value of the uv2 of this Face value object
	 */
	private function get_uv2u():Float
	{
		return _uvs[4];
	}
	
	/**
	 * @return return the v value of the uv2 of this Face value object
	 */
	private function get_uv2v():Float
	{
		return _uvs[5];
	}
	
	//vertices
	/**
	 * To set uv values for either v0, v1 or v2.
	 * @param    index        The id of the uv (0, 1 or 2)
	 * @param    x            The x value of the vertex.
	 * @param    y            The y value of the vertex.
	 * @param    z            The z value of the vertex.
	 */
	public function setVertexAt(index:Int, x:Float, y:Float, z:Float):Void
	{
		var ind:Int = (index*3);
		_vertices[ind] = x;
		_vertices[ind + 1] = y;
		_vertices[ind + 2] = z;
	}
	
	//v0
	/**
	 * set the index value for v0
	 * @param    ind            The index value to store
	 */
	private function set_v0Index(ind:Int):Int
	{
		_v0Index = ind;
		return ind;
	}
	
	/**
	 * @return Returns the index value of the v0 stored in the Face value object
	 */
	private function get_v0Index():Int
	{
		return _v0Index;
	}
	
	/**
	 * @return Returns a Vector.<Number> representing the v0 stored in the Face value object
	 */
	private function get_v0():Vector<Float>
	{
		return Vector.ofArray([_vertices[0], _vertices[1], _vertices[2]]);
	}
	
	/**
	 * @return Returns the x value of the v0 stored in the Face value object
	 */
	private function get_v0x():Float
	{
		return _vertices[0];
	}
	
	/**
	 * @return Returns the y value of the v0 stored in the Face value object
	 */
	private function get_v0y():Float
	{
		return _vertices[1];
	}
	
	/**
	 * @return Returns the z value of the v0 stored in the Face value object
	 */
	private function get_v0z():Float
	{
		return _vertices[2];
	}
	
	//v1
	/**
	 * set the index value for v1
	 * @param    ind            The index value to store
	 */
	private function set_v1Index(ind:Int):Int
	{
		_v1Index = ind;
		return ind;
	}
	
	/**
	 * @return Returns the index value of the v1 stored in the Face value object
	 */
	private function get_v1Index():Int
	{
		return _v1Index;
	}
	
	/**
	 * @return Returns a Vector.<Number> representing the v1 stored in the Face value object
	 */
	private function get_v1():Vector<Float>
	{
		return Vector.ofArray([_vertices[3], _vertices[4], _vertices[5]]);
	}
	
	/**
	 * @return Returns the x value of the v1 stored in the Face value object
	 */
	private function get_v1x():Float
	{
		return _vertices[3];
	}
	
	/**
	 * @return Returns the y value of the v1 stored in the Face value object
	 */
	private function get_v1y():Float
	{
		return _vertices[4];
	}
	
	/**
	 * @return Returns the z value of the v1 stored in the Face value object
	 */
	private function get_v1z():Float
	{
		return _vertices[5];
	}
	
	//v2
	/**
	 * set the index value for v2
	 * @param    ind            The index value to store
	 */
	private function set_v2Index(ind:Int):Int
	{
		_v2Index = ind;
		return ind;
	}
	
	/**
	 * @return return the index value of the v2 stored in the Face value object
	 */
	private function get_v2Index():Int
	{
		return _v2Index;
	}
	
	/**
	 * @return Returns a Vector.<Number> representing the v2 stored in the Face value object
	 */
	private function get_v2():Vector<Float>
	{
		return Vector.ofArray([_vertices[6], _vertices[7], _vertices[8]]);
	}
	
	/**
	 * @return Returns the x value of the v2 stored in the Face value object
	 */
	private function get_v2x():Float
	{
		return _vertices[6];
	}
	
	/**
	 * @return Returns the y value of the v2 stored in the Face value object
	 */
	private function get_v2y():Float
	{
		return _vertices[7];
	}
	
	/**
	 * @return Returns the z value of the v2 stored in the Face value object
	 */
	private function get_v2z():Float
	{
		return _vertices[8];
	}
	
	/**
	 * returns a new Face value Object
	 */
	public function clone():Face
	{
		var nVertices:Vector<Float> = Vector.ofArray([	 _vertices[0], _vertices[1], _vertices[2],
			_vertices[3], _vertices[4], _vertices[5],
			_vertices[6], _vertices[7], _vertices[8]]);
		
		var nUvs:Vector<Float> = Vector.ofArray([_uvs[0], _uvs[1],
			_uvs[2], _uvs[3],
			_uvs[4], _uvs[5]]);
		
		return new Face(nVertices, nUvs);
	}
	
	/**
	 * Returns the first two barycentric coordinates for a point on (or outside) the triangle. The third coordinate is 1 - x - y
	 * @param point The point for which to calculate the new target
	 * @param target An optional Point object to store the calculation in order to prevent creation of a new object
	 */
	public function getBarycentricCoords(point:Vector3D, target:Point = null):Point
	{
		var v0x:Float = _vertices[0];
		var v0y:Float = _vertices[1];
		var v0z:Float = _vertices[2];
		var dx0:Float = point.x - v0x;
		var dy0:Float = point.y - v0y;
		var dz0:Float = point.z - v0z;
		var dx1:Float = _vertices[3] - v0x;
		var dy1:Float = _vertices[4] - v0y;
		var dz1:Float = _vertices[5] - v0z;
		var dx2:Float = _vertices[6] - v0x;
		var dy2:Float = _vertices[7] - v0y;
		var dz2:Float = _vertices[8] - v0z;
		
		var dot01:Float = dx1*dx0 + dy1*dy0 + dz1*dz0;
		var dot02:Float = dx2*dx0 + dy2*dy0 + dz2*dz0;
		var dot11:Float = dx1*dx1 + dy1*dy1 + dz1*dz1;
		var dot22:Float = dx2*dx2 + dy2*dy2 + dz2*dz2;
		var dot12:Float = dx2*dx1 + dy2*dy1 + dz2*dz1;
		
		var invDenom:Float = 1/(dot22*dot11 - dot12*dot12);
		if (target == null) target = new Point();
		target.x = (dot22*dot01 - dot12*dot02)*invDenom;
		target.y = (dot11*dot02 - dot12*dot01)*invDenom;
		return target;
	}
	
	/**
	 * Tests whether a given point is inside the triangle
	 * @param point The point to test against
	 * @param maxDistanceToPlane The minimum distance to the plane for the point to be considered on the triangle. This is usually used to allow for rounding error, but can also be used to perform a volumetric test.
	 */
	public function containsPoint(point:Vector3D, maxDistanceToPlane:Float = .007):Bool
	{
		if (!planeContains(point, maxDistanceToPlane))
			return false;
		
		if (_calcPoint == null) _calcPoint = new Point();
		getBarycentricCoords(point, _calcPoint);
		var s:Float = _calcPoint.x;
		var t:Float = _calcPoint.y;
		return s >= 0.0 && t >= 0.0 && (s + t) <= 1.0;
	}
	
	private function planeContains(point:Vector3D, epsilon:Float = .007):Bool
	{
		var v0x:Float = _vertices[0];
		var v0y:Float = _vertices[1];
		var v0z:Float = _vertices[2];
		var d1x:Float = _vertices[3] - v0x;
		var d1y:Float = _vertices[4] - v0y;
		var d1z:Float = _vertices[5] - v0z;
		var d2x:Float = _vertices[6] - v0x;
		var d2y:Float = _vertices[7] - v0y;
		var d2z:Float = _vertices[8] - v0z;
		var a:Float = d1y*d2z - d1z*d2y;
		var b:Float = d1z*d2x - d1x*d2z;
		var c:Float = d1x*d2y - d1y*d2x;
		var len:Float = 1/Math.sqrt(a*a + b*b + c*c);
		a *= len;
		b *= len;
		c *= len;
		var dist:Float = a*(point.x - v0x) + b*(point.y - v0y) + c*(point.z - v0z);
		return dist > -epsilon && dist < epsilon;
	}
	
	/**
	 * Returns the target coordinates for a point on a triangle
	 * @param v0 The triangle's first vertex
	 * @param v1 The triangle's second vertex
	 * @param v2 The triangle's third vertex
	 * @param uv0 The UV coord associated with the triangle's first vertex
	 * @param uv1 The UV coord associated with the triangle's second vertex
	 * @param uv2 The UV coord associated with the triangle's third vertex
	 * @param point The point for which to calculate the new target
	 * @param target An optional UV object to store the calculation in order to prevent creation of a new object
	 */
	public function getUVAtPoint(point:Vector3D, target:UV = null):UV
	{
		if (_calcPoint == null)_calcPoint = new Point();
		getBarycentricCoords(point, _calcPoint);
		
		var s:Float = _calcPoint.x;
		var t:Float = _calcPoint.y;
		
		if (s >= 0.0 && t >= 0.0 && (s + t) <= 1.0) {
			var u0:Float = _uvs[0];
			var v0:Float = _uvs[1];
			if (target == null) target = new UV();
			target.u = u0 + t*(_uvs[4] - u0) + s*(_uvs[2] - u0);
			target.v = v0 + t*(_uvs[5] - v0) + s*(_uvs[3] - v0);
			return target;
		} else
			return null;
	}
}