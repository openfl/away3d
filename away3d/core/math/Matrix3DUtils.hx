package away3d.core.math;

import openfl.geom.*;
import openfl.Vector;

/**
 * Matrix3DUtils provides additional Matrix3D math functions.
 */
class Matrix3DUtils
{
	/**
	 * A reference to a Vector to be used as a temporary raw data container, to prevent object creation.
	 */
	public static var RAW_DATA_CONTAINER:Vector<Float> = new Vector<Float>(16);
	
	public static var CALCULATION_MATRIX:Matrix3D = new Matrix3D();
	public static var CALCULATION_VECTOR3D:Vector3D = new Vector3D();
	public static var CALCULATION_DECOMPOSE:Vector<Vector3D> = Vector.ofArray([new Vector3D(), new Vector3D(), new Vector3D()]);
	
	/**
	 * Fills the 3d matrix object with values representing the transformation made by the given quaternion.
	 *
	 * @param    quarternion    The quarterion object to convert.
	 */
	public static function quaternion2matrix(quarternion:Quaternion, m:Matrix3D = null):Matrix3D
	{
		var x:Float = quarternion.x;
		var y:Float = quarternion.y;
		var z:Float = quarternion.z;
		var w:Float = quarternion.w;
		
		var xx:Float = x * x;
		var xy:Float = x * y;
		var xz:Float = x * z;
		var xw:Float = x * w;
		
		var yy:Float = y * y;
		var yz:Float = y * z;
		var yw:Float = y * w;
		
		var zz:Float = z * z;
		var zw:Float = z * w;
		
		var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
		raw[0] = 1 - 2 * (yy + zz);
		raw[1] = 2 * (xy + zw);
		raw[2] = 2 * (xz - yw);
		raw[4] = 2 * (xy - zw);
		raw[5] = 1 - 2 * (xx + zz);
		raw[6] = 2 * (yz + xw);
		raw[8] = 2 * (xz + yw);
		raw[9] = 2 * (yz - xw);
		raw[10] = 1 - 2 * (xx + yy);
		raw[3] = raw[7] = raw[11] = raw[12] = raw[13] = raw[14] = 0;
		raw[15] = 1;
		
		if (m != null) {
			m.copyRawDataFrom(raw);
			return m;
		} else
			return new Matrix3D(raw);
	}
	
	/**
	 * Returns a normalised <code>Vector3D</code> object representing the forward vector of the given matrix.
	 * @param    m        The Matrix3D object to use to get the forward vector
	 * @param    v        [optional] A vector holder to prevent make new Vector3D instance if already exists. Default is null.
	 * @return            The forward vector
	 */
	public static function getForward(m:Matrix3D, v:Vector3D = null):Vector3D
	{
		if (v == null)
			v = new Vector3D(0.0, 0.0, 0.0);
		
		m.copyColumnTo(2, v);
		v.normalize();
		
		return v;
	}
	
	/**
	 * Returns a normalised <code>Vector3D</code> object representing the up vector of the given matrix.
	 * @param    m        The Matrix3D object to use to get the up vector
	 * @param    v        [optional] A vector holder to prevent make new Vector3D instance if already exists. Default is null.
	 * @return            The up vector
	 */
	public static function getUp(m:Matrix3D, v:Vector3D = null):Vector3D
	{
		if (v == null)
			v = new Vector3D(0.0, 0.0, 0.0);
		
		m.copyColumnTo(1, v);
		v.normalize();
		
		return v;
	}
	
	/**
	 * Returns a normalised <code>Vector3D</code> object representing the right vector of the given matrix.
	 * @param    m        The Matrix3D object to use to get the right vector
	 * @param    v        [optional] A vector holder to prevent make new Vector3D instance if already exists. Default is null.
	 * @return            The right vector
	 */
	public static function getRight(m:Matrix3D, v:Vector3D = null):Vector3D
	{
		if (v == null)
			v = new Vector3D(0.0, 0.0, 0.0);
		
		m.copyColumnTo(0, v);
		v.normalize();
		
		return v;
	}
	
	/**
	 * Returns a boolean value representing whether there is any significant difference between the two given 3d matrices.
	 */
	public static function compare(m1:Matrix3D, m2:Matrix3D):Bool
	{
		var r1:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
		var r2:Vector<Float> = m2.rawData;
		m1.copyRawDataTo(r1);
		
		for (i in 0...16) {
			if (r1[i] != r2[i])
				return false;
		}
		
		return true;
	}

