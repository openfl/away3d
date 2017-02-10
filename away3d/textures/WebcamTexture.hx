package away3d.textures;

import away3d.tools.utils.TextureUtils;

import openfl.display.BitmapData;
import openfl.display3D.textures.TextureBase;
import openfl.geom.Matrix;
import openfl.media.Video;

#if flash
import flash.media.Camera;
#end

class WebcamTexture extends BitmapTexture
{	
	#if flash
	public var autoUpdate(get, set):Bool;
	public var camera(get, never):Camera;
	public var smoothing(get, set):Bool;
	
	private var _materialSize:Int;
	private var _video:Video;
	private var _camera:Camera;
	private var _matrix:Matrix;
	private var _smoothing:Bool;
	private var _playing:Bool;
	private var _autoUpdate:Bool;
	
	public function new(cameraWidth:Int = 320, cameraHeight:Int = 240, materialSize:Int = 256, autoStart:Bool = true, camera:Camera = null, smoothing:Bool = true)
	{
		_materialSize = validateMaterialSize(materialSize);
		
		super(new BitmapData(_materialSize, _materialSize, false, 0));
		
		// Use default camera if none supplied
		_camera = camera;
		if (_camera == null)
			_camera = Camera.getCamera();
		_video = new Video(cameraWidth, cameraHeight);
		
		_matrix = new Matrix();
		_matrix.scale(_materialSize/cameraWidth, _materialSize/cameraHeight);
		
		if (autoStart) {
			_autoUpdate = true;
			start();
		}
		
		_smoothing = smoothing;
	}
	
	/**
	 * Defines whether the texture should automatically update while camera stream is
	 * playing. If false, the update() method must be invoked for the texture to redraw.
	 */
	private function get_autoUpdate():Bool
	{
		return _autoUpdate;
	}
	
	private function set_autoUpdate(val:Bool):Bool
	{
		_autoUpdate = val;
		
		if (_autoUpdate && _playing)
			invalidateContent();
		return val;
	}
	
	/**
	 * The Camera instance (webcam) used by this texture.
	 */
	private function get_camera():Camera
	{
		return _camera;
	}
	
	/**
	 * Toggles smoothing on the texture as it's drawn (and potentially scaled)
	 * from the video stream to a BitmapData object.
	 */
	private function get_smoothing():Bool
	{
		return _smoothing;
	}
	
	private function set_smoothing(value:Bool):Bool
	{
		_smoothing = value;
		return value;
	}
	
	/**
	 * Start subscribing to camera stream. For the texture to update the update()
	 * method must be repeatedly invoked, or autoUpdate set to true.
	 */
	public function start():Void
	{
		_video.attachCamera(_camera);
		_playing = true;
		invalidateContent();
	}
	
	/**
	 * Detaches from the camera stream.
	 */
	public function stop():Void
	{
		_playing = false;
		_video.attachCamera(null);
	}
	
	/**
	 * Draws the video and updates the bitmap texture
	 * If autoUpdate is false and this function is not called the bitmap texture will not update!
	 */
	public function update():Void
	{
		// draw
		bitmapData.lock();
		bitmapData.fillRect(bitmapData.rect, 0);
		bitmapData.draw(_video, _matrix, null, null, bitmapData.rect, _smoothing);
		bitmapData.unlock();
		invalidateContent();
	}
	
	/**
	 * Flips the image from the webcam horizontally
	 */
	public function flipHorizontal():Void
	{
		_matrix.a = -1*_matrix.a;
		_matrix.a > 0? _matrix.tx = _video.x - _video.width*Math.abs(_matrix.a) : _matrix.tx = _video.width*Math.abs(_matrix.a) + _video.x;
	}
	
	/**
	 * Flips the image from the webcam vertically
	 */
	public function flipVertical():Void
	{
		_matrix.d = -1*_matrix.d;
		_matrix.d > 0? _matrix.ty = _video.y - _video.height*Math.abs(_matrix.d) : _matrix.ty = _video.height*Math.abs(_matrix.d) + _video.y;
	}
	
	/**
	 * Clean up used resources.
	 */
	override public function dispose():Void
	{
		super.dispose();
		stop();
		bitmapData.dispose();
		_video.attachCamera(null);
		_camera = null;
		_video = null;
		_matrix = null;
	}
	
	override private function uploadContent(texture:TextureBase):Void
	{
		super.uploadContent(texture);
		
		if (_playing && _autoUpdate) {
			// Keep content invalid so that it will
			// be updated again next render cycle
			update();
		}
	}
	
	private function validateMaterialSize(size:Int):Int
	{
		if (!TextureUtils.isDimensionValid(size)) {
			var oldSize:Int = size;
			size = TextureUtils.getBestPowerOf2(size);
			trace("Warning: " + oldSize + " is not a valid material size. Updating to the closest supported resolution: " + size);
		}
		
		return size;
	}
	#end
}