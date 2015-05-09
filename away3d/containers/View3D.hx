package away3d.containers;


import away3d.core.managers.Touch3DManager;
import away3d.events.Scene3DEvent;

import openfl.display.Sprite;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.textures.Texture;

import openfl.events.Event;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.geom.Transform;
import openfl.geom.Vector3D;
import openfl.net.URLRequest;
import openfl.filters.BitmapFilter;
 
import away3d.Away3D;
import away3d.cameras.Camera3D;
import away3d.core.managers.Mouse3DManager;
import away3d.core.managers.RTTBufferManager;
import away3d.core.managers.Stage3DManager;
import away3d.core.managers.Stage3DProxy;
import away3d.core.pick.IPicker;
import away3d.core.render.DefaultRenderer;
import away3d.core.render.DepthRenderer;
import away3d.core.render.Filter3DRenderer;
import away3d.core.render.RendererBase;
import away3d.core.traverse.EntityCollector;
import away3d.events.CameraEvent;
import away3d.events.Object3DEvent;
import away3d.events.Stage3DEvent;
import away3d.filters.Filter3DBase;
import away3d.textures.Texture2DBase;

import openfl.Lib;
import openfl.errors.Error;
import openfl.Vector;

//use namespace arcane;

class View3D extends Sprite
{
    var _width:Float;
    var _height:Float;
    var _localPos:Point;
    var _globalPos:Point;
    var _globalPosDirty:Bool;
    var _scene:Scene3D;
    var _camera:Camera3D;
    var _entityCollector:EntityCollector;
    
    var _aspectRatio:Float;
    var _time:UInt;
    var _deltaTime:UInt;
    var _backgroundColor:UInt;
    var _backgroundAlpha:Float;
    
    var _mouse3DManager:Mouse3DManager;
    
    var _touch3DManager:Touch3DManager;
    
    var _renderer:RendererBase;
    var _depthRenderer:DepthRenderer;
    var _addedToStage:Bool;
    
    var _forceSoftware:Bool;
    
    var _filter3DRenderer:Filter3DRenderer;
    var _requireDepthRender:Bool;
    var _depthRender:Texture;
    var _depthTextureInvalid:Bool;
    
    var _hitField:Sprite;
    var _parentIsStage:Bool;
    
    var _background:Texture2DBase;
    var _stage3DProxy:Stage3DProxy;
    var _backBufferInvalid:Bool;
    var _antiAlias:UInt;
    
    var _rttBufferManager:RTTBufferManager;
    
    var _rightClickMenuEnabled:Bool;
    var _sourceURL:String;
    //var _menu0:ContextMenuItem;
    //var _menu1:ContextMenuItem;
    //var _ViewContextMenu:ContextMenu;
    var _shareContext:Bool;
    var _scissorRect:Rectangle;
    var _scissorRectDirty:Bool;
    var _viewportDirty:Bool;
    
    var _depthPrepass:Bool;
    var _profile:String;
    var _layeredView:Bool = false;
    var _callbackMethod:Event -> Void;
	var _contextIndex:Int = -1;
    
    // private function viewSource(e:ContextMenuEvent):Void
    // {
    //  var request:URLRequest = new URLRequest(_sourceURL);
    //  try {
    //      Lib.getURL(request, "_blank");
    //  } catch (error:Error) {
            
    //  }
    // }
    
    public var depthPrepass(get, set) : Bool;
    
    public function get_depthPrepass() : Bool
    {
        return _depthPrepass;
    }
    
    public function set_depthPrepass(value:Bool) : Bool
    {
        _depthPrepass = value;
        return value;
    }
    
    // private function visitWebsite(e:ContextMenuEvent):Void
    // {
    //  var url:String = Away3D.WEBSITE_URL;
    //  var request:URLRequest = new URLRequest(url);
    //  try {
    //      Lib.getURL(request);
    //  } catch (error:Error) {
            
    //  }
    // }
    
    // private function initRightClickMenu():Void
    // {
    //  _menu0 = new ContextMenuItem("Away3D.com\tv" + Away3D.MAJOR_VERSION + "." + Away3D.MINOR_VERSION + "." + Away3D.REVISION, true, true, true);
    //  _menu1 = new ContextMenuItem("View Source", true, true, true);
    //  _menu0.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, visitWebsite);
    //  _menu1.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, viewSource);
    //  _ViewContextMenu = new ContextMenu();
        