	public static function lookAt(matrix:Matrix3D, pos:Vector3D, dir:Vector3D, up:Vector3D):Void {
		var dirN:Vector3D;
		var upN:Vector3D;
		var lftN:Vector3D;
		var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
		
		lftN = dir.crossProduct(up);
		lftN.normalize();
		
		upN = lftN.crossProduct(dir);
		upN.normalize();
		dirN = dir.clone();
		dirN.normalize();
		
		raw[0] = lftN.x;
		raw[1] = upN.x;
		raw[2] = -dirN.x;
		raw[3] = 0.0;
		
		raw[4] = lftN.y;
		raw[5] = upN.y;
		raw[6] = -dirN.y;
		raw[7] = 0.0;
		
		raw[8] = lftN.z;
		raw[9] = upN.z;
		raw[10] = -dirN.z;
		raw[11] = 0.0;
		
		raw[12] = -lftN.dotProduct(pos);
		raw[13] = -upN.dotProduct(pos);
		raw[14] = dirN.dotProduct(pos);
		raw[15] = 1.0;
		
		matrix.copyRawDataFrom(raw);
	}
	
	public static function reflection(plane:Plane3D, target:Matrix3D = null):Matrix3D
	{
		if (target == null)
			target = new Matrix3D();
		
		var a:Float = plane.a, b:Float = plane.b, c:Float = plane.c, d:Float = plane.d;
		var rawData:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
		var ab2:Float = -2 * a * b;
		var ac2:Float = -2 * a * c;
		var bc2:Float = -2 * b * c;
		// reflection matrix
		rawData[0] = 1 - 2 * a * a;
		rawData[4] = ab2;
		rawData[8] = ac2;
		rawData[12] = -2 * a * d;
		rawData[1] = ab2;
		rawData[5] = 1 - 2 * b * b;
		rawData[9] = bc2;
		rawData[13] = -2 * b * d;
		rawData[2] = ac2;
		rawData[6] = bc2;
		rawData[10] = 1 - 2 * c * c;
		rawData[14] = -2 * c * d;
		rawData[3] = 0;
		rawData[7] = 0;
		rawData[11] = 0;
		rawData[15] = 1;
		target.copyRawDataFrom(rawData);
		
		return target;
	}
	
	public static function decompose(sourceMatrix:Matrix3D, orientationStyle:Orientation3D = EULER_ANGLES):Vector<Vector3D>
	{
		var raw:Vector<Float> = RAW_DATA_CONTAINER;
		sourceMatrix.copyRawDataTo(raw);
		
		var a:Float = raw[0];
		var e:Float = raw[1];
		var i:Float = raw[2];
		var b:Float = raw[4];
		var f:Float = raw[5];
		var j:Float = raw[6];
		var c:Float = raw[8];
		var g:Float = raw[9];
		var k:Float = raw[10];
		
		var x:Float = raw[12];
		var y:Float = raw[13];
		var z:Float = raw[14];
		
		var tx:Float = Math.sqrt(a * a + e * e + i * i);
		var ty:Float = Math.sqrt(b * b + f * f + j * j);
		var tz:Float = Math.sqrt(c * c + g * g + k * k);
		var tw:Float = 0;
		
		var scaleX:Float = tx;
		var scaleY:Float = ty;
		var scaleZ:Float = tz;
		
		if (a*(f*k - j*g) - e*(b*k - j*c) + i*(b*g - f*c) < 0) {
			scaleZ = -scaleZ;
		}
		
		a = a / scaleX;
		e = e / scaleX;
		i = i / scaleX;
		b = b / scaleY;
		f = f / scaleY;
		j = j / scaleY;
		c = c / scaleZ;
		g = g / scaleZ;
		k = k / scaleZ;
		
		//from away3d-ts
		if (orientationStyle == Orientation3D.EULER_ANGLES) {
			tx = Math.atan2(j, k);
			ty = Math.atan2(-i, Math.sqrt(a * a + e * e));
			var s1:Float = Math.sin(tx);
			var c1:Float = Math.cos(tx);
			tz = Math.atan2(s1*c-c1*b, c1*f - s1*g);
		} else if (orientationStyle == Orientation3D.AXIS_ANGLE) {
			tw = Math.acos((a + f + k - 1) / 2);
			var len:Float = Math.sqrt((j - g) * (j - g) + (c - i) * (c - i) + (e - b) * (e - b));
			if(len == 0)
			{
				tx = 0;
				ty = 1;
				tz = 0;
			}
			else
			{
				tx = (j - g) / len;
				ty = (c - i) / len;
				tz = (e - b) / len;
			}
		} else {//Orientation3D.QUATERNION
			var tr:Float = a + f + k;
			if (tr > 0) {
				tw = Math.sqrt(1 + tr) / 2;
				tx = (j - g) / (4 * tw);
				ty = (c - i) / (4 * tw);
				tz = (e - b) / (4 * tw);
			} else if ((a > f) && (a > k)) {
				tx = Math.sqrt(1 + a - f - k) / 2;
				tw = (j - g) / (4 * tx);
				ty = (e + b) / (4 * tx);
				tz = (c + i) / (4 * tx);
			} else if (f > k) {
				ty = Math.sqrt(1 + f - a - k) / 2;
				tx = (e + b) / (4 * ty);
				tw = (c - i) / (4 * ty);
				tz = (j + g) / (4 * ty);
			} else {
				tz = Math.sqrt(1 + k - a - f) / 2;
				tx = (c + i) / (4 * tz);
				ty = (j + g) / (4 * tz);
				tw = (e - b) / (4 * tz);
			}
		}
		
		var v:Vector<Vector3D> = CALCULATION_DECOMPOSE;
		v[0].x = x;
		v[0].y = y;
		v[0].z = z;
		v[1].x = tx;
		v[1].y = ty;
		v[1].z = tz;
		v[1].w = tw;
		v[2].x = scaleX;
		v[2].y = scaleY;
		v[2].z = scaleZ;
		return v;
	}
	
