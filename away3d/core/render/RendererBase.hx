package away3d.core.render;

	//import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.sort.IEntitySorter;
	import away3d.core.sort.RenderableMergeSort;
	import away3d.core.traverse.EntityCollector;
	import away3d.errors.AbstractMethodError;
	import away3d.events.Stage3DEvent;
	import away3d.textures.Texture2DBase;
	
	import flash.display.BitmapData;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.textures.TextureBase;
	import flash.events.Event;
	import away3d.geom.Matrix3D;
	import flash.geom.Rectangle;
	
	//use namespace arcane;
	
	/**
	 * RendererBase forms an abstract base class for classes that are used in the rendering pipeline to render geometry
	 * to the back buffer or a texture.
	 */
	class RendererBase
	{
		var _context:Context3D;
		var _stage3DProxy:Stage3DProxy;
		
		var _backgroundR:Float;
		var _backgroundG:Float;
		var _backgroundB:Float;
		var _backgroundAlpha:Float;
		var _shareContext:Bool;
		
		var _renderTarget:TextureBase;
		var _renderTargetSurface:Int;
		
		// only used by renderers that need to render geometry to textures
		var _viewWidth:Float;
		var _viewHeight:Float;
		
		var _renderableSorter:IEntitySorter;
		var _backgroundImageRenderer:BackgroundImageRenderer;
		var _background:Texture2DBase;
		
		var _renderToTexture:Bool;
		var _antiAlias:UInt;
		var _textureRatioX:Float;
		var _textureRatioY:Float;
		
		var _snapshotBitmapData:BitmapData;
		var _snapshotRequired:Bool;
		
		var _clearOnRender:Bool;
		var _rttViewProjectionMatrix:Matrix3D;
		
		/**
		 * Creates a new RendererBase object.
		 */
		public function new(renderToTexture:Bool = false)
		{
			_backgroundR = 0;
			_backgroundG = 0;
			_backgroundB = 0;
			_backgroundAlpha = 1;
			_shareContext = false;
			
			_textureRatioX = 1;
			_textureRatioY = 1;
		
			_clearOnRender = true;
			_rttViewProjectionMatrix = new Matrix3D();
			_renderableSorter = new RenderableMergeSort();
			_renderToTexture = renderToTexture;
		}
		
		public function createEntityCollector():EntityCollector
		{
			return new EntityCollector();
		}
		
		public var viewWidth(get, set) : Float;
		
		public function get_viewWidth() : Float
		{
			return _viewWidth;
		}
		
		public function set_viewWidth(value:Float) : Float
		{
			_viewWidth = value;
			return value;
		}
		
		public var viewHeight(get, set) : Float;
		
		public function get_viewHeight() : Float
		{
			return _viewHeight;
		}
		
		public function set_viewHeight(value:Float) : Float
		{
			_viewHeight = value;
			return value;
		}
		
		public var renderToTexture(get, null) : Bool;
		
		public function get_renderToTexture() : Bool
		{
			return _renderToTexture;
		}
		
		public var renderableSorter(get, set) : IEntitySorter;
		
		public function get_renderableSorter() : IEntitySorter
		{
			return _renderableSorter;
		}
		
		public function set_renderableSorter(value:IEntitySorter) : IEntitySorter
		{
			_renderableSorter = value;
			return value;
		}
		
		public var clearOnRender(get, set) : Bool;
		
		public function get_clearOnRender() : Bool
		{
			return _clearOnRender;
		}
		
		public function set_clearOnRender(value:Bool) : Bool
		{
			_clearOnRender = value;
			return value;
		}
		
		/**
		 * The background color's red component, used when clearing.
		 *
		 * @private
		 */
		public var backgroundR(get, set) : Float;
		public function get_backgroundR() : Float
		{
			return _backgroundR;
		}
		
		public function set_backgroundR(value:Float) : Float
		{
			_backgroundR = value;
			return value;
		}
		
		/**
		 * The background color's green component, used when clearing.
		 *
		 * @private
		 */
		public var backgroundG(get, set) : Float;
		public function get_backgroundG() : Float
		{
			return _backgroundG;
		}
		
		public function set_backgroundG(value:Float) : Float
		{
			_backgroundG = value;
			return value;
		}
		
		/**
		 * The background color's blue component, used when clearing.
		 *
		 * @private
		 */
		public var backgroundB(get, set) : Float;
		public function get_backgroundB() : Float
		{
			return _backgroundB;
		}
		
		public function set_backgroundB(value:Float) : Float
		{
			_backgroundB = value;
			return value;
		}
		
		/**
		 * The Stage3DProxy that will provide the Context3D used for rendering.
		 *
		 * @private
		 */
		public var stage3DProxy(get, set) : Stage3DProxy;
		public function get_stage3DProxy() : Stage3DProxy
		{
			return _stage3DProxy;
		}
		
		public function set_stage3DProxy(value:Stage3DProxy) : Stage3DProxy
		{
			if (value == _stage3DProxy)
				return value;
			
			if (value==null) {
				if (_stage3DProxy!=null) {
					_stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContextUpdate);
					_stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContextUpdate);
				}
				_stage3DProxy = null;
				_context = null;
				return value;
			}
			//else if (_stage3DProxy) throw new Error("A Stage3D instance was already assigned!");
			
			_stage3DProxy = value;
			_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContextUpdate);
			_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContextUpdate);
			if (_backgroundImageRenderer!=null)
				_backgroundImageRenderer.stage3DProxy = value;
			
			if (value.context3D!=null)
				_context = value.context3D;

			return value;
		}
		
		/**
		 * Defers control of Context3D clear() and present() calls to Stage3DProxy, enabling multiple Stage3D frameworks
		 * to share the same Context3D object.
		 *
		 * @private
		 */
		public var shareContext(get, set) : Bool;
		public function get_shareContext() : Bool
		{
			return _shareContext;
		}
		
		public function set_shareContext(value:Bool) : Bool
		{
			_shareContext = value;
			return value;
		}
		
		/**
		 * Disposes the resources used by the RendererBase.
		 *
		 * @private
		 */
		public function dispose():Void
		{
			stage3DProxy = null;
			if (_backgroundImageRenderer!=null) {
				_backgroundImageRenderer.dispose();
				_backgroundImageRenderer = null;
			}
		}
		
		/**
		 * Renders the potentially visible geometry to the back buffer or texture.
		 * @param entityCollector The EntityCollector object containing the potentially visible geometry.
		 * @param target An option target texture to render to.
		 * @param surfaceSelector The index of a CubeTexture's face to render to.
		 * @param additionalClearMask Additional clear mask information, in case extra clear channels are to be omitted.
		 */
		public function render(entityCollector:EntityCollector, target:TextureBase = null, scissorRect:Rectangle = null, surfaceSelector:Int = 0):Void
		{
			if (_stage3DProxy==null || _context==null)
				return;
			
			_rttViewProjectionMatrix.copyFrom(entityCollector.camera.viewProjection);
			_rttViewProjectionMatrix.appendScale(_textureRatioX, _textureRatioY, 1);
			
			executeRender(entityCollector, target, scissorRect, surfaceSelector);
			
			// TODO: Maybe unncessary in this Context3D implementation
			// clear buffers
			// For loop conversion - 			for (var i:UInt = 0; i < 8; ++i)
			// var i:UInt = 0;
			// for (i in 0...8) {
			// 	_context.setVertexBufferAt(i, null);
			// 	_context.setTextureAt(i, null);
			// }
		}
		
		/**
		 * Renders the potentially visible geometry to the back buffer or texture. Only executed if everything is set up.
		 * @param entityCollector The EntityCollector object containing the potentially visible geometry.
		 * @param target An option target texture to render to.
		 * @param surfaceSelector The index of a CubeTexture's face to render to.
		 * @param additionalClearMask Additional clear mask information, in case extra clear channels are to be omitted.
		 */
		private function executeRender(entityCollector:EntityCollector, target:TextureBase = null, scissorRect:Rectangle = null, surfaceSelector:Int = 0):Void
		{
			_renderTarget = target;
			_renderTargetSurface = surfaceSelector;
			if (_renderableSorter!=null)
				_renderableSorter.sort(entityCollector);
			
			if (_renderToTexture)
				executeRenderToTexturePass(entityCollector);
			
			_stage3DProxy.setRenderTarget(target, true, surfaceSelector);
			
			if ((target!=null || !_shareContext) && _clearOnRender)
				_context.clear(_backgroundR, _backgroundG, _backgroundB, _backgroundAlpha, 1, 0);
			_context.setDepthTest(false, Context3DCompareMode.ALWAYS);
			_stage3DProxy.scissorRect = scissorRect;
			if (_backgroundImageRenderer!=null)
				_backgroundImageRenderer.render();
			
			draw(entityCollector, target);
			
			//line required for correct rendering when using away3d with starling. DO NOT REMOVE UNLESS STARLING INTEGRATION IS RETESTED!
			_context.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);

			if (!_shareContext) {
				if (_snapshotRequired && _snapshotBitmapData!=null) {
					_context.drawToBitmapData(_snapshotBitmapData);
					_snapshotRequired = false;
				}
			}
			_stage3DProxy.scissorRect = null;
		}
		
		/*
		 * Will draw the renderer's output on next render to the provided bitmap data.
		 * */
		public function queueSnapshot(bmd:BitmapData):Void
		{
			_snapshotRequired = true;
			_snapshotBitmapData = bmd;
		}
		
		private function executeRenderToTexturePass(entityCollector:EntityCollector):Void
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * Performs the actual drawing of geometry to the target.
		 * @param entityCollector The EntityCollector object containing the potentially visible geometry.
		 */
		private function draw(entityCollector:EntityCollector, target:TextureBase):Void
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * Assign the context once retrieved
		 */
		private function onContextUpdate(event:Event):Void
		{
			_context = _stage3DProxy.context3D;
		}
		
		public var backgroundAlpha(get, set) : Float;
		
		public function get_backgroundAlpha() : Float
		{
			return _backgroundAlpha;
		}
		
		public function set_backgroundAlpha(value:Float) : Float
		{
			_backgroundAlpha = value;
			return value;
		}
		
		public var background(get, set) : Texture2DBase;
		
		public function get_background() : Texture2DBase
		{
			return _background;
		}
		
		public function set_background(value:Texture2DBase) : Texture2DBase
		{
			if (_backgroundImageRenderer!=null && value==null) {
				_backgroundImageRenderer.dispose();
				_backgroundImageRenderer = null;
			}
			
			if (_backgroundImageRenderer==null && value!=null)
				_backgroundImageRenderer = new BackgroundImageRenderer(_stage3DProxy);
			
			_background = value;
			
			if (_backgroundImageRenderer!=null)
				_backgroundImageRenderer.texture = value;
			return value;
		}
		
		public var backgroundImageRenderer(get, null) : BackgroundImageRenderer;
		
		public function get_backgroundImageRenderer() : BackgroundImageRenderer
		{
			return _backgroundImageRenderer;
		}
		
		public var antiAlias(get, set) : UInt;
		
		public function get_antiAlias() : UInt
		{
			return _antiAlias;
		}
		
		public function set_antiAlias(antiAlias:UInt) : UInt
		{
			_antiAlias = antiAlias;
			return _antiAlias;
		}
		
		public var textureRatioX(get, set) : Float;
		
		public function get_textureRatioX() : Float
		{
			return _textureRatioX;
		}
		
		public function set_textureRatioX(value:Float) : Float
		{
			_textureRatioX = value;
			return value;
		}
		
		public var textureRatioY(get, set) : Float;
		
		public function get_textureRatioY() : Float
		{
			return _textureRatioY;
		}
		
		public function set_textureRatioY(value:Float) : Float
		{
			_textureRatioY = value;
			return value;
		}
	}

