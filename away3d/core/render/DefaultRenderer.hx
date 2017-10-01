package away3d.core.render;

import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.data.RenderableListItem;
import away3d.core.managers.Stage3DProxy;
import away3d.core.math.Matrix3DUtils;
import away3d.core.traverse.EntityCollector;
import away3d.lights.DirectionalLight;
import away3d.lights.LightBase;
import away3d.lights.PointLight;
import away3d.lights.shadowmaps.ShadowMapperBase;
import away3d.materials.MaterialBase;

import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.textures.TextureBase;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * The DefaultRenderer class provides the default rendering method. It renders the scene graph objects using the
 * materials assigned to them.
 */
class DefaultRenderer extends RendererBase
{
	private static var RTT_PASSES:Int = 1;
	private static var SCREEN_PASSES:Int = 2;
	private static var ALL_PASSES:Int = 3;
	private var _activeMaterial:MaterialBase;
	private var _distanceRenderer:DepthRenderer;
	private var _depthRenderer:DepthRenderer;
	private var _skyboxProjection:Matrix3D = new Matrix3D();
	private var _tempSkyboxMatrix:Matrix3D = new Matrix3D();
	private var _skyboxTempVector:Vector3D = new Vector3D();

	/**
	 * Creates a new DefaultRenderer object.
	 * @param antiAlias The amount of anti-aliasing to use.
	 * @param renderMode The render mode to use.
	 */
	public function new()
	{
		super();
		_depthRenderer = new DepthRenderer();
		_distanceRenderer = new DepthRenderer(false, true);
	}

	override private function set_stage3DProxy(value:Stage3DProxy):Stage3DProxy
	{
		super.stage3DProxy = value;
		_distanceRenderer.stage3DProxy = _depthRenderer.stage3DProxy = value;
		return value;
	}

	override private function executeRender(entityCollector:EntityCollector, target:TextureBase = null, scissorRect:Rectangle = null, surfaceSelector:Int = 0):Void
	{
		updateLights(entityCollector);
		
		// otherwise RTT will interfere with other RTTs
		if (target != null) {
			drawRenderables(entityCollector.opaqueRenderableHead, entityCollector, RTT_PASSES);
			drawRenderables(entityCollector.blendedRenderableHead, entityCollector, RTT_PASSES);
		}
		
		super.executeRender(entityCollector, target, scissorRect, surfaceSelector);
	}

	private function updateLights(entityCollector:EntityCollector):Void
	{
		var dirLights:Vector<DirectionalLight> = entityCollector.directionalLights;
		var pointLights:Vector<PointLight> = entityCollector.pointLights;
		var len:Int, i:Int;
		var light:LightBase;
		var shadowMapper:ShadowMapperBase;
		
		len = dirLights.length;
		for (i in 0...len) {
			light = dirLights[i];
			shadowMapper = light.shadowMapper;
			if (light.castsShadows && (shadowMapper.autoUpdateShadows || shadowMapper._shadowsInvalid))
				shadowMapper.renderDepthMap(_stage3DProxy, entityCollector, _depthRenderer);
		}
		
		len = pointLights.length;
		for (i in 0...len) {
			light = pointLights[i];
			shadowMapper = light.shadowMapper;
			if (light.castsShadows && (shadowMapper.autoUpdateShadows || shadowMapper._shadowsInvalid))
				shadowMapper.renderDepthMap(_stage3DProxy, entityCollector, _distanceRenderer);
		}
	}

	/**
	 * @inheritDoc
	 */
	override private function draw(entityCollector:EntityCollector, target:TextureBase):Void
	{
		_context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		
		if (entityCollector.skyBox != null) {
			if (_activeMaterial != null)
				_activeMaterial.deactivate(_stage3DProxy);
			_activeMaterial = null;
			
			_context.setDepthTest(false, Context3DCompareMode.ALWAYS);
			drawSkyBox(entityCollector);
		}
		
		_context.setDepthTest(true, Context3DCompareMode.LESS_EQUAL);
		
		var which:Int = (target != null) ? SCREEN_PASSES : ALL_PASSES;
		drawRenderables(entityCollector.opaqueRenderableHead, entityCollector, which);
		drawRenderables(entityCollector.blendedRenderableHead, entityCollector, which);
		
		_context.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);
		
		if (_activeMaterial != null)
			_activeMaterial.deactivate(_stage3DProxy);
		
