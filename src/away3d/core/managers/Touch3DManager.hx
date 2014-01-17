package away3d.core.managers;


import flash.Vector;
import away3d.containers.ObjectContainer3D;
import away3d.containers.View3D;
import away3d.core.pick.IPicker;
import away3d.core.pick.PickingCollisionVO;
import away3d.core.pick.PickingType;
import away3d.events.TouchEvent3D;
import flash.events.TouchEvent;
import flash.geom.Vector3D;
import haxe.ds.IntMap;

class Touch3DManager {
    public var forceTouchMove(get_forceTouchMove, set_forceTouchMove):Bool;
    public var touchPicker(get_touchPicker, set_touchPicker):IPicker;
    public var view(never, set_view):View3D;

    private var _updateDirty:Bool;
    private var _nullVector:Vector3D;
    private var _numTouchPoints:Int;
    private var _touchPoint:TouchPoint;
    private var _collidingObject:PickingCollisionVO;
    private var _previousCollidingObject:PickingCollisionVO;
    private static var _collidingObjectFromTouchId:IntMap<PickingCollisionVO> = new IntMap<PickingCollisionVO>();
    private static var _previousCollidingObjectFromTouchId:IntMap<PickingCollisionVO> = new IntMap<PickingCollisionVO>();
    static private var _queuedEvents:Vector<TouchEvent3D> = new Vector<TouchEvent3D>();
    private var _touchPoints:Vector<TouchPoint>;
    private var _touchPointFromId:IntMap<TouchPoint>;
    private var _touchMoveEvent:TouchEvent;
    private var _forceTouchMove:Bool;
    private var _touchPicker:IPicker;
    private var _view:View3D;

    public function new() {
        _updateDirty = true;
        _nullVector = new Vector3D();
        _touchMoveEvent = new TouchEvent(TouchEvent.TOUCH_MOVE);
        _touchPicker = PickingType.RAYCAST_FIRST_ENCOUNTERED;

        _touchPoints = new Vector<TouchPoint>();
        _touchPointFromId = new IntMap<TouchPoint>();
    }

// ---------------------------------------------------------------------
// Interface.
// ---------------------------------------------------------------------

    public function updateCollider():Void {
        if (_forceTouchMove || _updateDirty) { // If forceTouchMove is off, and no 2D Touch events dirty the update, don't update either.
            for (i in 0..._numTouchPoints) {
                _touchPoint = _touchPoints[i];
                _collidingObject = _touchPicker.getViewCollision(_touchPoint.x, _touchPoint.y, _view);
                _collidingObjectFromTouchId.set(_touchPoint.id, _collidingObject);
            }
        }
    }

    public function fireTouchEvents():Void {

        var i:Int;
        var len:Int;
        var event:TouchEvent3D;
        var dispatcher:ObjectContainer3D;

        for (i in 0..._numTouchPoints) {
            _touchPoint = _touchPoints[i];
// If colliding object has changed, queue over/out events.
            _collidingObject = _collidingObjectFromTouchId.get(_touchPoint.id);
            _previousCollidingObject = _previousCollidingObjectFromTouchId.get(_touchPoint.id);
            if (_collidingObject != _previousCollidingObject) {
                if (_previousCollidingObject != null)
                    queueDispatch(TouchEvent3D.TOUCH_OUT, _touchMoveEvent, _previousCollidingObject, _touchPoint);
                if (_collidingObject != null)
                    queueDispatch(TouchEvent3D.TOUCH_OVER, _touchMoveEvent, _collidingObject, _touchPoint);
            }
// Fire Touch move events here if forceTouchMove is on.
            if (_forceTouchMove && _collidingObject != null) {
                queueDispatch(TouchEvent3D.TOUCH_MOVE, _touchMoveEvent, _collidingObject, _touchPoint);
            }
        }

// Dispatch all queued events.
        len = _queuedEvents.length;
        for (i in 0...len) {

// Only dispatch from first implicitly enabled object ( one that is not a child of a TouchChildren = false hierarchy ).
            event = _queuedEvents[i];
            dispatcher = event.object;

            while (dispatcher != null && !dispatcher._ancestorsAllowMouseEnabled)
                dispatcher = dispatcher.parent;

            if (dispatcher != null)
                dispatcher.dispatchEvent(event);
        }
        _queuedEvents.length = 0;

        _updateDirty = false;

        for (i in 0..._numTouchPoints) {
            _touchPoint = _touchPoints[i];
            _previousCollidingObjectFromTouchId.set(_touchPoint.id, _collidingObjectFromTouchId.get(_touchPoint.id));
        }
    }

