package away3d.core.render;

import away3d.core.managers.Stage3DProxy;
import away3d.core.sort.IEntitySorter;
import away3d.core.sort.RenderableMergeSort;
import away3d.core.traverse.EntityCollector;
import away3d.errors.AbstractMethodError;
import away3d.events.Stage3DEvent;
import away3d.textures.Texture2DBase;

import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.textures.TextureBase;
import openfl.events.Event;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;
import openfl.Vector;

/**
 * RendererBase forms an abstract base class for classes that are used in the rendering pipeline to render geometry
 * to the back buffer or a texture.
 */
class RendererBase
{
	@:allow(away3d) private var viewWidth(get, set):Float;
	@:allow(away3d) private var viewHeight(get, set):Float;
	@:allow(away3d) private var renderToTexture(get, never):Bool;
	public var renderableSorter(get, set):IEntitySorter;
	@:allow(away3d) private var clearOnRender(get, set):Bool;
	@:allow(away3d) private var backgroundR(get, set):Float;
	@:allow(away3d) private var backgroundG(get, set):Float;
	@:allow(away3d) private var backgroundB(get, set):Float;
	@:allow(away3d) private var stage3DProxy(get, set):Stage3DProxy;
	@:allow(away3d) private var shareContext(get, set):Bool;
	@:allow(away3d) private var backgroundAlpha(get, set):Float;
	@:allow(away3d) private var background(get, set):Texture2DBase;
	public var backgroundImageRenderer(get, never):BackgroundImageRenderer;
	public var antiAlias(get, set):Int;
	@:allow(away3d) private var textureRatioX(get, set):Float;
	@:allow(away3d) private var textureRatioY(get, set):Float;
	
	private var _context:Context3D;
	private var _stage3DProxy:Stage3DProxy;
	
	private var _backgroundR:Float = 0;
	private var _backgroundG:Float = 0;
	private var _backgroundB:Float = 0;
	private var _backgroundAlpha:Float = 1;
	private var _shareContext:Bool = false;
	
	private var _renderTarget:TextureBase;
	private var _renderTargetSurface:Int;
	
	// only used by renderers that need to render geometry to textures
	private var _viewWidth:Float;
	private var _viewHeight:Float;
	
	private var _renderableSorter:IEntitySorter;
	private var _backgroundImageRenderer:BackgroundImageRenderer;
	private var _background:Texture2DBase;
	
	private var _renderToTexture:Bool;
	private var _antiAlias:Int;
	private var _textureRatioX:Float = 1;
	private var _textureRatioY:Float = 1;
	
	private var _snapshotBitmapData:BitmapData;
	private var _snapshotRequired:Bool;
	
	private var _clearOnRender:Bool = true;
	private var _rttViewProjectionMatrix:Matrix3D = new Matrix3D();
	
	/**
	 * Creates a new RendererBase object.
	 */
	public function new(renderToTexture:Bool = false)
	{
		_renderableSorter = new RenderableMergeSort();
		_renderToTexture = renderToTexture;
	}
	
	@:allow(away3d) private function createEntityCollector():EntityCollector
	{
		return new EntityCollector();
	}
	
	private function get_viewWidth():Float
	{
		return _viewWidth;
	}
	
	private function set_viewWidth(value:Float):Float
	{
		_viewWidth = value;
		return value;
	}
	
	private function get_viewHeight():Float
	{
		return _viewHeight;
	}
	
	private function set_viewHeight(value:Float):Float
	{
		_viewHeight = value;
		return value;
	}
	
	private function get_renderToTexture():Bool
	{
		return _renderToTexture;
	}
	
	private function get_renderableSorter():IEntitySorter
	{
		return _renderableSorter;
	}
	
	private function set_renderableSorter(value:IEntitySorter):IEntitySorter
	{
		_renderableSorter = value;
		return value;
	}
	
	private function get_clearOnRender():Bool
	{
		return _clearOnRender;
	}
	
	private function set_clearOnRender(value:Bool):Bool
	{
		_clearOnRender = value;
		return value;
	}
	
	/**
	 * The background color's red component, used when clearing.
	 *
	 * @private
	 */
	private function get_backgroundR():Float
	{
		return _backgroundR;
	}
	
	private function set_backgroundR(value:Float):Float
	{
		_backgroundR = value;
		return value;
	}
	
	/**
	 * The background color's green component, used when clearing.
	 *
	 * @private
	 */
	private function get_backgroundG():Float
	{
		return _backgroundG;
	}
	
	private function set_backgroundG(value:Float):Float
	{
		_backgroundG = value;
		return value;
	}
	
	/**
	 * The background color's blue component, used when clearing.
	 *
	 * @private
	 */
	private function get_backgroundB():Float
	{
		return _backgroundB;
	}
	
