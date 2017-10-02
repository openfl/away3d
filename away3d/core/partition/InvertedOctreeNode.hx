package away3d.core.partition;

import away3d.core.math.Plane3D;
import away3d.core.traverse.PartitionTraverser;
import away3d.primitives.WireframeCube;
import away3d.primitives.WireframePrimitiveBase;

import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * InvertedOctreeNode is an octree data structure not used hierarchically for culling, but for fast dynamic insertion.
 * The data structure is essentially a grid, but "overarching" parent container nodes for entities striding across nodes.
 * If this is visible, so is the parent.
 * Traversal happens invertedly too.
 */
class InvertedOctreeNode extends NodeBase
{
	private var _minX:Float;
	private var _minY:Float;
	private var _minZ:Float;
	private var _maxX:Float;
	private var _maxY:Float;
	private var _maxZ:Float;
	private var _centerX:Float;
	private var _centerY:Float;
	private var _centerZ:Float;
	private var _halfExtentX:Float;
	private var _halfExtentY:Float;
	private var _halfExtentZ:Float;
	
	public function new(minBounds:Vector3D, maxBounds:Vector3D)
	{
		_minX = minBounds.x;
		_minY = minBounds.y;
		_minZ = minBounds.z;
		_maxX = maxBounds.x;
		_maxY = maxBounds.y;
		_maxZ = maxBounds.z;
		_centerX = (_maxX + _minX)*.5;
		_centerY = (_maxY + _minY)*.5;
		_centerZ = (_maxZ + _minZ)*.5;
		_halfExtentX = (_maxX - _minX)*.5;
		_halfExtentY = (_maxY - _minY)*.5;
		_halfExtentZ = (_maxZ - _minZ)*.5;
		super();
	}
	
	@:allow(away3d) private function setParent(value:InvertedOctreeNode):Void
	{
		_parent = value;
	}
	
	override public function isInFrustum(planes:Vector<Plane3D>, numPlanes:Int):Bool
	{
		for (i in 0...numPlanes) {
			var plane:Plane3D = planes[i];
			var flippedExtentX:Float = plane.a < 0? -_halfExtentX : _halfExtentX;
			var flippedExtentY:Float = plane.b < 0? -_halfExtentY : _halfExtentY;
			var flippedExtentZ:Float = plane.c < 0? -_halfExtentZ : _halfExtentZ;
			var projDist:Float = plane.a*(_centerX + flippedExtentX) + plane.b*(_centerY + flippedExtentY) + plane.c*(_centerZ + flippedExtentZ) - plane.d;
			if (projDist < 0)
				return false;
		}
		
		return true;
	}
	
	override private function createDebugBounds():WireframePrimitiveBase
	{
		var cube:WireframeCube = new WireframeCube(_maxX - _minX, _maxY - _minY, _maxZ - _minZ, 0x8080ff);
		cube.x = _centerX;
		cube.y = _centerY;
		cube.z = _centerZ;
		return cube;
	}
	
	override public function acceptTraverser(traverser:PartitionTraverser):Void
	{
		super.acceptTraverser(traverser);
		if (_parent != null)
			_parent.acceptTraverser(traverser);
	}
}