		_activeMaterial = null;
	}

	/**
	 * Draw the skybox if present.
	 * @param entityCollector The EntityCollector containing all potentially visible information.
	 */
	private function drawSkyBox(entityCollector:EntityCollector):Void
	{
		var skyBox:IRenderable = entityCollector.skyBox;
		var material:MaterialBase = skyBox.material;
		var camera:Camera3D = entityCollector.camera;
		
		updateSkyBoxProjection(camera);
		
		material.activatePass(0, _stage3DProxy, camera);
		material.renderPass(0, skyBox, _stage3DProxy, entityCollector, _skyboxProjection);
		material.deactivatePass(0, _stage3DProxy);
	}

	private function updateSkyBoxProjection(camera:Camera3D):Void
	{
		_skyboxProjection.copyFrom(_rttViewProjectionMatrix);
		_skyboxProjection.copyRowTo(2, _skyboxTempVector);
		var camPos:Vector3D = camera.scenePosition;
		var cx:Float = _skyboxTempVector.x;
		var cy:Float = _skyboxTempVector.y;
		var cz:Float = _skyboxTempVector.z;
		var length:Float = Math.sqrt(cx*cx + cy*cy + cz*cz);

		_skyboxTempVector.x = 0;
		_skyboxTempVector.y = 0;
		_skyboxTempVector.z = 0;
		_skyboxTempVector.w = 1;
		_tempSkyboxMatrix.copyFrom(camera.sceneTransform);
		_tempSkyboxMatrix.copyColumnFrom(3,_skyboxTempVector);

		_skyboxTempVector.x = 0;
		_skyboxTempVector.y = 0;
		_skyboxTempVector.z = 1;
		_skyboxTempVector.w = 0;

		Matrix3DUtils.transformVector(_tempSkyboxMatrix,_skyboxTempVector, _skyboxTempVector);
		_skyboxTempVector.normalize();

		var angle:Float = Math.acos(_skyboxTempVector.x*(cx/length) + _skyboxTempVector.y*(cy/length) + _skyboxTempVector.z*(cz/length));
		if(Math.abs(angle)>0.000001) {
			return;
		}

		var cw:Float = -(cx*camPos.x + cy*camPos.y + cz*camPos.z + length);
		var signX:Float = cx >= 0? 1 : -1;
		var signY:Float = cy >= 0? 1 : -1;

		var p:Vector3D = _skyboxTempVector;
		p.x = signX;
		p.y = signY;
		p.z = 1;
		p.w = 1;
		_tempSkyboxMatrix.copyFrom(_skyboxProjection);
		_tempSkyboxMatrix.invert();
		var q:Vector3D = Matrix3DUtils.transformVector(_tempSkyboxMatrix,p,Matrix3DUtils.CALCULATION_VECTOR3D);
		_skyboxProjection.copyRowTo(3, p);
		var a:Float = (q.x*p.x + q.y*p.y + q.z*p.z + q.w*p.w)/(cx*q.x + cy*q.y + cz*q.z + cw*q.w);
		_skyboxTempVector.x = cx*a;
		_skyboxTempVector.y = cy*a;
		_skyboxTempVector.z = cz*a;
		_skyboxTempVector.w = cw*a;
		//copy changed near far
		_skyboxProjection.copyRowFrom(2, _skyboxTempVector);
	}

	/**
	 * Draw a list of renderables.
	 * @param renderables The renderables to draw.
	 * @param entityCollector The EntityCollector containing all potentially visible information.
	 */
	private function drawRenderables(item:RenderableListItem, entityCollector:EntityCollector, which:Int):Void
	{
		var numPasses:Int;
		var j:Int;
		var camera:Camera3D = entityCollector.camera;
		var item2:RenderableListItem;
		
		while (item != null) {
			_activeMaterial = item.renderable.material;
			_activeMaterial.updateMaterial(_context);
			
			numPasses = _activeMaterial.numPasses;
			j = 0;
			
			do {
				item2 = item;
				
				var rttMask:Int = _activeMaterial.passRendersToTexture(j)? 1 : 2;
				
				if ((rttMask & which) != 0) {
					_activeMaterial.activatePass(j, _stage3DProxy, camera);
					do {
						_activeMaterial.renderPass(j, item2.renderable, _stage3DProxy, entityCollector, _rttViewProjectionMatrix);
						item2 = item2.next;
					} while ((item2 != null && item2.renderable.material == _activeMaterial));
					_activeMaterial.deactivatePass(j, _stage3DProxy);
				} else {
					do {
						item2 = item2.next;
					} while ((item2 != null && item2.renderable.material == _activeMaterial));
				}

			} while (++j < numPasses);
			
			item = item2;
		}
		
	}
	
	override private function dispose():Void
	{
		super.dispose();
		_depthRenderer.dispose();
		_distanceRenderer.dispose();
		_depthRenderer = null;
		_distanceRenderer = null;
	}
}