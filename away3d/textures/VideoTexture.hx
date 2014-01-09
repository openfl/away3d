package away3d.textures;

	import away3d.materials.utils.IVideoPlayer;
	import away3d.materials.utils.SimpleVideoPlayer;
	import away3d.tools.utils.TextureUtils;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	class VideoTexture extends BitmapTexture
	{
		var _broadcaster:Sprite;
		var _autoPlay:Bool;
		var _autoUpdate:Bool;
		var _materialWidth:UInt;
		var _materialHeight:UInt;
		var _player:IVideoPlayer;
		var _clippingRect:Rectangle;
		
		public function new(source:String, materialWidth:UInt = 256, materialHeight:UInt = 256, loop:Bool = true, autoPlay:Bool = false, player:IVideoPlayer = null)
		{
			_broadcaster = new Sprite();
			
			// validates the size of the video
			_materialWidth = materialWidth;
			_materialHeight = materialHeight;
			
			// this clipping ensures the bimapdata size is valid.
			_clippingRect = new Rectangle(0, 0, _materialWidth, _materialHeight);
			
			// assigns the provided player or creates a simple player if null.
			_player = player || new SimpleVideoPlayer();
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
		public function set_autoPlay(b:Bool) : Void
		{
			_autoPlay = b;
		}
		
		public var autoPlay(get, set) : Void;
		
		public function get_autoPlay() : Void
		{
			return _autoPlay;
		}
		
		public var materialWidth(get, set) : UInt;
		
		public function get_materialWidth() : UInt
		{
			return _materialWidth;
		}
		
		public function set_materialWidth(value:UInt) : UInt
		{
			_materialWidth = validateMaterialSize(value);
			_player.width = _materialWidth;
			_clippingRect.width = _materialWidth;
		}
		
		public var materialHeight(get, set) : UInt;
		
		public function get_materialHeight() : UInt
		{
			return _materialHeight;
		}
		
		public function set_materialHeight(value:UInt) : UInt
		{
			_materialHeight = validateMaterialSize(value);
			_player.width = _materialHeight;
			_clippingRect.width = _materialHeight;
		}
		
		private function validateMaterialSize(size:UInt):Int
		{
			if (!TextureUtils.isDimensionValid(size)) {
				var oldSize:UInt = size;
				size = TextureUtils.getBestPowerOf2(size);
				trace("Warning: " + oldSize + " is not a valid material size. Updating to the closest supported resolution: " + size);
			}
			
			return size;
		}
		
		/**
		 * Indicates whether the material will redraw onEnterFrame
		 */
		public var autoUpdate(get, set) : Bool;
		public function get_autoUpdate() : Bool
		{
			return _autoUpdate;
		}
		
		public function set_autoUpdate(value:Bool) : Bool
		{
			if (value == _autoUpdate)
				return;
			
			_autoUpdate = value;
			
			if (value)
				_broadcaster.addEventListener(Event.ENTER_FRAME, autoUpdateHandler, false, 0, true);
			else
				_broadcaster.removeEventListener(Event.ENTER_FRAME, autoUpdateHandler);
		}
		
		public var player(get, null) : IVideoPlayer;
		
		public function get_player() : IVideoPlayer
		{
			return _player;
		}
	}

