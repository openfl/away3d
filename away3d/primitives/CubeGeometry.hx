package away3d.primitives;

import away3d.core.base.CompactSubGeometry;

import openfl.Vector;

/**
 * A Cube primitive mesh.
 */
class CubeGeometry extends PrimitiveBase
{
	/**
	 * The size of the cube along its X-axis.
	 */
	public var width(get, set):Float;
	/**
	 * The size of the cube along its Y-axis.
	 */
	public var height(get, set):Float;
	/**
	 * The size of the cube along its Z-axis.
	 */
	public var depth(get, set):Float;
	/**
	 * The type of uv mapping to use. When false, the entire image is mapped on each face.
	 * When true, a texture will be subdivided in a 3x2 grid, each used for a single face.
	 * Reading the tiles from left to right, top to bottom they represent the faces of the
	 * cube in the following order: bottom, top, back, left, front, right. This creates
	 * several shared edges (between the top, front, left and right faces) which simplifies
	 * texture painting.
	 */
	public var tile6(get, set):Bool;
	/**
	 * The number of sections the cube's width is divided into. Defaults to 1.
	 */
	public var sectionsW(get, set):Int;
	/**
	 * The number of sections the cube's height is divided into. Defaults to 1.
	 */
	public var sectionsH(get, set):Int;
	/**
	 * The number of sections the cube's depth is divided into. Defaults to 1.
	 */
	public var sectionsD(get, set):Int;
	@:noCompletion public var segmentsW(get, set):Int;
	@:noCompletion public var segmentsH(get, set):Int;
	@:noCompletion public var segmentsD(get, set):Int;
	
	private var _width:Float;
	private var _height:Float;
	private var _depth:Float;
	private var _tile6:Bool;
	
	private var _sectionsW:Int;
	private var _sectionsH:Int;
	private var _sectionsD:Int;
	
	/**
	 * Creates a new Cube object.
	 * @param width The size of the cube along its X-axis.
	 * @param height The size of the cube along its Y-axis.
	 * @param depth The size of the cube along its Z-axis.
	 * @param sectionsW The number of sections the cube's width is divided into.
	 * @param sectionsH The number of sections the cube's height is divided into.
	 * @param sectionsD The number of sections the cube's depth is divided into.
	 * @param tile6 The type of uv mapping to use. When true, a texture will be
	 * subdivided in a 2x3 grid, each used for a single face. When false, the
	 * entire image is mapped on each face.
	 */
	public function new(width:Float = 100, height:Float = 100, depth:Float = 100, sectionsW:Int = 1, sectionsH:Int = 1, sectionsD:Int = 1, tile6:Bool = true)
	{
		super();
		
		_width = width;
		_height = height;
		_depth = depth;
		_sectionsW = sectionsW;
		_sectionsH = sectionsH;
		_sectionsD = sectionsD;
		_tile6 = tile6;
	}
	
	private function get_width():Float
	{
		return _width;
	}
	
	private function set_width(value:Float):Float
	{
		_width = value;
		invalidateGeometry();
		return value;
	}
	
	private function get_height():Float
	{
		return _height;
	}
	
	private function set_height(value:Float):Float
	{
		_height = value;
		invalidateGeometry();
		return value;
	}
	
	private function get_depth():Float
	{
		return _depth;
	}
	
	private function set_depth(value:Float):Float
	{
		_depth = value;
		invalidateGeometry();
		return value;
	}
	
	private function get_tile6():Bool
	{
		return _tile6;
	}
	
	private function set_tile6(value:Bool):Bool
	{
		_tile6 = value;
		invalidateUVs();
		return value;
	}
	
	private function get_sectionsW():Int
	{
		return _sectionsW;
	}
	
	private function set_sectionsW(value:Int):Int
	{
		_sectionsW = value;
		invalidateGeometry();
		invalidateUVs();
		return value;
	}
	
	private function get_segmentsW():Int
	{
		return sectionsW;
	}
	
	private function set_segmentsW(value:Int):Int
	{
		return sectionsW = value;
	}
	
