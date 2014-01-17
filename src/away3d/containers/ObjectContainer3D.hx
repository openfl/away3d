/**
 * Dispatched when the scene transform matrix of the 3d object changes.
 *
 * @eventType away3d.events.Object3DEvent
 * @see    #sceneTransform
 */
//[Event(name="scenetransformChanged", type="away3d.events.Object3DEvent")]
/**
 * Dispatched when the parent scene of the 3d object changes.
 *
 * @eventType away3d.events.Object3DEvent
 * @see    #scene
 */
//[Event(name="sceneChanged", type="away3d.events.Object3DEvent")]
/**
 * Dispatched when a user moves the cursor while it is over the 3d object.
 *
 * @eventType away3d.events.MouseEvent3D
 */
//[Event(name="mouseMove3d", type="away3d.events.MouseEvent3D")]
/**
 * Dispatched when a user presses the left hand mouse button while the cursor is over the 3d object.
 *
 * @eventType away3d.events.MouseEvent3D
 */
//[Event(name="mouseDown3d", type="away3d.events.MouseEvent3D")]
/**
 * Dispatched when a user releases the left hand mouse button while the cursor is over the 3d object.
 *
 * @eventType away3d.events.MouseEvent3D
 */
//[Event(name="mouseUp3d", type="away3d.events.MouseEvent3D")]
/**
 * Dispatched when a user moves the cursor over the 3d object.
 *
 * @eventType away3d.events.MouseEvent3D
 */
//[Event(name="mouseOver3d", type="away3d.events.MouseEvent3D")]
/**
 * Dispatched when a user moves the cursor away from the 3d object.
 *
 * @eventType away3d.events.MouseEvent3D
 */
//[Event(name="mouseOut3d", type="away3d.events.MouseEvent3D")]
/**
 * ObjectContainer3D is the most basic scene graph node. It can contain other ObjectContainer3Ds.
 *
 * ObjectContainer3D can have its own scene partition assigned. However, when assigned to a different scene,
 * it will loose any partition information, since partitions are tied to a scene.
 */
package away3d.containers;


import flash.errors.Error;
import away3d.core.math.MathConsts;
import flash.Vector;
import away3d.core.base.Object3D;
import away3d.core.partition.Partition3D;
import away3d.events.Object3DEvent;
import away3d.events.Scene3DEvent;
import away3d.library.assets.AssetType;
import away3d.library.assets.IAsset;
import flash.events.Event;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
#if (cpp || neko || js)
using away3d.Stage3DUtils;
#end
class ObjectContainer3D extends Object3D implements IAsset {
    public var ignoreTransform(get_ignoreTransform, set_ignoreTransform):Bool;
    public var implicitPartition(get_implicitPartition, set_implicitPartition):Partition3D;
    public var isVisible(get_isVisible, never):Bool;
    public var mouseEnabled(get_mouseEnabled, set_mouseEnabled):Bool;
    public var mouseChildren(get_mouseChildren, set_mouseChildren):Bool;
    public var visible(get_visible, set_visible):Bool;
    public var assetType(get_assetType, never):String;
    public var scenePosition(get_scenePosition, never):Vector3D;
    public var minX(get_minX, never):Float;
    public var minY(get_minY, never):Float;
    public var minZ(get_minZ, never):Float;
    public var maxX(get_maxX, never):Float;
    public var maxY(get_maxY, never):Float;
    public var maxZ(get_maxZ, never):Float;
    public var partition(get_partition, set_partition):Partition3D;
    public var sceneTransform(get_sceneTransform, never):Matrix3D;
    public var scene(get_scene, set_scene):Scene3D;
    public var inverseSceneTransform(get_inverseSceneTransform, never):Matrix3D;
    public var parent(get_parent, never):ObjectContainer3D;
    public var numChildren(get_numChildren, never):Int;

/** @private */
    public var _ancestorsAllowMouseEnabled:Bool;
    public var _isRoot:Bool;
    private var _scene:Scene3D;
    private var _parent:ObjectContainer3D;
    private var _sceneTransform:Matrix3D;
    private var _sceneTransformDirty:Bool;
// these vars allow not having to traverse the scene graph to figure out what partition is set
    private var _explicitPartition:Partition3D;
// what the user explicitly set as the partition
    private var _implicitPartition:Partition3D;
// what is inherited from the parents if it doesn't have its own explicitPartition
    private var _mouseEnabled:Bool;
    private var _sceneTransformChanged:Object3DEvent;
    private var _scenechanged:Object3DEvent;
    private var _children:Vector<ObjectContainer3D>;
    private var _mouseChildren:Bool;
    private var _oldScene:Scene3D;
    private var _inverseSceneTransform:Matrix3D;
    private var _inverseSceneTransformDirty:Bool;
    private var _scenePosition:Vector3D;
    private var _scenePositionDirty:Bool;
    private var _explicitVisibility:Bool;
    private var _implicitVisibility:Bool;
    private var _listenToSceneTransformChanged:Bool;
    private var _listenToSceneChanged:Bool;
// visibility passed on from parents
    private var _ignoreTransform:Bool;
/**
	 * Does not apply any transformations to this object. Allows static objects to be described in world coordinates without any matrix calculations.
	 */

