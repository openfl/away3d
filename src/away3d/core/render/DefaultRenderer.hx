/**
 * The DefaultRenderer class provides the default rendering method. It renders the scene graph objects using the
 * materials assigned to them.
 */
package away3d.core.render;


import flash.Vector;
import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.data.RenderableListItem;
import away3d.core.managers.Stage3DProxy;
import away3d.core.traverse.EntityCollector;
import away3d.lights.DirectionalLight;
import away3d.lights.LightBase;
import away3d.lights.PointLight;
import away3d.lights.shadowmaps.ShadowMapperBase;
import away3d.materials.MaterialBase;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DCompareMode;
import flash.display3D.textures.TextureBase;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
#if (cpp || neko || js)
using away3d.Stage3DUtils;
#end
class DefaultRenderer extends RendererBase {

    static private var RTT_PASSES:Int = 1;
    static private var SCREEN_PASSES:Int = 2;
    static private var ALL_PASSES:Int = 3;
    private var _activeMaterial:MaterialBase;
    private var _distanceRenderer:DepthRenderer;
    private var _depthRenderer:DepthRenderer;
    private var _skyboxProjection:Matrix3D;
/**
	 * Creates a new DefaultRenderer object.
	 * @param antiAlias The amount of anti-aliasing to use.
	 * @param renderMode The render mode to use.
	 */

    public function new() {
        _skyboxProjection = new Matrix3D();
        super();
        _depthRenderer = new DepthRenderer();
        _distanceRenderer = new DepthRenderer(false, true);
    }

    override private function set_stage3DProxy(value:Stage3DProxy):Stage3DProxy {
        super.stage3DProxy = value;
        _distanceRenderer.stage3DProxy = _depthRenderer.stage3DProxy = value;
        return value;
    }

    override private function executeRender(entityCollector:EntityCollector, target:TextureBase = null, scissorRect:Rectangle = null, surfaceSelector:Int = 0):Void {
        updateLights(entityCollector);
// otherwise RTT will interfere with other RTTs
        if (target != null) {
            drawRenderables(entityCollector.opaqueRenderableHead, entityCollector, RTT_PASSES);
            drawRenderables(entityCollector.blendedRenderableHead, entityCollector, RTT_PASSES);
        }
        super.executeRender(entityCollector, target, scissorRect, surfaceSelector);
    }

    private function updateLights(entityCollector:EntityCollector):Void {
        var dirLights:Vector<DirectionalLight> = entityCollector.directionalLights;
        var pointLights:Vector<PointLight> = entityCollector.pointLights;
        var len:Int;
        var i:Int;
        var light:LightBase;
        var shadowMapper:ShadowMapperBase;
        len = dirLights.length;
        i = 0;
        while (i < len) {
            light = dirLights[i];
            shadowMapper = light.shadowMapper;
            if (light.castsShadows && (shadowMapper.autoUpdateShadows || shadowMapper._shadowsInvalid)) shadowMapper.renderDepthMap(_stage3DProxy, entityCollector, _depthRenderer);
            ++i;
        }
        len = pointLights.length;
        i = 0;
        while (i < len) {
            light = pointLights[i];
            shadowMapper = light.shadowMapper;
            if (light.castsShadows && (shadowMapper.autoUpdateShadows || shadowMapper._shadowsInvalid)) shadowMapper.renderDepthMap(_stage3DProxy, entityCollector, _distanceRenderer);
            ++i;
        }
    }

/**
	 * @inheritDoc
	 */

    override private function draw(entityCollector:EntityCollector, target:TextureBase):Void {
        _context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
        if (entityCollector.skyBox != null) {
            if (_activeMaterial != null) _activeMaterial.deactivate(_stage3DProxy);
            _activeMaterial = null;
            _context.setDepthTest(false, Context3DCompareMode.ALWAYS);
            drawSkyBox(entityCollector);
        }
        _context.setDepthTest(true, Context3DCompareMode.LESS_EQUAL);
        var which:Int = (target != null) ? SCREEN_PASSES : ALL_PASSES;
        drawRenderables(entityCollector.opaqueRenderableHead, entityCollector, which);
        drawRenderables(entityCollector.blendedRenderableHead, entityCollector, which);
        _context.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);
        if (_activeMaterial != null) _activeMaterial.deactivate(_stage3DProxy);
        _activeMaterial = null;
    }

/**
	 * Draw the skybox if present.
	 * @param entityCollector The EntityCollector containing all potentially visible information.
	 */

    private function drawSkyBox(entityCollector:EntityCollector):Void {
        var skyBox:IRenderable = entityCollector.skyBox;
        var material:MaterialBase = skyBox.material;
        var camera:Camera3D = entityCollector.camera;
        updateSkyBoxProjection(camera);
        material.activatePass(0, _stage3DProxy, camera);
        material.renderPass(0, skyBox, _stage3DProxy, entityCollector, _skyboxProjection);
        material.deactivatePass(0, _stage3DProxy);
    }

    private function updateSkyBoxProjection(camera:Camera3D):Void {
        var near:Vector3D = new Vector3D();
        _skyboxProjection.copyFrom(_rttViewProjectionMatrix);
        _skyboxProjection.copyRowTo(2, near);
        var camPos:Vector3D = camera.scenePosition;
        var cx:Float = near.x;
        var cy:Float = near.y;
        var cz:Float = near.z;
        var cw:Float = -(near.x * camPos.x + near.y * camPos.y + near.z * camPos.z + Math.sqrt(cx * cx + cy * cy + cz * cz));
        var signX:Float = cx >= (0) ? 1 : -1;
        var signY:Float = cy >= (0) ? 1 : -1;
        var p:Vector3D = new Vector3D(signX, signY, 1, 1);
        var inverse:Matrix3D = _skyboxProjection.clone();
        inverse.invert();
        var q:Vector3D = inverse.transformVector(p);
        _skyboxProjection.copyRowTo(3, p);
        var a:Float = (q.x * p.x + q.y * p.y + q.z * p.z + q.w * p.w) / (cx * q.x + cy * q.y + cz * q.z + cw * q.w);
        _skyboxProjection.copyRowFrom(2, new Vector3D(cx * a, cy * a, cz * a, cw * a));
    }

/**
	 * Draw a list of renderables.
	 * @param renderables The renderables to draw.
	 * @param entityCollector The EntityCollector containing all potentially visible information.
	 */

    private function drawRenderables(item:RenderableListItem, entityCollector:EntityCollector, which:Int):Void {
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
                var rttMask:Int = (_activeMaterial.passRendersToTexture(j)) ? 1 : 2;
                if ((rttMask & which) != 0) {
                    _activeMaterial.activatePass(j, _stage3DProxy, camera);
                    do {
                        _activeMaterial.renderPass(j, item2.renderable, _stage3DProxy, entityCollector, _rttViewProjectionMatrix);
                        item2 = item2.next;
                    }
                    while ((item2 != null && item2.renderable.material == _activeMaterial));
                    _activeMaterial.deactivatePass(j, _stage3DProxy);
                }

                else {
                    do {
                        item2 = item2.next;
                    }
                    while ((item2 != null && item2.renderable.material == _activeMaterial));
                }

            }
            while ((++j < numPasses));
            item = item2;
        }

    }

    override public function dispose():Void {
        super.dispose();
        _depthRenderer.dispose();
        _distanceRenderer.dispose();
        _depthRenderer = null;
        _distanceRenderer = null;
    }

}

