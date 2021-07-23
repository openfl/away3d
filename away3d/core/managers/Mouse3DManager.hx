package away3d.core.managers;

import away3d.containers.ObjectContainer3D;
import away3d.containers.View3D;
import away3d.core.pick.IPicker;
import away3d.core.pick.PickingCollisionVO;
import away3d.core.pick.PickingType;
import away3d.events.MouseEvent3D;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Stage;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * Mouse3DManager enforces a singleton pattern and is not intended to be instanced.
 * it provides a manager class for detecting 3D mouse hits on View3D objects and sending out 3D mouse events.
 */
class Mouse3DManager
{
	public var forceMouseMove(get, set):Bool;
	public var mousePicker(get, set):IPicker;
	
	private static var _view3Ds:Map<View3D, Int>;
	private static var _view3DLookup:Vector<View3D>;
	private static var _viewCount:Int = 0;
	
	private var _activeView:View3D;
	private var _updateDirty:Bool = true;
	private var _nullVector:Vector3D = new Vector3D();
	private static var _collidingObject:PickingCollisionVO;
	private static var _previousCollidingObject:PickingCollisionVO;
	private static var _collidingViewObjects:Vector<PickingCollisionVO>;
	private static var _queuedEvents:Vector<MouseEvent3D> = new Vector<MouseEvent3D>();
	
	private var _mouseMoveEvent:MouseEvent = new MouseEvent(MouseEvent.MOUSE_MOVE);
	
