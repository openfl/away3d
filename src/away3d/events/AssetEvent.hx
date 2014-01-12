package away3d.events;

	import away3d.library.assets.IAsset;
	
	import flash.events.Event;
	
	/**
	 * Dispatched whenever a ressource (asset) is parsed and created completly.
	 */
	class AssetEvent extends Event
	{
		public static var ASSET_COMPLETE:String = "assetComplete";
		public static var ENTITY_COMPLETE:String = "entityComplete";
		public static var SKYBOX_COMPLETE:String = "skyboxComplete";
		public static var CAMERA_COMPLETE:String = "cameraComplete";
		public static var MESH_COMPLETE:String = "meshComplete";
		public static var GEOMETRY_COMPLETE:String = "geometryComplete";
		public static var SKELETON_COMPLETE:String = "skeletonComplete";
		public static var SKELETON_POSE_COMPLETE:String = "skeletonPoseComplete";
		public static var CONTAINER_COMPLETE:String = "containerComplete";
		public static var TEXTURE_COMPLETE:String = "textureComplete";
		public static var TEXTURE_PROJECTOR_COMPLETE:String = "textureProjectorComplete";
		public static var MATERIAL_COMPLETE:String = "materialComplete";
		public static var ANIMATOR_COMPLETE:String = "animatorComplete";
		public static var ANIMATION_SET_COMPLETE:String = "animationSetComplete";
		public static var ANIMATION_STATE_COMPLETE:String = "animationStateComplete";
		public static var ANIMATION_NODE_COMPLETE:String = "animationNodeComplete";
		public static var STATE_TRANSITION_COMPLETE:String = "stateTransitionComplete";
		public static var SEGMENT_SET_COMPLETE:String = "segmentSetComplete";
		public static var LIGHT_COMPLETE:String = "lightComplete";
		public static var LIGHTPICKER_COMPLETE:String = "lightPickerComplete";
		public static var EFFECTMETHOD_COMPLETE:String = "effectMethodComplete";
		public static var SHADOWMAPMETHOD_COMPLETE:String = "shadowMapMethodComplete";
		
		public static var ASSET_RENAME:String = 'assetRename';
		public static var ASSET_CONFLICT_RESOLVED:String = 'assetConflictResolved';
		
		public static var TEXTURE_SIZE_ERROR:String = 'textureSizeError';
		
		var _asset:IAsset;
		var _prevName:String;
		
		public function new(type:String, asset:IAsset = null, prevName:String = "")
		{
			super(type);
			
			_asset = asset;
			_prevName = (prevName!="" ? prevName : (_asset!=null ? _asset.name : ""));
		}
		
		public var asset(get, null) : IAsset;
		
		public function get_asset() : IAsset
		{
			return _asset;
		}
		
		public var assetPrevName(get, null) : String;
		
		public function get_assetPrevName() : String
		{
			return _prevName;
		}
		
		public override function clone():Event
		{
			return new AssetEvent(type, asset, assetPrevName);
		}
	}

