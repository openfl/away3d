package away3d.core.render;

import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.data.RenderableListItem;
import away3d.core.math.Plane3D;
import away3d.core.traverse.EntityCollector;
import away3d.entities.Entity;
import away3d.materials.MaterialBase;

import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.textures.TextureBase;
import openfl.geom.Rectangle;
import openfl.Vector;

/**
 * The DepthRenderer class renders 32-bit depth information encoded as RGBA
 */
class DepthRenderer extends RendererBase
{
	public var disableColor(get, set):Bool;
	
	private var _activeMaterial:MaterialBase;
	private var _renderBlended:Bool;
	private var _distanceBased:Bool;
	private var _disableColor:Bool;
	
	/**
	 * Creates a new DepthRenderer object.
	 * @param renderBlended Indicates whether semi-transparent objects should be rendered.
	 * @param distanceBased Indicates whether the written depth value is distance-based or projected depth-based
	 */
	public function new(renderBlended:Bool = false, distanceBased:Bool = false)
	{
		super();
		_renderBlended = renderBlended;
		_distanceBased = distanceBased;
		_backgroundR = 1;
		_backgroundG = 1;
		_backgroundB = 1;
	}
	
	private function get_disableColor():Bool
	{
		return _disableColor;
	}
	
	private function set_disableColor(value:Bool):Bool
	{
		_disableColor = value;
		return value;
	}
	
	override private function set_backgroundR(value:Float):Float
	{
		return value;
	}
	
	override private function set_backgroundG(value:Float):Float
	{
		return value;
	}
	
	override private function set_backgroundB(value:Float):Float
	{
		return value;
	}
	
	@:allow(away3d) private function renderCascades(entityCollector:EntityCollector, target:TextureBase, numCascades:Int, scissorRects:Vector<Rectangle>, cameras:Vector<Camera3D>):Void
	{
		_renderTarget = target;
		_renderTargetSurface = 0;
		_renderableSorter.sort(entityCollector);
		_stage3DProxy.setRenderTarget(target, true, 0);
		_context.clear(1, 1, 1, 1, 1, 0);
		_context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		_context.setDepthTest(true, Context3DCompareMode.LESS);
		
		var head:RenderableListItem = entityCollector.opaqueRenderableHead;
		var first:Bool = true;
		var i:Int = numCascades - 1;
		while (i >= 0) {
			_stage3DProxy.scissorRect = scissorRects[i];
			drawCascadeRenderables(head, cameras[i], first? null : cameras[i].frustumPlanes);
			first = false;
			--i;
		}
		
		if (_activeMaterial != null)
			_activeMaterial.deactivateForDepth(_stage3DProxy);
		
		_activeMaterial = null;
		
		//line required for correct rendering when using away3d with starling. DO NOT REMOVE UNLESS STARLING INTEGRATION IS RETESTED!
		_context.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);
		
		_stage3DProxy.scissorRect = null;
	}
	
	private function drawCascadeRenderables(item:RenderableListItem, camera:Camera3D, cullPlanes:Vector<Plane3D>):Void
	{
		var material:MaterialBase;
		
		while (item != null) {
			if (item.cascaded) {
				item = item.next;
				continue;
			}
			
			var renderable:IRenderable = item.renderable;
			var entity:Entity = renderable.sourceEntity;
			
			// if completely in front, it will fall in a different cascade
			// do not use near and far planes
			if (cullPlanes == null || entity.worldBounds.isInFrustum(cullPlanes, 4)) {
				material = renderable.material;
				if (_activeMaterial != material) {
					if (_activeMaterial != null)
						_activeMaterial.deactivateForDepth(_stage3DProxy);
					_activeMaterial = material;
					_activeMaterial.activateForDepth(_stage3DProxy, camera, false);
				}
				
				_activeMaterial.renderDepth(renderable, _stage3DProxy, camera, camera.viewProjection);
			} else
				item.cascaded = true;
			
			item = item.next;
		}
	}
	
	/**
	 * @inheritDoc
	 */
	override private function draw(entityCollector:EntityCollector, target:TextureBase):Void
	{
		_context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		_context.setDepthTest(true, Context3DCompareMode.LESS);
		drawRenderables(entityCollector.opaqueRenderableHead, entityCollector);
		
		if (_disableColor)
			_context.setColorMask(false, false, false, false);
		
		if (_renderBlended)
			drawRenderables(entityCollector.blendedRenderableHead, entityCollector);
		
		if (_activeMaterial != null)
			_activeMaterial.deactivateForDepth(_stage3DProxy);
		
		if (_disableColor)
			_context.setColorMask(true, true, true, true);
		
		_activeMaterial = null;
	}
	
	/**
	 * Draw a list of renderables.
	 * @param renderables The renderables to draw.
	 * @param entityCollector The EntityCollector containing all potentially visible information.
	 */
	private function drawRenderables(item:RenderableListItem, entityCollector:EntityCollector):Void
	{
		var camera:Camera3D = entityCollector.camera;
		var item2:RenderableListItem;
		
		while (item != null) {
			_activeMaterial = item.renderable.material;
			
			// otherwise this would result in depth rendered anyway because fragment shader kil is ignored
			if (_disableColor && _activeMaterial.hasDepthAlphaThreshold()) {
				item2 = item;
				// fast forward
				do {
					item2 = item2.next;
				} while ((item2 != null && item2.renderable.material == _activeMaterial));
			} else {
				_activeMaterial.activateForDepth(_stage3DProxy, camera, _distanceBased);
				item2 = item;
				do {
					_activeMaterial.renderDepth(item2.renderable, _stage3DProxy, camera, _rttViewProjectionMatrix);
					item2 = item2.next;
				} while ((item2 != null && item2.renderable.material == _activeMaterial));
				_activeMaterial.deactivateForDepth(_stage3DProxy);
			}
			item = item2;
		}
	}
}