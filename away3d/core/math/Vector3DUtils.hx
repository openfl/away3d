package away3d.core.math;

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * Vector3DUtils provides additional Vector3D math functions.
 */
class Vector3DUtils
{
	private static var MathPI:Float = Math.PI;
	
	/**
	 * Returns the angle in radians made between the 3d number obejct and the given <code>Vector3D</code> object.
	 *
	 * @param    w                The first 3d number object to use in the calculation.
	 * @param    q                The first 3d number object to use in the calculation.
	 * @return                    An angle in radians representing the angle between the two <code>Vector3D</code> objects.
	 */
	public static function getAngle(w:Vector3D, q:Vector3D):Float
	{
		return Math.acos(w.dotProduct(q)/(w.length*q.length));
	}
	
	/**
	 * Returns a <code>Vector3D</code> object with the euler angles represented by the 3x3 matrix rotation of the given <code>Matrix3D</code> object.
	 *
	 * @param    m1    The 3d matrix object to use in the calculation.
	 * @return        A 3d vector representing the euler angles extracted from the 3d matrix.
	 */
	public static function matrix2euler(m1:Matrix3D):Vector3D
	{
		var m2:Matrix3D = new Matrix3D();
		var result:Vector3D = new Vector3D();
		var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
		m1.copyRawDataTo(raw);
		
		// Extract the first angle, rotationX
		result.x = -Math.atan2(raw[(6)], raw[(10)]); // rot.x = Math<T>::atan2 (M[1][2], M[2][2]);
		
		// Remove the rotationX rotation from m2, so that the remaining
		// rotation, m2 is only around two axes, and gimbal lock cannot occur.
		m2.appendRotation(result.x*180/MathPI, new Vector3D(1, 0, 0));
		m2.append(m1);
		
		m2.copyRawDataTo(raw);
		
		// Extract the other two angles, rot.y and rot.z, from m2.
		var cy:Float = Math.sqrt(raw[(0)] * raw[(0)] + raw[(1)] * raw[(1)]); // T cy = Math<T>::sqrt (N[0][0]*N[0][0] + N[0][1]*N[0][1]);
		
		result.y = Math.atan2(-raw[(2)], cy); // rot.y = Math<T>::atan2 (-N[0][2], cy);
		result.z = Math.atan2(-raw[(4)], raw[(5)]); //rot.z = Math<T>::atan2 (-N[1][0], N[1][1]);
		
		// Fix angles
		if (Math.round(result.z/MathPI) == 1) {
			if (result.y > 0)
				result.y = -(result.y - MathPI);
			else
				result.y = -(result.y + MathPI);
			
			result.z -= MathPI;
			
			if (result.x > 0)
				result.x -= MathPI;
			else
				result.x += MathPI;
		} else if (Math.round(result.z/MathPI) == -1) {
			if (result.y > 0)
				result.y = -(result.y - MathPI);
			else
				result.y = -(result.y + MathPI);
			
			result.z += MathPI;
			
			if (result.x > 0)
				result.x -= MathPI;
			else
				result.x += MathPI;
		} else if (Math.round(result.x/MathPI) == 1) {
			if (result.y > 0)
				result.y = -(result.y - MathPI);
			else
				result.y = -(result.y + MathPI);
			
			result.x -= MathPI;
			
			if (result.z > 0)
				result.z -= MathPI;
			else
				result.z += MathPI;
		} else if (Math.round(result.x/MathPI) == -1) {
			if (result.y > 0)
				result.y = -(result.y - MathPI);
			else
				result.y = -(result.y + MathPI);
			
			result.x += MathPI;
			
			if (result.z > 0)
				result.z -= MathPI;
			else
				result.z += MathPI;
		}
		
		return result;
	}
	
	/**
	 * Returns a <code>Vector3D</code> object containing the euler angles represented by the given <code>Quaternion</code> object.
	 *
	 * @param    quaternion    The quaternion object to use in the calculation.
	 * @return                A 3d vector representing the euler angles extracted from the quaternion.
	 */
	
