package away3d.errors;
import flash.errors.Error;
class DeprecationError extends Error {
    public var since(get_since, never):String;
    public var source(get_source, never):String;
    public var info(get_info, never):String;

    private var _since:String;
    private var _source:String;
    private var _info:String;

    public function new(source:String, since:String, info:String) {
        super(source + " has been marked as deprecated since version " + since + " and has been slated for removal. " + info);
        _since = since;
        _source = source;
        _info = info;
    }

    public function get_since():String {
        return _since;
    }

    public function get_source():String {
        return _source;
    }

    public function get_info():String {
        return _info;
    }

}

