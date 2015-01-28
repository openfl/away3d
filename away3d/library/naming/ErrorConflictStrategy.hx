package away3d.library.naming;

import openfl.errors.Error;
import away3d.library.assets.IAsset;

class ErrorConflictStrategy extends ConflictStrategyBase {

    public function new() {
        super();
    }

    override public function resolveConflict(changedAsset:IAsset, oldAsset:IAsset, assetsDictionary:Dynamic, precedence:String):Void {
        throw new Error("Asset name collision while Asset3DLibrary.namingStrategy set to Asset3DLibrary.THROW_ERROR. Asset path: " + changedAsset.assetFullPath);
    }

    override public function create():ConflictStrategyBase {
        return new ErrorConflictStrategy();
    }
}