	private function set_backgroundB(value:Float):Float
	{
		_backgroundB = value;
		return value;
	}
	
	/**
	 * The Stage3DProxy that will provide the Context3D used for rendering.
	 *
	 * @private
	 */
	private function get_stage3DProxy():Stage3DProxy
	{
		return _stage3DProxy;
	}
	
	private function set_stage3DProxy(value:Stage3DProxy):Stage3DProxy
	{
		if (value == _stage3DProxy)
			return value;
		
		if (value == null) {
			if (_stage3DProxy != null) {
				_stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContextUpdate);
				_stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContextUpdate);
			}
			_stage3DProxy = null;
			_context = null;
			return null;
		}
		
		_stage3DProxy = value;
		_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContextUpdate);
		_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContextUpdate);
		if (_backgroundImageRenderer != null)
			_backgroundImageRenderer.stage3DProxy = value;
		
		if (value.context3D != null)
			_context = value.context3D;
		
		return value;
	}
	
	/**
	 * Defers control of Context3D clear() and present() calls to Stage3DProxy, enabling multiple Stage3D frameworks
	 * to share the same Context3D object.
	 *
	 * @private
	 */
	private function get_shareContext():Bool
	{
		return _shareContext;
	}
	
	private function set_shareContext(value:Bool):Bool
	{
		_shareContext = value;
		return value;
	}
	
	/**
	 * Disposes the resources used by the RendererBase.
	 *
	 * @private
	 */
	@:allow(away3d) private function dispose():Void
	{
		stage3DProxy = null;
		if (_backgroundImageRenderer != null) {
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
		if (_stage3DProxy == null || _context == null)
			return;
		
		_rttViewProjectionMatrix.copyFrom(entityCollector.camera.viewProjection);
		_rttViewProjectionMatrix.appendScale(_textureRatioX, _textureRatioY, 1);
		
		executeRender(entityCollector, target, scissorRect, surfaceSelector);
		
		// clear buffers
		for (i in 0...8) {
			_context.setVertexBufferAt(i, null);
			_context.setTextureAt(i, null);
		}
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
		
		if (_renderableSorter != null) 
			_renderableSorter.sort(entityCollector);
		
		if (_renderToTexture)
			executeRenderToTexturePass(entityCollector);
		
		_stage3DProxy.setRenderTarget(target, true, surfaceSelector);
		
		if ((target != null || !_shareContext) && _clearOnRender)
			_context.clear(_backgroundR, _backgroundG, _backgroundB, _backgroundAlpha, 1, 0);
		_context.setDepthTest(false, Context3DCompareMode.ALWAYS);
		_stage3DProxy.scissorRect = scissorRect;
		if (_backgroundImageRenderer != null) 
			_backgroundImageRenderer.render();
		
		draw(entityCollector, target);
		
		//line required for correct rendering when using away3d with starling. DO NOT REMOVE UNLESS STARLING INTEGRATION IS RETESTED!
		_context.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);
		
		if (!_shareContext) {
			if (_snapshotRequired && _snapshotBitmapData != null) {
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
	
	private function get_backgroundAlpha():Float
	{
		return _backgroundAlpha;
	}
	
	private function set_backgroundAlpha(value:Float):Float
	{
		_backgroundAlpha = value;
		return value;
	}
	
	private function get_background():Texture2DBase
	{
		return _background;
	}
	
	private function set_background(value:Texture2DBase):Texture2DBase
	{
		if (_backgroundImageRenderer != null && value == null) {
			_backgroundImageRenderer.dispose();
			_backgroundImageRenderer = null;
		}
		
		if (_backgroundImageRenderer == null && value != null)
			_backgroundImageRenderer = new BackgroundImageRenderer(_stage3DProxy);
		
		_background = value;
		
		if (_backgroundImageRenderer != null)
			_backgroundImageRenderer.texture = value;
		
		return value;
	}
	
	private function get_backgroundImageRenderer():BackgroundImageRenderer
	{
		return _backgroundImageRenderer;
	}
	
	private function get_antiAlias():Int
	{
		return _antiAlias;
	}
	
	private function set_antiAlias(antiAlias:Int):Int
	{
		_antiAlias = antiAlias;
		return antiAlias;
	}
	
	private function get_textureRatioX():Float
	{
		return _textureRatioX;
	}
	
	private function set_textureRatioX(value:Float):Float
	{
		_textureRatioX = value;
		return value;
	}
	
	private function get_textureRatioY():Float
	{
		return _textureRatioY;
	}
	
	private function set_textureRatioY(value:Float):Float {
		_textureRatioY = value;
		return value;
	}
}