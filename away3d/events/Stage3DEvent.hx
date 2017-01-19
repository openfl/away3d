/**
 *
 */
package away3d.events;

import openfl.events.Event;

class Stage3DEvent extends Event
{
	public static inline var CONTEXT3D_CREATED:String = "Context3DCreated";
	public static inline var CONTEXT3D_DISPOSED:String = "Context3DDisposed";
	public static inline var CONTEXT3D_RECREATED:String = "Context3DRecreated";
	public static inline var VIEWPORT_UPDATED:String = "ViewportUpdated";
	
	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false)
	{
		super(type, bubbles, cancelable);
	}
}