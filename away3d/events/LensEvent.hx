/**
 *
 */
package away3d.events;

import away3d.cameras.lenses.LensBase;

import openfl.events.Event;

class LensEvent extends Event
{
	public var lens(get, never):LensBase;
	
	public static inline var MATRIX_CHANGED:String = "matrixChanged";
	
	private var _lens:LensBase;
	
	public function new(type:String, lens:LensBase, bubbles:Bool = false, cancelable:Bool = false)
	{
		super(type, bubbles, cancelable);
		_lens = lens;
	}
	
	private function get_lens():LensBase
	{
		return _lens;
	}
	
	override public function clone():Event
	{
		return new LensEvent(type, _lens, bubbles, cancelable);
	}
}