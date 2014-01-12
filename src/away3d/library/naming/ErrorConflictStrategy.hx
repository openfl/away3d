package away3d.library.naming;

	import away3d.library.assets.IAsset;

	import haxe.ds.StringMap;

	import flash.errors.Error;
	
	class ErrorConflictStrategy extends ConflictStrategyBase
	{
		public function new()
		{
			super();
		}
		
		public override function resolveConflict(changedAsset:IAsset, oldAsset:IAsset, assetsDictionary:StringMap<IAsset>, precedence:String):Void
		{
			throw new Error('Asset name collision while AssetLibrary.namingStrategy set to AssetLibrary.THROW_ERROR. Asset path: ' + changedAsset.assetFullPath);
		}
		
		public override function create():ConflictStrategyBase
		{
			return new ErrorConflictStrategy();
		}
	}