	private static var _mouseUp:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_UP);
	private static var _mouseClick:MouseEvent3D = new MouseEvent3D(MouseEvent3D.CLICK);
	private static var _mouseOut:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_OUT);
	private static var _mouseDown:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_DOWN);
	private static var _mouseMove:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_MOVE);
	private static var _mouseOver:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_OVER);
	private static var _mouseWheel:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_WHEEL);
	private static var _mouseDoubleClick:MouseEvent3D = new MouseEvent3D(MouseEvent3D.DOUBLE_CLICK);
	private var _forceMouseMove:Bool;
	private var _mousePicker:IPicker = PickingType.RAYCAST_FIRST_ENCOUNTERED;
	private var _childDepth:Int = 0;
	private static var _previousCollidingView:Int = -1;
	private static var _collidingView:Int = -1;
	private var _collidingDownObject:PickingCollisionVO;
	private var _collidingUpObject:PickingCollisionVO;
	
	/**
	 * Creates a new <code>Mouse3DManager</code> object.
	 */
	public function new()
	{
		if (_view3Ds == null) {
			_view3Ds = new Map<View3D, Int>();
			_view3DLookup = new Vector<View3D>();
		}
	}
	
	// ---------------------------------------------------------------------
	// Interface.
	// ---------------------------------------------------------------------
	
	public function updateCollider(view:View3D):Void
	{
		_previousCollidingView = _collidingView;
		
		if (view != null) {
			// Clear the current colliding objects for multiple views if backBuffer just cleared
			if (view.stage3DProxy.bufferClear)
				_collidingViewObjects = new Vector<PickingCollisionVO>(_viewCount);
			
			var p:Point = view.localToGlobal(new Point(view.mouseX, view.mouseY));
			if (!view.shareContext) {
				if (view == _activeView && (_forceMouseMove || _updateDirty)) { // If forceMouseMove is off, and no 2D mouse events dirtied the update, don't update either.
					_collidingObject = _mousePicker.getViewCollision(p.x, p.y, view);
				}
			} else {
				//if (view.getBounds(view.parent).contains((view.mouseX + view.x)/view.parent.scaleX, (view.mouseY + view.y)/view.parent.scaleY)) {
					if (_collidingViewObjects == null) 
						_collidingViewObjects = new Vector<PickingCollisionVO>(_viewCount);
					_collidingObject = _collidingViewObjects[_view3Ds[view]] = _mousePicker.getViewCollision(p.x, p.y, view);
				//}
			}
		}
	}
	
	public function fireMouseEvents():Void
	{
		var i:Int = 0;
		var len:Int;
		var event:MouseEvent3D;
		var dispatcher:ObjectContainer3D;
		
		// If multiple view are used, determine the best hit based on the depth intersection.
		if (_collidingViewObjects != null) {
			_collidingObject = null;
			// Get the top-most view colliding object
			var distance:Float = Math.POSITIVE_INFINITY;
			var view:View3D;
			var v:Int = _viewCount - 1;
			while (v >= 0) {
				view = _view3DLookup[v];
				if (_collidingViewObjects[v] != null && (view.layeredView || _collidingViewObjects[v].rayEntryDistance < distance)) {
					distance = _collidingViewObjects[v].rayEntryDistance;
					_collidingObject = _collidingViewObjects[v];
					if (view.layeredView)
						break;
				}
				v--;
			}
		}
		
		// If colliding object has changed, queue over/out events.
		if (_collidingObject != _previousCollidingObject) {
			if (_previousCollidingObject != null)
				queueDispatch(_mouseOut, _mouseMoveEvent, _previousCollidingObject);
			if (_collidingObject != null)
				queueDispatch(_mouseOver, _mouseMoveEvent, _collidingObject);
		}
		
		// Fire mouse move events here if forceMouseMove is on.
		if (_forceMouseMove && _collidingObject != null)
			queueDispatch(_mouseMove, _mouseMoveEvent, _collidingObject);
		
		// Dispatch all queued events.
		len = _queuedEvents.length;
		for (i in 0...len) {
			// Only dispatch from first implicitly enabled object ( one that is not a child of a mouseChildren = false hierarchy ).
			event = _queuedEvents[i];
			dispatcher = event.object;
			
			while (dispatcher != null && !dispatcher._ancestorsAllowMouseEnabled)
				dispatcher = dispatcher.parent;
			
			if (dispatcher != null)
				dispatcher.dispatchEvent(event);
		}
		_queuedEvents.length = 0;
		
		_updateDirty = false;
		_previousCollidingObject = _collidingObject;
	}
	
	public function addViewLayer(view:View3D):Void
	{
		var stg:Stage = view.stage;
		
		// Add instance to mouse3dmanager to fire mouse events for multiple views
		if (view.stage3DProxy.mouse3DManager == null)
			view.stage3DProxy.mouse3DManager = this;
		
		if (!hasKey(view))
			_view3Ds.set(view, 0);
		
		_childDepth = 0;
		traverseDisplayObjects(stg);
		_viewCount = _childDepth;
	}
	
	public function enableMouseListeners(view:View3D):Void
	{
		view.addEventListener(MouseEvent.CLICK, onClick);
		view.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
		view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		view.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		view.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		view.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		view.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
	}
	
	public function disableMouseListeners(view:View3D):Void
	{
		view.removeEventListener(MouseEvent.CLICK, onClick);
		view.removeEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
		view.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		view.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		view.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		view.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		view.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		view.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
	}
	
	public function dispose():Void
	{
		_mousePicker.dispose();
	}
	
	// ---------------------------------------------------------------------
	// Private.
	// ---------------------------------------------------------------------
	
	private function queueDispatch(event:MouseEvent3D, sourceEvent:MouseEvent, collider:PickingCollisionVO = null):Void
	{
		
		// 2D properties.
		event.ctrlKey = sourceEvent.ctrlKey;
		event.altKey = sourceEvent.altKey;
		event.shiftKey = sourceEvent.shiftKey;
		event.delta = sourceEvent.delta;
		event.screenX = sourceEvent.localX;
		event.screenY = sourceEvent.localY;
		
		if (collider == null)
			collider = _collidingObject;
		
		// 3D properties.
		if (collider != null) {
			// Object.
			event.object = collider.entity;
			event.renderable = collider.renderable;
			// UV.
			event.uv = collider.uv;
			// Position.
			event.localPosition = (collider.localPosition != null) ? collider.localPosition.clone() : null;
			// Normal.
			event.localNormal = (collider.localNormal != null) ? collider.localNormal.clone() : null;
			// Face index.
			event.index = collider.index;
			// SubGeometryIndex.
			event.subGeometryIndex = collider.subGeometryIndex;
			
		} else {
			// Set all to null.
			event.uv = null;
			event.object = null;
			event.localPosition = _nullVector;
			event.localNormal = _nullVector;
			event.index = 0;
			event.subGeometryIndex = 0;
		}
		
		// Store event to be dispatched later.
		_queuedEvents.push(event);
	}
	
	private function reThrowEvent(event:MouseEvent):Void
	{
		if (_activeView == null || (_activeView != null && !_activeView.shareContext))
			return;
		
		var keys:Iterator<View3D> = _view3Ds.keys();
		for (v in keys) {
			if (v != _activeView && _view3Ds.get(v) == _view3Ds.get(_activeView) - 1) {
				if (event.bubbles == true)
					v.dispatchEvent(new MouseEvent(event.type, false, event.cancelable, event.localX, event.localY, event.relatedObject, event.ctrlKey, event.altKey, event.shiftKey, event.buttonDown, event.delta, event.commandKey, event.clickCount));
				else v.dispatchEvent(event);
			}
		}
	}
	
	private function hasKey(view:View3D):Bool
	{
		return _view3Ds.exists(view);
	}
	
	private function traverseDisplayObjects(container:DisplayObjectContainer):Void
	{
		var childCount:Int = container.numChildren;
		var c:Int = 0;
		var child:DisplayObject;
		for (c in 0...childCount) {
			child = container.getChildAt(c);
			if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(child, View3D) && _view3Ds.exists(cast child)) {
				_view3Ds[cast child] = _childDepth;
				_view3DLookup[_childDepth] = cast child;
				_childDepth++;
			}
			if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(child, DisplayObjectContainer))
				traverseDisplayObjects(cast(child, DisplayObjectContainer));
		}
	}
	
	// ---------------------------------------------------------------------
	// Listeners.
	// ---------------------------------------------------------------------
	
	private function onMouseMove(event:MouseEvent):Void
	{
		if (_collidingObject != null)
			queueDispatch(_mouseMove, _mouseMoveEvent = event)
		else
			reThrowEvent(event);
		_updateDirty = true;
	}
	
	private function onMouseOut(event:MouseEvent):Void
	{
		_activeView = null;
		if (_collidingObject != null)
			queueDispatch(_mouseOut, event, _collidingObject);
		_updateDirty = true;
	}
	
	private function onMouseOver(event:MouseEvent):Void
	{
		_activeView = cast(event.currentTarget, View3D);
		if (_collidingObject != null && _previousCollidingObject != _collidingObject)
			queueDispatch(_mouseOver, event, _collidingObject)
		else
			reThrowEvent(event);
		_updateDirty = true;
	}
	
	private function onClick(event:MouseEvent):Void
	{
		if (_collidingObject != null) {
			queueDispatch(_mouseClick, event);
		} else
			reThrowEvent(event);
		_updateDirty = true;
	}
	
	private function onDoubleClick(event:MouseEvent):Void
	{
		if (_collidingObject != null)
			queueDispatch(_mouseDoubleClick, event)
		else
			reThrowEvent(event);
		_updateDirty = true;
	}
	
	private function onMouseDown(event:MouseEvent):Void
	{
		_activeView = cast(event.currentTarget, View3D);
		updateCollider(_activeView); // ensures collision check is done with correct mouse coordinates on mobile
		if (_collidingObject != null) {
			queueDispatch(_mouseDown, event);
			_previousCollidingObject = _collidingObject;
		} else
			reThrowEvent(event);
		_updateDirty = true;
	}
	
	private function onMouseUp(event:MouseEvent):Void
	{
		if (_collidingObject != null) {
			queueDispatch(_mouseUp, event);
			_previousCollidingObject = _collidingObject;
		} else
			reThrowEvent(event);
		_updateDirty = true;
	}
	
	private function onMouseWheel(event:MouseEvent):Void
	{
		if (_collidingObject != null)
			queueDispatch(_mouseWheel, event)
		else
			reThrowEvent(event);
		_updateDirty = true;
	}
	
	// ---------------------------------------------------------------------
	// Getters & setters.
	// ---------------------------------------------------------------------
	
	private function get_forceMouseMove():Bool
	{
		return _forceMouseMove;
	}
	
	private function set_forceMouseMove(value:Bool):Bool
	{
		_forceMouseMove = value;
		return value;
	}
	
	private function get_mousePicker():IPicker
	{
		return _mousePicker;
	}
	
	private function set_mousePicker(value:IPicker):IPicker
	{
		_mousePicker = value;
		return value;
	}
}