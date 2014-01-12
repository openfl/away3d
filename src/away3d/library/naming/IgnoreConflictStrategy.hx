package away3d.library.naming;

	import away3d.library.assets.IAsset;

	import haxe.ds.StringMap;
	
	class IgnoreConflictStrategy extends ConflictStrategyBase
	{
		public function new()
		{
			super();
		}
		
		public override function resolveConflict(changedAsset:IAsset, oldAsset:IAsset, assetsDictionary:StringMap<IAsset>, precedence:String):Void
		{
			// Do nothing, ignore the fact that there is a conflict.
			return;
		}
		
		public override function create():ConflictStrategyBase
		{
			return new IgnoreConflictStrategy();
		}
	}

