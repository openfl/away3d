package away3d.audio.drivers;

import flash.geom.Vector3D;
import flash.media.Sound;
import flash.events.EventDispatcher;

class AbstractSound3DDriver extends EventDispatcher {
    public var sourceSound(get_sourceSound, set_sourceSound):Sound;
    public var volume(get_volume, set_volume):Float;
    public var scale(get_scale, set_scale):Float;
    public var mute(get_mute, set_mute):Bool;

    private var _ref_v:Vector3D;
    private var _src:Sound;
    private var _volume:Float;
    private var _scale:Float;
    private var _mute:Bool;
    private var _paused:Bool;
    private var _playing:Bool;

    public function new() {
        _volume = 1;
        _scale = 1000;
        _playing = false;
        super();
    }

    public function get_sourceSound():Sound {
        return _src;
    }

    public function set_sourceSound(val:Sound):Sound {
        if (_src == val) return val;
        _src = val;
        return val;
    }

    public function get_volume():Float {
        return _volume;
    }

    public function set_volume(val:Float):Float {
        _volume = val;
        return val;
    }

    public function get_scale():Float {
        return _scale;
    }

    public function set_scale(val:Float):Float {
        _scale = val;
        return val;
    }

    public function get_mute():Bool {
        return _mute;
    }

    public function set_mute(val:Bool):Bool {
        if (_mute == val) return val;
        _mute = val;
        return val;
    }

    public function updateReferenceVector(v:Vector3D):Void {
        this._ref_v = v;
    }

}

