package away3d.library.assets;

	//import away3d.arcane;
	import away3d.events.AssetEvent;
	
	import flash.events.EventDispatcher;
	
	//use namespace arcane;
	
	class NamedAssetBase extends EventDispatcher
	{
		var _originalName:String;
		var _namespace:String;
		var _name:String;
		var _id:String;
		var _full_path:Array<Dynamic>;
		
		public static var DEFAULT_NAMESPACE:String = 'default';
		
		public function new(name:String = null)
		{
			super();
			
			if (name == null)
				name = 'null';
			
			_name = name;
			_originalName = name;
			
			updateFullPath();
		}
		
		/**
		 * The original name used for this asset in the resource (e.g. file) in which
		 * it was found. This may not be the same as <code>name</code>, which may
		 * have changed due to of a name conflict.
		 */
		public var originalName(get, null) : String;
		public function get_originalName() : String
		{
			return _originalName;
		}
		
		public var id(get, set) : String;
		
		public function get_id() : String
		{
			return _id;
		}
		
		public function set_id(newID:String) : String
		{
			_id = newID;
			return _id;
		}
		
		public var name(get, set) : String;
		
		public function get_name() : String
		{
			return _name;
		}
		
		public function set_name(val:String) : String
		{
			var prev:String;
			
			prev = _name;
			_name = val;
			if (_name == null)
				_name = 'null';
			
			updateFullPath();
			
			if (hasEventListener(AssetEvent.ASSET_RENAME))
				dispatchEvent(new AssetEvent(AssetEvent.ASSET_RENAME, cast(this, IAsset), prev));

			return _name;
		}
		
		public var assetNamespace(get, null) : String;
		
		public function get_assetNamespace() : String
		{
			return _namespace;
		}
		
		public var assetFullPath(get, null) : Array<Dynamic>;
		
		public function get_assetFullPath() : Array<Dynamic>
		{
			return _full_path;
		}
		
		public function assetPathEquals(name:String, ns:String):Bool
		{
			return (_name == name && (ns!=null || _namespace == ns));
		}
		
		public function resetAssetPath(name:String, ns:String = null, overrideOriginal:Bool = true):Void
		{
			_name = name!=null ? name : 'null';
			_namespace = ns!=null ? ns : DEFAULT_NAMESPACE;
			if (overrideOriginal)
				_originalName = _name;
			
			updateFullPath();
		}
		
		private function updateFullPath():Void
		{
			_full_path = [ _namespace, _name ];
		}
	}

