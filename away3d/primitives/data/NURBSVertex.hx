package away3d.primitives.data;

import away3d.core.base.data.Vertex;

/**
 * A nurbvertex that simply extends vertex with a w weight property.
 * Properties x, y, z and w represent a 3d point in space with nurb weighting.
 */
class NURBSVertex extends Vertex
{
	public var w(get, set):Float;
	
	private var _w:Float;
	
	private function get_w():Float {
		return _w;
	}
	
	private function set_w(w:Float):Float
	{
		_w = w;
		return w;
	}
	
	/**
	 * Creates a new <code>Vertex</code> object.
	 *
	 * @param    x    [optional]    The local x position of the vertex. Defaults to 0.
	 * @param    y    [optional]    The local y position of the vertex. Defaults to 0.
	 * @param    z    [optional]    The local z position of the vertex. Defaults to 0.
	 * @param    w    [optional]    The local w weight of the vertex. Defaults to 1.
	 */
	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 1)
	{
		_w = w;
		super(x, y, z);
	}
}