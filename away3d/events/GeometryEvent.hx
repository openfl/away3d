package away3d.events;

import away3d.core.base.ISubGeometry;

import openfl.events.Event;

/**
 * Dispatched to notify changes in a geometry object's state.
 *
 * @see away3d.core.base.Geometry
 */
class GeometryEvent extends Event
{
	public var subGeometry(get, never):ISubGeometry;
	
	/**
	 * Dispatched when a SubGeometry was added from the dispatching Geometry.
	 */
	public static inline var SUB_GEOMETRY_ADDED:String = "SubGeometryAdded";
	
	/**
	 * Dispatched when a SubGeometry was removed from the dispatching Geometry.
	 */
	public static inline var SUB_GEOMETRY_REMOVED:String = "SubGeometryRemoved";
	
	public static inline var BOUNDS_INVALID:String = "BoundsInvalid";
	
	private var _subGeometry:ISubGeometry;
	
	/**
	 * Create a new GeometryEvent
	 * @param type The event type.
	 * @param subGeometry An optional SubGeometry object that is the subject of this event.
	 */
	public function new(type:String, subGeometry:ISubGeometry = null)
	{
		super(type, false, false);
		_subGeometry = subGeometry;
	}
	
	/**
	 * The SubGeometry object that is the subject of this event, if appropriate.
	 */
	private function get_subGeometry():ISubGeometry
	{
		return _subGeometry;
	}
	
	/**
	 * Clones the event.
	 * @return An exact duplicate of the current object.
	 */
	override public function clone():Event
	{
		return new GeometryEvent(type, _subGeometry);
	}
}