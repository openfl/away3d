package away3d.core.managers;

	//import away3d.arcane;
	import away3d.debug.Debug;
	import away3d.events.Stage3DEvent;
	
	import flash.display.Shape;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DClearMask;
	import flash.display3D.Context3DRenderMode;
	import flash.display3D.Program3D;
	import flash.display3D.textures.TextureBase;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	import flash.errors.Error;
	
	//use namespace arcane;
	
	//[Event(name="enterFrame", type="flash.events.Event")]
	//[Event(name="exitFrame", type="flash.events.Event")]
	
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
	class Stage3DProxy extends EventDispatcher
	{
		private static var _frameEventDriver:Shape = new Shape();
		
		/*arcane*/ public var _context3D:Context3D;
		/*arcane*/ public var _stage3DIndex:Int = -1;
		
		var _usesSoftwareRendering:Bool;
		var _profile:String;
		var _stage3D:Stage3D;
		var _activeProgram3D:Program3D;
		var _stage3DManager:Stage3DManager;
		var _backBufferWidth:Int;
		var _backBufferHeight:Int;
		var _antiAlias:Int;
		var _enableDepthAndStencil:Bool;
		var _contextRequested:Bool;
		//var _activeVertexBuffers : Array<VertexBuffer3D> = new Array<VertexBuffer3D>();
		//var _activeTextures : Array<TextureBase> = new Array<TextureBase>();
		var _renderTarget:TextureBase;
		var _renderSurfaceSelector:Int;
		var _scissorRect:Rectangle;
		var _color:UInt;
		var _backBufferDirty:Bool;
		var _viewPort:Rectangle;
		var _enterFrame:Event;
		var _exitFrame:Event;
		var _viewportUpdated:Stage3DEvent;
		var _viewportDirty:Bool;
		var _bufferClear:Bool;
		var _mouse3DManager:Mouse3DManager;
		var _touch3DManager:Touch3DManager;
		var _renderFunction:Event -> Void;
		
		private function notifyViewportUpdated():Void
		{
			if (_viewportDirty)
				return;
			
			_viewportDirty = true;
			
			if (!hasEventListener(Stage3DEvent.VIEWPORT_UPDATED))
				return;
			
			//TODO: investigate bug causing coercion error
			//if (!_viewportUpdated)
			_viewportUpdated = new Stage3DEvent(Stage3DEvent.VIEWPORT_UPDATED);
			
			dispatchEvent(_viewportUpdated);
		}
		
		private function notifyEnterFrame():Void
		{
			if (!hasEventListener(Event.ENTER_FRAME))
				return;
			
			if (_enterFrame==null)
				_enterFrame = new Event(Event.ENTER_FRAME);
			
			dispatchEvent(_enterFrame);
		}
		
		private function notifyExitFrame():Void
		{
			// TODO: No EXIT_FRAME exists in OpenFL at the time of writing

			// if (!hasEventListener(Event.EXIT_FRAME))
			// 	return;
			
			// if (_exitFrame==null)
			// 	_exitFrame = new Event(Event.EXIT_FRAME);
			
			// dispatchEvent(_exitFrame);
		}
		
		/**
		 * Creates a Stage3DProxy object. This method should not be called directly. Creation of Stage3DProxy objects should
		 * be handled by Stage3DManager.
		 * @param stage3DIndex The index of the Stage3D to be proxied.
		 * @param stage3D The Stage3D to be proxied.
		 * @param stage3DManager
		 * @param forceSoftware Whether to force software mode even if hardware acceleration is available.
		 */
		public function new(stage3DIndex:Int, stage3D:Stage3D, stage3DManager:Stage3DManager, forceSoftware:Bool = false, profile:String = "baseline")
		{
			super();
			_stage3DIndex = stage3DIndex;
			_stage3D = stage3D;
			_stage3D.x = 0;
			_stage3D.y = 0;
			_stage3D.visible = true;
			_stage3DManager = stage3DManager;
			_viewPort = new Rectangle();
			_enableDepthAndStencil = true;
			
			// whatever happens, be sure this has highest priority
			_stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DUpdate, false, 1000, false);
			requestContext(forceSoftware, profile);
		}
		
		public var profile(get, null) : String;
		
		public function get_profile() : String
		{
			return _profile;
		}
		
		/**
		 * Disposes the Stage3DProxy object, freeing the Context3D attached to the Stage3D.
		 */
		public function dispose():Void
		{
			_stage3DManager.removeStage3DProxy(this);
			_stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContext3DUpdate);
			freeContext3D();
			_stage3D = null;
			_stage3DManager = null;
			_stage3DIndex = -1;
		}
		
		/**
		 * Configures the back buffer associated with the Stage3D object.
		 * @param backBufferWidth The width of the backbuffer.
		 * @param backBufferHeight The height of the backbuffer.
		 * @param antiAlias The amount of anti-aliasing to use.
		 * @param enableDepthAndStencil Indicates whether the back buffer contains a depth and stencil buffer.
		 */
		public function configureBackBuffer(backBufferWidth:Int, backBufferHeight:Int, antiAlias:Int, enableDepthAndStencil:Bool):Void
		{
			var oldWidth:UInt = _backBufferWidth;
			var oldHeight:UInt = _backBufferHeight;
			
			_viewPort.width = _backBufferWidth = backBufferWidth;
			_viewPort.height = _backBufferHeight = backBufferHeight;

			if (oldWidth != _backBufferWidth || oldHeight != _backBufferHeight)
				notifyViewportUpdated();
			
			_antiAlias = antiAlias;
			_enableDepthAndStencil = enableDepthAndStencil;
			
			if (_context3D!=null)
				_context3D.configureBackBuffer(backBufferWidth, backBufferHeight, antiAlias, enableDepthAndStencil);
		}
		
		/*
		 * Indicates whether the depth and stencil buffer is used
		 */
		public var enableDepthAndStencil(get, set) : Bool;
		public function get_enableDepthAndStencil() : Bool
		{
			return _enableDepthAndStencil;
		}
		
		public function set_enableDepthAndStencil(enableDepthAndStencil:Bool) : Bool
		{
			_enableDepthAndStencil = enableDepthAndStencil;
			_backBufferDirty = true;
			return enableDepthAndStencil;
			{
				
			}
		}
		
		public var renderTarget(get, null) : TextureBase;	
		public function get_renderTarget() : TextureBase
		{
			return _renderTarget;
		}
		
		public var renderSurfaceSelector(get, null) : Int;		
		public function get_renderSurfaceSelector() : Int
		{
			return _renderSurfaceSelector;
		}
		
		public function setRenderTarget(target:TextureBase, enableDepthAndStencil:Bool = false, surfaceSelector:Int = 0):Void
		{
			if (_renderTarget == target && surfaceSelector == _renderSurfaceSelector && _enableDepthAndStencil == enableDepthAndStencil)
				return;
			_renderTarget = target;
			_renderSurfaceSelector = surfaceSelector;
			_enableDepthAndStencil = enableDepthAndStencil;
			
			if (target!=null)
				_context3D.setRenderToTexture(target, enableDepthAndStencil, _antiAlias, surfaceSelector);
			else
				_context3D.setRenderToBackBuffer();
		}
		
		/*
		 * Clear and reset the back buffer when using a shared context
		 */
		public function clear():Void
		{
			if (_context3D==null)
				return;
			
			if (_backBufferDirty) {
				configureBackBuffer(_backBufferWidth, _backBufferHeight, _antiAlias, _enableDepthAndStencil);
				_backBufferDirty = false;
			}
			
			_context3D.clear(
				((_color >> 16) & 0xff)/255.0,
				((_color >> 8) & 0xff)/255.0,
				(_color & 0xff)/255.0,
				((_color >> 24) & 0xff)/255.0);
			
			_bufferClear = true;
		}
		
		/*
		 * Display the back rendering buffer
		 */
		public function present():Void
		{
			if (_context3D==null)
				return;
			
			_context3D.present();
			
			_activeProgram3D = null;
			
			if (_mouse3DManager!=null)
				_mouse3DManager.fireMouseEvents();
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
		public override function addEventListener(type : String, listener : Dynamic -> Void, useCapture : Bool = false, priority : Int = 0, useWeakReference : Bool = false):Void
		{
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
			
			//if ((type == Event.ENTER_FRAME || type == Event.EXIT_FRAME) && !_frameEventDriver.hasEventListener(Event.ENTER_FRAME))
			if (type == Event.ENTER_FRAME && !_frameEventDriver.hasEventListener(Event.ENTER_FRAME))
				_frameEventDriver.addEventListener(Event.ENTER_FRAME, onEnterFrame, useCapture, priority, useWeakReference);
		}
		
		/**
		 * Removes a listener from the EventDispatcher object. Special case for enterframe and exitframe events - will switch Stage3DProxy out of automatic render mode.
		 * If there is no matching listener registered with the EventDispatcher object, a call to this method has no effect.
		 *
		 * @param type The type of event.
		 * @param listener The listener object to remove.
		 * @param useCapture Specifies whether the listener was registered for the capture phase or the target and bubbling phases. If the listener was registered for both the capture phase and the target and bubbling phases, two calls to removeEventListener() are required to remove both, one call with useCapture() set to true, and another call with useCapture() set to false.
		 */
		public override function removeEventListener(type : String, listener : Dynamic -> Void, useCapture : Bool = false):Void
		{
			super.removeEventListener(type, listener, useCapture);
			
			// Remove the main rendering listener if no EnterFrame listeners remain
			//if (!hasEventListener(Event.ENTER_FRAME) && !hasEventListener(Event.EXIT_FRAME) && _frameEventDriver.hasEventListener(Event.ENTER_FRAME))
			if (!hasEventListener(Event.ENTER_FRAME) && _frameEventDriver.hasEventListener(Event.ENTER_FRAME))
				_frameEventDriver.removeEventListener(Event.ENTER_FRAME, onEnterFrame, useCapture);
		}
		
		public var scissorRect(get, set) : Rectangle;		
		public function get_scissorRect() : Rectangle
		{
			return _scissorRect;
		}
		
		public function set_scissorRect(value:Rectangle) : Rectangle
		{
			_scissorRect = value;
			if (_scissorRect!=null) _context3D.setScissorRectangle(_scissorRect);
			return value;
		}
		
		/**
		 * The index of the Stage3D which is managed by this instance of Stage3DProxy.
		 */
		public var stage3DIndex(get, null) : Int;
		public function get_stage3DIndex() : Int
		{
			return _stage3DIndex;
		}
		
		/**
		 * The base Stage3D object associated with this proxy.
		 */
		public var stage3D(get, null) : Stage3D;
		public function get_stage3D() : Stage3D
		{
			return _stage3D;
		}
		
		/**
		 * The Context3D object associated with the given Stage3D object.
		 */
		public var context3D(get, null) : Context3D;
		public function get_context3D() : Context3D
		{
			return _context3D;
		}
		
		/**
		 * The driver information as reported by the Context3D object (if any)
		 */
		public var driverInfo(get, null) : String;
		public function get_driverInfo() : String
		{
			return _context3D != null ? _context3D.driverInfo : null;
		}
		
		/**
		 * Indicates whether the Stage3D managed by this proxy is running in software mode.
		 * Remember to wait for the CONTEXT3D_CREATED event before checking this property,
		 * as only then will it be guaranteed to be accurate.
		 */
		public var usesSoftwareRendering(get, null) : Bool;
		public function get_usesSoftwareRendering() : Bool
		{
			return _usesSoftwareRendering;
		}
		
		/**
		 * The x position of the Stage3D.
		 */
		public var x(get, set) : Float;
		public function get_x() : Float
		{
			return _stage3D.x;
		}
		
		public function set_x(value:Float) : Float
		{
			if (_viewPort.x == value)
				return value;
			
			_stage3D.x = _viewPort.x = value;
			
			notifyViewportUpdated();
			return value;
		}
		
		/**
		 * The y position of the Stage3D.
		 */
		public var y(get, set) : Float;
		public function get_y() : Float
		{
			return _stage3D.y;
		}
		
		public function set_y(value:Float) : Float
		{
			if (_viewPort.y == value)
				return value;
			
			_stage3D.y = _viewPort.y = value;
			
			notifyViewportUpdated();
			return value;
		}
		
		/**
		 * The width of the Stage3D.
		 */
		public var width(get, set) : Int;
		public function get_width() : Int
		{
			return _backBufferWidth;
		}
		
		public function set_width(width:Int) : Int
		{
			if (_viewPort.width == width)
				return width;
			
			_viewPort.width = _backBufferWidth = width;
			_backBufferDirty = true;
			
			notifyViewportUpdated();
			return width;
		}
		
		/**
		 * The height of the Stage3D.
		 */
		public var height(get, set) : Int;
		public function get_height() : Int
		{
			return _backBufferHeight;
		}
		
		public function set_height(height:Int) : Int
		{
			if (_viewPort.height == height)
				return height;
			
			_viewPort.height = _backBufferHeight = height;
			_backBufferDirty = true;
			
			notifyViewportUpdated();
			return height;
		}
		
		/**
		 * The antiAliasing of the Stage3D.
		 */
		public var antiAlias(get, set) : Int;
		public function get_antiAlias() : Int
		{
			return _antiAlias;
		}
		
		public function set_antiAlias(antiAlias:Int) : Int
		{
			_antiAlias = antiAlias;
			_backBufferDirty = true;
			return antiAlias;
		}
		
		/**
		 * A viewPort rectangle equivalent of the Stage3D size and position.
		 */
		public var viewPort(get, null) : Rectangle;
		public function get_viewPort() : Rectangle
		{
			_viewportDirty = false;
			
			return _viewPort;
		}
		
		/**
		 * The background color of the Stage3D.
		 */
		public var color(get, set) : UInt;
		public function get_color() : UInt
		{
			return _color;
		}
		
		public function set_color(color:UInt) : UInt
		{
			_color = color;
			return color;
		}
		
		/**
		 * The visibility of the Stage3D.
		 */
		public var visible(get, set) : Bool;
		public function get_visible() : Bool
		{
			return _stage3D.visible;
		}
		
		public function set_visible(value:Bool) : Bool
		{
			_stage3D.visible = value;
			return value;
		}
		
		/**
		 * The freshly cleared state of the backbuffer before any rendering
		 */
		public var bufferClear(get, set) : Bool;
		public function get_bufferClear() : Bool
		{
			return _bufferClear;
		}
		
		public function set_bufferClear(newBufferClear:Bool) : Bool
		{
			_bufferClear = newBufferClear;
			return newBufferClear;
		}
		
		/*
		 * Access to fire mouseevents across multiple layered view3D instances
		 */
		public var mouse3DManager(get, set) : Mouse3DManager;
		public function get_mouse3DManager() : Mouse3DManager
		{
			return _mouse3DManager;
		}
		
		public function set_mouse3DManager(value:Mouse3DManager) : Mouse3DManager
		{
			_mouse3DManager = value;
			return value;
		}
		
		public var touch3DManager(get, set) : Touch3DManager;
		
		public function get_touch3DManager() : Touch3DManager
		{
			return _touch3DManager;
		}
		
		public function set_touch3DManager(value:Touch3DManager) : Touch3DManager
		{
			_touch3DManager = value;
			return value;
		}

		/**
		 * Frees the Context3D associated with this Stage3DProxy.
		 */
		private function freeContext3D():Void
		{
			if (_context3D!=null) {
				_context3D.dispose();
				dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_DISPOSED));
			}
			_context3D = null;
		}
		
		/*
		 * Called whenever the Context3D is retrieved or lost.
		 * @param event The event dispatched.
		 */
		private function onContext3DUpdate(event:Event):Void
		{
			if (_stage3D.context3D != null) {
				var hadContext:Bool = (_context3D != null);
				_context3D = _stage3D.context3D;
				_context3D.enableErrorChecking = Debug.active;
				
				_usesSoftwareRendering = (_context3D.driverInfo==null ? false : _context3D.driverInfo.indexOf('Software') == 0);
				
				// Only configure back buffer if width and height have been set,
				// which they may not have been if View3D.render() has yet to be
				// invoked for the first time.
				if (_backBufferWidth>0 && _backBufferHeight>0)
					_context3D.configureBackBuffer(_backBufferWidth, _backBufferHeight, _antiAlias, _enableDepthAndStencil);
				
				// Dispatch the appropriate event depending on whether context was
				// created for the first time or recreated after a device loss.
				dispatchEvent(new Stage3DEvent(hadContext? Stage3DEvent.CONTEXT3D_RECREATED : Stage3DEvent.CONTEXT3D_CREATED));

				if (_renderFunction != null) {
					setRenderCallback(_renderFunction);
				}
				
			} else
				throw new Error("Rendering context lost!");
		}

		/**
		 *	Set the callback function for rendering
		 */
		public function setRenderCallback(func:Event -> Void) : Void {
			if (_stage3D!=null && _stage3D.context3D!=null) {
				
				if (_renderFunction!=null)
					OpenFLStage3D.removeRenderCallback(_stage3D.context3D, _renderFunction);
				
				if (func!=null)
					OpenFLStage3D.setRenderCallback(_stage3D.context3D, func);
			}

			_renderFunction = func;
		}
		
		/**
		 * Requests a Context3D object to attach to the managed Stage3D.
		 */
		private function requestContext(forceSoftware:Bool = false, profile:String = "baseline"):Void
		{
			// If forcing software, we can be certain that the
			// returned Context3D will be running software mode.
			// If not, we can't be sure and should stick to the
			// old value (will likely be same if re-requesting.)
			if (!_usesSoftwareRendering) _usesSoftwareRendering = forceSoftware;
			_profile = profile;
			
			// ugly stuff for backward compatibility
			var renderMode:String = Std.string(forceSoftware? Context3DRenderMode.SOFTWARE : Context3DRenderMode.AUTO);
			OpenFLStage3D.requestAGLSLContext3D(_stage3D, renderMode);
			//if (profile == "baseline")
			//	_stage3D.requestContext3D(renderMode);
			// else {
			// 	try {
			// 		_stage3D["requestContext3D"](renderMode, profile);
			// 	} catch (error:Error) {
			// 		throw "An error occurred creating a context using the given profile. Profiles are not supported for the SDK this was compiled with.";
			// 	}
			//}
			
			_contextRequested = true;
		}
		
		/**
		 * The Enter_Frame handler for processing the proxy.ENTER_FRAME and proxy.EXIT_FRAME event handlers.
		 * Typically the proxy.ENTER_FRAME listener would render the layers for this Stage3D instance.
		 */
		private function onEnterFrame(event:Event):Void
		{
			if (_context3D==null)
				return;
			
			// Clear the stage3D instance
			clear();
			
			//notify the enterframe listeners
			notifyEnterFrame();
			
			// Call the present() to render the frame
			present();
			
			//notify the exitframe listeners
			notifyExitFrame();
		}
		
		public function recoverFromDisposal():Bool
		{
			if (_context3D==null)
				return false;
			if (_context3D.driverInfo == "Disposed") {
				_context3D = null;
				dispatchEvent(new Stage3DEvent(Stage3DEvent.CONTEXT3D_DISPOSED));
				return false;
			}
			return true;
		}
		
		public function clearDepthBuffer():Void
		{
			if (_context3D==null)
				return;
			_context3D.clear(0, 0, 0, 1, 1, 0, Context3DClearMask.DEPTH);
		}
	}

