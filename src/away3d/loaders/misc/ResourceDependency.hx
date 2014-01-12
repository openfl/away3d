package away3d.loaders.misc;

	//import away3d.arcane;
	import away3d.library.assets.IAsset;
	import away3d.loaders.parsers.ParserBase;
	
	import flash.net.URLRequest;
	
	//use namespace arcane;
	
	/**
	 * ResourceDependency represents the data required to load, parse and resolve additional files ("dependencies")
	 * required by a parser, used by ResourceLoadSession.
	 *
	 */
	class ResourceDependency
	{
		var _id:String;
		var _req:URLRequest;
		var _assets:Array<IAsset>;
		var _parentParser:ParserBase;
		var _data:Dynamic;
		var _retrieveAsRawData:Bool;
		var _suppressAssetEvents:Bool;
		var _dependencies:Array<ResourceDependency>;
		
		/*arcane*/ public var loader:SingleFileLoader;
		/*arcane*/ public var success:Bool;
		
		public function new(id:String, req:URLRequest, data:Dynamic, parentParser:ParserBase, retrieveAsRawData:Bool = false, suppressAssetEvents:Bool = false)
		{
			_id = id;
			_req = req;
			_parentParser = parentParser;
			_data = data;
			_retrieveAsRawData = retrieveAsRawData;
			_suppressAssetEvents = suppressAssetEvents;
			
			_assets = new Array<IAsset>();
			_dependencies = new Array<ResourceDependency>();
		}
		
		public var id(get, null) : String;		
		public function get_id() : String
		{
			return _id;
		}
		
		public var assets(get, null) : Array<IAsset>;		
		public function get_assets() : Array<IAsset>
		{
			return _assets;
		}
		
		public var dependencies(get, null) : Array<ResourceDependency>;		
		public function get_dependencies() : Array<ResourceDependency>
		{
			return _dependencies;
		}
		
		public var request(get, null) : URLRequest;	
		public function get_request() : URLRequest
		{
			return _req;
		}
		
		public var retrieveAsRawData(get, null) : Bool;		
		public function get_retrieveAsRawData() : Bool
		{
			return _retrieveAsRawData;
		}
		
		public var suppresAssetEvents(get, null) : Bool;		
		public function get_suppresAssetEvents() : Bool
		{
			return _suppressAssetEvents;
		}
		
		/**
		 * The data containing the dependency to be parsed, if the resource was already loaded.
		 */
		public var data(get, null) : Dynamic;
		public function get_data() : Dynamic
		{
			return _data;
		}
		
		/**
		 * @private
		 * Method to set data after having already created the dependency object, e.g. after load.
		 */
		public function setData(data:Dynamic):Void
		{
			_data = data;
		}
		
		/**
		 * The parser which is dependent on this ResourceDependency object.
		 */
		public var parentParser(get, null) : ParserBase;
		public function get_parentParser() : ParserBase
		{
			return _parentParser;
		}
		
		/**
		 * Resolve the dependency when it's loaded with the parent parser. For example, a dependency containing an
		 * ImageResource would be assigned to a Mesh instance as a BitmapMaterial, a scene graph object would be added
		 * to its intended parent. The dependency should be a member of the dependencies property.
		 */
		public function resolve():Void
		{
trace("ResourceDependency.resolve:_parentParser="+_parentParser+" id="+_id+" url="+_req.url);
			if (_parentParser!=null)
				_parentParser.resolveDependency(this);
		}
		
		/**
		 * Resolve a dependency failure. For example, map loading failure from a 3d file
		 */
		public function resolveFailure():Void
		{
			if (_parentParser!=null)
				_parentParser.resolveDependencyFailure(this);
		}
		
		/**
		 * Resolve the dependencies name
		 */
		public function resolveName(asset:IAsset):String
		{
			if (_parentParser!=null)
				return _parentParser.resolveDependencyName(this, asset);
			return asset.name;
		}
	
	}

