package away3d.primitives.data;


import away3d.entities.SegmentSet;
import flash.geom.Vector3D;

class Segment {
    public var start(get_start, set_start):Vector3D;
    public var end(get_end, set_end):Vector3D;
    public var thickness(get_thickness, set_thickness):Float;
    public var startColor(get_startColor, set_startColor):Int;
    public var endColor(get_endColor, set_endColor):Int;
    public var index(get_index, set_index):Int;
    public var subSetIndex(get_subSetIndex, set_subSetIndex):Int;
    public var segmentsBase(never, set_segmentsBase):SegmentSet;

    public var _segmentsBase:SegmentSet;
    public var _thickness:Float;
    public var _start:Vector3D;
    public var _end:Vector3D;
    public var _startR:Float;
    public var _startG:Float;
    public var _startB:Float;
    public var _endR:Float;
    public var _endG:Float;
    public var _endB:Float;
    public var _index:Int;
    public var _subSetIndex:Int;
    public var _startColor:Int;
    public var _endColor:Int;

    public function new(start:Vector3D, end:Vector3D, anchor:Vector3D, colorStart:Int = 0x333333, colorEnd:Int = 0x333333, thickness:Float = 1) {
        _index = -1;
        _subSetIndex = -1;
// TODO: not yet used: for CurveSegment support
        anchor = null;
        _thickness = thickness * .5;
// TODO: add support for curve using anchor v1
// Prefer removing v1 from this, and make Curve a separate class extending Segment? (- David)
        _start = start;
        _end = end;
        startColor = colorStart;
        endColor = colorEnd;
    }

    public function updateSegment(start:Vector3D, end:Vector3D, anchor:Vector3D, colorStart:Int = 0x333333, colorEnd:Int = 0x333333, thickness:Float = 1):Void {
// TODO: not yet used: for CurveSegment support
        anchor = null;
        _start = start;
        _end = end;
        if (_startColor != colorStart) startColor = colorStart;
        if (_endColor != colorEnd) endColor = colorEnd;
        _thickness = thickness * .5;
        update();
    }

/**
	 * Defines the starting vertex.
	 */

    public function get_start():Vector3D {
        return _start;
    }

    public function set_start(value:Vector3D):Vector3D {
        _start = value;
        update();
        return value;
    }

/**
	 * Defines the ending vertex.
	 */

    public function get_end():Vector3D {
        return _end;
    }

    public function set_end(value:Vector3D):Vector3D {
        _end = value;
        update();
        return value;
    }

/**
	 * Defines the ending vertex.
	 */

    public function get_thickness():Float {
        return _thickness * 2;
    }

    public function set_thickness(value:Float):Float {
        _thickness = value * .5;
        update();
        return value;
    }

/**
	 * Defines the startColor
	 */

    public function get_startColor():Int {
        return _startColor;
    }

    public function set_startColor(color:Int):Int {
        _startR = ((color >> 16) & 0xff) / 255;
        _startG = ((color >> 8) & 0xff) / 255;
        _startB = (color & 0xff) / 255;
        _startColor = color;
        update();
        return color;
    }

/**
	 * Defines the endColor
	 */

    public function get_endColor():Int {
        return _endColor;
    }

    public function set_endColor(color:Int):Int {
        _endR = ((color >> 16) & 0xff) / 255;
        _endG = ((color >> 8) & 0xff) / 255;
        _endB = (color & 0xff) / 255;
        _endColor = color;
        update();
        return color;
    }

    public function dispose():Void {
        _start = null;
        _end = null;
    }

    private function get_index():Int {
        return _index;
    }

    private function set_index(ind:Int):Int {
        _index = ind;
        return ind;
    }

    private function get_subSetIndex():Int {
        return _subSetIndex;
    }

    private function set_subSetIndex(ind:Int):Int {
        _subSetIndex = ind;
        return ind;
    }

    private function set_segmentsBase(segBase:SegmentSet):SegmentSet {
        _segmentsBase = segBase;
        return segBase;
    }

    private function update():Void {
        if (_segmentsBase == null) return;
        _segmentsBase.updateSegment(this);
    }

}

