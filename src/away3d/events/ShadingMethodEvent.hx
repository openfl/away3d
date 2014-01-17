package away3d.events;

import flash.events.Event;

class ShadingMethodEvent extends Event {

    static public var SHADER_INVALIDATED:String = "ShaderInvalidated";

    public function new(type:String, bubbles:Bool = false, cancelable:Bool = false) {
        super(type, bubbles, cancelable);
    }

}

