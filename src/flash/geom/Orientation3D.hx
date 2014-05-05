package flash.geom;

/**
 * The Orientation3D class is an enumeration of constant values for representing the 
 * orientation style of a Matrix3D object. The three types of orientation are Euler 
 * angles, axis angle, and quaternion. The decompose and recompose methods of the 
 * Matrix3D object take one of these enumerated types to identify the rotational 
 * components of the Matrix.
 */
enum Orientation3D {
	AXIS_ANGLE;
	EULER_ANGLES;
	QUATERNION;
}