    public function get_ignoreTransform():Bool {
        return _ignoreTransform;
    }

    public function set_ignoreTransform(value:Bool):Bool {
        _ignoreTransform = value;
        _sceneTransformDirty = !value;
        _inverseSceneTransformDirty = !value;
        _scenePositionDirty = !value;
        if (!value) {
            _sceneTransform.identity();
            _scenePosition.x = 0;
            _scenePosition.y = 0;
            _scenePosition.z = 0;
        }
        return value;
    }

/**
	 * @private
	 * The space partition used for this object, possibly inherited from its parent.
	 */

    private function get_implicitPartition():Partition3D {
        return _implicitPartition;
    }

    private function set_implicitPartition(value:Partition3D):Partition3D {
        if (value == _implicitPartition) return value;
        var i:Int = 0;
        var len:Int = _children.length;
        var child:ObjectContainer3D;
        _implicitPartition = value;
        while (i < len) {
            child = _children[i++];
// assign implicit partition if no explicit one is given
            if (child._explicitPartition == null) child.implicitPartition = value;
        }

        return value;
    }

/** @private */

    private function get_isVisible():Bool {
        return _implicitVisibility && _explicitVisibility;
    }

/** @private */

    private function setParent(value:ObjectContainer3D):Void {
        _parent = value;
        updateMouseChildren();
        if (value == null) {
            scene = null;
            return;
        }
        notifySceneTransformChange();
        notifySceneChange();
    }

    private function notifySceneTransformChange():Void {
        if (_sceneTransformDirty || _ignoreTransform) return;
        invalidateSceneTransform();
        var i:Int = 0;
        var len:Int = _children.length;
//act recursively on child objects
        while (i < len)_children[i++].notifySceneTransformChange();
//trigger event if listener exists
        if (_listenToSceneTransformChanged) {
            if (_sceneTransformChanged == null) _sceneTransformChanged = new Object3DEvent(Object3DEvent.SCENETRANSFORM_CHANGED, this);
            dispatchEvent(_sceneTransformChanged);
        }
    }

    private function notifySceneChange():Void {
        notifySceneTransformChange();
        var i:Int = 0;
        var len:Int = _children.length;
//act recursively on child objects
        while (i < len)_children[i++].notifySceneChange();
        if (_listenToSceneChanged) {
            if (_scenechanged == null) _scenechanged = new Object3DEvent(Object3DEvent.SCENE_CHANGED, this);
            dispatchEvent(_scenechanged);
        }
    }

    private function updateMouseChildren():Void {
        if (_parent != null && !_parent._isRoot) {
// Set implicit mouse enabled if parent its children to be so.
            _ancestorsAllowMouseEnabled = parent._ancestorsAllowMouseEnabled && _parent.mouseChildren;
        }

        else _ancestorsAllowMouseEnabled = mouseChildren;
// Sweep children.
        var len:Int = _children.length;
        var i:Int = 0;
        while (i < len) {
            _children[i].updateMouseChildren();
            ++i;
        }
    }

/**
	 * Indicates whether the IRenderable should trigger mouse events, and hence should be rendered for hit testing.
	 */

    public function get_mouseEnabled():Bool {
        return _mouseEnabled;
    }

