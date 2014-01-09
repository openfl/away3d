package away3d.lights.shadowmaps;

	//import away3d.arcane;
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
	
	import flash.display3D.textures.TextureBase;
	
	import flash.errors.Error;
	//use namespace arcane;
	
	class ShadowMapperBase
	{
		var _casterCollector:ShadowCasterCollector;
		
		var _depthMap:TextureProxyBase;
		var _depthMapSize:UInt = 2048;
		var _light:LightBase;
		var _explicitDepthMap:Bool;
		var _autoUpdateShadows:Bool = true;
		/*arcane*/ public var _shadowsInvalid:Bool;
		
		public function new()
		{
			_casterCollector = createCasterCollector();
		}
		
		private function createCasterCollector():ShadowCasterCollector
		{
			return new ShadowCasterCollector();
		}
		
		public var autoUpdateShadows(get, set) : Bool;
		
		public function get_autoUpdateShadows() : Bool
		{
			return _autoUpdateShadows;
		}
		
		public function set_autoUpdateShadows(value:Bool) : Bool
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
		public function setDepthMap(depthMap:TextureProxyBase):Void
		{
			if (_depthMap == depthMap)
				return;
			if (_depthMap!=null && !_explicitDepthMap)
				_depthMap.dispose();
			_depthMap = depthMap;
			if (_depthMap!=null) {
				_explicitDepthMap = true;
				_depthMapSize = _depthMap.width;
			} else
				_explicitDepthMap = false;
		}
		
		public var light(get, set) : LightBase;
		
		public function get_light() : LightBase
		{
			return _light;
		}
		
		public function set_light(value:LightBase) : LightBase
		{
			_light = value;
			return value;
		}
		
		public var depthMap(get, null) : TextureProxyBase;
		
		public function get_depthMap() : TextureProxyBase
		{
			if (_depthMap==null) _depthMap = createDepthTexture();
			return _depthMap;
		}
		
		public var depthMapSize(get, set) : UInt;
		
		public function get_depthMapSize() : UInt
		{
			return _depthMapSize;
		}
		
		public function set_depthMapSize(value:UInt) : UInt
		{
			if (value == _depthMapSize)
				return value;
			_depthMapSize = value;
			
			if (_explicitDepthMap) 
				throw new Error("Cannot set depth map size for the current renderer.");
			else if (_depthMap!=null) {
				_depthMap.dispose();
				_depthMap = null;
			}
			return value;
		}
		
		public function dispose():Void
		{
			_casterCollector = null;
			if (_depthMap!=null && !_explicitDepthMap)
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
		public function renderDepthMap(stage3DProxy:Stage3DProxy, entityCollector:EntityCollector, renderer:DepthRenderer):Void
		{
			_shadowsInvalid = false;
			updateDepthProjection(entityCollector.camera);
			if (_depthMap==null) _depthMap = createDepthTexture();
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

