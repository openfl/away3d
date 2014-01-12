package away3d.errors;

	
	/**
	 * TextureError is thrown when an invalid texture is used regarding Stage3D limitations.
	 */
	class InvalidTextureError extends Error
	{
		/**
		 * Create a new TextureError.
		 * @param message An optional message to override the default error message.
		 * @param id The id of the error.
		 */
		public function new(message:String = null, id:Int = 0)
		{
			super(message || "Invalid bitmapData! Must be power of 2 and not exceeding 2048.", id);
		}
	}

