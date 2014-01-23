/**
 * Vertex value object.
 */
package away3d.core.base.data;

class Vertex {
    public var index(get_index, set_index):Int;
    public var x(get_x, set_x):Float;
    public var y(get_y, set_y):Float;
    public var z(get_z, set_z):Float;

    private var _x:Float;
    private var _y:Float;
    private var _z:Float;
    private var _index:Int;
/**
	 * Creates a new <code>Vertex</code> value object.
	 *
	 * @param    x            [optional]    The x value. Defaults to 0.
	 * @param    y            [optional]    The y value. Defaults to 0.
	 * @param    z            [optional]    The z value. Defaults to 0.
	 * @param    index        [optional]    The index value. Defaults is NaN.
	 */

    public function new(x:Float = 0, y:Float = 0, z:Float = 0, index:Int = 0) {
        _x = x;
        _y = y;
        _z = z;
        _index = index;
    }

/**
	 * To define/store the index of value object
	 * @param    ind        The index
	 */

    public function set_index(ind:Int):Int {
        _index = ind;
        return ind;
    }

    public function get_index():Int {
        return _index;
    }

/**
	 * To define/store the x value of the value object
	 * @param    value        The x value
	 */

    public function get_x():Float {
        return _x;
    }

    public function set_x(value:Float):Float {
        _x = value;
        return value;
    }

/**
	 * To define/store the y value of the value object
	 * @param    value        The y value
	 */

    public function get_y():Float {
        return _y;
    }

    public function set_y(value:Float):Float {
        _y = value;
        return value;
    }

/**
	 * To define/store the z value of the value object
	 * @param    value        The z value
	 */

    public function get_z():Float {
        return _z;
    }

    public function set_z(value:Float):Float {
        _z = value;
        return value;
    }

/**
	 * returns a new Vertex value Object
	 */

    public function clone():Vertex {
        return new Vertex(_x, _y, _z);
    }

/**
	 * returns the value object as a string for trace/debug purpose
	 */

    public function toString():String {
        return _x + "," + _y + "," + _z;
    }

}