    //  updateRightClickMenu();
    // }
    
    // private function updateRightClickMenu():Void
    // {
    //  if (_rightClickMenuEnabled)
    //      _ViewContextMenu.customItems = _sourceURL!="" ? [_menu0, _menu1] : [_menu0];
    //  else
    //      _ViewContextMenu.customItems = [];
        
    //  //TODO Not sure atm why contextMenu is not avaialble - maybe not in OpenFL
    //  //contextMenu = _ViewContextMenu;
    // }
    
    public function new(scene:Scene3D = null, camera:Camera3D = null, renderer:RendererBase = null, forceSoftware:Bool = false, profile:String = "baseline", contextIndex:Int=-1)
    {
		_width = 0;
        _height = 0;
        _localPos = new Point();
        _globalPos = new Point();

        super();

        _time = 0;
        _backgroundColor = 0x000000;
        _backgroundAlpha = 1;

        _depthTextureInvalid = true;
        
        _backBufferInvalid = true;
            
        _rightClickMenuEnabled = true;
        _shareContext = false;
        _scissorRectDirty = true;
        _viewportDirty = true;
        
        _layeredView = false;

        _profile = profile;
        _scene = scene != null ? scene : new Scene3D();
        _scene.addEventListener(Scene3DEvent.PARTITION_CHANGED, onScenePartitionChanged);
        _camera = camera!=null ? camera : new Camera3D();
        _renderer = renderer!=null ? renderer : new DefaultRenderer();
        _depthRenderer = new DepthRenderer();
        _forceSoftware = forceSoftware;
        _contextIndex = contextIndex;
		
        // todo: entity collector should be defined by renderer
        _entityCollector = _renderer.createEntityCollector();
        _entityCollector.camera = _camera;
        
        _scissorRect = new Rectangle();
        
        initHitField();
        
        _mouse3DManager = new Mouse3DManager();
        _mouse3DManager.enableMouseListeners(this);
        
        _touch3DManager = new Touch3DManager();
        //_touch3DManager.view = this;
        //_touch3DManager.enableTouchListeners(this);
        
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
        addEventListener(Event.ADDED, onAdded, false, 0, true);
        
        _camera.addEventListener(CameraEvent.LENS_CHANGED, onLensChanged);
        
        _camera.partition = _scene.partition;
        
        //initRightClickMenu();
    }
    
    private function onScenePartitionChanged(event:Event):Void
    {
        if (_camera!=null)
            _camera.partition = scene.partition;
    }
    
    // public var rightClickMenuEnabled(get, set) : Bool;
    
    // public function get_rightClickMenuEnabled() : Bool
    // {
    //  return _rightClickMenuEnabled;
    // }
    
    // public function set_rightClickMenuEnabled(val:Bool) : Bool
    // {
    //  _rightClickMenuEnabled = val;
        
    //  updateRightClickMenu();
    //  return _rightClickMenuEnabled;
    // }
    
    public var stage3DProxy(get, set) : Stage3DProxy;
    
    public function get_stage3DProxy() : Stage3DProxy
    {
        return _stage3DProxy;
    }
    
    public function set_stage3DProxy(stage3DProxy:Stage3DProxy) : Stage3DProxy
    {
        if (_stage3DProxy!=null)
            _stage3DProxy.removeEventListener(Stage3DEvent.VIEWPORT_UPDATED, onViewportUpdated);
        
        _stage3DProxy = stage3DProxy;
        
        _stage3DProxy.addEventListener(Stage3DEvent.VIEWPORT_UPDATED, onViewportUpdated);
        
        _renderer.stage3DProxy = _depthRenderer.stage3DProxy = _stage3DProxy;
        
        _globalPosDirty = true;
        _backBufferInvalid = true;
        return _stage3DProxy;
    }
    
    /**
     * Forces mouse-move related events even when the mouse hasn't moved. This allows mouseOver and mouseOut events
     * etc to be triggered due to changes in the scene graph. Defaults to false.
     */
    public var forceMouseMove(get, set) : Bool;
    public function get_forceMouseMove() : Bool
    {
        return _mouse3DManager.forceMouseMove;
    }
    
    public function set_forceMouseMove(value:Bool) : Bool
    {
        _mouse3DManager.forceMouseMove = value;
        //_touch3DManager.forceTouchMove = value;
        return value;
    }
    
