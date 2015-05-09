/**
 * Stage3DProxy provides a proxy class to manage a single Stage3D instance as well as handling the creation and
 * attachment of the Context3D (and in turn the back buffer) is uses. Stage3DProxy should never be created directly,
 * but requested through Stage3DManager.
 *
 * @see away3d.core.managers.Stage3DProxy
 *
 * todo: consider moving all creation methods (createVertexBuffer etc) in here, so that disposal can occur here
 * along with the context, instead of scattered throughout the framework
 */
package away3d.core.managers;


import openfl.display.Shape;
import openfl.errors.Error;
import away3d.debug.Debug;
import away3d.events.Stage3DEvent;
import openfl.display.Stage3D;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DClearMask;
import openfl.display3D.Context3DRenderMode;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.textures.TextureBase;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.geom.Rectangle;
import openfl.Vector;

//using openfl.display3D.OpenFLStage3D;

class Stage3DProxy extends EventDispatcher {
    public var profile(get_profile, never):String;
    public var enableDepthAndStencil(get_enableDepthAndStencil, set_enableDepthAndStencil):Bool;
    public var renderTarget(get_renderTarget, never):TextureBase;
    public var renderSurfaceSelector(get_renderSurfaceSelector, never):Int;
    public var scissorRect(get_scissorRect, set_scissorRect):Rectangle;
    public var stage3DIndex(get_stage3DIndex, never):Int;
    public var stage3D(get_stage3D, never):Stage3D;
    public var context3D(get_context3D, never):Context3D;
    public var driverInfo(get_driverInfo, never):String;
    public var usesSoftwareRendering(get_usesSoftwareRendering, never):Bool;
    public var x(get_x, set_x):Float;
    public var y(get_y, set_y):Float;
    public var width(get_width, set_width):Int;
    public var height(get_height, set_height):Int;
    public var antiAlias(get_antiAlias, set_antiAlias):Int;
    public var viewPort(get_viewPort, never):Rectangle;
    public var color(get_color, set_color):Int;
    public var visible(get_visible, set_visible):Bool;
    public var bufferClear(get_bufferClear, set_bufferClear):Bool;
    public var mouse3DManager(get_mouse3DManager, set_mouse3DManager):Mouse3DManager;
    public var touch3DManager(get_touch3DManager, set_touch3DManager):Touch3DManager;
    static private var _frameEventDriver:Shape = new Shape();
    public var _context3D:Context3D;
    public var _stage3DIndex:Int;
    private var _usesSoftwareRendering:Bool;
    private var _profile:String;
    private var _stage3D:Stage3D;
    private var _activeProgram3D:Program3D;
    private var _stage3DManager:Stage3DManager;
    private var _backBufferWidth:Int;
    private var _backBufferHeight:Int;
    private var _antiAlias:Int;
    private var _enableDepthAndStencil:Bool;
    private var _contextRequested:Bool;
    //private var _activeVertexBuffers : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8, true);
    //private var _activeTextures : Vector.<TextureBase> = new Vector.<TextureBase>(8, true);
    private var _renderTarget:TextureBase;
    private var _renderSurfaceSelector:Int;
    private var _scissorRect:Rectangle;
    private var _color:Int;
    private var _backBufferDirty:Bool;
    private var _viewPort:Rectangle;
    private var _enterFrame:Event;
    private var _exitFrame:Event;
    private var _viewportUpdated:Stage3DEvent;
    private var _viewportDirty:Bool;
    private var _bufferClear:Bool;
    private var _mouse3DManager:Mouse3DManager;
    private var _touch3DManager:Touch3DManager;
    private var _callbackMethod:Event -> Void;

    private function notifyViewportUpdated():Void {
        if (_viewportDirty) return;
        _viewportDirty = true;
        if (!hasEventListener(Stage3DEvent.VIEWPORT_UPDATED)) return;
        _viewportUpdated = new Stage3DEvent(Stage3DEvent.VIEWPORT_UPDATED);
        dispatchEvent(_viewportUpdated);

    }

    private function notifyEnterFrame():Void {
        if (!hasEventListener(Event.ENTER_FRAME)) return;
        if (_enterFrame == null) _enterFrame = new Event(Event.ENTER_FRAME);
        dispatchEvent(_enterFrame);
    }

