package away3d.core.partition;

import away3d.bounds.BoundingVolumeBase;
import away3d.core.math.Plane3D;
import away3d.entities.Entity;

import openfl.geom.Vector3D;
import openfl.Vector;

class QuadTreeNode extends NodeBase
{
	private var _centerX:Float;
	private var _centerZ:Float;
	private var _depth:Float;
	private var _leaf:Bool;
	private var _height:Float;
	
	private var _rightFar:QuadTreeNode;
	private var _leftFar:QuadTreeNode;
	private var _rightNear:QuadTreeNode;
	private var _leftNear:QuadTreeNode;
	
	private var _halfExtentXZ:Float;
	private var _halfExtentY:Float;
	
	public function new(maxDepth:Int = 5, size:Float = 10000, height:Float = 1000000, centerX:Float = 0, centerZ:Float = 0, depth:Int = 0)
	{
		var hs:Float = size*.5;
		
		_centerX = centerX;
		_centerZ = centerZ;
		_height = height;
		_depth = depth;
		_halfExtentXZ = size*.5;
		_halfExtentY = height*.5;
		
		_leaf = depth == maxDepth;
		
		if (!_leaf) {
			var hhs:Float = hs*.5;
			addNode(_leftNear = new QuadTreeNode(maxDepth, hs, height, centerX - hhs, centerZ - hhs, depth + 1));
			addNode(_rightNear = new QuadTreeNode(maxDepth, hs, height, centerX + hhs, centerZ - hhs, depth + 1));
			addNode(_leftFar = new QuadTreeNode(maxDepth, hs, height, centerX - hhs, centerZ + hhs, depth + 1));
			addNode(_rightFar = new QuadTreeNode(maxDepth, hs, height, centerX + hhs, centerZ + hhs, depth + 1));
		}
		super();
	}
	
	// todo: fix to infinite height so that height needn't be passed in constructor
	override public function isInFrustum(planes:Vector<Plane3D>, numPlanes:Int):Bool
	{
		for (i in 0...numPlanes) {
			var plane:Plane3D = planes[i];
			var flippedExtentX:Float = plane.a < 0? -_halfExtentXZ : _halfExtentXZ;
			var flippedExtentY:Float = plane.b < 0? -_halfExtentY : _halfExtentY;
			var flippedExtentZ:Float = plane.c < 0? -_halfExtentXZ : _halfExtentXZ;
			var projDist:Float = plane.a*(_centerX + flippedExtentX) + plane.b*flippedExtentY + plane.c*(_centerZ + flippedExtentZ) - plane.d;
			if (projDist < 0)
				return false;
		}
		
		return true;
	}
	
	override public function findPartitionForEntity(entity:Entity):NodeBase
	{
		var bounds:BoundingVolumeBase = entity.worldBounds;
		var min:Vector3D = bounds.min;
		var max:Vector3D = bounds.max;
		return findPartitionForBounds(min.x, min.z, max.x, max.z);
	}
	
	private function findPartitionForBounds(minX:Float, minZ:Float, maxX:Float, maxZ:Float):QuadTreeNode
	{
		var left:Bool, right:Bool;
		var far:Bool, near:Bool;
		
		if (_leaf)
			return this;
		
		right = maxX > _centerX;
		left = minX < _centerX;
		far = maxZ > _centerZ;
		near = minZ < _centerZ;
		
		if (left && right)
			return this;
		
		if (near) {
			if (far)
				return this;
			
			if (left)
				return _leftNear.findPartitionForBounds(minX, minZ, maxX, maxZ);
			else
				return _rightNear.findPartitionForBounds(minX, minZ, maxX, maxZ);
		} else {
			if (left)
				return _leftFar.findPartitionForBounds(minX, minZ, maxX, maxZ);
			else
				return _rightFar.findPartitionForBounds(minX, minZ, maxX, maxZ);
		}
	}
}