	public static function transformVector(matrix:Matrix3D, vector:Vector3D, result:Vector3D = null):Vector3D
	{
		if (result == null) result = new Vector3D();
		var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
		matrix.copyRawDataTo(raw);
		var a:Float = raw[0];
		var e:Float = raw[1];
		var i:Float = raw[2];
		var m:Float = raw[3];
		var b:Float = raw[4];
		var f:Float = raw[5];
		var j:Float = raw[6];
		var n:Float = raw[7];
		var c:Float = raw[8];
		var g:Float = raw[9];
		var k:Float = raw[10];
		var o:Float = raw[11];
		var d:Float = raw[12];
		var h:Float = raw[13];
		var l:Float = raw[14];
		var p:Float = raw[15];
		
		var x:Float = vector.x;
		var y:Float = vector.y;
		var z:Float = vector.z;
		result.x = a * x + b * y + c * z + d;
		result.y = e * x + f * y + g * z + h;
		result.z = i * x + j * y + k * z + l;
		result.w = m * x + n * y + o * z + p;
		return result;
	}
	
	public static function deltaTransformVector(matrix:Matrix3D, vector:Vector3D, result:Vector3D = null):Vector3D
	{
		if (result == null) result = new Vector3D();
		var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
		matrix.copyRawDataTo(raw);
		var a:Float = raw[0];
		var e:Float = raw[1];
		var i:Float = raw[2];
		var m:Float = raw[3];
		var b:Float = raw[4];
		var f:Float = raw[5];
		var j:Float = raw[6];
		var n:Float = raw[7];
		var c:Float = raw[8];
		var g:Float = raw[9];
		var k:Float = raw[10];
		var o:Float = raw[11];
		var x:Float = vector.x;
		var y:Float = vector.y;
		var z:Float = vector.z;
		result.x = a * x + b * y + c * z;
		result.y = e * x + f * y + g * z;
		result.z = i * x + j * y + k * z;
		result.w = m * x + n * y + o * z;
		return result;
	}
	
	public static function getTranslation(transform:Matrix3D, result:Vector3D = null):Vector3D
	{
		if(result == null) result = new Vector3D();
		transform.copyColumnTo(3, result);
		return result;
	}
	
	public static function deltaTransformVectors(matrix:Matrix3D, vin:Vector<Float>, vout:Vector<Float>):Void
	{
		var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
		matrix.copyRawDataTo(raw);
		var a:Float = raw[0];
		var e:Float = raw[1];
		var i:Float = raw[2];
		var m:Float = raw[3];
		var b:Float = raw[4];
		var f:Float = raw[5];
		var j:Float = raw[6];
		var n:Float = raw[7];
		var c:Float = raw[8];
		var g:Float = raw[9];
		var k:Float = raw[10];
		var o:Float = raw[11];
		var outIndex:Int = 0;
		var length:Float = vin.length;
		var index:Int = 0;
		while(index<length) {
			var x:Float = vin[index];
			var y:Float = vin[index+1];
			var z:Float = vin[index+2];
			vout[outIndex++] = a * x + b * y + c * z;
			vout[outIndex++] = e * x + f * y + g * z;
			vout[outIndex++] = i * x + j * y + k * z;
			index+=3;
		}
	}
}