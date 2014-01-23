/**
 * Provides an interface for picking objects that can pick 3d objects from a view or scene.
 */
package away3d.core.pick;

import flash.geom.Vector3D;
import away3d.containers.Scene3D;
import away3d.containers.View3D;
interface IPicker {
    var onlyMouseEnabled(get_onlyMouseEnabled, set_onlyMouseEnabled):Bool;

/**
	 * Gets the collision object from the screen coordinates of the picking ray.
	 *
	 * @param x The x coordinate of the picking ray in screen-space.
	 * @param y The y coordinate of the picking ray in screen-space.
	 * @param view The view on which the picking object acts.
	 */
    function getViewCollision(x:Float, y:Float, view:View3D):PickingCollisionVO;
/**
	 * Gets the collision object from the scene position and direction of the picking ray.
	 *
	 * @param position The position of the picking ray in scene-space.
	 * @param direction The direction of the picking ray in scene-space.
	 * @param scene The scene on which the picking object acts.
	 */
    function getSceneCollision(position:Vector3D, direction:Vector3D, scene:Scene3D):PickingCollisionVO;
/**
	 * Determines whether the picker takes account of the mouseEnabled properties of entities. Defaults to true.
	 */
    function get_onlyMouseEnabled():Bool;
    function set_onlyMouseEnabled(value:Bool):Bool;
/**
	 * Disposes memory used by the IPicker object
	 */
    function dispose():Void;
}

