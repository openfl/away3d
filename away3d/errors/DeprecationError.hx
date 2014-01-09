package away3d.errors;

	
	class DeprecationError extends Error
	{
		var _since:String;
		var _source:String;
		var _info:String;
		
		public function new(source:String, since:String, info:String)
		{
			super(source + " has been marked as deprecated since version " + since + " and has been slated for removal. " + info);
			_since = since;
			_source = source;
			_info = info;
		}
		
		public var since(get, null) : String;
		
		public function get_since() : String
		{
			return _since;
		}
		
		public var source(get, null) : String;
		
		public function get_source() : String
		{
			return _source;
		}
		
		public var info(get, null) : String;
		
		public function get_info() : String
		{
			return _info;
		}
	}

