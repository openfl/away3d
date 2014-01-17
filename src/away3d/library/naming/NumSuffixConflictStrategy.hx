package away3d.library.naming;


import away3d.library.assets.IAsset;
import haxe.ds.StringMap;

class NumSuffixConflictStrategy extends ConflictStrategyBase {
    private var _separator:String;
    private var _next_suffix:StringMap<Int>;

    public function new(separator:String = '.') {
        super();

        _separator = separator;
        _next_suffix = new StringMap<Int>();
    }


    override public function resolveConflict(changedAsset:IAsset, oldAsset:IAsset,
                                             assetsDictionary:StringMap<IAsset>, precedence:String):Void {
        var orig:String;
        var new_name:String;
        var base:String, suffix:Int;

        orig = changedAsset.name;
        if (orig.indexOf(_separator) >= 0) {
// Name has an ocurrence of the separator, so get base name and suffix,
// unless suffix is non-numerical, in which case revert to zero and
// use entire name as base
            base = orig.substring(0, orig.lastIndexOf(_separator));
            suffix = Std.parseInt(orig.substring(base.length - 1));
            if (Math.isNaN(suffix)) {
                base = orig;
                suffix = 0;
            }
        }
        else {
            base = orig;
            suffix = 0;
        }

        if (suffix == 0 && _next_suffix.exists(base))
            suffix = _next_suffix.get(base);

// Find the first suffixed name that does
// not collide with other names.
        do {
            suffix++;
            new_name = base + _separator + suffix;
        } while (assetsDictionary.exists(new_name));

        _next_suffix.set(base, suffix);

        updateNames(oldAsset.assetNamespace, new_name, oldAsset, changedAsset, assetsDictionary, precedence);
    }


    override public function create():ConflictStrategyBase {
        return new NumSuffixConflictStrategy(_separator);
    }
}

