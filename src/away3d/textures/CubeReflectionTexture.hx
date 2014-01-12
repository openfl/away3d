package away3d.textures;

	//import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.PerspectiveLens;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.render.DefaultRenderer;
	import away3d.core.render.RendererBase;
	import away3d.core.traverse.EntityCollector;
	
	import flash.display.BitmapData;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Vector3D;
	
	//use namespace arcane;
	
	/**
	 * CubeReflectionTexture provides a cube map texture for real-time reflections, used for any method that uses environment maps,
	 * such as EnvMapMethod.
	 *
	 * @see away3d.materials.methods.EnvMapMethod
	 */
	class CubeReflectionTexture extends RenderCubeTexture
	{
		var _mockTexture:BitmapCubeTexture;
		var _mockBitmapData:BitmapData;
		var _renderer:RendererBase;
		var _entityCollector:EntityCollector;
		var _cameras:Array<Camera3D>;
		var _lenses:Array<PerspectiveLens>;
		var _nearPlaneDistance:Float = .01;
		var _farPlaneDistance:Float = 2000;
		var _position:Vector3D;
		var _isRendering:Bool;
		
		/**
		 * Creates a new CubeReflectionTexture object
		 * @param size The size of the cube texture
		 */
		public function new(size:Int)
		{
			super(size);
			_renderer = new DefaultRenderer();
			_entityCollector = _renderer.createEntityCollector();
			_position = new Vector3D();
			initMockTexture();
			initCameras();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getTextureForStage3D(stage3DProxy:Stage3DProxy):TextureBase
		{
			return _isRendering? _mockTexture.getTextureForStage3D(stage3DProxy) : super.getTextureForStage3D(stage3DProxy);
		}
		
		/**
		 * The origin where the environment map will be rendered. This is usually in the centre of the reflective object.
		 */
		public var position(get, set) : Vector3D;
		public function get_position() : Vector3D
		{
			return _position;
		}
		
		public function set_position(value:Vector3D) : Vector3D
		{
			_position = value;
		}
		
		/**
		 * The near plane used by the camera lens.
		 */
		public var nearPlaneDistance(get, set) : Float;
		public function get_nearPlaneDistance() : Float
		{
			return _nearPlaneDistance;
		}
		
		public function set_nearPlaneDistance(value:Float) : Float
		{
			_nearPlaneDistance = value;
		}
		
		/**
		 * The far plane of the camera lens. Can be used to cut off objects that are too far to be of interest in reflections
		 */
		public var farPlaneDistance(get, set) : Float;
		public function get_farPlaneDistance() : Float
		{
			return _farPlaneDistance;
		}
		
		public function set_farPlaneDistance(value:Float) : Float
		{
			_farPlaneDistance = value;
		}
		
		/**
		 * Renders the scene in the given view for reflections.
		 * @param view The view containing the scene to render.
		 */
		public function render(view:View3D):Void
		{
			var stage3DProxy:Stage3DProxy = view.stage3DProxy;
			var scene:Scene3D = view.scene;
			var targetTexture:TextureBase = super.getTextureForStage3D(stage3DProxy);
			
			_isRendering = true;
			_renderer.stage3DProxy = stage3DProxy;
			
			// For loop conversion - 						for (var i:UInt = 0; i < 6; ++i)
			
			var i:UInt = 0;
			
			for (i in 0...6)
				renderSurface(i, scene, targetTexture);
			
			_isRendering = false;
		}
		
		/**
		 * The renderer to use.
		 */
		public var renderer(get, set) : RendererBase;
		public function get_renderer() : RendererBase
		{
			return _renderer;
		}
		
		public function set_renderer(value:RendererBase) : RendererBase
		{
			_renderer.dispose();
			_renderer = value;
			_entityCollector = _renderer.createEntityCollector();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():Void
		{
			super.dispose();
			_mockTexture.dispose();
			// For loop conversion - 			for (var i:Int = 0; i < 6; ++i)
			var i:Int;
			for (i in 0...6)
				_cameras[i].dispose();
			
			_mockBitmapData.dispose();
		}
		
		private function renderSurface(surfaceIndex:UInt, scene:Scene3D, targetTexture:TextureBase):Void
		{
			var camera:Camera3D = _cameras[surfaceIndex];
			
			camera.lens.near = _nearPlaneDistance;
			camera.lens.far = _farPlaneDistance;
			camera.position = position;
			
			_entityCollector.camera = camera;
			_entityCollector.clear();
			scene.traversePartitions(_entityCollector);
			
			_renderer.render(_entityCollector, targetTexture, null, surfaceIndex);
			
			_entityCollector.cleanUp();
		}
		
		private function initMockTexture():Void
		{
			// use a completely transparent map to prevent anything from using this texture when updating map
			_mockBitmapData = new BitmapData(2, 2, true, 0x00000000);
			_mockTexture = new BitmapCubeTexture(_mockBitmapData, _mockBitmapData, _mockBitmapData, _mockBitmapData, _mockBitmapData, _mockBitmapData);
		}
		
		private function initCameras():Void
		{
			_cameras = new Array<Camera3D>();
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
			PerspectiveLens(cam.lens).fieldOfView = 90;
			_lenses.push(PerspectiveLens(cam.lens));
			cam.lens.aspectRatio = 1;
			_cameras.push(cam);
		}
	}

