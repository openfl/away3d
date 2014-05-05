package away3d.loaders;

	import away3d.*;
	import away3d.cameras.*;
	import away3d.containers.*;
	import away3d.entities.*;
	import away3d.events.*;
	import away3d.library.*;
	import away3d.library.assets.*;
	import away3d.lights.*;
	import away3d.loaders.misc.*;
	import away3d.loaders.parsers.*;
	import away3d.primitives.*;
	
	import flash.events.*;
	import flash.net.*;
	
	//use namespace arcane;
	
	/**
	 * Dispatched when any asset finishes parsing. Also see specific events for each
	 * individual asset type (meshes, materials et c.)
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="assetComplete", type="away3d.events.Asset3DEvent")]
	
	
	/**
	 * Dispatched when a full resource (including dependencies) finishes loading.
	 *
	 * @eventType away3d.events.LoaderEvent
	 */
	//[Event(name="resourceComplete", type="away3d.events.LoaderEvent")]
	
	
	/**
	 * Dispatched when a single dependency (which may be the main file of a resource)
	 * finishes loading.
	 *
	 * @eventType away3d.events.LoaderEvent
	 */
	//[Event(name="dependencyComplete", type="away3d.events.LoaderEvent")]
	
	
	/**
	 * Dispatched when an error occurs during loading. I
	 *
	 * @eventType away3d.events.LoaderEvent
	 */
	//[Event(name="loadError", type="away3d.events.LoaderEvent")]
	
	
	/**
	 * Dispatched when an error occurs during parsing.
	 *
	 * @eventType away3d.events.ParserEvent
	 */
	//[Event(name="parseError", type="away3d.events.ParserEvent")]
	
	
	/**
	 * Dispatched when a skybox asset has been costructed from a ressource.
	 * 
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="skyboxComplete", type="away3d.events.Asset3DEvent")]
	
	/**
	 * Dispatched when a camera3d asset has been costructed from a ressource.
	 * 
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="cameraComplete", type="away3d.events.Asset3DEvent")]
	
	/**
	 * Dispatched when a mesh asset has been costructed from a ressource.
	 * 
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="meshComplete", type="away3d.events.Asset3DEvent")]
	
	/**
	 * Dispatched when a geometry asset has been constructed from a resource.
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="geometryComplete", type="away3d.events.Asset3DEvent")]
	
	/**
	 * Dispatched when a skeleton asset has been constructed from a resource.
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="skeletonComplete", type="away3d.events.Asset3DEvent")]
	
	/**
	 * Dispatched when a skeleton pose asset has been constructed from a resource.
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="skeletonPoseComplete", type="away3d.events.Asset3DEvent")]
	
	/**
	 * Dispatched when a container asset has been constructed from a resource.
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="containerComplete", type="away3d.events.Asset3DEvent")]
	
	/**
	 * Dispatched when a texture asset has been constructed from a resource.
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="textureComplete", type="away3d.events.Asset3DEvent")]
	
	/**
	 * Dispatched when a texture projector asset has been constructed from a resource.
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="textureProjectorComplete", type="away3d.events.Asset3DEvent")]
	
	
	/**
	 * Dispatched when a material asset has been constructed from a resource.
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="materialComplete", type="away3d.events.Asset3DEvent")]
	
	
	/**
	 * Dispatched when a animator asset has been constructed from a resource.
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="animatorComplete", type="away3d.events.Asset3DEvent")]
	
	
	/**
	 * Dispatched when an animation set has been constructed from a group of animation state resources.
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="animationSetComplete", type="away3d.events.Asset3DEvent")]
	
	
	/**
	 * Dispatched when an animation state has been constructed from a group of animation node resources.
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="animationStateComplete", type="away3d.events.Asset3DEvent")]
	
	
	/**
	 * Dispatched when an animation node has been constructed from a resource.
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="animationNodeComplete", type="away3d.events.Asset3DEvent")]
	
	
	/**
	 * Dispatched when an animation state transition has been constructed from a group of animation node resources.
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="stateTransitionComplete", type="away3d.events.Asset3DEvent")]
	
	
	/**
	 * Dispatched when an light asset has been constructed from a resources.
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="lightComplete", type="away3d.events.Asset3DEvent")]
	
	
	/**
	 * Dispatched when an light picker asset has been constructed from a resources.
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="lightPickerComplete", type="away3d.events.Asset3DEvent")]
	
	
	/**
	 * Dispatched when an effect method asset has been constructed from a resources.
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="effectMethodComplete", type="away3d.events.Asset3DEvent")]
	
	
	/**
	 * Dispatched when an shadow map method asset has been constructed from a resources.
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="shadowMapMethodComplete", type="away3d.events.Asset3DEvent")]
	
	/**
	 * Dispatched when an image asset dimensions are not a power of 2
	 *
	 * @eventType away3d.events.Asset3DEvent
	 */
	//[Event(name="textureSizeError", type="away3d.events.Asset3DEvent")]
	/**
	 * Loader3D can load any file format that Away3D supports (or for which a third-party parser
	 * has been plugged in) and be added directly to the scene. As assets are encountered
	 * they are added to the Loader3D container. Assets that can not be displayed in the scene
	 * graph (e.g. unused bitmaps/materials/skeletons etc) will be ignored.
	 *
	 * This provides a fast and easy way to load models (no need for event listeners) but is not
	 * very versatile since many types of assets are ignored.
	 *
	 * Loader3D by default uses the Asset3DLibrary to load all assets, which means that they also
	 * ends up in the library. To circumvent this, Loader3D can be configured to not use the
	 * Asset3DLibrary in which case it will use the AssetLoader directly.
	 *
	 * @see away3d.loaders.AssetLoader
	 * @see away3d.library.Asset3DLibrary
	 */
	class Loader3D extends ObjectContainer3D
	{
		var _loadingSessions:Array<AssetLoader>;
		var _useAssetLib:Bool;
		var _assetLibId:String;
		
		public function new(useAsset3DLibrary:Bool = true, Asset3DLibraryId:String = null)
		{
			super();
			
			_loadingSessions = new Array<AssetLoader>();
			_useAssetLib = useAsset3DLibrary;
			_assetLibId = Asset3DLibraryId;
		}
		
		/**
		 * Loads a file and (optionally) all of its dependencies.
		 *
		 * @param req The URLRequest object containing the URL of the file to be loaded.
		 * @param context An optional context object providing additional parameters for loading
		 * @param ns An optional namespace string under which the file is to be loaded, allowing the differentiation of two resources with identical assets
		 * @param parser An optional parser object for translating the loaded data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.
		 */
		public function load(req:URLRequest, context:AssetLoaderContext = null, ns:String = null, parser:ParserBase = null):AssetLoaderToken
		{
			var token:AssetLoaderToken;
			
			if (_useAssetLib) {
				var lib:Asset3DLibraryBundle;
				lib = Asset3DLibraryBundle.getInstance(_assetLibId);
				token = lib.load(req, context, ns, parser);
			} else {
				var loader:AssetLoader = new AssetLoader();
				_loadingSessions.push(loader);
				token = loader.load(req, context, ns, parser);
			}
			
			token.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
			token.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.TEXTURE_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.CONTAINER_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.GEOMETRY_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.MATERIAL_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.MESH_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.ENTITY_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.SKELETON_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
			
			// Error are handled separately (see documentation for addErrorHandler)
			token._loader.addErrorHandler(onLoadError);
			
			return token;
		}
		
		/**
		 * Loads a resource from already loaded data.
		 *
		 * @param data The data object containing all resource information.
		 * @param context An optional context object providing additional parameters for loading
		 * @param ns An optional namespace string under which the file is to be loaded, allowing the differentiation of two resources with identical assets
		 * @param parser An optional parser object for translating the loaded data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.
		 */
		public function loadData(data:Dynamic, context:AssetLoaderContext = null, ns:String = null, parser:ParserBase = null):AssetLoaderToken
		{
			var token:AssetLoaderToken;
			
			if (_useAssetLib) {
				var lib:Asset3DLibraryBundle;
				lib = Asset3DLibraryBundle.getInstance(_assetLibId);
				token = lib.loadData(data, context, ns, parser);
			} else {
				var loader:AssetLoader = new AssetLoader();
				_loadingSessions.push(loader);
				token = loader.loadData(data, '', context, ns, parser);
			}
			
			token.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
			token.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.TEXTURE_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.CONTAINER_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.GEOMETRY_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.MATERIAL_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.MESH_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.ENTITY_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.SKELETON_COMPLETE, onAssetComplete);
			token.addEventListener(Asset3DEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
			
			// Error are handled separately (see documentation for addErrorHandler)
			token._loader.addErrorHandler(onLoadError);
			
			return token;
		}
				
		/**
		 * Stop the current loading/parsing process.
		 */
		public function stopLoad():Void
		{
			if (_useAssetLib) {
				var lib:Asset3DLibraryBundle;
				lib = Asset3DLibraryBundle.getInstance(_assetLibId);
				lib.stopAllLoadingSessions();
				_loadingSessions = null;
				return;
			}
			var i:Int;
			var length:Int = _loadingSessions.length;
			// For loop conversion - 			for (i = 0; i < length; i++)
			for (i in 0...length) {
				removeListeners(_loadingSessions[i]);
				_loadingSessions[i].stop();
				_loadingSessions[i] = null;
			}
			_loadingSessions = null;
		}
				
		/**
		 * Enables a specific parser. 
		 * When no specific parser is set for a loading/parsing opperation, 
		 * loader3d can autoselect the correct parser to use.
		 * A parser must have been enabled, to be considered when autoselecting the parser.
		 *
		 * @param parserClass The parser class to enable.
		 * @see away3d.loaders.parsers.Parsers
		*/
		public static function enableParser(parserClass):Void
		{
			SingleFileLoader.enableParser(parserClass);
		}
		
		/**
		 * Enables a list of parsers. 
		 * When no specific parser is set for a loading/parsing opperation, 
		 * loader3d can autoselect the correct parser to use.
		 * A parser must have been enabled, to be considered when autoselecting the parser.
		 *
		 * @param parserClasses A Vector of parser classes to enable.
		 * @see away3d.loaders.parsers.Parsers
		 */
		public static function enableParsers(parserClasses:Array<Dynamic>):Void
		{
			SingleFileLoader.enableParsers(parserClasses);
		}
		
		private function removeListeners(dispatcher:EventDispatcher):Void
		{
			dispatcher.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
			dispatcher.removeEventListener(LoaderEvent.LOAD_ERROR, onLoadError);
			dispatcher.removeEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(Asset3DEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(Asset3DEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(Asset3DEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(Asset3DEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(Asset3DEvent.TEXTURE_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(Asset3DEvent.CONTAINER_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(Asset3DEvent.GEOMETRY_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(Asset3DEvent.MATERIAL_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(Asset3DEvent.MESH_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(Asset3DEvent.ENTITY_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(Asset3DEvent.SKELETON_COMPLETE, onAssetComplete);
			dispatcher.removeEventListener(Asset3DEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
		}
		
		private function onAssetComplete(ev:Asset3DEvent):Void
		{
			if (ev.type == Asset3DEvent.ASSET_COMPLETE) {
				// TODO: not used
				// var type : String = ev.asset.assetType;
				var obj:ObjectContainer3D = null;
				switch (ev.asset.assetType) {
					case Asset3DType.LIGHT:
						obj = cast(ev.asset, LightBase);
					case Asset3DType.CONTAINER:
						obj = cast(ev.asset, ObjectContainer3D);
					case Asset3DType.MESH:
						obj = cast(ev.asset, Mesh);
					case Asset3DType.SKYBOX:
						obj = cast(ev.asset, SkyBox);
					case Asset3DType.TEXTURE_PROJECTOR:
						obj = cast(ev.asset, TextureProjector);
					case Asset3DType.CAMERA:
						obj = cast(ev.asset, Camera3D);
					case Asset3DType.SEGMENT_SET:
						obj = cast(ev.asset, SegmentSet);
				}
				
				// If asset was of fitting type, and doesn't
				// already have a parent, add to loader container
				if (obj!=null && obj.parent == null)
					addChild(obj);
			}
			
			this.dispatchEvent(ev.clone());
		}
		
		private function onParseError(ev:ParserEvent):Bool
		{
			if (hasEventListener(ParserEvent.PARSE_ERROR)) {
				dispatchEvent(ev);
				return true;
			} else
				return false;
		}
		
		
		private function onLoadError(ev:LoaderEvent):Bool
		{
			if (hasEventListener(LoaderEvent.LOAD_ERROR)) {
				dispatchEvent(ev);
				return true;
			} else
				return false;
		}
		
		private function onResourceComplete(ev:Event):Void
		{
			removeListeners(cast(ev.currentTarget, EventDispatcher));
			this.dispatchEvent(ev.clone());
		}
	}