	public static function quaternion2euler(quarternion:Quaternion):Vector3D
	{
		var result:Vector3D = new Vector3D();
		
		var test:Float = quarternion.x*quarternion.y + quarternion.z*quarternion.w;
		if (test > 0.499) { // singularity at north pole
			result.x = 2*Math.atan2(quarternion.x, quarternion.w);
			result.y = Math.PI/2;
			result.z = 0;
			return result;
		}
		if (test < -0.499) { // singularity at south pole
			result.x = -2*Math.atan2(quarternion.x, quarternion.w);
			result.y = -Math.PI/2;
			result.z = 0;
			return result;
		}
		
		var sqx:Float = quarternion.x*quarternion.x;
		var sqy:Float = quarternion.y*quarternion.y;
		var sqz:Float = quarternion.z*quarternion.z;
		
		result.x = Math.atan2(2*quarternion.y*quarternion.w - 2*quarternion.x*quarternion.z, 1 - 2*sqy - 2*sqz);
		result.y = Math.asin(2*test);
		result.z = Math.atan2(2*quarternion.x*quarternion.w - 2*quarternion.y*quarternion.z, 1 - 2*sqx - 2*sqz);
		
		return result;
	}
	
	/**
	 * Returns a <code>Vector3D</code> object containing the scale values represented by the given <code>Matrix3D</code> object.
	 *
	 * @param    m    The 3d matrix object to use in the calculation.
	 * @return        A 3d vector representing the axis scale values extracted from the 3d matrix.
	 */
	public static function matrix2scale(m:Matrix3D):Vector3D
	{
		var result:Vector3D = new Vector3D();
		var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
		m.copyRawDataTo(raw);
		
		result.x = Math.sqrt(raw[(0)] * raw[(0)] + raw[(1)] * raw[(1)] + raw[(2)] * raw[(2)]);
		result.y = Math.sqrt(raw[(4)] * raw[(4)] + raw[(5)] * raw[(5)] + raw[(6)] * raw[(6)]);
		result.z = Math.sqrt(raw[(8)] * raw[(8)] + raw[(9)] * raw[(9)] + raw[(10)] * raw[(10)]);
		
		return result;
	}
	
	public static function rotatePoint(aPoint:Vector3D, rotation:Vector3D):Vector3D
	{
		if (rotation.x != 0 || rotation.y != 0 || rotation.z != 0) {
			
			var x1:Float;
			var y1:Float;
			
			var rad:Float = MathConsts.DEGREES_TO_RADIANS;
			var rotx:Float = rotation.x * rad;
			var roty:Float = rotation.y * rad;
			var rotz:Float = rotation.z * rad;
			
			var sinx:Float = Math.sin(rotx);
			var cosx:Float = Math.cos(rotx);
			var siny:Float = Math.sin(roty);
			var cosy:Float = Math.cos(roty);
			var sinz:Float = Math.sin(rotz);
			var cosz:Float = Math.cos(rotz);
			
			var x:Float = aPoint.x;
			var y:Float = aPoint.y;
			var z:Float = aPoint.z;
			
			y1 = y;
			y = y1*cosx + z* -sinx;
			z = y1*sinx + z*cosx;
			
			x1 = x;
			x = x1*cosy + z*siny;
			z = x1* -siny + z*cosy;
			
			x1 = x;
			x = x1*cosz + y* -sinz;
			y = x1*sinz + y*cosz;
			
			aPoint.x = x;
			aPoint.y = y;
			aPoint.z = z;
		}
		
		return aPoint;
	}

	public static function subdivide(startVal:Vector3D, endVal:Vector3D, numSegments:Int):Vector<Vector3D>
	{
		var points:Vector<Vector3D> = new Vector<Vector3D>();
		var numPoints:Int = 0;
		var stepx:Float = (endVal.x - startVal.x)/numSegments;
		var stepy:Float = (endVal.y - startVal.y)/numSegments;
		var stepz:Float = (endVal.z - startVal.z)/numSegments;
		
		var step:Int = 1;
		var scalestep:Vector3D;
		
		while (step < numSegments) {
			scalestep = new Vector3D();
			scalestep.x = startVal.x + (stepx*step);
			scalestep.y = startVal.y + (stepy*step);
			scalestep.z = startVal.z + (stepz*step);
			points[numPoints++] = scalestep;
			
			step++;
		}
		
		points[numPoints] = endVal;
		
		return points;
	}
}