    public var background(get, set) : Texture2DBase;
    
    public function get_background() : Texture2DBase
    {
        return _background;
    }
    
    public function set_background(value:Texture2DBase) : Texture2DBase
    {
        _background = value;
        _renderer.background = _background;
        return _background;
    }
    
    /**
     * Used in a sharedContext. When true, clears the depth buffer prior to rendering this particular
     * view to avoid depth sorting with lower layers. When false, the depth buffer is not cleared
     * from the previous (lower) view's render so objects in this view may be occluded by the lower
     * layer. Defaults to false.
     */
    public var layeredView(get, set) : Bool;
    public function get_layeredView() : Bool
    {
        return _layeredView;
    }
    
    public function set_layeredView(value:Bool) : Bool
    {
        _layeredView = value;
        return _layeredView;
    }
    
    private function initHitField():Void
    {
        _hitField = new Sprite();
        _hitField.alpha = 0;
        _hitField.doubleClickEnabled = true;
        _hitField.graphics.beginFill(0x000000);
        _hitField.graphics.drawRect(0, 0, 100, 100);
        addChild(_hitField);
    }
    
    public var filters3d(get, set) : Array<Filter3DBase>;
    public function get_filters3d() : Array<Filter3DBase>
    {
        return _filter3DRenderer!=null ? _filter3DRenderer.filters : null;
    }
    
    public function set_filters3d(value:Array<Filter3DBase>) : Array<Filter3DBase>
    {
        if (value!=null && value.length == 0)
            value = null;
        
        if (_filter3DRenderer!=null && value==null) {
            _filter3DRenderer.dispose();
            _filter3DRenderer = null;
        } else if (_filter3DRenderer==null && value!=null) {
            _filter3DRenderer = new Filter3DRenderer(stage3DProxy);
            _filter3DRenderer.filters = value;
        }
        
        if (_filter3DRenderer!=null) {
            _filter3DRenderer.filters = value;
            _requireDepthRender = _filter3DRenderer.requireDepthRender;
        } else {
            _requireDepthRender = false;
            if (_depthRender!=null) {
                _depthRender.dispose();
                _depthRender = null;
            }
        }
        return value;
    }
    
    /**
     * The renderer used to draw the scene.
     */
    public var renderer(get, set) : RendererBase;
    public function get_renderer() : RendererBase
    {
        return _renderer;
    }
    
    public function set_renderer(value:RendererBase) : RendererBase
    {
        _renderer.dispose();
        _renderer = value;
        _entityCollector = _renderer.createEntityCollector();
        _entityCollector.camera = _camera;
        _renderer.stage3DProxy = _stage3DProxy;
        _renderer.antiAlias = _antiAlias;
        _renderer.backgroundR = ((_backgroundColor >> 16) & 0xff)/0xff;
        _renderer.backgroundG = ((_backgroundColor >> 8) & 0xff)/0xff;
        _renderer.backgroundB = (_backgroundColor & 0xff)/0xff;
        _renderer.backgroundAlpha = _backgroundAlpha;
        _renderer.viewWidth = _width;
        _renderer.viewHeight = _height;
        _backBufferInvalid = true;
        return _renderer;
    }
    
    /**
     * The background color of the screen. This value is only used when clearAll is set to true.
     */
    public var backgroundColor(get, set) : UInt;
    public function get_backgroundColor() : UInt
    {
        return _backgroundColor;
    }
    
    public function set_backgroundColor(value:UInt) : UInt
    {
        _backgroundColor = value;
        _renderer.backgroundR = ((value >> 16) & 0xff)/0xff;
        _renderer.backgroundG = ((value >> 8) & 0xff)/0xff;
        _renderer.backgroundB = (value & 0xff)/0xff;
        return value;
    }
    
    public var backgroundAlpha(get, set) : Float;       
    public function get_backgroundAlpha() : Float
    {
        return _backgroundAlpha;
    }
    
    public function set_backgroundAlpha(value:Float) : Float
    {
        if (value > 1)
            value = 1;
        else if (value < 0)
            value = 0;
        
        _renderer.backgroundAlpha = value;
        _backgroundAlpha = value;
        return value;
    }
    
    /**
     * The camera that's used to render the scene for this viewport
     */
    public var camera(get, set) : Camera3D;
    public function get_camera() : Camera3D
    {
        return _camera;
    }
    
