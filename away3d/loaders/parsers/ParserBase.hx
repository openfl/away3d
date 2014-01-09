package away3d.loaders.parsers;

	//import away3d.arcane;
	import away3d.errors.AbstractMethodError;
	import away3d.events.AssetEvent;
	import away3d.events.ParserEvent;
	import away3d.library.assets.AssetType;
	import away3d.library.assets.IAsset;
	import away3d.loaders.misc.ResourceDependency;
	import away3d.loaders.parsers.utils.ParserUtil;
	import away3d.tools.utils.TextureUtils;
	
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.Lib;
	
	import flash.errors.Error;

	//use namespace arcane;
	
	/**
	 * Dispatched when the parsing finishes.
	 *
	 * @eventType away3d.events.ParserEvent
	 */
	//[Event(name="parseComplete", type="away3d.events.ParserEvent")]
	
	/**
	 * Dispatched when parser pauses to wait for dependencies, used internally to trigger
	 * loading of dependencies which are then returned to the parser through it's interface
	 * in the arcane namespace.
	 *
	 * @eventType away3d.events.ParserEvent
	 */
	//[Event(name="readyForDependencies", type="away3d.events.ParserEvent")]
	
	/**
	 * Dispatched if an error was caught during parsing.
	 *
	 * @eventType away3d.events.ParserEvent
	 */
	//[Event(name="parseError", type="away3d.events.ParserEvent")]
	
	/**
	 * Dispatched when any asset finishes parsing. Also see specific events for each
	 * individual asset type (meshes, materials et c.)
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="assetComplete", type="away3d.events.AssetEvent")]
		
	
	/**
	 * Dispatched when a skybox asset has been costructed from a ressource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="skyboxComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a camera3d asset has been costructed from a ressource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="cameraComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a mesh asset has been costructed from a ressource.
	 * 
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="meshComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a geometry asset has been constructed from a resource.
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="geometryComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a skeleton asset has been constructed from a resource.
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="skeletonComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a skeleton pose asset has been constructed from a resource.
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="skeletonPoseComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a container asset has been constructed from a resource.
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="containerComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a texture asset has been constructed from a resource.
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="textureComplete", type="away3d.events.AssetEvent")]
	
	/**
	 * Dispatched when a texture projector asset has been constructed from a resource.
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="textureProjectorComplete", type="away3d.events.AssetEvent")]
	
	
	/**
	 * Dispatched when a material asset has been constructed from a resource.
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="materialComplete", type="away3d.events.AssetEvent")]
	
	
	/**
	 * Dispatched when a animator asset has been constructed from a resource.
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="animatorComplete", type="away3d.events.AssetEvent")]
	
	
	/**
	 * Dispatched when an animation set has been constructed from a group of animation state resources.
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="animationSetComplete", type="away3d.events.AssetEvent")]
	
	
	/**
	 * Dispatched when an animation state has been constructed from a group of animation node resources.
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="animationStateComplete", type="away3d.events.AssetEvent")]
	
	
	/**
	 * Dispatched when an animation node has been constructed from a resource.
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="animationNodeComplete", type="away3d.events.AssetEvent")]
	
	
	/**
	 * Dispatched when an animation state transition has been constructed from a group of animation node resources.
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="stateTransitionComplete", type="away3d.events.AssetEvent")]
	
	
	/**
	 * Dispatched when an light asset has been constructed from a resources.
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="lightComplete", type="away3d.events.AssetEvent")]
	
	
	/**
	 * Dispatched when an light picker asset has been constructed from a resources.
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="lightPickerComplete", type="away3d.events.AssetEvent")]
	
	
	/**
	 * Dispatched when an effect method asset has been constructed from a resources.
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="effectMethodComplete", type="away3d.events.AssetEvent")]
	
	
	/**
	 * Dispatched when an shadow map method asset has been constructed from a resources.
	 *
	 * @eventType away3d.events.AssetEvent
	 */
	//[Event(name="shadowMapMethodComplete", type="away3d.events.AssetEvent")]
	
	
	/**
	 * <code>ParserBase</code> provides an abstract base class for objects that convert blocks of data to data structures
	 * supported by Away3D.
	 *
	 * If used by <code>AssetLoader</code> to automatically determine the parser type, two static public methods should
	 * be implemented, with the following signatures:
	 *
	 * <code>public static function supportsType(extension : String) : Bool</code>
	 * Indicates whether or not a given file extension is supported by the parser.
	 *
	 * <code>public static function supportsData(data : *) : Bool</code>
	 * Tests whether a data block can be parsed by the parser.
	 *
	 * Furthermore, for any concrete subtype, the method <code>initHandle</code> should be overridden to immediately
	 * create the object that will contain the parsed data. This allows <code>ResourceManager</code> to return an object
	 * handle regardless of whether the object was loaded or not.
	 *
	 * @see away3d.loading.parsers.AssetLoader
	 * @see away3d.loading.ResourceManager
	 */
	class ParserBase extends EventDispatcher
	{
		/*arcane*/ public var _fileName:String;
		var _dataFormat:String;
		var _data:Dynamic;
		var _frameLimit:Float;
		var _lastFrameTime:Float;
		
		private function getTextData():String
		{
			return ParserUtil.toString(_data);
		}
		
		private function getByteData():ByteArray
		{
			return ParserUtil.toByteArray(_data);
		}
		
		var _dependencies:Array<ResourceDependency>;
		var _parsingPaused:Bool;
		var _parsingComplete:Bool;
		var _parsingFailure:Bool;
		var _timer:Timer;
		var _materialMode:UInt;
		
		/**
		 * Returned by <code>proceedParsing</code> to indicate no more parsing is needed.
		 */
		public static var PARSING_DONE:Bool = true;
		
		/**
		 * Returned by <code>proceedParsing</code> to indicate more parsing is needed, allowing asynchronous parsing.
		 */
		public static var MORE_TO_PARSE:Bool = false;

		
		/**
		 * Creates a new ParserBase object
		 * @param format The data format of the file data to be parsed. Can be either <code>ParserDataFormat.BINARY</code> or <code>ParserDataFormat.PLAIN_TEXT</code>, and should be provided by the concrete subtype.
		 *
		 * @see away3d.loading.parsers.ParserDataFormat
		 */
		public function new(format:String)
		{
			super();
			_materialMode = 0;
			_dataFormat = format;
			_dependencies = new Array<ResourceDependency>();
		}
		
		/**
		 * Validates a bitmapData loaded before assigning to a default BitmapMaterial
		 */
		public function isBitmapDataValid(bitmapData:BitmapData):Bool
		{
			var isValid:Bool = TextureUtils.isBitmapDataValid(bitmapData);
			if (!isValid)
				trace(">> Bitmap loaded is not having power of 2 dimensions or is higher than 2048");
			
			return isValid;
		}
		
		public function set_parsingFailure(b:Bool) : Bool
		{
			_parsingFailure = b;
			return b;
		}
		
		public var parsingFailure(get, set) : Bool;
		
		public function get_parsingFailure() : Bool
		{
			return _parsingFailure;
		}
		
		
		
		/**
		 * parsingPaused will be true, if the parser is paused 
		 * (e.g. it is waiting for dependencys to be loadet and parsed before it will continue)
		 */
		public var parsingPaused(get, null) : Bool;
		public function get_parsingPaused() : Bool
		{
			return _parsingPaused;
		}
		
		public var parsingComplete(get, null) : Bool;
		
		public function get_parsingComplete() : Bool
		{
			return _parsingComplete;
		}
		
		/**
		 * MaterialMode defines, if the Parser should create SinglePass or MultiPass Materials
		 * Options:
		 * 0 (Default / undefined) - All Parsers will create SinglePassMaterials, but the AWD2.1parser will create Materials as they are defined in the file
		 * 1 (Force SinglePass) - All Parsers create SinglePassMaterials
		 * 2 (Force MultiPass) - All Parsers will create MultiPassMaterials
		 * 
		 */
		public function set_materialMode(newMaterialMode:UInt) : UInt
		{
			_materialMode = newMaterialMode;
			return _materialMode;
		}
		
		public var materialMode(get, set) : UInt;
		
		public function get_materialMode() : UInt
		{
			return _materialMode;
		}
		
		/**
		 * The data format of the file data to be parsed. Can be either <code>ParserDataFormat.BINARY</code> or <code>ParserDataFormat.PLAIN_TEXT</code>.
		 */
		public var dataFormat(get, null) : String;
		public function get_dataFormat() : String
		{
			return _dataFormat;
		}
		
		/**
		 * Parse data (possibly containing bytearry, plain text or BitmapAsset) asynchronously, meaning that
		 * the parser will periodically stop parsing so that the AVM may proceed to the
		 * next frame.
		 *
		 * @param data The untyped data object in which the loaded data resides.
		 * @param frameLimit number of milliseconds of parsing allowed per frame. The
		 * actual time spent on a frame can exceed this number since time-checks can
		 * only be performed between logical sections of the parsing procedure.
		 */
		public function parseAsync(data:Dynamic, frameLimit:UInt = 30):Void
		{
			_data = data;
			startParsing(frameLimit);
		}
		
		/**
		 * A list of dependencies that need to be loaded and resolved for the object being parsed.
		 */
		public var dependencies(get, set) : Array<ResourceDependency>;
		public function get_dependencies() : Array<ResourceDependency>
		{
			return _dependencies;
		}
		public function set_dependencies(val : Array<ResourceDependency>) : Array<ResourceDependency>
		{
			_dependencies = val;
			return _dependencies;
		}
		
		/**
		 * Resolve a dependency when it's loaded. For example, a dependency containing an ImageResource would be assigned
		 * to a Mesh instance as a BitmapMaterial, a scene graph object would be added to its intended parent. The
		 * dependency should be a member of the dependencies property.
		 *
		 * @param resourceDependency The dependency to be resolved.
		 */
		public function resolveDependency(resourceDependency:ResourceDependency):Void
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * Resolve a dependency loading failure. Used by parser to eventually provide a default map
		 *
		 * @param resourceDependency The dependency to be resolved.
		 */
		public function resolveDependencyFailure(resourceDependency:ResourceDependency):Void
		{
			throw new AbstractMethodError();
		}
		
		/**
		 * Resolve a dependency name
		 *
		 * @param resourceDependency The dependency to be resolved.
		 */
		public function resolveDependencyName(resourceDependency:ResourceDependency, asset:IAsset):String
		{
			return asset.name;
		}
		
		/**
		 * After Dependencys has been loaded and parsed, continue to parse
		 */
		public function resumeParsingAfterDependencies():Void
		{
			_parsingPaused = false;
			if (_timer!=null)
				_timer.start();
		}
		
		/**
		 * Finalize a constructed asset. This function is executed for every asset that has been successfully constructed.
		 * It will dispatch a <code>AssetEvent.ASSET_COMPLETE</code> and another AssetEvent, that depents on the type of asset.
		 * 
		 * @param asset The asset to finalize
		 * @param name The name of the asset. The name will be applied to the asset
		 */
		private function finalizeAsset(asset:IAsset, name:String = null):Void
		{
			var type_event:String;
			var type_name:String;
			
			if (name != null)
				asset.name = name;
			
			switch (asset.assetType) {
				case AssetType.LIGHT_PICKER:
					type_name = 'lightPicker';
					type_event = AssetEvent.LIGHTPICKER_COMPLETE;
				case AssetType.LIGHT:
					type_name = 'light';
					type_event = AssetEvent.LIGHT_COMPLETE;
				case AssetType.ANIMATOR:
					type_name = 'animator';
					type_event = AssetEvent.ANIMATOR_COMPLETE;
				case AssetType.ANIMATION_SET:
					type_name = 'animationSet';
					type_event = AssetEvent.ANIMATION_SET_COMPLETE;
				case AssetType.ANIMATION_STATE:
					type_name = 'animationState';
					type_event = AssetEvent.ANIMATION_STATE_COMPLETE;
				case AssetType.ANIMATION_NODE:
					type_name = 'animationNode';
					type_event = AssetEvent.ANIMATION_NODE_COMPLETE;
				case AssetType.STATE_TRANSITION:
					type_name = 'stateTransition';
					type_event = AssetEvent.STATE_TRANSITION_COMPLETE;
				case AssetType.TEXTURE:
					type_name = 'texture';
					type_event = AssetEvent.TEXTURE_COMPLETE;
				case AssetType.TEXTURE_PROJECTOR:
					type_name = 'textureProjector';
					type_event = AssetEvent.TEXTURE_PROJECTOR_COMPLETE;
				case AssetType.CONTAINER:
					type_name = 'container';
					type_event = AssetEvent.CONTAINER_COMPLETE;
				case AssetType.GEOMETRY:
					type_name = 'geometry';
					type_event = AssetEvent.GEOMETRY_COMPLETE;
				case AssetType.MATERIAL:
					type_name = 'material';
					type_event = AssetEvent.MATERIAL_COMPLETE;
				case AssetType.MESH:
					type_name = 'mesh';
					type_event = AssetEvent.MESH_COMPLETE;
				case AssetType.SKELETON:
					type_name = 'skeleton';
					type_event = AssetEvent.SKELETON_COMPLETE;
				case AssetType.SKELETON_POSE:
					type_name = 'skelpose';
					type_event = AssetEvent.SKELETON_POSE_COMPLETE;
				case AssetType.ENTITY:
					type_name = 'entity';
					type_event = AssetEvent.ENTITY_COMPLETE;
				case AssetType.SKYBOX:
					type_name = 'skybox';
					type_event = AssetEvent.SKYBOX_COMPLETE;
				case AssetType.CAMERA:
					type_name = 'camera';
					type_event = AssetEvent.CAMERA_COMPLETE;
				case AssetType.SEGMENT_SET:
					type_name = 'segmentSet';
					type_event = AssetEvent.SEGMENT_SET_COMPLETE;
				case AssetType.EFFECTS_METHOD:
					type_name = 'effectsMethod';
					type_event = AssetEvent.EFFECTMETHOD_COMPLETE;
				case AssetType.SHADOW_MAP_METHOD:
					type_name = 'effectsMethod';
					type_event = AssetEvent.SHADOWMAPMETHOD_COMPLETE;
				default:
					throw new Error('Unhandled asset type ' + asset.assetType + '. Report as bug!');
			};
			
			// If the asset has no name, give it
			// a per-type default name.
			if (asset.name=="")
				asset.name = type_name;
			
			dispatchEvent(new AssetEvent(AssetEvent.ASSET_COMPLETE, asset));
			dispatchEvent(new AssetEvent(type_event, asset));
		}
		
		/**
		 * Parse the next block of data.
		 * @return Whether or not more data needs to be parsed. Can be <code>ParserBase.PARSING_DONE</code> or
		 * <code>ParserBase.MORE_TO_PARSE</code>.
		 */
		private function proceedParsing():Bool
		{
			throw new AbstractMethodError();
			return true;
		}
		
		/**
		 * Stops the parsing and dispatches a <code>ParserEvent.PARSE_ERROR</code> 
		 * 
		 * @param message The message to apply to the <code>ParserEvent.PARSE_ERROR</code> 
		 */
		private function dieWithError(message:String = 'Unknown parsing error'):Void
		{
			if (_timer!=null) {
				_timer.removeEventListener(TimerEvent.TIMER, onInterval);
				_timer.stop();
				_timer = null;
			}
			dispatchEvent(new ParserEvent(ParserEvent.PARSE_ERROR, message));
		}
		
		private function addDependency(id:String, req:URLRequest, retrieveAsRawData:Bool = false, data:Dynamic = null, suppressErrorEvents:Bool = false):Void
		{
			_dependencies.push(new ResourceDependency(id, req, data, this, retrieveAsRawData, suppressErrorEvents));
		}
		
		/**
		 * Pauses the parser, and dispatches a <code>ParserEvent.READY_FOR_DEPENDENCIES</code> 
		 */
		private function pauseAndRetrieveDependencies():Void
		{
			if (_timer!=null)
				_timer.stop();
			_parsingPaused = true;
			dispatchEvent(new ParserEvent(ParserEvent.READY_FOR_DEPENDENCIES));
		}
		
		/**
		 * Tests whether or not there is still time left for parsing within the maximum allowed time frame per session.
		 * @return True if there is still time left, false if the maximum allotted time was exceeded and parsing should be interrupted.
		 */
		private function hasTime():Bool
		{
			return ((Lib.getTimer() - _lastFrameTime) < _frameLimit);
		}
		
		/**
		 * Called when the parsing pause interval has passed and parsing can proceed.
		 */
		private function onInterval(event:TimerEvent = null):Void
		{
			_lastFrameTime = Lib.getTimer();
			if (proceedParsing() && !_parsingFailure)
				finishParsing();
		}
		
		/**
		 * Initializes the parsing of data.
		 * @param frameLimit The maximum duration of a parsing session.
		 */
		private function startParsing(frameLimit:UInt):Void
		{
			_frameLimit = frameLimit;
			_timer = new Timer(_frameLimit, 0);
			_timer.addEventListener(TimerEvent.TIMER, onInterval);
			_timer.start();
		}
		
		/**
		 * Finish parsing the data.
		 */
		private function finishParsing():Void
		{
			if (_timer!=null) {
				_timer.removeEventListener(TimerEvent.TIMER, onInterval);
				_timer.stop();
			}
			_timer = null;
			_parsingComplete = true;
			dispatchEvent(new ParserEvent(ParserEvent.PARSE_COMPLETE));
		}
	}