    public function set_mouseEnabled(value:Bool):Bool {
        _mouseEnabled = value;
        updateMouseChildren();
        return value;
    }

/**
	 * @inheritDoc
	 */

    override private function invalidateTransform():Void {
        super.invalidateTransform();
        notifySceneTransformChange();
    }

/**
	 * Invalidates the scene transformation matrix, causing it to be updated the next time it's requested.
	 */

    private function invalidateSceneTransform():Void {
        _sceneTransformDirty = !_ignoreTransform;
        _inverseSceneTransformDirty = !_ignoreTransform;
        _scenePositionDirty = !_ignoreTransform;
    }

/**
	 * Updates the scene transformation matrix.
	 */

    private function updateSceneTransform():Void {
        if (_parent != null && !_parent._isRoot) {
            _sceneTransform.copyFrom(_parent.sceneTransform);
            _sceneTransform.prepend(transform);
        }

        else _sceneTransform.copyFrom(transform);
        _sceneTransformDirty = false;
    }

/**
	 *
	 */

    public function get_mouseChildren():Bool {
        return _mouseChildren;
    }

    public function set_mouseChildren(value:Bool):Bool {
        _mouseChildren = value;
        updateMouseChildren();
        return value;
    }

/**
	 *
	 */

    public function get_visible():Bool {
        return _explicitVisibility;
    }

    public function set_visible(value:Bool):Bool {
        var len:Int = _children.length;
        _explicitVisibility = value;
        var i:Int = 0;
        while (i < len) {
            _children[i].updateImplicitVisibility();
            ++i;
        }
        return value;
    }

    public function get_assetType():String {
        return AssetType.CONTAINER;
    }

/**
	 * The global position of the ObjectContainer3D in the scene. The value of the return object should not be changed.
	 */

    public function get_scenePosition():Vector3D {
        if (_scenePositionDirty) {
            sceneTransform.copyColumnTo(3, _scenePosition);
            _scenePositionDirty = false;
        }
        return _scenePosition;
    }

/**
	 * The minimum extremum of the object along the X-axis.
	 */

    public function get_minX():Float {
        var i:Int = 0;
        var len:Int = _children.length;
        var min:Float = MathConsts.POSITIVE_INFINITY;
        var m:Float;
        while (i < len) {
            var child:ObjectContainer3D = _children[i++];
            m = child.minX + child.x;
            if (m < min) min = m;
        }

        return min;
    }

/**
	 * The minimum extremum of the object along the Y-axis.
	 */

    public function get_minY():Float {
        var i:Int = 0;
        var len:Int = _children.length;
        var min:Float = MathConsts.POSITIVE_INFINITY;
        var m:Float;
        while (i < len) {
            var child:ObjectContainer3D = _children[i++];
            m = child.minY + child.y;
            if (m < min) min = m;
        }

        return min;
    }

/**
	 * The minimum extremum of the object along the Z-axis.
	 */

    public function get_minZ():Float {
        var i:Int = 0;
        var len:Int = _children.length;
        var min:Float = MathConsts.POSITIVE_INFINITY;
        var m:Float;
        while (i < len) {
            var child:ObjectContainer3D = _children[i++];
            m = child.minZ + child.z;
            if (m < min) min = m;
        }

        return min;
    }

/**
	 * The maximum extremum of the object along the X-axis.
	 */

    public function get_maxX():Float {
// todo: this isn't right, doesn't take into account transforms
        var i:Int = 0;
        var len:Int = _children.length;
        var max:Float = MathConsts.NEGATIVE_INFINITY;
        var m:Float;
        while (i < len) {
            var child:ObjectContainer3D = _children[i++];
            m = child.maxX + child.x;
            if (m > max) max = m;
        }

        return max;
    }

/**
	 * The maximum extremum of the object along the Y-axis.
	 */

    public function get_maxY():Float {
        var i:Int = 0;
        var len:Int = _children.length;
        var max:Float = MathConsts.NEGATIVE_INFINITY;
        var m:Float;
        while (i < len) {
            var child:ObjectContainer3D = _children[i++];
            m = child.maxY + child.y;
            if (m > max) max = m;
        }

        return max;
    }

/**
	 * The maximum extremum of the object along the Z-axis.
	 */