    /**
     * Set camera that's used to render the scene for this viewport
     */
    public function set_camera(camera:Camera3D) : Camera3D
    {
        _camera.removeEventListener(CameraEvent.LENS_CHANGED, onLensChanged);
        
        _camera = camera;
        _entityCollector.camera = _camera;
        
        if (_scene!=null)
            _camera.partition = _scene.partition;
        
        _camera.addEventListener(CameraEvent.LENS_CHANGED, onLensChanged);
        
        _scissorRectDirty = true;
        _viewportDirty = true;
        return camera;
    }
    
    /**
     * The scene that's used to render for this viewport
     */
    public var scene(get, set) : Scene3D;
    public function get_scene() : Scene3D
    {
        return _scene;
    }
    
    /**
     * Set the scene that's used to render for this viewport
     */
    public function set_scene(scene:Scene3D) : Scene3D
    {
        _scene.removeEventListener(Scene3DEvent.PARTITION_CHANGED, onScenePartitionChanged);
        _scene = scene;
        _scene.addEventListener(Scene3DEvent.PARTITION_CHANGED, onScenePartitionChanged);
        
        if (_camera!=null)
            _camera.partition = _scene.partition;
        return _scene;
    }
    
    // todo: probably temporary:
    /**
     * The amount of milliseconds the last render call took
     */
    public var deltaTime(get, null) : UInt;
    public function get_deltaTime() : UInt
    {
        return _deltaTime;
    }
    
    #if flash

    /**
     * Not supported. Use filters3d instead.
     */
    @:getter(filters)
    public function get_filters() : Array<Dynamic>
    {
        throw new Error("filters is not supported in View3D. Use filters3d instead.");
        return null;
    }
    
    /**
     * Not supported. Use filters3d instead.
     */
    @:setter(filters)
    public function set_filters(value:Array<Dynamic>) : Void
    {
        throw new Error("filters is not supported in View3D. Use filters3d instead.");
    }
    
    /**
     * The width of the viewport. When software rendering is used, this is limited by the
     * platform to 2048 pixels.
     */
    @:getter(width)
    public function get_width() : Float
    {
        return _width;
    }

    @:setter(width)
    public function set_width(value:Float) : Void
    {
        // Backbuffer limitation in software mode. See comment in updateBackBuffer()
        if (_stage3DProxy!=null && _stage3DProxy.usesSoftwareRendering && value > 2048)
            value = 2048;
        
        if (_width == value)
            return;
        
        if (_rttBufferManager!=null)
            _rttBufferManager.viewWidth = Std.int(value);
        
        _hitField.width = value;
        _width = value;
        _aspectRatio = _width/_height;
        _camera.lens.aspectRatio = _aspectRatio;
        _depthTextureInvalid = true;
        
        _renderer.viewWidth = value;
        
        _scissorRect.width = value;
        
        _backBufferInvalid = true;
        _scissorRectDirty = true;
    }

    /**
     * The height of the viewport. When software rendering is used, this is limited by the
     * platform to 2048 pixels.
     */
    @:getter(height)
    public function get_height() : Float
    {
        return _height;
    }

    @:setter(height)
    public function set_height(value:Float) : Void
    {
        // Backbuffer limitation in software mode. See comment in updateBackBuffer()
        if (_stage3DProxy!=null && _stage3DProxy.usesSoftwareRendering && value > 2048)
            value = 2048;
        
        if (_height == value)
            return;
        
        if (_rttBufferManager!=null)
            _rttBufferManager.viewHeight = Std.int(value);
        
        _hitField.height = value;
        _height = value;
        _aspectRatio = _width/_height;
        _camera.lens.aspectRatio = _aspectRatio;
        _depthTextureInvalid = true;
        
        _renderer.viewHeight = value;
        
        _scissorRect.height = value;
        
        _backBufferInvalid = true;
        _scissorRectDirty = true;
        return;
    }

    @:setter(x)
    public function set_x(value:Float) : Void
    {
        if (x == value)
            return;
        
        _localPos.x = value;
        
        _globalPos.x = parent!=null ? parent.localToGlobal(_localPos).x : value;
        _globalPosDirty = true;
        return;
    }

    @:setter(x)
    public function set_y(value:Float) : Void
    {
        if (y == value)
            return;
        
        _localPos.y = value;
        
        _globalPos.y = parent!=null ? parent.localToGlobal(_localPos).y : value;
        _globalPosDirty = true;
        return;
    }

