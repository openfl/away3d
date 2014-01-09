package away3d.lights.shadowmaps;

	//import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.PerspectiveLens;
	import away3d.containers.Scene3D;
	import away3d.core.render.DepthRenderer;
	import away3d.lights.PointLight;
	import away3d.textures.RenderCubeTexture;
	import away3d.textures.TextureProxyBase;
	
	import flash.display3D.textures.TextureBase;
	
	import flash.geom.Vector3D;
	
	//use namespace arcane;
	
	class CubeMapShadowMapper extends ShadowMapperBase
	{
		var _depthCameras:Array<Camera3D>;
		var _lenses:Array<PerspectiveLens>;
		var _needsRender:Array<Bool>;
		
		public function new()
		{
			super();
			
			_depthMapSize = 512;
			
			_needsRender = new Array<Bool>();
			initCameras();
		}
		
		private function initCameras():Void
		{
			_depthCameras = new Array<Camera3D>();
			_lenses = new Array<PerspectiveLens>();
			// posX, negX, posY, negY, posZ, negZ
			addCamera(0, 90, 0);
			addCamera(0, -90, 0);
			addCamera(-90, 0, 0);
			addCamera(90, 0, 0);
			addCamera(0, 0, 0);
			addCamera(0, 180, 0);
		}
		
		private function addCamera(rotationX:Float, rotationY:Float, rotationZ:Float):Void
		{
			var cam:Camera3D = new Camera3D();
			cam.rotationX = rotationX;
			cam.rotationY = rotationY;
			cam.rotationZ = rotationZ;
			cam.lens.near = .01;
			cast(cam.lens, PerspectiveLens).fieldOfView = 90;
			_lenses.push(cast(cam.lens, PerspectiveLens));
			cam.lens.aspectRatio = 1;
			_depthCameras.push(cam);
		}
		
		override private function createDepthTexture():TextureProxyBase
		{
			return new RenderCubeTexture(_depthMapSize);
		}
		
		override private function updateDepthProjection(viewCamera:Camera3D):Void
		{
			var maxDistance:Float = cast(_light, PointLight)._fallOff;
			var pos:Vector3D = _light.scenePosition;
			
			// todo: faces outside frustum which are pointing away from camera need not be rendered!
			// For loop conversion - 			for (var i:UInt = 0; i < 6; ++i)
			var i:UInt = 0;
			for (i in 0...6) {
				_lenses[i].far = maxDistance;
				_depthCameras[i].position = pos;
				_needsRender[i] = true;
			}
		}
		
		override private function drawDepthMap(target:TextureBase, scene:Scene3D, renderer:DepthRenderer):Void
		{
			// For loop conversion - 			for (var i:UInt = 0; i < 6; ++i)
			var i:UInt = 0;
			for (i in 0...6) {
				if (_needsRender[i]) {
					_casterCollector.camera = _depthCameras[i];
					_casterCollector.clear();
					scene.traversePartitions(_casterCollector);
					renderer.render(_casterCollector, target, null, i);
					_casterCollector.cleanUp();
				}
			}
		}
	}

