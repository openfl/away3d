package away3d.textures;

import away3d.cameras.Camera3D;
import away3d.cameras.lenses.PerspectiveLens;
import away3d.containers.Scene3D;
import away3d.containers.View3D;
import away3d.core.managers.Stage3DProxy;
import away3d.core.render.DefaultRenderer;
import away3d.core.render.RendererBase;
import away3d.core.traverse.EntityCollector;

import openfl.display.BitmapData;
import openfl.display3D.textures.TextureBase;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * CubeReflectionTexture provides a cube map texture for real-time reflections, used for any method that uses environment maps,
 * such as EnvMapMethod.
 *
 * @see away3d.materials.methods.EnvMapMethod
 */
class CubeReflectionTexture extends RenderCubeTexture
{
	public var position(get, set):Vector3D;
	public var nearPlaneDistance(get, set):Float;
	public var farPlaneDistance(get, set):Float;
	public var renderer(get, set):RendererBase;
	
	private var _mockTexture:BitmapCubeTexture;
	private var _mockBitmapData:BitmapData;
	private var _renderer:RendererBase;
	private var _entityCollector:EntityCollector;
	private var _cameras:Vector<Camera3D>;
	private var _lenses:Vector<PerspectiveLens>;
	private var _nearPlaneDistance:Float = .01;
	private var _farPlaneDistance:Float = 2000;
	private var _position:Vector3D;
	private var _isRendering:Bool;
	
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
	private function get_position():Vector3D
	{
		return _position;
	}
	
	private function set_position(value:Vector3D):Vector3D
	{
		_position = value;
		return value;
	}
	
	/**
	 * The near plane used by the camera lens.
	 */
	private function get_nearPlaneDistance():Float
	{
		return _nearPlaneDistance;
	}
	
	private function set_nearPlaneDistance(value:Float):Float
	{
		_nearPlaneDistance = value;
		return value;
	}
	
	/**
	 * The far plane of the camera lens. Can be used to cut off objects that are too far to be of interest in reflections
	 */
	private function get_farPlaneDistance():Float
	{
		return _farPlaneDistance;
	}
	
	private function set_farPlaneDistance(value:Float):Float
	{
		_farPlaneDistance = value;
		return value;
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
		
		for (i in 0...6)
			renderSurface(i, scene, targetTexture);
		
		_isRendering = false;
	}
	
	/**
	 * The renderer to use.
	 */
	private function get_renderer():RendererBase
	{
		return _renderer;
	}
	
	private function set_renderer(value:RendererBase):RendererBase
	{
		_renderer.dispose();
		_renderer = value;
		_entityCollector = _renderer.createEntityCollector();
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function dispose():Void
	{
		super.dispose();
		_mockTexture.dispose();
		for (i in 0...6)
			_cameras[i].dispose();
		
		_mockBitmapData.dispose();
	}
	
	private function renderSurface(surfaceIndex:Int, scene:Scene3D, targetTexture:TextureBase):Void
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
		_cameras = new Vector<Camera3D>();
		_lenses = new Vector<PerspectiveLens>();
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
		_cameras.push(cam);
	}
}