    @:setter(visible)
    public function set_visible(value:Bool) : Void
    {
        super.visible = value;
        
        if (_stage3DProxy!=null && !_shareContext)
            _stage3DProxy.visible = value;
        return;
    }

    #else
    
    /**
     * The width of the viewport. When software rendering is used, this is limited by the
     * platform to 2048 pixels.
     */
    override public function get_width() : Float
    {
        return _width;
    }

    override public function set_width(value:Float) : Float
    {
        // Backbuffer limitation in software mode. See comment in updateBackBuffer()
        if (_stage3DProxy!=null && _stage3DProxy.usesSoftwareRendering && value > 2048)
            value = 2048;
        
        if (_width == value)
            return value;
        
        if (_rttBufferManager!=null)
            _rttBufferManager.viewWidth = Std.int(value);
        
        _hitField.width = value;
        _width = value;
        _aspectRatio = _width/_height;
        _camera.lens.aspectRatio = _aspectRatio;
        _depthTextureInvalid = true;
        
        _renderer.viewWidth = value;
        
        _scissorRect.width = value;
        
        _backBufferInvalid = true;
        _scissorRectDirty = true;
        return value;
    }

    /**
     * The height of the viewport. When software rendering is used, this is limited by the
     * platform to 2048 pixels.
     */
    override public function get_height() : Float
    {
        return _height;
    }

    override public function set_height(value:Float) : Float
    {
        // Backbuffer limitation in software mode. See comment in updateBackBuffer()
        if (_stage3DProxy!=null && _stage3DProxy.usesSoftwareRendering && value > 2048)
            value = 2048;
        
        if (_height == value)
            return value;
        
        if (_rttBufferManager!=null)
            _rttBufferManager.viewHeight = Std.int(value);
        
        _hitField.height = value;
        _height = value;
        _aspectRatio = _width/_height;
        _camera.lens.aspectRatio = _aspectRatio;
        _depthTextureInvalid = true;
        
        _renderer.viewHeight = value;
        
        _scissorRect.height = value;
        
        _backBufferInvalid = true;
        _scissorRectDirty = true;
        return value;
    }

    override public function set_x(value:Float) : Float
    {
        if (x == value)
            return x;
        
        _localPos.x = super.x = value;
        
        _globalPos.x = parent!=null ? parent.localToGlobal(_localPos).x : value;
        _globalPosDirty = true;
        return x;
    }

    override public function set_y(value:Float) : Float
    {
        if (y == value)
            return y;
        
        _localPos.y = super.y = value;
        
        _globalPos.y = parent!=null ? parent.localToGlobal(_localPos).y : value;
        _globalPosDirty = true;
        return y;
    }

    override public function set_visible(value:Bool) : Bool
    {
        super.visible = value;
        
        if (_stage3DProxy!=null && !_shareContext)
            _stage3DProxy.visible = value;
        return value;
    }

    #end      
    
    /**
     * The amount of anti-aliasing to be used.
     */
    public var antiAlias(get, set) : UInt;
    public function get_antiAlias() : UInt
    {
        return _antiAlias;
    }
    
    public function set_antiAlias(value:UInt) : UInt
    {
        _antiAlias = value;
        _renderer.antiAlias = value;
        
        _backBufferInvalid = true;
        return _antiAlias;
    }
    
    /**
     * The amount of faces that were pushed through the render pipeline on the last frame render.
     */
    public var renderedFacesCount(get, null) : UInt;
    public function get_renderedFacesCount() : UInt
    {
        return _entityCollector.numTriangles;
    }
    
    /**
     * Defers control of Context3D clear() and present() calls to Stage3DProxy, enabling multiple Stage3D frameworks
     * to share the same Context3D object.
     */
    public var shareContext(get, set) : Bool;
    public function get_shareContext() : Bool
    {
        return _shareContext;
    }
    
    public function set_shareContext(value:Bool) : Bool
    {
        if (_shareContext == value)
            return value;
        
        _shareContext = value;
        _globalPosDirty = true;
        return value;
    }
    
