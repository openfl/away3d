package away3d.textures;

import away3d.materials.utils.IVideoPlayer;
import away3d.materials.utils.SimpleVideoPlayer;
import away3d.tools.utils.TextureUtils;

import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Rectangle;

class VideoTexture extends BitmapTexture
{
	public var autoPlay(get, set):Bool;
	public var materialWidth(get, set):Int;
	public var materialHeight(get, set):Int;
	public var autoUpdate(get, set):Bool;
	public var player(get, never):IVideoPlayer;
	
	private var _broadcaster:Sprite;
	private var _autoPlay:Bool;
	private var _autoUpdate:Bool;
	private var _materialWidth:Int;
	private var _materialHeight:Int;
	private var _player:IVideoPlayer;
	private var _clippingRect:Rectangle;
	
	public function new(source:String, materialWidth:Int = 256, materialHeight:Int = 256, loop:Bool = true, autoPlay:Bool = false, player:IVideoPlayer = null)
	{
		_broadcaster = new Sprite();
		
		// validates the size of the video
		_materialWidth = materialWidth;
		_materialHeight = materialHeight;
		
		// this clipping ensures the bimapdata size is valid.
		_clippingRect = new Rectangle(0, 0, _materialWidth, _materialHeight);
		
		// assigns the provided player or creates a simple player if null.
		_player = player;
		if (_player == null)
			_player = new SimpleVideoPlayer();
		_player.loop = loop;
		_player.source = source;
		_player.width = _materialWidth;
		_player.height = _materialHeight;
		
		// sets autplay
		_autoPlay = autoPlay;
		
		// Sets up the bitmap material
		super(new BitmapData(_materialWidth, _materialHeight, true, 0));
		
		// if autoplay start video
		if (autoPlay)
			_player.play();
		
		// auto update is true by default
		autoUpdate = true;
	}
	
	/**
	 * Draws the video and updates the bitmap texture
	 * If autoUpdate is false and this function is not called the bitmap texture will not update!
	 */
	public function update():Void
	{
		
		if (_player.playing && !_player.paused) {
			
			bitmapData.lock();
			bitmapData.fillRect(_clippingRect, 0);
			bitmapData.draw(_player.container, null, null, null, _clippingRect);
			bitmapData.unlock();
			invalidateContent();
		}
	
	}
	
	override public function dispose():Void
	{
		super.dispose();
		autoUpdate = false;
		bitmapData.dispose();
		_player.dispose();
		_player = null;
		_broadcaster = null;
		_clippingRect = null;
	}
	
	private function autoUpdateHandler(event:Event):Void
	{
		update();
	}
	
	/**
	 * Indicates whether the video will start playing on initialisation.
	 * If false, only the first frame is displayed.
	 */
	private function set_autoPlay(b:Bool):Bool
	{
		_autoPlay = b;
		return b;
	}
	
	private function get_autoPlay():Bool
	{
		return _autoPlay;
	}
	
	private function get_materialWidth():Int
	{
		return _materialWidth;
	}
	
	private function set_materialWidth(value:Int):Int
	{
		_materialWidth = validateMaterialSize(value);
		_player.width = _materialWidth;
		_clippingRect.width = _materialWidth;
		return value;
	}
	
	private function get_materialHeight():Int
	{
		return _materialHeight;
	}
	
	private function set_materialHeight(value:Int):Int
	{
		_materialHeight = validateMaterialSize(value);
		_player.width = _materialHeight;
		_clippingRect.width = _materialHeight;
		return value;
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
	
	/**
	 * Indicates whether the material will redraw onEnterFrame
	 */
	private function get_autoUpdate():Bool
	{
		return _autoUpdate;
	}
	
	private function set_autoUpdate(value:Bool):Bool
	{
		if (value == _autoUpdate)
			return value;
		
		_autoUpdate = value;
		
		if (value)
			_broadcaster.addEventListener(Event.ENTER_FRAME, autoUpdateHandler, false, 0, true);
		else
			_broadcaster.removeEventListener(Event.ENTER_FRAME, autoUpdateHandler);
		return value;
	}
	
	private function get_player():IVideoPlayer
	{
		return _player;
	}
}