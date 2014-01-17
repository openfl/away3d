/**
 * Dispatched to notify changes in an animator's state.
 */
package away3d.events;


import away3d.animators.AnimatorBase;
import away3d.animators.AnimatorBase;
import flash.events.Event;
class AnimatorEvent extends Event {
    public var animator(get_animator, never):AnimatorBase;

/**
	 * Defines the value of the type property of a start event object.
	 */
    static public var START:String = "start";
/**
	 * Defines the value of the type property of a stop event object.
	 */
    static public var STOP:String = "stop";
/**
	 * Defines the value of the type property of a cycle complete event object.
	 */
    static public var CYCLE_COMPLETE:String = "cycle_complete";
    private var _animator:AnimatorBase;
/**
	 * Create a new <code>AnimatorEvent</code> object.
	 *
	 * @param type The event type.
	 * @param animator The animator object that is the subject of this event.
	 */

    public function new(type:String, animator:AnimatorBase) {
        super(type, false, false);
        _animator = animator;
    }

    public function get_animator():AnimatorBase {
        return _animator;
    }

/**
	 * Clones the event.
	 *
	 * @return An exact duplicate of the current event object.
	 */

    override public function clone():Event {
        return new AnimatorEvent(type, _animator);
    }

}

