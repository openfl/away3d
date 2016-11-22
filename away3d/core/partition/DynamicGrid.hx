package away3d.core.partition;

import away3d.bounds.BoundingVolumeBase;
import away3d.entities.Entity;

import openfl.errors.Error;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * DynamicGrid is used by certain partitioning systems that require vislists for regions of dynamic data.
 */
class DynamicGrid
{
	public var numCellsX(get, never):Int;
	public var numCellsY(get, never):Int;
	public var numCellsZ(get, never):Int;
	public var showDebugBounds(get, set):Bool;
	
	private var _minX:Float;
	private var _minY:Float;
	private var _minZ:Float;
	private var _leaves:Vector<InvertedOctreeNode>;
	private var _numCellsX:Int;
	private var _numCellsY:Int;
	private var _numCellsZ:Int;
	private var _cellWidth:Float;
	private var _cellHeight:Float;
	private var _cellDepth:Float;
	private var _showDebugBounds:Bool;
	
	public function new(minBounds:Vector3D, maxBounds:Vector3D, numCellsX:Int, numCellsY:Int, numCellsZ:Int)
	{
		_numCellsX = numCellsX;
		_numCellsY = numCellsY;
		_numCellsZ = numCellsZ;
		_minX = minBounds.x;
		_minY = minBounds.y;
		_minZ = minBounds.z;
		_cellWidth = (maxBounds.x - _minX)/numCellsX;
		_cellHeight = (maxBounds.y - _minY)/numCellsY;
		_cellDepth = (maxBounds.z - _minZ)/numCellsZ;
		_leaves = createLevel(numCellsX, numCellsY, numCellsZ, _cellWidth, _cellHeight, _cellDepth);
	}
	
	private function get_numCellsX():Int
	{
		return _numCellsX;
	}
	
	private function get_numCellsY():Int
	{
		return _numCellsY;
	}
	
	private function get_numCellsZ():Int
	{
		return _numCellsZ;
	}
	
	public function getCellAt(x:Int, y:Int, z:Int):InvertedOctreeNode
	{
		if (x >= _numCellsX || y >= _numCellsY || z >= _numCellsZ)
			throw new Error("Index out of bounds!");
		
		return _leaves[x + (y + z*_numCellsY)*_numCellsX];
	}
	
	private function createLevel(numCellsX:Int, numCellsY:Int, numCellsZ:Int, cellWidth:Float, cellHeight:Float, cellDepth:Float):Vector<InvertedOctreeNode>
	{
		var nodes:Vector<InvertedOctreeNode> = new Vector<InvertedOctreeNode>(numCellsX * numCellsY * numCellsZ);
		var parents:Vector<InvertedOctreeNode> = null;
		var node:InvertedOctreeNode;
		var i:Int = 0;
		var minX:Float, minY:Float, minZ:Float;
		var numParentsX:Int = 0, numParentsY:Int = 0, numParentsZ:Int = 0;
		
		if (numCellsX != 1 || numCellsY != 1 || numCellsZ != 1) {
			numParentsX = Math.ceil(numCellsX/2);
			numParentsY = Math.ceil(numCellsY/2);
			numParentsZ = Math.ceil(numCellsZ/2);
			parents = createLevel(numParentsX, numParentsY, numParentsZ, cellWidth*2, cellHeight*2, cellDepth*2);
		}
		
		minZ = _minZ;
		for (z in 0...numCellsZ) {
			minY = _minY;
			for (y in 0...numCellsY) {
				minX = _minX;
				for (x in 0...numCellsX) {
					node = new InvertedOctreeNode(new Vector3D(minX, minY, minZ), new Vector3D(minX + cellWidth, minY + cellHeight, minZ + cellDepth));
					if (parents != null) {
						var index:Int = (x >> 1) + ((y >> 1) + (z >> 1) * numParentsY) * numParentsX;
						node.setParent(parents[index]);
					}
					nodes[i++] = node;
					minX += cellWidth;
				}
				minY += cellHeight;
			}
			minZ += cellDepth;
		}
		
		return nodes;
	}
	
