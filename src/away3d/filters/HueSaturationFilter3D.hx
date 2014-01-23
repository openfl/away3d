package away3d.filters;

import away3d.filters.tasks.Filter3DHueSaturationTask;

class HueSaturationFilter3D extends Filter3DBase {
    public var saturation(get_saturation, set_saturation):Float;
    public var r(get_r, set_r):Float;
    public var b(get_b, set_b):Float;
    public var g(get_g, set_g):Float;

    private var _hslTask:Filter3DHueSaturationTask;

    public function new(saturation:Float = 1, r:Float = 1, g:Float = 1, b:Float = 1) {
        super();
        _hslTask = new Filter3DHueSaturationTask();
        this.saturation = saturation;
        this.r = r;
        this.g = g;
        this.b = b;
        addTask(_hslTask);
    }

    public function get_saturation():Float {
        return _hslTask.saturation;
    }

    public function set_saturation(value:Float):Float {
        if (_hslTask.saturation == value) return value;
        _hslTask.saturation = value;
        return value;
    }

    public function get_r():Float {
        return _hslTask.r;
    }

    public function set_r(value:Float):Float {
        if (_hslTask.r == value) return value;
        _hslTask.r = value;
        return value;
    }

    public function get_b():Float {
        return _hslTask.b;
    }

    public function set_b(value:Float):Float {
        if (_hslTask.b == value) return value;
        _hslTask.b = value;
        return value;
    }

    public function get_g():Float {
        return _hslTask.g;
    }

    public function set_g(value:Float):Float {
        if (_hslTask.g == value) return value;
        _hslTask.g = value;
        return value;
    }

}