    public function get_maxZ():Float {
        var i:Int = 0;
        var len:Int = _children.length;
        var max:Float = MathConsts.NEGATIVE_INFINITY;
        var m:Float;
        while (i < len) {
            var child:ObjectContainer3D = _children[i++];
            m = child.maxZ + child.z;
            if (m > max) max = m;
        }

        return max;
    }

/**
	 * The space partition to be used by the object container and all its recursive children, unless it has its own
	 * space partition assigned.
	 */

    public function get_partition():Partition3D {
        return _explicitPartition;
    }

    public function set_partition(value:Partition3D):Partition3D {
        _explicitPartition = value;
        implicitPartition = (value != null) ? value : ((_parent != null) ? _parent.implicitPartition : null);
        return value;
    }

/**
	 * The transformation matrix that transforms from model to world space.
	 */

    public function get_sceneTransform():Matrix3D {
        if (_sceneTransformDirty) updateSceneTransform();
        return _sceneTransform;
    }

/**
	 * A reference to the Scene3D object to which this object belongs.
	 */

    public function get_scene():Scene3D {
        return _scene;
    }

    public function set_scene(value:Scene3D):Scene3D {
        var i:Int = 0;
        var len:Int = _children.length;
        while (i < len)_children[i++].scene = value;
        if (_scene == value) return value;
        if (value == null) _oldScene = _scene;
        if (_explicitPartition != null && _oldScene != null && _oldScene != _scene) partition = null;
        if (value != null) _oldScene = null;
        _scene = value;
        if (_scene != null) _scene.dispatchEvent(new Scene3DEvent(Scene3DEvent.ADDED_TO_SCENE, this))
        else if (_oldScene != null) _oldScene.dispatchEvent(new Scene3DEvent(Scene3DEvent.REMOVED_FROM_SCENE, this));
        return value;
    }

/**
	 * The inverse scene transform object that transforms from world to model space.
	 */

    public function get_inverseSceneTransform():Matrix3D {
        if (_inverseSceneTransformDirty) {
            _inverseSceneTransform.copyFrom(sceneTransform);
            _inverseSceneTransform.invert();
            _inverseSceneTransformDirty = false;
        }
        return _inverseSceneTransform;
    }

/**
	 * The parent ObjectContainer3D to which this object's transformation is relative.
	 */

    public function get_parent():ObjectContainer3D {
        return _parent;
    }

/**
	 * Creates a new ObjectContainer3D object.
	 */

    public function new() {
        _sceneTransform = new Matrix3D();
        _sceneTransformDirty = true;
        _children = new Vector<ObjectContainer3D>();
        _mouseChildren = true;
        _inverseSceneTransform = new Matrix3D();
        _inverseSceneTransformDirty = true;
        _scenePosition = new Vector3D();
        _scenePositionDirty = true;
        _explicitVisibility = true;
        _implicitVisibility = true;
        _ignoreTransform = false;
        super();
    }

    public function contains(child:ObjectContainer3D):Bool {
        return _children.indexOf(child) >= 0;
    }

/**
	 * Adds a child ObjectContainer3D to the current object. The child's transformation will become relative to the
	 * current object's transformation.
	 * @param child The object to be added as a child.
	 * @return A reference to the added child object.
	 */

    public function addChild(child:ObjectContainer3D):ObjectContainer3D {
        if (child == null) throw new Error("Parameter child cannot be null.");
        if (child._parent != null) child._parent.removeChild(child);
        if (child._explicitPartition == null) child.implicitPartition = _implicitPartition;
        child.setParent(this);
        child.scene = _scene;
        child.notifySceneTransformChange();
        child.updateMouseChildren();
        child.updateImplicitVisibility();
        _children.push(child);
        return child;
    }

/**
	 * Adds an array of 3d objects to the scene as children of the container
	 *
	 * @param    ...childarray        An array of 3d objects to be added
	 */

    public function addChildren(childarray:Array<ObjectContainer3D>):Void {
        for (child in childarray)addChild(child);
    }

/**
	 * Removes a 3d object from the child array of the container
	 *
	 * @param    child    The 3d object to be removed
	 * @throws    Error    ObjectContainer3D.removeChild(null)
	 */

