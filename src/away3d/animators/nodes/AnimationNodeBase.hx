package away3d.animators.nodes;

	import away3d.library.assets.*;
	
	/**
	 * Provides an abstract base class for nodes in an animation blend tree.
	 */
	class AnimationNodeBase extends NamedAssetBase implements IAsset
	{
		var _stateClass:String;
		
		/**
		 * Creates a new <code>AnimationNodeBase</code> object.
		 */
		public function new()
		{
			super();
		}

		public var stateClass(get, null) : String;
		public function get_stateClass() : String
		{
			return _stateClass;
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function dispose():Void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public var assetType(get, null) : String;
		public function get_assetType() : String
		{
			return AssetType.ANIMATION_NODE;
		}
	}

