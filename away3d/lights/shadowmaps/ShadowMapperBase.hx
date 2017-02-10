package away3d.lights.shadowmaps;

import away3d.cameras.Camera3D;
import away3d.containers.Scene3D;
import away3d.core.managers.Stage3DProxy;
import away3d.core.render.DepthRenderer;
import away3d.core.traverse.EntityCollector;
import away3d.core.traverse.ShadowCasterCollector;
import away3d.errors.AbstractMethodError;
import away3d.lights.LightBase;
import away3d.textures.RenderTexture;
import away3d.textures.TextureProxyBase;

import openfl.display3D.textures.TextureBase;
import openfl.errors.Error;

class ShadowMapperBase
{
	public var autoUpdateShadows(get, set):Bool;
	public var light(get, set):LightBase;
	public var depthMap(get, never):TextureProxyBase;
	public var depthMapSize(get, set):Int;
	
	private var _casterCollector:ShadowCasterCollector;
	private var _depthMap:TextureProxyBase;
	private var _depthMapSize:Int = 2048;
	private var _light:LightBase;
	private var _explicitDepthMap:Bool;
	private var _autoUpdateShadows:Bool = true;
	@:allow(away3d) private var _shadowsInvalid:Bool;
	
	public function new()
	{
		_casterCollector = createCasterCollector();
	}
	
	private function createCasterCollector():ShadowCasterCollector
	{
		return new ShadowCasterCollector();
	}
	
	private function get_autoUpdateShadows():Bool
	{
		return _autoUpdateShadows;
	}
	
	private function set_autoUpdateShadows(value:Bool):Bool
	{
		_autoUpdateShadows = value;
		return value;
	}
	
	public function updateShadows():Void
	{
		_shadowsInvalid = true;
	}
	
	/**
	 * This is used by renderers that can support depth maps to be shared across instances
	 * @param depthMap
	 */
	@:allow(away3d) private function setDepthMap(depthMap:TextureProxyBase):Void
	{
		if (_depthMap == depthMap)
			return;
		if (_depthMap != null && !_explicitDepthMap)
			_depthMap.dispose();
		_depthMap = depthMap;
		if (_depthMap != null) {
			_explicitDepthMap = true;
			_depthMapSize = _depthMap.width;
		} else
			_explicitDepthMap = false;
	}
	
	private function get_light():LightBase
	{
		return _light;
	}
	
	private function set_light(value:LightBase):LightBase
	{
		_light = value;
		return value;
	}
	
	private function get_depthMap():TextureProxyBase
	{
		if (_depthMap == null)
			_depthMap = createDepthTexture();
		
		return _depthMap ;
	}
	
	private function get_depthMapSize():Int
	{
		return _depthMapSize;
	}
	
	private function set_depthMapSize(value:Int):Int
	{
		if (value == _depthMapSize)
			return value;
		_depthMapSize = value;
		
		if (_explicitDepthMap)
			throw new Error("Cannot set depth map size for the current renderer.");
		else if (_depthMap != null) {
			_depthMap.dispose();
			_depthMap = null;
		}
		return value;
	}
	
	public function dispose():Void
	{
		_casterCollector = null;
		if (_depthMap != null && !_explicitDepthMap)
			_depthMap.dispose();
		_depthMap = null;
	}
	
	private function createDepthTexture():TextureProxyBase
	{
		return new RenderTexture(_depthMapSize, _depthMapSize);
	}
	
	/**
	 * Renders the depth map for this light.
	 * @param entityCollector The EntityCollector that contains the original scene data.
	 * @param renderer The DepthRenderer to render the depth map.
	 */
	@:allow(away3d) private function renderDepthMap(stage3DProxy:Stage3DProxy, entityCollector:EntityCollector, renderer:DepthRenderer):Void
	{
		_shadowsInvalid = false;
		updateDepthProjection(entityCollector.camera);
		if (_depthMap == null)
			_depthMap = createDepthTexture();
		drawDepthMap(_depthMap.getTextureForStage3D(stage3DProxy), entityCollector.scene, renderer);
	}
	
	private function updateDepthProjection(viewCamera:Camera3D):Void
	{
		throw new AbstractMethodError();
	}
	
	private function drawDepthMap(target:TextureBase, scene:Scene3D, renderer:DepthRenderer):Void
	{
		throw new AbstractMethodError();
	}
}