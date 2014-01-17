/**
 *
 */
package away3d.events;

import flash.events.Event;

class Stage3DEvent extends Event {

    static public var CONTEXT3D_CREATED:String = "Context3DCreated";
    static public var CONTEXT3D_DISPOSED:String = "Context3DDisposed";
    static public var CONTEXT3D_RECREATED:String = "Context3DRecreated";
    static public var VIEWPORT_UPDATED:String = "ViewportUpdated";

    public function new(type:String, bubbles:Bool = false, cancelable:Bool = false) {
        super(type, bubbles, cancelable);
    }

}

