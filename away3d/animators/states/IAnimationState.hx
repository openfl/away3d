package away3d.animators.states;

import openfl.geom.*;

interface IAnimationState
{
	var positionDelta(get, never):Vector3D;
	
	function offset(startTime:Int):Void;
	
	function update(time:Int):Void;
	
	/**
	 * Sets the animation phase of the node.
	 *
	 * @param value The phase value to use. 0 represents the beginning of an animation clip, 1 represents the end.
	 */
	function phase(value:Float):Void;
}