    #if flash
    private function notifyExitFrame():Void {
        if (!hasEventListener(Event.EXIT_FRAME)) return;
        if (_exitFrame == null) _exitFrame = new Event(Event.EXIT_FRAME);
        dispatchEvent(_exitFrame);
    }
    #end

    /**
     * Creates a Stage3DProxy object. This method should not be called directly. Creation of Stage3DProxy objects should
     * be handled by Stage3DManager.
     * @param stage3DIndex The index of the Stage3D to be proxied.
     * @param stage3D The Stage3D to be proxied.
     * @param stage3DManager
     * @param forceSoftware Whether to force software mode even if hardware acceleration is available.
     */
    public function new(stage3DIndex:Int, stage3D:Stage3D, stage3DManager:Stage3DManager, forceSoftware:Bool = false, profile:String = "baseline") {
        _stage3DIndex = -1;
        _stage3DIndex = stage3DIndex;
        _stage3D = stage3D;
        _stage3D.x = 0;
        _stage3D.y = 0;
        _stage3D.visible = true;
        _stage3DManager = stage3DManager;
        _viewPort = new Rectangle();
        _enableDepthAndStencil = true;

        super();

        this.forceSoftware = forceSoftware;
		this._profile = profile;
		
        // whatever happens, be sure this has highest priority
		if (_stage3D.context3D == null){
			_stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DUpdate, false, 1000, false);
			requestContext(forceSoftware, _profile);
		}
		else {
			onContext3DUpdate(null);
		}
    }

    private var forceSoftware:Bool ;

    public function get_profile():String {
        return _profile;
    }

    /**
     * Disposes the Stage3DProxy object, freeing the Context3D attached to the Stage3D.
     */
    public function dispose():Void {
        _stage3DManager.removeStage3DProxy(this);
        _stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContext3DUpdate);
        freeContext3D();
        _stage3D = null;
        _stage3DManager = null;
        _stage3DIndex = -1;
    }

    /**
     * Set the callback method for rendering using setRenderMethod or ENTER_FRAME
     */
    public function setRenderCallback(func : Event -> Void) : Void {
        if (_context3D != null) {
            if (_callbackMethod != null) {
                #if flash
                flash.Lib.current.removeEventListener(flash.events.Event.ENTER_FRAME, func);
                #else
                _context3D.removeRenderMethod(func);
                #end
            }

            if (func != null) {
                #if flash
                flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, func);
                #else
                _context3D.setRenderMethod(func);
                #end
            }
        }

        _callbackMethod = func;

    }

    /**
     * Configures the back buffer associated with the Stage3D object.
     * @param backBufferWidth The width of the backbuffer.
     * @param backBufferHeight The height of the backbuffer.
     * @param antiAlias The amount of anti-aliasing to use.
     * @param enableDepthAndStencil Indicates whether the back buffer contains a depth and stencil buffer.
     */
    public function configureBackBuffer(backBufferWidth:Int, backBufferHeight:Int, antiAlias:Int, enableDepthAndStencil:Bool):Void {
        var oldWidth:Int = _backBufferWidth;
        var oldHeight:Int = _backBufferHeight;

        _viewPort.width = _backBufferWidth = backBufferWidth;
        _viewPort.height = _backBufferHeight = backBufferHeight;

        if (oldWidth != _backBufferWidth || oldHeight != _backBufferHeight)
            notifyViewportUpdated();

        _antiAlias = antiAlias;
        _enableDepthAndStencil = enableDepthAndStencil;

        if (_context3D != null)
            _context3D.configureBackBuffer(backBufferWidth, backBufferHeight, antiAlias, enableDepthAndStencil);

    }

    /*
     * Indicates whether the depth and stencil buffer is used
     */
    public function get_enableDepthAndStencil():Bool {
        return _enableDepthAndStencil;
    }

    public function set_enableDepthAndStencil(enableDepthAndStencil:Bool):Bool {
        _enableDepthAndStencil = enableDepthAndStencil;
        _backBufferDirty = true;
        return enableDepthAndStencil;
    }

    public function get_renderTarget():TextureBase {
        return _renderTarget;
    }

    public function get_renderSurfaceSelector():Int {
        return _renderSurfaceSelector;
    }

    public function setRenderTarget(target:TextureBase, enableDepthAndStencil:Bool = false, surfaceSelector:Int = 0):Void {
        if (_renderTarget == target && surfaceSelector == _renderSurfaceSelector && _enableDepthAndStencil == enableDepthAndStencil)
            return;

        _renderTarget = target;
        _renderSurfaceSelector = surfaceSelector;
        _enableDepthAndStencil = enableDepthAndStencil;

        if (target != null)
            _context3D.setRenderToTexture(target, enableDepthAndStencil, _antiAlias, surfaceSelector)
        else {
            _context3D.setRenderToBackBuffer();
            _context3D.configureBackBuffer(_backBufferWidth, _backBufferHeight, _antiAlias, _enableDepthAndStencil);
        }
    }

    /*
     * Clear and reset the back buffer when using a shared context
     */
    public function clear():Void {
        if (_context3D == null) return;
        if (_backBufferDirty) {
            configureBackBuffer(_backBufferWidth, _backBufferHeight, _antiAlias, _enableDepthAndStencil);
            _backBufferDirty = false;
        }
        _context3D.clear(((_color >> 16) & 0xff) / 255.0, ((_color >> 8) & 0xff) / 255.0, (_color & 0xff) / 255.0, ((_color >> 24) & 0xff) / 255.0);
        _bufferClear = true;
    }

    /*
     * Display the back rendering buffer
     */
    public function present():Void {
        if (_context3D == null) return;
        _context3D.present();
        _activeProgram3D = null;
        if (_mouse3DManager != null) _mouse3DManager.fireMouseEvents();
    }

    /**
     * Registers an event listener object with an EventDispatcher object so that the listener receives notification of an event. Special case for enterframe and exitframe events - will switch Stage3DProxy into automatic render mode.
     * You can register event listeners on all nodes in the display list for a specific type of event, phase, and priority.
     *
     * @param type The type of event.
     * @param listener The listener function that processes the event.
     * @param useCapture Determines whether the listener works in the capture phase or the target and bubbling phases. If useCapture is set to true, the listener processes the event only during the capture phase and not in the target or bubbling phase. If useCapture is false, the listener processes the event only during the target or bubbling phase. To listen for the event in all three phases, call addEventListener twice, once with useCapture set to true, then again with useCapture set to false.
     * @param priority The priority level of the event listener. The priority is designated by a signed 32-bit integer. The higher the number, the higher the priority. All listeners with priority n are processed before listeners of priority n-1. If two or more listeners share the same priority, they are processed in the order in which they were added. The default priority is 0.
     * @param useWeakReference Determines whether the reference to the listener is strong or weak. A strong reference (the default) prevents your listener from being garbage-collected. A weak reference does not.
     */
    #if flash
    override public function addEventListener(type:String, listener:Dynamic -> Void, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void {
        super.addEventListener(type, listener, useCapture, priority, useWeakReference);

        if ((type == Event.ENTER_FRAME || type == Event.EXIT_FRAME) && !_frameEventDriver.hasEventListener(Event.ENTER_FRAME)) _frameEventDriver.addEventListener(Event.ENTER_FRAME, onEnterFrame, useCapture, priority, useWeakReference);

    }

    /**
     * Removes a listener from the EventDispatcher object. Special case for enterframe and exitframe events - will switch Stage3DProxy out of automatic render mode.
     * If there is no matching listener registered with the EventDispatcher object, a call to this method has no effect.
     *
     * @param type The type of event.
     * @param listener The listener object to remove.
     * @param useCapture Specifies whether the listener was registered for the capture phase or the target and bubbling phases. If the listener was registered for both the capture phase and the target and bubbling phases, two calls to removeEventListener() are required to remove both, one call with useCapture() set to true, and another call with useCapture() set to false.
     */
    override public function removeEventListener(type:String, listener:Dynamic -> Void, useCapture:Bool = false):Void {
        super.removeEventListener(type, listener, useCapture);
        // Remove the main rendering listener if no EnterFrame listeners remain

        if (!hasEventListener(Event.ENTER_FRAME) && !hasEventListener(Event.EXIT_FRAME) && _frameEventDriver.hasEventListener(Event.ENTER_FRAME)) _frameEventDriver.removeEventListener(Event.ENTER_FRAME, onEnterFrame, useCapture);

    }
    #end

    public function get_scissorRect():Rectangle {
        return _scissorRect;
    }

    public function set_scissorRect(value:Rectangle):Rectangle {
        _scissorRect = value;
        _context3D.setScissorRectangle(_scissorRect);
        return value;
    }

    /**
     * The index of the Stage3D which is managed by this instance of Stage3DProxy.
     */
    public function get_stage3DIndex():Int {
        return _stage3DIndex;
    }

    /**
     * The base Stage3D object associated with this proxy.
     */
    public function get_stage3D():Stage3D {
        return _stage3D;
    }

    /**
     * The Context3D object associated with the given Stage3D object.
     */
    public function get_context3D():Context3D {
        return _context3D;
    }

    /**
     * The driver information as reported by the Context3D object (if any)
     */
    public function get_driverInfo():String {
        return (_context3D != null) ? _context3D.driverInfo : null;
    }

    /**
     * Indicates whether the Stage3D managed by this proxy is running in software mode.
     * Remember to wait for the CONTEXT3D_CREATED event before checking this property,
     * as only then will it be guaranteed to be accurate.
     */
    public function get_usesSoftwareRendering():Bool {
        return _usesSoftwareRendering;
    }

    /**
     * The x position of the Stage3D.
     */
    public function get_x():Float {
        return _stage3D.x;
    }

    public function set_x(value:Float):Float {
        if (_viewPort.x == value) return value;
        _stage3D.x = _viewPort.x = value;
        notifyViewportUpdated();
        return value;
    }

    /**
     * The y position of the Stage3D.
     */
    public function get_y():Float {
        return _stage3D.y;
    }

    public function set_y(value:Float):Float {
        if (_viewPort.y == value) return value;
        _stage3D.y = _viewPort.y = value;
        notifyViewportUpdated();
        return value;
    }

    /**
     * The width of the Stage3D.
     */
    public function get_width():Int {
        return _backBufferWidth;
    }

    public function set_width(width:Int):Int {
        if (_viewPort.width == width) return width;
        _viewPort.width = _backBufferWidth = width;
        _backBufferDirty = true;
        notifyViewportUpdated();
        return width;
    }

    /**
     * The height of the Stage3D.
     */
    public function get_height():Int {
        return _backBufferHeight;
    }

    public function set_height(height:Int):Int {
        if (_viewPort.height == height) return height;
        _viewPort.height = _backBufferHeight = height;
        _backBufferDirty = true;
        notifyViewportUpdated();
        return height;
    }

    /**
     * The antiAliasing of the Stage3D.
     */
    public function get_antiAlias():Int {
        return _antiAlias;
    }

    public function set_antiAlias(antiAlias:Int):Int {
        _antiAlias = antiAlias;
        _backBufferDirty = true;
        return antiAlias;
    }

    /**
     * A viewPort rectangle equivalent of the Stage3D size and position.
     */
    public function get_viewPort():Rectangle {
        _viewportDirty = false;
        return _viewPort;
    }

    /**
     * The background color of the Stage3D.
     */
    public function get_color():Int {
        return _color;
    }

    public function set_color(color:Int):Int {
        _color = color;
        return color;
    }

    /**
     * The visibility of the Stage3D.
     */
    public function get_visible():Bool {
        return _stage3D.visible;
    }

    public function set_visible(value:Bool):Bool {
        _stage3D.visible = value;
        return value;
    }

    /**
     * The freshly cleared state of the backbuffer before any rendering
     */
    public function get_bufferClear():Bool {
        return _bufferClear;
    }

    public function set_bufferClear(newBufferClear:Bool):Bool {
        _bufferClear = newBufferClear;
        return newBufferClear;
    }

    /*
     * Access to fire mouseevents across multiple layered view3D instances
     */
    public function get_mouse3DManager():Mouse3DManager {
        return _mouse3DManager;
    }

    public function set_mouse3DManager(value:Mouse3DManager):Mouse3DManager {
        _mouse3DManager = value;
        return value;
    }

    public function get_touch3DManager():Touch3DManager {
        return _touch3DManager;
    }

    public function set_touch3DManager(value:Touch3DManager):Touch3DManager {
        _touch3DManager = value;
        return value;
    }

    /**
     * Frees the Context3D associated with this Stage3DProxy.
     */
    private function freeContext3D():Void {
        if (_context3D != null) {
            _context3D.dispose();
            dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_DISPOSED));
        }
        _context3D = null;
    }

    /*
     * Called whenever the Context3D is retrieved or lost.
     * @param event The event dispatched.
     */
    private function onContext3DUpdate(event:Event):Void {

        if (_stage3D.context3D != null) {
            var hadContext:Bool = (_context3D != null);
            _context3D = _stage3D.context3D;
            _context3D.enableErrorChecking = Debug.active;
            #if flash
            _usesSoftwareRendering = (_context3D.driverInfo.indexOf("Software") == 0);
            #end

            // Only configure back buffer if width and height have been set,
            // which they may not have been if View3D.render() has yet to be
            // invoked for the first time.

            if (_backBufferWidth > 0 && _backBufferHeight > 0) {
                _context3D.configureBackBuffer(_backBufferWidth, _backBufferHeight, _antiAlias, _enableDepthAndStencil);

            }

            setRenderCallback(_callbackMethod);

            dispatchEvent(new Stage3DEvent((hadContext) ? Stage3DEvent.CONTEXT3D_RECREATED : Stage3DEvent.CONTEXT3D_CREATED));
        }

        else throw new Error("Rendering context lost!");
    }

    /**
     * Requests a Context3D object to attach to the managed Stage3D.
     */
    private function requestContext(forceSoftware:Bool = false, profile:String = "baseline"):Void {
        // If forcing software, we can be certain that the
        // returned Context3D will be running software mode.
        // If not, we can't be sure and should stick to the
        // old value (will likely be same if re-requesting.)
        if (!_usesSoftwareRendering)
            _usesSoftwareRendering = forceSoftware;
        _profile = profile;

        // ugly stuff for backward compatibility
        var renderMode:Context3DRenderMode = (forceSoftware) ? Context3DRenderMode.SOFTWARE : Context3DRenderMode.AUTO;
        #if flash
            _stage3D.requestContext3D(cast renderMode);
        #else
            _stage3D.requestContext3D(Std.string(renderMode));
        #end

        _contextRequested = true;

    }

    /**
     * The Enter_Frame handler for processing the proxy.ENTER_FRAME and proxy.EXIT_FRAME event handlers.
     * Typically the proxy.ENTER_FRAME listener would render the layers for this Stage3D instance.
     */
    private function onEnterFrame(event:Event):Void {
        if (_context3D == null) return;
        clear();

        //notify the enterframe listeners
        notifyEnterFrame();

        // Call the present() to render the frame
        present();
        //notify the exitframe listeners

        #if flash
        notifyExitFrame();
        #end
    }

    public function recoverFromDisposal():Bool {
        if (_context3D == null) return false;
        if (_context3D.driverInfo == "Disposed") {
            _context3D = null;
            dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_DISPOSED));
            return false;
        }
        return true;
    }

    public function clearDepthBuffer():Void {
        if (_context3D == null) return;
        _context3D.clear(0, 0, 0, 1, 1, 0, Context3DClearMask.DEPTH);
    }



    /*
    Moving all creation methods here, so we can trace the usages of vertexbuffers or indexbuffers.
    Flash will throw the ERROR, when the vertexbuffer creation reached 4096..
    */
    private static var _vbCount : UInt = 0;
    private static var _ibCount : UInt = 0;

    public static function getVertexBufferCount() : UInt{
        return _vbCount;
    }

    public static function getIndexBufferCount() : UInt{
        return _ibCount;
    }

    private static var _vbUploadCount : UInt = 0;
    private static var _ibUploadCount : UInt = 0;

    private static var _bmpUploadCount : UInt = 0;
    private static var _atfUploadCount : UInt = 0;

    public function createVertexBuffer(numVertices:Int, data32PerVertex:Int) : VertexBuffer3D
    {
        _vbCount++;
        return _context3D.createVertexBuffer(numVertices, data32PerVertex);
    }

    public static function disposeVertexBuffer(vb : VertexBuffer3D) : Void
    {
        vb.dispose();
        _vbCount--;
    }

    public function createIndexBuffer(numIndices:Int) : IndexBuffer3D
    {
        _ibCount++;
        return _context3D.createIndexBuffer(numIndices);
    }

    public static function disposeIndexBuffer(ib : IndexBuffer3D) : Void
    {
        ib.dispose();
        _ibCount--;
    }

    public static function uploadVertexBufferFromVector(vb : VertexBuffer3D, data:Vector<Float>, startVertex:Int, numVertices:Int) : Void
    {
        vb.uploadFromVector(data, startVertex, numVertices);
        _vbUploadCount++;
    }

    public static function uploadIndexBufferFromVector(ib : IndexBuffer3D, data:Vector<UInt>, startOffset:Int, count:Int) : Void
    {
        ib.uploadFromVector(data, startOffset, count);
        _ibUploadCount++;
    }
}