    public function removeChild(child:ObjectContainer3D):Void {
        if (child == null) throw new Error("Parameter child cannot be null");
        var childIndex:Int = _children.indexOf(child);
        if (childIndex == -1) throw new Error("Parameter is not a child of the caller");
        removeChildInternal(childIndex, child);
    }

/**
	 * Removes a 3d object from the child array of the container
	 *
	 * @param    index    Index of 3d object to be removed
	 */

    public function removeChildAt(index:Int):Void {
        var child:ObjectContainer3D = _children[index];
        removeChildInternal(index, child);
    }

    private function removeChildInternal(childIndex:Int, child:ObjectContainer3D):Void {
// index is important because getChildAt needs to be regular.
        _children.splice(childIndex, 1);
// this needs to be nullified before the callbacks!
        child.setParent(null);
        if (child._explicitPartition == null) child.implicitPartition = null;
    }

/**
	 * Retrieves the child object at the given index.
	 * @param index The index of the object to be retrieved.
	 * @return The child object at the given index.
	 */

    public function getChildAt(index:Int):ObjectContainer3D {
        return _children[index];
    }

/**
	 * The amount of child objects of the ObjectContainer3D.
	 */

    public function get_numChildren():Int {
        return _children.length;
    }

/**
	 * @inheritDoc
	 */

    override public function lookAt(target:Vector3D, upAxis:Vector3D = null):Void {
        super.lookAt(target, upAxis);
        notifySceneTransformChange();
    }

    override public function translateLocal(axis:Vector3D, distance:Float):Void {
        super.translateLocal(axis, distance);
        notifySceneTransformChange();
    }

/**
	 * @inheritDoc
	 */

    override public function dispose():Void {
        if (parent != null) parent.removeChild(this);
    }

/**
	 * Disposes the current ObjectContainer3D including all of its children. This is a merely a convenience method.
	 */

    public function disposeWithChildren():Void {
        dispose();
        while (numChildren > 0)getChildAt(0).dispose();
    }

/**
	 * Clones this ObjectContainer3D instance along with all it's children, and
	 * returns the result (which will be a copy of this container, containing copies
	 * of all it's children.)
	 */

    override public function clone():Object3D {
        var clone:ObjectContainer3D = new ObjectContainer3D();
        clone.pivotPoint = pivotPoint;
        clone.transform = transform;
        clone.partition = partition;
        clone.name = name;
        var len:Int = _children.length;
        var i:Int = 0;
        while (i < len) {
            clone.addChild(cast((_children[i].clone()), ObjectContainer3D));
            ++i;
        }
// todo: implement for all subtypes
        return clone;
    }

    override public function rotate(axis:Vector3D, angle:Float):Void {
        super.rotate(axis, angle);
        notifySceneTransformChange();
    }

/**
	 * @inheritDoc
	 */

    override public function dispatchEvent(event:Event):Bool {
// maybe not the best way to fake bubbling?
        var ret:Bool = super.dispatchEvent(event);
        if (event.bubbles) {
            if (_parent != null) _parent.dispatchEvent(event)
            else if (_scene != null) _scene.dispatchEvent(event);
        }
        return ret;
    }

    public function updateImplicitVisibility():Void {
        var len:Int = _children.length;
        _implicitVisibility = _parent._explicitVisibility && _parent._implicitVisibility;
        var i:Int = 0;
        while (i < len) {
            _children[i].updateImplicitVisibility();
            ++i;
        }
    }

    override public function addEventListener(type:String, listener:Dynamic -> Void, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void {
        super.addEventListener(type, listener, useCapture, priority, useWeakReference);
        switch(type) {
            case Object3DEvent.SCENETRANSFORM_CHANGED:
                _listenToSceneTransformChanged = true;
            case Object3DEvent.SCENE_CHANGED:
                _listenToSceneChanged = true;
        }
    }

    override public function removeEventListener(type:String, listener:Dynamic -> Void, useCapture:Bool = false):Void {
        super.removeEventListener(type, listener, useCapture);
        if (hasEventListener(type)) return;
        switch(type) {
            case Object3DEvent.SCENETRANSFORM_CHANGED:
                _listenToSceneTransformChanged = false;
            case Object3DEvent.SCENE_CHANGED:
                _listenToSceneChanged = false;
        }
    }

}

