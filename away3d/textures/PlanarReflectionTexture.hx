package away3d.textures;

import away3d.cameras.Camera3D;
import away3d.cameras.lenses.ObliqueNearPlaneLens;
import away3d.containers.View3D;
import away3d.core.managers.Stage3DProxy;
import away3d.core.math.Matrix3DUtils;
import away3d.core.math.Plane3D;
import away3d.core.render.DefaultRenderer;
import away3d.core.render.RendererBase;
import away3d.core.traverse.EntityCollector;
import away3d.tools.utils.TextureUtils;

import openfl.display.BitmapData;
import openfl.display3D.textures.TextureBase;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * PlanarReflectionTexture is a Texture that can be used for material-based planar reflections, as provided by PlanarReflectionMethod, FresnelPlanarReflectionMethod.
 *
 * @see away3d.materials.methods.PlanarReflectionMethod
 */
class PlanarReflectionTexture extends RenderTexture
{
	public var plane(get, set):Plane3D;
	public var renderer(get, set):RendererBase;
	public var scale(get, set):Float;
	public var textureRatioX(get, never):Float;
	public var textureRatioY(get, never):Float;
	
	private var _mockTexture:BitmapTexture;
	private var _mockBitmapData:BitmapData;
	private var _renderer:RendererBase;
	private var _scale:Float = 1;
	private var _isRendering:Bool;
	private var _entityCollector:EntityCollector;
	private var _camera:Camera3D;
	private var _plane:Plane3D;
	private var _matrix:Matrix3D;
	private var _vector:Vector3D;
	private var _scissorRect:Rectangle;
	private var _lens:ObliqueNearPlaneLens;
	private var _viewWidth:Float;
	private var _viewHeight:Float;
	
	/**
	 * Creates a new PlanarReflectionTexture object.
	 */
	public function new()
	{
		super(2, 2);
		_camera = new Camera3D();
		_lens = new ObliqueNearPlaneLens(null, null);
		_camera.lens = _lens;
		_matrix = new Matrix3D();
		_vector = new Vector3D();
		_plane = new Plane3D();
		_scissorRect = new Rectangle();
		_renderer = new DefaultRenderer();
		_entityCollector = _renderer.createEntityCollector();
		initMockTexture();
	}
	
	/**
	 * The plane to reflect with.
	 */
	private function get_plane():Plane3D
	{
		return _plane;
	}
	
	private function set_plane(value:Plane3D):Plane3D
	{
		_plane = value;
		return value;
	}
	
	/**
	 * Sets the plane to match a given matrix. This is used to easily match a Mesh using a PlaneGeometry and yUp = false.
	 * @param matrix The transformation matrix to rotate the plane with.
	 */
	public function applyTransform(matrix:Matrix3D):Void
	{
		//var rawData : Vector.<Number> = Matrix3DUtils.RAW_DATA_CONTAINER;
		_matrix.copyFrom(matrix);
		// invert transpose
		_matrix.invert();
		_matrix.copyRowTo(2, _vector);
		
		_plane.a = -_vector.x;
		_plane.b = -_vector.y;
		_plane.c = -_vector.z;
		_plane.d = -_vector.w;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function getTextureForStage3D(stage3DProxy:Stage3DProxy):TextureBase
	{
		return _isRendering? _mockTexture.getTextureForStage3D(stage3DProxy) : super.getTextureForStage3D(stage3DProxy);
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
	 * A scale factor to reduce the quality of the reflection. Default value is 1 (same quality as the View)
	 */
	private function get_scale():Float
	{
		return _scale;
	}
	
	private function set_scale(value:Float):Float
	{
		_scale = value > 1? 1 :
			value < 0? 0 :
			value;
		return value;
	}
	
	/**
	 * Renders the scene in the given view for reflections.
	 * @param view The view containing the Scene to render.
	 */
	public function render(view:View3D):Void
	{
		var camera:Camera3D = view.camera;
		if (isCameraBehindPlane(camera))
			return;
		_isRendering = true;
		updateSize(view.width, view.height);
		updateCamera(camera);
		
		_entityCollector.camera = _camera;
		_entityCollector.clear();
		view.scene.traversePartitions(_entityCollector);
		_renderer.stage3DProxy = view.stage3DProxy;
		_renderer.render(_entityCollector, super.getTextureForStage3D(view.stage3DProxy), _scissorRect);
		
		_entityCollector.cleanUp();
		_isRendering = false;
	}
	
	override public function dispose():Void
	{
		super.dispose();
		_mockTexture.dispose();
		_camera.dispose();
		_mockBitmapData.dispose();
	}
	
	private function get_textureRatioX():Float
	{
		return _renderer.textureRatioX;
	}
	
	private function get_textureRatioY():Float
	{
		return _renderer.textureRatioY;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function uploadContent(texture:TextureBase):Void
	{ /* disallow */
	}
	
	private function updateCamera(camera:Camera3D):Void
	{
		Matrix3DUtils.reflection(_plane, _matrix);
		_matrix.prepend(camera.sceneTransform);
		_matrix.prependScale(1, -1, 1);
		_camera.transform = _matrix;
		_lens.baseLens = camera.lens;
		_lens.aspectRatio = _viewWidth/_viewHeight;
		_lens.plane = transformPlane(_plane, _matrix, _lens.plane);
	}
	
	private function isCameraBehindPlane(camera:Camera3D):Bool
	{
		return camera.x*_plane.a + camera.y*_plane.b + camera.z*_plane.c + _plane.d < 0;
	}
	
	private function transformPlane(plane:Plane3D, matrix:Matrix3D, result:Plane3D = null):Plane3D
	{
		if (result == null) result = new Plane3D();
		// actually transposed inverseSceneTransform is used, but since sceneTransform is already the inverse of the inverse
		var rawData:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
		var a:Float = plane.a, b:Float = plane.b, c:Float = plane.c, d:Float = plane.d;
		matrix.copyRawDataTo(rawData);
		result.a = a*rawData[0] + b*rawData[1] + c*rawData[2] + d*rawData[3];
		result.b = a*rawData[4] + b*rawData[5] + c*rawData[6] + d*rawData[7];
		result.c = a*rawData[8] + b*rawData[9] + c*rawData[10] + d*rawData[11];
		result.d = -(a*rawData[12] + b*rawData[13] + c*rawData[14] + d*rawData[15]);
		result.normalize();
		return result;
	}
	
	private function updateSize(width:Float, height:Float):Void
	{
		if (width > 2048)
			width = 2048;
		if (height > 2048)
			height = 2048;
		_viewWidth = width*_scale;
		_viewHeight = height*_scale;
		var textureWidth:Int = TextureUtils.getBestPowerOf2(Std.int(_viewWidth));
		var textureHeight:Int = TextureUtils.getBestPowerOf2(Std.int(_viewHeight));
		setSize(textureWidth, textureHeight);
		
		var textureRatioX:Float = _viewWidth/textureWidth;
		var textureRatioY:Float = _viewHeight/textureHeight;
		_renderer.textureRatioX = textureRatioX;
		_renderer.textureRatioY = textureRatioY;
		_scissorRect.x = (textureWidth - _viewWidth)*.5;
		_scissorRect.y = (textureHeight - _viewHeight)*.5;
		_scissorRect.width = _viewWidth;
		_scissorRect.height = _viewHeight;
	}
	
	private function initMockTexture():Void
	{
		// use a completely transparent map to prevent anything from using this texture when updating map
		_mockBitmapData = new BitmapData(2, 2, true, 0x00000000);
		_mockTexture = new BitmapTexture(_mockBitmapData);
	}
}