    /**
     * Updates the backbuffer dimensions.
     */
    private function updateBackBuffer():Void
    {
        // No reason trying to configure back buffer if there is no context available.
        // Doing this anyway (and relying on _stage3DProxy to cache width/height for 
        // context does get available) means usesSoftwareRendering won't be reliable.
        if (_stage3DProxy.context3D!=null && !_shareContext) {
            if (_width>0 && _height>0) {
                // Backbuffers are limited to 2048x2048 in software mode and
                // trying to configure the backbuffer to be bigger than that
                // will throw an error. Capping the value is a graceful way of
                // avoiding runtime exceptions for developers who are unable
                // to test their Away3D implementation on screens that are 
                // large enough for this error to ever occur.
                if (_stage3DProxy.usesSoftwareRendering) {
                    // Even though these checks where already made in the width
                    // and height setters, at that point we couldn't be sure that
                    // the context had even been retrieved and the software flag
                    // thus be reliable. Make checks again.
                    if (_width > 2048)
                        _width = 2048;
                    if (_height > 2048)
                        _height = 2048;
                }
                
                _stage3DProxy.configureBackBuffer(Std.int(_width), Std.int(_height), _antiAlias, true);
                _backBufferInvalid = false;
            } else {
                width = stage.stageWidth;
                height = stage.stageHeight;
            }
        }
    }
    
    /**
     * Defines the enter frame/render method to be used for rendering across platforms
     *
     */
    public function setRenderCallback(func : Event -> Void) : Void {
        if (_stage3DProxy != null)
            _stage3DProxy.setRenderCallback(func);

        _callbackMethod = func;
    }


    /**
     * Defines a source url string that can be accessed though a View Source option in the right-click menu.
     *
     * Requires the stats panel to be enabled.
     *
     * @param    url        The url to the source files.
     */
    // public function addSourceURL(url:String):Void
    // {
    //  _sourceURL = url;
        
    //  updateRightClickMenu();
    // }
    
    /**
     * Renders the view.
     */
    public function render():Void
    {
        
        //if context3D has Disposed by the OS,don't render at this frame
        if (!stage3DProxy.recoverFromDisposal()) {
            _backBufferInvalid = true;
            return;
        }
        
        // reset or update render settings
        if (_backBufferInvalid)
            updateBackBuffer();
        
        if (_shareContext && _layeredView)
            stage3DProxy.clearDepthBuffer();
        
        if (!_parentIsStage) {
            var globalPos:Point = parent.localToGlobal(_localPos);
            if (_globalPos.x != globalPos.x || _globalPos.y != globalPos.y) {
                _globalPos = globalPos;
                _globalPosDirty = true;
            }
        }
        
        if (_globalPosDirty)
            updateGlobalPos();
        
        updateTime();
        
        updateViewSizeData();
        
        _entityCollector.clear();
        
        // collect stuff to render
        _scene.traversePartitions(_entityCollector);

        // update picking
        _mouse3DManager.updateCollider(this);
        //_touch3DManager.updateCollider();
        
        if (_requireDepthRender)
            renderSceneDepthToTexture(_entityCollector);
        
        // todo: perform depth prepass after light update and before final render
        if (_depthPrepass)
            renderDepthPrepass(_entityCollector);
        
        _renderer.clearOnRender = !_depthPrepass;
        
        if (_filter3DRenderer!=null && _stage3DProxy._context3D!=null) {
            _renderer.render(_entityCollector, _filter3DRenderer.getMainInputTexture(_stage3DProxy), _rttBufferManager.renderToTextureRect);
            _filter3DRenderer.render(_stage3DProxy, camera, _depthRender);
        } else {
            _renderer.shareContext = _shareContext;
            if (_shareContext)
                _renderer.render(_entityCollector, null, _scissorRect);
            else {
                _renderer.render(_entityCollector);
            }
        }
        
		if (!_shareContext) {
            stage3DProxy.present();
            
            // fire collected mouse events
            _mouse3DManager.fireMouseEvents();
            //_touch3DManager.fireTouchEvents();
        }
        
        // clean up data for this render
        _entityCollector.cleanUp();
        
        // register that a view has been rendered
        stage3DProxy.bufferClear = false;
    }
    
    private function updateGlobalPos():Void
    {
        _globalPosDirty = false;
        
        if (_stage3DProxy==null)
            return;
        
        if (_shareContext) {
            _scissorRect.x = _globalPos.x - _stage3DProxy.x;
            _scissorRect.y = _globalPos.y - _stage3DProxy.y;
        } else {
            _scissorRect.x = 0;
            _scissorRect.y = 0;
            _stage3DProxy.x = _globalPos.x;
            _stage3DProxy.y = _globalPos.y;
        }
        
        _scissorRectDirty = true;
    }
    
