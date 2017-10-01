package away3d.library.naming;

import away3d.library.assets.IAsset;

class IgnoreConflictStrategy extends ConflictStrategyBase
{
	public function new()
	{
		super();
	}
	
	override public function resolveConflict(changedAsset:IAsset, oldAsset:IAsset, assetsDictionary:Dynamic, precedence:String):Void
	{
		// Do nothing, ignore the fact that there is a conflict.
		return;
	}
	
	override public function create():ConflictStrategyBase
	{
		return new IgnoreConflictStrategy();
	}
}