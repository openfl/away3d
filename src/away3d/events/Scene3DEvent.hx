package away3d.events;

import away3d.containers.ObjectContainer3D;
import flash.events.Event;

class Scene3DEvent extends Event {

    static public var ADDED_TO_SCENE:String = "addedToScene";
    static public var REMOVED_FROM_SCENE:String = "removedFromScene";
    static public var PARTITION_CHANGED:String = "partitionChanged";
    public var objectContainer3D:ObjectContainer3D;
//@:getter(target)
#if flash
    public function get_target():Dynamic {
        return objectContainer3D;
    }
#end

    public function new(type:String, objectContainer:ObjectContainer3D) {
        objectContainer3D = objectContainer;
        super(type);
    }

    override public function clone():Event {
        return new Scene3DEvent(type, objectContainer3D);
    }

}