    private function updateTime():Void
    {
        var time:UInt = Lib.getTimer();
        if (_time == 0)
            _time = time;
        _deltaTime = time - _time;
        _time = time;
    }
    
    private function updateViewSizeData():Void
    {
        _camera.lens.aspectRatio = _aspectRatio;
        
        if (_scissorRectDirty) {
            _scissorRectDirty = false;
            _camera.lens.updateScissorRect(_scissorRect.x, _scissorRect.y, _scissorRect.width, _scissorRect.height);
        }
        
        if (_viewportDirty) {
            _viewportDirty = false;
            _camera.lens.updateViewport(_stage3DProxy.viewPort.x, _stage3DProxy.viewPort.y, _stage3DProxy.viewPort.width, _stage3DProxy.viewPort.height);
        }
        
        if (_filter3DRenderer!=null || _renderer.renderToTexture) {
            _renderer.textureRatioX = _rttBufferManager.textureRatioX;
            _renderer.textureRatioY = _rttBufferManager.textureRatioY;
        } else {
            _renderer.textureRatioX = 1;
            _renderer.textureRatioY = 1;
        }
    }
    
    private function renderDepthPrepass(entityCollector:EntityCollector):Void
    {
        _depthRenderer.disableColor = true;
        if (_filter3DRenderer!=null || _renderer.renderToTexture) {
            _depthRenderer.textureRatioX = _rttBufferManager.textureRatioX;
            _depthRenderer.textureRatioY = _rttBufferManager.textureRatioY;
            _depthRenderer.render(entityCollector, _filter3DRenderer.getMainInputTexture(_stage3DProxy), _rttBufferManager.renderToTextureRect);
        } else {
            _depthRenderer.textureRatioX = 1;
            _depthRenderer.textureRatioY = 1;
            _depthRenderer.render(entityCollector);
        }
        _depthRenderer.disableColor = false;
    }
    
    private function renderSceneDepthToTexture(entityCollector:EntityCollector):Void
    {
        if (_depthTextureInvalid || _depthRender==null)
            initDepthTexture(_stage3DProxy._context3D);
        _depthRenderer.textureRatioX = _rttBufferManager.textureRatioX;
        _depthRenderer.textureRatioY = _rttBufferManager.textureRatioY;
        _depthRenderer.render(entityCollector, _depthRender);
    }
    
    private function initDepthTexture(context:Context3D):Void
    {
        _depthTextureInvalid = false;
        
        if (_depthRender!=null)
            _depthRender.dispose();
        
        _depthRender = context.createTexture(_rttBufferManager.textureWidth, _rttBufferManager.textureHeight, Context3DTextureFormat.BGRA, true);
    }
    
    /**
     * Disposes all memory occupied by the view. This will also dispose the renderer.
     */
    public function dispose():Void
    {
        _stage3DProxy.removeEventListener(Stage3DEvent.VIEWPORT_UPDATED, onViewportUpdated);
        if (!shareContext)
            _stage3DProxy.dispose();
        _renderer.dispose();
        
        if (_depthRender!=null)
            _depthRender.dispose();
        
        if (_rttBufferManager!=null)
            _rttBufferManager.dispose();
        
        _mouse3DManager.disableMouseListeners(this);
        _mouse3DManager.dispose();
        
        //_touch3DManager.disableTouchListeners(this);
        //_touch3DManager.dispose();
        
        _rttBufferManager = null;
        _depthRender = null;
        _mouse3DManager = null;
        //_touch3DManager = null;
        _depthRenderer = null;
        _stage3DProxy = null;
        _renderer = null;
        _entityCollector = null;
    }
    
    /**
     * Calculates the projected position in screen space of the given scene position.
     *
     * @param point3d the position vector of the point to be projected.
     * @return The absolute screen position of the given scene coordinates.
     */
    public function project(point3d:Vector3D):Vector3D
    {
        var v:Vector3D = _camera.project(point3d);
        
        v.x = (v.x + 1.0)*_width/2.0;
        v.y = (v.y + 1.0)*_height/2.0;
        
        return v;
    }
    
