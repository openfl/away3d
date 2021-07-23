package away3d.events;

import away3d.containers.ObjectContainer3D;
import away3d.containers.View3D;
import away3d.core.base.IRenderable;
import away3d.materials.MaterialBase;

import openfl.events.Event;
import openfl.geom.Point;
import openfl.geom.Vector3D;

class TouchEvent3D extends Event
{
	public var scenePosition(get, never):Vector3D;
	public var sceneNormal(get, never):Vector3D;

	// Private.
	@:allow(away3d) private var _allowedToPropagate:Bool = true;
	@:allow(away3d) private var _parentEvent:TouchEvent3D;
	
	public static inline var TOUCH_END:String = "touchEnd3d";
	public static inline var TOUCH_BEGIN:String = "touchBegin3d";
	public static inline var TOUCH_MOVE:String = "touchMove3d";
	public static inline var TOUCH_OUT:String = "touchOut3d";
	public static inline var TOUCH_OVER:String = "touchOver3d";
	
	/**
	 * The horizontal coordinate at which the event occurred in view coordinates.
	 */
	public var screenX:Float;
	
	/**
	 * The vertical coordinate at which the event occurred in view coordinates.
	 */
	public var screenY:Float;
	
	/**
	 * The view object inside which the event took place.
	 */
	public var view:View3D;
	
	/**
	 * The 3d object inside which the event took place.
	 */
	public var object:ObjectContainer3D;
	
	/**
	 * The renderable inside which the event took place.
	 */
	public var renderable:IRenderable;
	
	/**
	 * The material of the 3d element inside which the event took place.
	 */
	public var material:MaterialBase;
	
	/**
	 * The uv coordinate inside the draw primitive where the event took place.
	 */
	public var uv:Point;
	
	/**
	 * The index of the face where the event took place.
	 */
	public var index:Int;
	
	/**
	 * The index of the subGeometry where the event took place.
	 */
	public var subGeometryIndex:Int;
	
	/**
	 * The position in object space where the event took place
	 */
	public var localPosition:Vector3D;
	
	/**
	 * The normal in object space where the event took place
	 */
	public var localNormal:Vector3D;
	
	/**
	 * Indicates whether the Control key is active (true) or inactive (false).
	 */
	public var ctrlKey:Bool;
	
	/**
	 * Indicates whether the Alt key is active (true) or inactive (false).
	 */
	public var altKey:Bool;
	
	/**
	 * Indicates whether the Shift key is active (true) or inactive (false).
	 */
	public var shiftKey:Bool;
	
	public var touchPointID:Int;
	
	/**
	 * Create a new TouchEvent3D object.
	 * @param type The type of the TouchEvent3D.
	 */
	public function new(type:String)
	{
		super(type, true, true);
	}

	/**
	 * @inheritDoc
	 */
	#if flash
	@:getter(bubbles) function get_bubbles():Bool
	{
		// Don't bubble if propagation has been stopped.
		return this.bubbles && _allowedToPropagate;
	}
	#end
	
	/**
	 * @inheritDoc
	 */
	override public function stopPropagation():Void
	{
		super.stopPropagation();
		_allowedToPropagate = false;
		if (_parentEvent != null)
			_parentEvent._allowedToPropagate = false;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function stopImmediatePropagation():Void
	{
		super.stopImmediatePropagation();
		_allowedToPropagate = false;
		if (_parentEvent != null)
			_parentEvent._allowedToPropagate = false;
	}
	
	/**
	 * Creates a copy of the TouchEvent3D object and sets the value of each property to match that of the original.
	 */
	override public function clone():Event
	{
		var result:TouchEvent3D = new TouchEvent3D(type);
		
		#if flash
		if (isDefaultPrevented())
			result.preventDefault();
		#end
		
		result.screenX = screenX;
		result.screenY = screenY;
		
		result.view = view;
		result.object = object;
		result.renderable = renderable;
		result.material = material;
		result.uv = uv;
		result.localPosition = localPosition;
		result.localNormal = localNormal;
		result.index = index;
		result.subGeometryIndex = subGeometryIndex;
		
		result.ctrlKey = ctrlKey;
		result.shiftKey = shiftKey;
		
		result._parentEvent = this;
		
		return result;
	}
	
	/**
	 * The position in scene space where the event took place
	 */
	private function get_scenePosition():Vector3D
	{
		if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(object, ObjectContainer3D))
			return cast((object), ObjectContainer3D).sceneTransform.transformVector(localPosition)
		else
			return localPosition;
	}
	
	/**
	 * The normal in scene space where the event took place
	 */
	private function get_sceneNormal():Vector3D
	{
		if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(object, ObjectContainer3D)) {
			var sceneNormal:Vector3D = cast((object), ObjectContainer3D).sceneTransform.deltaTransformVector(localNormal);
			sceneNormal.normalize();
			return sceneNormal;
		} else
			return localNormal;
	}
}