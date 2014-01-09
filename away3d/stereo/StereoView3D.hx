package away3d.stereo;

	//import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.core.render.RendererBase;
	import away3d.stereo.methods.StereoRenderMethodBase;
	
	import flash.display3D.textures.Texture;
	
	//use namespace arcane;
	
	class StereoView3D extends View3D
	{
		var _stereoCam:StereoCamera3D;
		var _stereoRenderer:StereoRenderer;
		
		var _stereoEnabled:Bool;
		
		public function new(scene:Scene3D = null, camera:Camera3D = null, renderer:RendererBase = null, stereoRenderMethod:StereoRenderMethodBase = null)
		{
			super(scene, camera, renderer);
			
			this.camera = camera;
			
			_stereoRenderer = new StereoRenderer(stereoRenderMethod);
		}
		
		public var stereoRenderMethod(get, set) : StereoRenderMethodBase;
		
		public function get_stereoRenderMethod() : StereoRenderMethodBase
		{
			return _stereoRenderer.renderMethod;
		}
		
		public function set_stereoRenderMethod(value:StereoRenderMethodBase) : StereoRenderMethodBase
		{
			_stereoRenderer.renderMethod = value;
		}
		
		public var camera(get, set) : Camera3D;
		
		override public function get_camera() : Camera3D
		{
			return _stereoCam;
		}
		
		override public function set_camera(value:Camera3D) : Camera3D
		{
			if (value == _stereoCam)
				return;
			
			if (value is StereoCamera3D)
				_stereoCam = StereoCamera3D(value);
			else
				throw new Error('StereoView3D must be used with StereoCamera3D');
		}
		
		public var stereoEnabled(get, set) : Bool;
		
		public function get_stereoEnabled() : Bool
		{
			return _stereoEnabled;
		}
		
		public function set_stereoEnabled(val:Bool) : Bool
		{
			_stereoEnabled = val;
		}
		
		override public function render():Void
		{
			if (_stereoEnabled) {
				// reset or update render settings
				if (_backBufferInvalid)
					updateBackBuffer();
				
				if (!_parentIsStage)
					updateGlobalPos();
				
				updateTime();
				
				renderWithCamera(_stereoCam.leftCamera, _stereoRenderer.getLeftInputTexture(_stage3DProxy), true);
				renderWithCamera(_stereoCam.rightCamera, _stereoRenderer.getRightInputTexture(_stage3DProxy), false);
				
				_stereoRenderer.render(_stage3DProxy);
				
				if (!_shareContext)
					_stage3DProxy._context3D.present();
				
				// fire collected mouse events
				_mouse3DManager.fireMouseEvents();
			} else {
				_camera = _stereoCam;
				super.render();
			}
		}
		
		private function renderWithCamera(cam:Camera3D, texture:Texture, doMouse:Bool):Void
		{
			_entityCollector.clear();
			
			_camera = cam;
			_camera.lens.aspectRatio = _aspectRatio;
			_entityCollector.camera = _camera;
			
			updateViewSizeData();
			
			// Always use RTT for stereo rendering
			_renderer.textureRatioX = _rttBufferManager.textureRatioX;
			_renderer.textureRatioY = _rttBufferManager.textureRatioY;
			
			// collect stuff to render
			_scene.traversePartitions(_entityCollector);
			
			// update picking
			if (doMouse)
				_mouse3DManager.updateCollider(this);
			
			//			updateLights(_entityCollector);
			
			if (_requireDepthRender)
				renderDepthPrepass(_entityCollector);
			
			if (_filter3DRenderer && _stage3DProxy._context3D) {
				_renderer.render(_entityCollector, _filter3DRenderer.getMainInputTexture(_stage3DProxy), _rttBufferManager.renderToTextureRect);
				_filter3DRenderer.render(_stage3DProxy, camera, _depthRender);
				if (!_shareContext)
					_stage3DProxy._context3D.present();
			} else {
				_renderer.shareContext = _shareContext;
				if (_shareContext)
					_renderer.render(_entityCollector, texture, _scissorRect);
				else
					_renderer.render(_entityCollector, texture, _rttBufferManager.renderToTextureRect);
				
			}
			
			// clean up data for this render
			_entityCollector.cleanUp();
		}
	}