    public function enableTouchListeners(view:View3D):Void {
        view.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
        view.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
        view.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);
    }

    public function disableTouchListeners(view:View3D):Void {
        view.removeEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
        view.removeEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
        view.removeEventListener(TouchEvent.TOUCH_END, onTouchEnd);
    }

    public function dispose():Void {
        _touchPicker.dispose();
        _touchPoints = null;
        _touchPointFromId = null;
        _collidingObjectFromTouchId = null;
        _previousCollidingObjectFromTouchId = null;
    }

// ---------------------------------------------------------------------
// Private.
// ---------------------------------------------------------------------

    private function queueDispatch(emitType:String, sourceEvent:TouchEvent, collider:PickingCollisionVO, touch:TouchPoint):Void {
        var event:TouchEvent3D = new TouchEvent3D(emitType);
// 2D properties.
        event.ctrlKey = sourceEvent.ctrlKey;
        event.altKey = sourceEvent.altKey;
        event.shiftKey = sourceEvent.shiftKey;
        event.screenX = touch.x;
        event.screenY = touch.y;
        event.touchPointID = touch.id;
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
        }

        else {
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

// ---------------------------------------------------------------------
// Event handlers.
// ---------------------------------------------------------------------


    private function onTouchBegin(event:TouchEvent):Void {

        var touch:TouchPoint = new TouchPoint();
        touch.id = event.touchPointID;
        touch.x = event.stageX;
        touch.y = event.stageY;
        _numTouchPoints++;
        _touchPoints.push(touch);
        _touchPointFromId.set(touch.id, touch);

        updateCollider(); // ensures collision check is done with correct mouse coordinates on mobile

        _collidingObject = _collidingObjectFromTouchId.get(touch.id);
        if (_collidingObject != null) {
            queueDispatch(TouchEvent3D.TOUCH_BEGIN, event, _collidingObject, touch);
        }

        _updateDirty = true;
    }

    private function onTouchMove(event:TouchEvent):Void {

        var touch:TouchPoint = _touchPointFromId.get(event.touchPointID);
        touch.x = event.stageX;
        touch.y = event.stageY;

        _collidingObject = _collidingObjectFromTouchId.get(touch.id);
        if (_collidingObject != null) {
            queueDispatch(TouchEvent3D.TOUCH_MOVE, _touchMoveEvent = event, _collidingObject, touch);
        }

        _updateDirty = true;
    }

    private function onTouchEnd(event:TouchEvent):Void {

        var touch:TouchPoint = _touchPointFromId.get(event.touchPointID);

        _collidingObject = _collidingObjectFromTouchId.get(touch.id);
        if (_collidingObject != null) {
            queueDispatch(TouchEvent3D.TOUCH_END, event, _collidingObject, touch);
        }

        _touchPointFromId.remove(touch.id);
        _numTouchPoints--;
        _touchPoints.splice(_touchPoints.indexOf(touch), 1);

        _updateDirty = true;
    }

// ---------------------------------------------------------------------
// Getters & setters.
// ---------------------------------------------------------------------

    public function get_forceTouchMove():Bool {
        return _forceTouchMove;
    }

    public function set_forceTouchMove(value:Bool):Bool {
        _forceTouchMove = value;
        return value;
    }

    public function get_touchPicker():IPicker {
        return _touchPicker;
    }

    public function set_touchPicker(value:IPicker):IPicker {
        _touchPicker = value;
        return value;
    }

    public function set_view(value:View3D):View3D {
        _view = value;
        return value;
    }

}

class TouchPoint {

    public var id:Int;
    public var x:Float;
    public var y:Float;

    public function new() {

    }
}

