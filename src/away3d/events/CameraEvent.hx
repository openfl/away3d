/**
 *
 */
package away3d.events;

import flash.events.Event;
import away3d.cameras.Camera3D;

class CameraEvent extends Event {
    public var camera(get_camera, never):Camera3D;

    static public var LENS_CHANGED:String = "lensChanged";
    private var _camera:Camera3D;

    public function new(type:String, camera:Camera3D, bubbles:Bool = false, cancelable:Bool = false) {
        super(type, bubbles, cancelable);
        _camera = camera;
    }

    public function get_camera():Camera3D {
        return _camera;
    }

    override public function clone():Event {
        return new CameraEvent(type, _camera, bubbles, cancelable);
    }

}

