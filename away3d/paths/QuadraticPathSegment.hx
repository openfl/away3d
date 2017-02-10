package away3d.paths;

import openfl.geom.Vector3D;

/**
 * Creates a curved line segment definition required for the Path class.
 */
class QuadraticPathSegment implements IPathSegment
{
	/**
	 * Defines the first vector of the PathSegment
	 */
	public var start:Vector3D;
	
	/**
	 * Defines the control vector of the PathSegment
	 */
	public var control:Vector3D;
	
	/**
	 * Defines the control vector of the PathSegment
	 */
	public var end:Vector3D;
	
	public function new(pStart:Vector3D, pControl:Vector3D, pEnd:Vector3D)
	{
		this.start = pStart;
		this.control = pControl;
		this.end = pEnd;
	}
	
	public function toString():String
	{
		return start + ", " + control + ", " + end;
	}
	
	/**
	 * nulls the 3 vectors
	 */
	public function dispose():Void
	{
		start = control = end = null;
	}
	
	public function getPointOnSegment(t:Float, target:Vector3D = null):Vector3D
	{
		var sx:Float = start.x;
		var sy:Float = start.y;
		var sz:Float = start.z;
		var t2Inv:Float = 2*(1 - t);
		
		if (target == null)
			target = new Vector3D();
		
		target.x = sx + t*(t2Inv*(control.x - sx) + t*(end.x - sx));
		target.y = sy + t*(t2Inv*(control.y - sy) + t*(end.y - sy));
		target.z = sz + t*(t2Inv*(control.z - sz) + t*(end.z - sz));
		
		return target;
	}
}