	public function findPartitionForEntity(entity:Entity):NodeBase
	{
		var bounds:BoundingVolumeBase = entity.worldBounds;
		var min:Vector3D = bounds.min;
		var max:Vector3D = bounds.max;
		
		var minX:Float = min.x;
		var minY:Float = min.y;
		var minZ:Float = min.z;
		var maxX:Float = max.x;
		var maxY:Float = max.y;
		var maxZ:Float = max.z;
		
		var minIndexX:Int = Std.int((minX - _minX) / _cellWidth);
		var maxIndexX:Int = Std.int((maxX - _minX) / _cellWidth);
		var minIndexY:Int = Std.int((minY - _minY) / _cellHeight);
		var maxIndexY:Int = Std.int((maxY - _minY) / _cellHeight);
		var minIndexZ:Int = Std.int((minZ - _minZ) / _cellDepth);
		var maxIndexZ:Int = Std.int((maxZ - _minZ) / _cellDepth);
		
		if (minIndexX < 0)
			minIndexX = 0;
		else if (minIndexX >= _numCellsX)
			minIndexX = _numCellsX - 1;
		if (minIndexY < 0)
			minIndexY = 0;
		else if (minIndexY >= _numCellsY)
			minIndexY = _numCellsY - 1;
		if (minIndexZ < 0)
			minIndexZ = 0;
		else if (minIndexZ >= _numCellsZ)
			minIndexZ = _numCellsZ - 1;
		if (maxIndexX < 0)
			maxIndexX = 0;
		else if (maxIndexX >= _numCellsX)
			maxIndexX = _numCellsX - 1;
		if (maxIndexY < 0)
			maxIndexY = 0;
		else if (maxIndexY >= _numCellsY)
			maxIndexY = _numCellsY - 1;
		if (maxIndexZ < 0)
			maxIndexZ = 0;
		else if (maxIndexZ >= _numCellsZ)
			maxIndexZ = _numCellsZ - 1;
		
		var node:NodeBase = _leaves[minIndexX + (minIndexY + minIndexZ*_numCellsY)*_numCellsX];
		
		// could do this with log2, but not sure if at all faster in expected case (would usually be 0 or at worst 1 iterations, or dynamic grid was set up poorly)
		while (minIndexX != maxIndexX && minIndexY != maxIndexY && minIndexZ != maxIndexZ) {
			maxIndexX >>= 1;
			minIndexX >>= 1;
			maxIndexY >>= 1;
			minIndexY >>= 1;
			maxIndexZ >>= 1;
			minIndexZ >>= 1;
			node = node._parent;
		}
		
		return node;
	}
	
	private function get_showDebugBounds():Bool
	{
		return _showDebugBounds;
	}
	
	private function set_showDebugBounds(value:Bool):Bool
	{
		var numLeaves:Int = _leaves.length;
		_showDebugBounds = showDebugBounds;
		for (i in 0...numLeaves)
			_leaves[i].showDebugBounds = value;
		return value;
	}
	
	public function getCellsIntersecting(minBounds:Vector3D, maxBounds:Vector3D):Vector<InvertedOctreeNode>
	{
		var cells:Vector<InvertedOctreeNode> = new Vector<InvertedOctreeNode>();
		var minIndexX:Int = Std.int((minBounds.x - _minX)/_cellWidth);
		var maxIndexX:Int = Std.int((maxBounds.x - _minX)/_cellWidth);
		var minIndexY:Int = Std.int((minBounds.y - _minY)/_cellHeight);
		var maxIndexY:Int = Std.int((maxBounds.y - _minY)/_cellHeight);
		var minIndexZ:Int = Std.int((minBounds.z - _minZ)/_cellDepth);
		var maxIndexZ:Int = Std.int((maxBounds.z - _minZ)/_cellDepth);
		
		if (minIndexX < 0)
			minIndexX = 0;
		else if (minIndexX >= _numCellsX)
			minIndexX = _numCellsX - 1;
		if (maxIndexX < 0)
			maxIndexX = 0;
		else if (maxIndexX >= _numCellsX)
			maxIndexX = _numCellsX - 1;
		
		if (minIndexY < 0)
			minIndexY = 0;
		else if (minIndexY >= _numCellsY)
			minIndexY = _numCellsY - 1;
		if (maxIndexY < 0)
			maxIndexY = 0;
		else if (maxIndexY >= _numCellsY)
			maxIndexY = _numCellsY - 1;
		
		if (maxIndexZ < 0)
			maxIndexZ = 0;
		else if (maxIndexZ >= _numCellsZ)
			maxIndexZ = _numCellsZ - 1;
		if (minIndexZ < 0)
			minIndexZ = 0;
		else if (minIndexZ >= _numCellsZ)
			minIndexZ = _numCellsZ - 1;
		
		var i:Int = 0;
		for (z in minIndexZ...(maxIndexZ + 1)) {
			for (y in minIndexY...(maxIndexY + 1)) {
				for (x in minIndexX...(maxIndexX + 1)) {
					cells[i++] = getCellAt(x, y, z);
				}
			}
		}
		
		return cells;
	}
}