	private function get_sectionsH():Int
	{
		return _sectionsH;
	}
	
	private function set_sectionsH(value:Int):Int
	{
		_sectionsH = value;
		invalidateGeometry();
		invalidateUVs();
		return value;
	}
	
	private function get_segmentsH():Int
	{
		return sectionsH;
	}
	
	private function set_segmentsH(value:Int):Int
	{
		return sectionsH = value;
	}
	
	private function get_sectionsD():Int
	{
		return _sectionsD;
	}
	
	private function set_sectionsD(value:Int):Int
	{
		_sectionsD = value;
		invalidateGeometry();
		invalidateUVs();
		return value;
	}
	
	private function get_segmentsD():Int
	{
		return sectionsD;
	}
	
	private function set_segmentsD(value:Int):Int
	{
		return sectionsD = value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function buildGeometry(target:CompactSubGeometry):Void
	{
		var data:Vector<Float>;
		var indices:Vector<UInt>;
		
		var tl:Int = 0, tr:Int = 0, bl:Int = 0, br:Int = 0;
		var i:Int = 0, j:Int = 0, inc:Int = 0;
		
		var vidx:Int = 0, fidx:Int = 0;	// indices
		var hw:Float = 0, hh:Float = 0, hd:Float = 0; // halves
		var dw:Float = 0, dh:Float = 0, dd:Float = 0; // deltas
		
		var outer_pos:Float;
		
		var numVerts:Int = ((_sectionsW + 1)*(_sectionsH + 1) +
			(_sectionsW + 1)*(_sectionsD + 1) +
			(_sectionsH + 1)*(_sectionsD + 1))*2;
		
		var stride:Int = target.vertexStride;
		var skip:Int = stride - 9;
		
		if (numVerts == target.numVertices) {
			data = target.vertexData;
			indices = target.indexData;
			if (indices == null)
				indices = new Vector<UInt>((_sectionsW*_sectionsH + _sectionsW*_sectionsD + _sectionsH*_sectionsD)*12, true);
		} else {
			data = new Vector<Float>(numVerts*stride, true);
			indices = new Vector<UInt>((_sectionsW*_sectionsH + _sectionsW*_sectionsD + _sectionsH*_sectionsD)*12, true);
			invalidateUVs();
		}
		
		// Indices
		vidx = target.vertexOffset;
		fidx = 0;
		
		// half cube dimensions
		hw = _width/2;
		hh = _height/2;
		hd = _depth/2;
		
		// Segment dimensions
		dw = _width/_sectionsW;
		dh = _height/_sectionsH;
		dd = _depth/_sectionsD;
		
		for (i in 0..._sectionsW + 1) {
			outer_pos = -hw + i*dw;
			
			for (j in 0..._sectionsH + 1) {
				// front
				data[vidx++] = outer_pos;
				data[vidx++] = -hh + j*dh;
				data[vidx++] = -hd;
				data[vidx++] = 0;
				data[vidx++] = 0;
				data[vidx++] = -1;
				data[vidx++] = 1;
				data[vidx++] = 0;
				data[vidx++] = 0;
				vidx += skip;
				
				// back
				data[vidx++] = outer_pos;
				data[vidx++] = -hh + j*dh;
				data[vidx++] = hd;
				data[vidx++] = 0;
				data[vidx++] = 0;
				data[vidx++] = 1;
				data[vidx++] = -1;
				data[vidx++] = 0;
				data[vidx++] = 0;
				vidx += skip;
				
				if (i > 0 && j > 0) {
					tl = Std.int(2*((i - 1)*(_sectionsH + 1) + (j - 1)));
					tr = Std.int(2*(i*(_sectionsH + 1) + (j - 1)));
					bl = tl + 2;
					br = tr + 2;
					
					indices[fidx++] = tl;
					indices[fidx++] = bl;
					indices[fidx++] = br;
					indices[fidx++] = tl;
					indices[fidx++] = br;
					indices[fidx++] = tr;
					indices[fidx++] = tr + 1;
					indices[fidx++] = br + 1;
					indices[fidx++] = bl + 1;
					indices[fidx++] = tr + 1;
					indices[fidx++] = bl + 1;
					indices[fidx++] = tl + 1;
				}
			}
		}
		
		inc += Std.int(2*(_sectionsW + 1)*(_sectionsH + 1));
		
		for (i in 0..._sectionsW + 1) {
			outer_pos = -hw + i*dw;
			
			for (j in 0..._sectionsD + 1) {
				// top
				data[vidx++] = outer_pos;
				data[vidx++] = hh;
				data[vidx++] = -hd + j*dd;
				data[vidx++] = 0;
				data[vidx++] = 1;
				data[vidx++] = 0;
				data[vidx++] = 1;
				data[vidx++] = 0;
				data[vidx++] = 0;
				vidx += skip;
				
				// bottom
				data[vidx++] = outer_pos;
				data[vidx++] = -hh;
				data[vidx++] = -hd + j*dd;
				data[vidx++] = 0;
				data[vidx++] = -1;
				data[vidx++] = 0;
				data[vidx++] = 1;
				data[vidx++] = 0;
				data[vidx++] = 0;
				vidx += skip;
				
				if (i > 0 && j > 0) {
					
					tl = Std.int(inc + 2*((i - 1)*(_sectionsD + 1) + (j - 1)));
					tr = Std.int(inc + 2*(i*(_sectionsD + 1) + (j - 1)));
					bl = tl + 2;
					br = tr + 2;
					
					indices[fidx++] = tl;
					indices[fidx++] = bl;
					indices[fidx++] = br;
					indices[fidx++] = tl;
					indices[fidx++] = br;
					indices[fidx++] = tr;
					indices[fidx++] = tr + 1;
					indices[fidx++] = br + 1;
					indices[fidx++] = bl + 1;
					indices[fidx++] = tr + 1;
					indices[fidx++] = bl + 1;
					indices[fidx++] = tl + 1;
				}
			}
		}
		
		inc += Std.int(2*(_sectionsW + 1)*(_sectionsD + 1));
		
		for (i in 0..._sectionsD + 1) {
			outer_pos = hd - i*dd;
			
			for (j in 0..._sectionsH + 1) {
				// left
				data[vidx++] = -hw;
				data[vidx++] = -hh + j*dh;
				data[vidx++] = outer_pos;
				data[vidx++] = -1;
				data[vidx++] = 0;
				data[vidx++] = 0;
				data[vidx++] = 0;
				data[vidx++] = 0;
				data[vidx++] = -1;
				vidx += skip;
				
				// right
				data[vidx++] = hw;
				data[vidx++] = -hh + j*dh;
				data[vidx++] = outer_pos;
				data[vidx++] = 1;
				data[vidx++] = 0;
				data[vidx++] = 0;
				data[vidx++] = 0;
				data[vidx++] = 0;
				data[vidx++] = 1;
				vidx += skip;
				
				if (i > 0 && j > 0) {
					tl = Std.int(inc + 2*((i - 1)*(_sectionsH + 1) + (j - 1)));
					tr = Std.int(inc + 2*(i*(_sectionsH + 1) + (j - 1)));
					bl = tl + 2;
					br = tr + 2;
					
					indices[fidx++] = tl;
					indices[fidx++] = bl;
					indices[fidx++] = br;
					indices[fidx++] = tl;
					indices[fidx++] = br;
					indices[fidx++] = tr;
					indices[fidx++] = tr + 1;
					indices[fidx++] = br + 1;
					indices[fidx++] = bl + 1;
					indices[fidx++] = tr + 1;
					indices[fidx++] = bl + 1;
					indices[fidx++] = tl + 1;
				}
			}
		}
		
		target.updateData(data);
		target.updateIndexData(indices);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function buildUVs(target:CompactSubGeometry):Void
	{
		var i:Int = 0, j:Int = 0, uidx:Int;
		var data:Vector<Float>;
		
		var u_tile_dim:Float, v_tile_dim:Float;
		var u_tile_step:Float, v_tile_step:Float;
		var tl0u:Float, tl0v:Float;
		var tl1u:Float, tl1v:Float;
		var du:Float, dv:Float;
		var stride:Int = target.UVStride;
		var numUvs:Int = Std.int(((_sectionsW + 1)*(_sectionsH + 1) +
			(_sectionsW + 1)*(_sectionsD + 1) +
			(_sectionsH + 1)*(_sectionsD + 1))*2*stride);
		var skip:Int = stride - 2;
		
		if (target.UVData != null && numUvs == target.UVData.length)
			data = target.UVData;
		else {
			data = new Vector<Float>(numUvs, true);
			invalidateGeometry();
		}
		
		if (_tile6) {
			u_tile_dim = u_tile_step = 1/3;
			v_tile_dim = v_tile_step = 1/2;
		} else {
			u_tile_dim = v_tile_dim = 1;
			u_tile_step = v_tile_step = 0;
		}
		
		// Create planes two and two, the same way that they were
		// constructed in the buildGeometry() function. First calculate
		// the top-left UV coordinate for both planes, and then loop
		// over the points, calculating the UVs from these numbers.
		
		// When tile6 is true, the layout is as follows:
		//       .-----.-----.-----. (1,1)
		//       | Bot |  T  | Bak |
		//       |-----+-----+-----|
		//       |  L  |  F  |  R  |
		// (0,0)'-----'-----'-----'
		
		uidx = target.UVOffset;
		
		// FRONT / BACK
		tl0u = 1*u_tile_step;
		tl0v = 1*v_tile_step;
		tl1u = 2*u_tile_step;
		tl1v = 0*v_tile_step;
		du = u_tile_dim/_sectionsW;
		dv = v_tile_dim/_sectionsH;
		for (i in 0..._sectionsW + 1) {
			for (j in 0..._sectionsH + 1) {
				data[uidx++] = ( tl0u + i*du )*target.scaleU;
				data[uidx++] = ( tl0v + (v_tile_dim - j*dv))*target.scaleV;
				uidx += skip;
				data[uidx++] = ( tl1u + (u_tile_dim - i*du))*target.scaleU;
				data[uidx++] = ( tl1v + (v_tile_dim - j*dv))*target.scaleV;
				uidx += skip;
			}
		}
		
		// TOP / BOTTOM
		tl0u = 1*u_tile_step;
		tl0v = 0*v_tile_step;
		tl1u = 0*u_tile_step;
		tl1v = 0*v_tile_step;
		du = u_tile_dim/_sectionsW;
		dv = v_tile_dim/_sectionsD;
		for (i in 0..._sectionsW + 1) {
			for (j in 0..._sectionsD + 1) {
				data[uidx++] = ( tl0u + i*du)*target.scaleU;
				data[uidx++] = ( tl0v + (v_tile_dim - j*dv))*target.scaleV;
				uidx += skip;
				data[uidx++] = ( tl1u + i*du)*target.scaleU;
				data[uidx++] = ( tl1v + j*dv)*target.scaleV;
				uidx += skip;
			}
		}
		
		// LEFT / RIGHT
		tl0u = 0*u_tile_step;
		tl0v = 1*v_tile_step;
		tl1u = 2*u_tile_step;
		tl1v = 1*v_tile_step;
		du = u_tile_dim/_sectionsD;
		dv = v_tile_dim/_sectionsH;
		for (i in 0..._sectionsD + 1) {
			for (j in 0..._sectionsH + 1) {
				data[uidx++] = ( tl0u + i*du)*target.scaleU;
				data[uidx++] = ( tl0v + (v_tile_dim - j*dv))*target.scaleV;
				uidx += skip;
				data[uidx++] = ( tl1u + (u_tile_dim - i*du))*target.scaleU;
				data[uidx++] = ( tl1v + (v_tile_dim - j*dv))*target.scaleV;
				uidx += skip;
			}
		}
		
		target.updateData(data);
	}
}