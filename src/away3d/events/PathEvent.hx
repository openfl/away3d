package away3d.events;

import flash.events.Event;

class PathEvent extends Event {

/**
	 * Dispatched when the time pointer enter a new cycle at time 0, after last time was greater than 0.99
	 */
    static public var CYCLE:String = "cycle";
/**
	 * Dispatched when the time pointer is included a given from/to time region on a path
	 */
    static public var RANGE:String = "range";
/**
	 * Dispatched when the time pointer enters a new PathSegment
	 */
    static public var CHANGE_SEGMENT:String = "change_segment";

    public function new(type:String) {
        super(type);
    }

}

