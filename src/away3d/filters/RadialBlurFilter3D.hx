package away3d.filters;

import away3d.filters.tasks.Filter3DRadialBlurTask;

class RadialBlurFilter3D extends Filter3DBase {
    public var intensity(get_intensity, set_intensity):Float;
    public var glowGamma(get_glowGamma, set_glowGamma):Float;
    public var blurStart(get_blurStart, set_blurStart):Float;
    public var blurWidth(get_blurWidth, set_blurWidth):Float;
    public var cx(get_cx, set_cx):Float;
    public var cy(get_cy, set_cy):Float;

    private var _blurTask:Filter3DRadialBlurTask;

    public function new(intensity:Float = 8.0, glowGamma:Float = 1.6, blurStart:Float = 1.0, blurWidth:Float = -0.3, cx:Float = 0.5, cy:Float = 0.5) {
        super();
        _blurTask = new Filter3DRadialBlurTask(intensity, glowGamma, blurStart, blurWidth, cx, cy);
        addTask(_blurTask);
    }

    public function get_intensity():Float {
        return _blurTask.intensity;
    }

    public function set_intensity(intensity:Float):Float {
        _blurTask.intensity = intensity;
        return intensity;
    }

    public function get_glowGamma():Float {
        return _blurTask.glowGamma;
    }

    public function set_glowGamma(glowGamma:Float):Float {
        _blurTask.glowGamma = glowGamma;
        return glowGamma;
    }

    public function get_blurStart():Float {
        return _blurTask.blurStart;
    }

    public function set_blurStart(blurStart:Float):Float {
        _blurTask.blurStart = blurStart;
        return blurStart;
    }

    public function get_blurWidth():Float {
        return _blurTask.blurWidth;
    }

    public function set_blurWidth(blurWidth:Float):Float {
        _blurTask.blurWidth = blurWidth;
        return blurWidth;
    }

    public function get_cx():Float {
        return _blurTask.cx;
    }

    public function set_cx(cx:Float):Float {
        _blurTask.cx = cx;
        return cx;
    }

    public function get_cy():Float {
        return _blurTask.cy;
    }

    public function set_cy(cy:Float):Float {
        _blurTask.cy = cy;
        return cy;
    }

}