    /**
     * Calculates the scene position of the given screen coordinates.
     *
     * eg. unproject(view.mouseX, view.mouseY, 500) returns the scene position of the mouse 500 units into the screen.
     *
     * @param sX The absolute x coordinate in 2D relative to View3D, representing the screenX coordinate.
     * @param sY The absolute y coordinate in 2D relative to View3D, representing the screenY coordinate.
     * @param sZ The distance into the screen, representing the screenZ coordinate.
     * @return The scene position of the given screen coordinates.
     */
    public function unproject(sX:Float, sY:Float, sZ:Float):Vector3D
    {
        return _camera.unproject((sX*2 - _width)/_stage3DProxy.width, (sY*2 - _height)/_stage3DProxy.height, sZ);
    }
    
    /**
     * Calculates the ray in scene space from the camera to the given screen coordinates.
     *
     * eg. getRay(view.mouseX, view.mouseY, 500) returns the ray from the camera to a position under the mouse, 500 units into the screen.
     *
     * @param sX The absolute x coordinate in 2D relative to View3D, representing the screenX coordinate.
     * @param sY The absolute y coordinate in 2D relative to View3D, representing the screenY coordinate.
     * @param sZ The distance into the screen, representing the screenZ coordinate.
     * @return The ray from the camera to the scene space position of the given screen coordinates.
     */
    public function getRay(sX:Float, sY:Float, sZ:Float):Vector3D
    {
        return _camera.getRay((sX*2 - _width)/_width, (sY*2 - _height)/_height, sZ);
    }
    
    public var mousePicker(get, set) : IPicker;
    
    public function get_mousePicker() : IPicker
    {
        return _mouse3DManager.mousePicker;
    }
    
    public function set_mousePicker(value:IPicker) : IPicker
    {
        _mouse3DManager.mousePicker = value;
        return value;
    }
    
    public var touchPicker(get, set) : IPicker;
    
    public function get_touchPicker() : IPicker
    {
        return _touch3DManager.touchPicker;
    }
    
    public function set_touchPicker(value:IPicker) : IPicker
    {
        _touch3DManager.touchPicker = value;
        return value;
    }
    
    /**
     * The EntityCollector object that will collect all potentially visible entities in the partition tree.
     *
     * @see away3d.core.traverse.EntityCollector
     * @private
     */
    public var entityCollector(get, null) : EntityCollector;
    public function get_entityCollector() : EntityCollector
    {
        return _entityCollector;
    }
    
    private function onLensChanged(event:Event):Void
    {
        _scissorRectDirty = true;
        _viewportDirty = true;
    }
    
    /**
     * When added to the stage, retrieve a Stage3D instance
     */
    private function onAddedToStage(event:Event):Void
    {
        if (_addedToStage)
            return;
        
        _addedToStage = true;
        
        if (_stage3DProxy==null) {
            if (_contextIndex == -1) _stage3DProxy = Stage3DManager.getInstance(stage).getFreeStage3DProxy(_forceSoftware, _profile);
			else _stage3DProxy = Stage3DManager.getInstance(stage).getStage3DProxy(_contextIndex, _forceSoftware, _profile);
            _stage3DProxy.addEventListener(Stage3DEvent.VIEWPORT_UPDATED, onViewportUpdated);
            if (_callbackMethod!=null) {
                _stage3DProxy.setRenderCallback(_callbackMethod);
            }       
        }
        
        _globalPosDirty = true;
        
        _rttBufferManager = RTTBufferManager.getInstance(_stage3DProxy);
        
        _renderer.stage3DProxy = _depthRenderer.stage3DProxy = _stage3DProxy;
        
        //default wiidth/height to stageWidth/stageHeight
        if (_width == 0)
            width = stage.stageWidth;
        else
            _rttBufferManager.viewWidth = Std.int(_width);
        if (_height == 0)
            height = stage.stageHeight;
        else
            _rttBufferManager.viewHeight = Std.int(_height);
        
        if (_shareContext)
            _mouse3DManager.addViewLayer(this);
    }
    
    private function onAdded(event:Event):Void
    {
        _parentIsStage = (parent == stage);
        
        _globalPos = parent.localToGlobal(_localPos);
        _globalPosDirty = true;
    }
    
    private function onViewportUpdated(event:Stage3DEvent):Void
    {
        if (_shareContext) {
            _scissorRect.x = _globalPos.x - _stage3DProxy.x;
            _scissorRect.y = _globalPos.y - _stage3DProxy.y;
            _scissorRectDirty = true;
        }
        
        _viewportDirty = true;
    }
}

