package away3d.core.partition;


import away3d.bounds.BoundingVolumeBase;
import away3d.core.math.Plane3D;
import away3d.entities.Entity;
import away3d.primitives.WireframeCube;
import away3d.primitives.WireframePrimitiveBase;

import openfl.geom.Vector3D;
import openfl.Vector;

class OctreeNode extends NodeBase
{
	private var _centerX:Float;
	private var _centerY:Float;
	private var _centerZ:Float;
	private var _minX:Float;
	private var _minY:Float;
	private var _minZ:Float;
	private var _maxX:Float;
	private var _maxY:Float;
	private var _maxZ:Float;
	private var _quadSize:Float;
	private var _depth:Float;
	private var _leaf:Bool;
	
	private var _rightTopFar:OctreeNode;
	private var _leftTopFar:OctreeNode;
	private var _rightBottomFar:OctreeNode;
	private var _leftBottomFar:OctreeNode;
	private var _rightTopNear:OctreeNode;
	private var _leftTopNear:OctreeNode;
	private var _rightBottomNear:OctreeNode;
	private var _leftBottomNear:OctreeNode;
	
	//private var _entityWorldBounds : Vector.<Number> = new Vector.<Number>();
	private var _halfExtent:Float;
	
	public function new(maxDepth:Int = 5, size:Float = 10000, centerX:Float = 0, centerY:Float = 0, centerZ:Float = 0, depth:Int = 0)
	{
		init(size, centerX, centerY, centerZ, depth, maxDepth);
		super();
	}
	
	private function init(size:Float, centerX:Float, centerY:Float, centerZ:Float, depth:Int, maxDepth:Int):Void
	{
		_halfExtent = size*.5;
		_centerX = centerX;
		_centerY = centerY;
		_centerZ = centerZ;
		_quadSize = size;
		_depth = depth;
		_minX = centerX - _halfExtent;
		_minY = centerY - _halfExtent;
		_minZ = centerZ - _halfExtent;
		_maxX = centerX + _halfExtent;
		_maxY = centerY + _halfExtent;
		_maxZ = centerZ + _halfExtent;
		
		_leaf = depth == maxDepth;
		
		if (!_leaf) {
			var hhs:Float = _halfExtent*.5;
			addNode(_leftTopNear = new OctreeNode(maxDepth, _halfExtent, centerX - hhs, centerY + hhs, centerZ - hhs, depth + 1));
			addNode(_rightTopNear = new OctreeNode(maxDepth, _halfExtent, centerX + hhs, centerY + hhs, centerZ - hhs, depth + 1));
			addNode(_leftBottomNear = new OctreeNode(maxDepth, _halfExtent, centerX - hhs, centerY - hhs, centerZ - hhs, depth + 1));
			addNode(_rightBottomNear = new OctreeNode(maxDepth, _halfExtent, centerX + hhs, centerY - hhs, centerZ - hhs, depth + 1));
			addNode(_leftTopFar = new OctreeNode(maxDepth, _halfExtent, centerX - hhs, centerY + hhs, centerZ + hhs, depth + 1));
			addNode(_rightTopFar = new OctreeNode(maxDepth, _halfExtent, centerX + hhs, centerY + hhs, centerZ + hhs, depth + 1));
			addNode(_leftBottomFar = new OctreeNode(maxDepth, _halfExtent, centerX - hhs, centerY - hhs, centerZ + hhs, depth + 1));
			addNode(_rightBottomFar = new OctreeNode(maxDepth, _halfExtent, centerX + hhs, centerY - hhs, centerZ + hhs, depth + 1));
		}
	}
	
	override private function createDebugBounds():WireframePrimitiveBase
	{
		var cube:WireframeCube = new WireframeCube(_quadSize, _quadSize, _quadSize);
		cube.x = _centerX;
		cube.y = _centerY;
		cube.z = _centerZ;
		return cube;
	}
	
	override public function isInFrustum(planes:Vector<Plane3D>, numPlanes:Int):Bool
	{
		for (i in 0...numPlanes) {
			var plane:Plane3D = planes[i];
			var flippedExtentX:Float = plane.a < 0? -_halfExtent : _halfExtent;
			var flippedExtentY:Float = plane.b < 0? -_halfExtent : _halfExtent;
			var flippedExtentZ:Float = plane.c < 0? -_halfExtent : _halfExtent;
			var projDist:Float = plane.a*(_centerX + flippedExtentX) + plane.b*(_centerY + flippedExtentY) + plane.c*(_centerZ + flippedExtentZ) - plane.d;
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
		return findPartitionForBounds(min.x, min.y, min.z, max.x, max.y, max.z);
	}
	
	// TODO: this can be done quicker through inversion
	private function findPartitionForBounds(minX:Float, minY:Float, minZ:Float, maxX:Float, maxY:Float, maxZ:Float):OctreeNode
	{
		var left:Bool, right:Bool;
		var far:Bool, near:Bool;
		var top:Bool, bottom:Bool;
		
		if (_leaf)
			return this;
		
		right = maxX > _centerX;
		left = minX < _centerX;
		top = maxY > _centerY;
		bottom = minY < _centerY;
		far = maxZ > _centerZ;
		near = minZ < _centerZ;
		
		if ((left && right) || (far && near))
			return this;
		
		if (top) {
			if (bottom)
				return this;
			if (near) {
				if (left)
					return _leftTopNear.findPartitionForBounds(minX, minY, minZ, maxX, maxY, maxZ);
				else
					return _rightTopNear.findPartitionForBounds(minX, minY, minZ, maxX, maxY, maxZ);
			} else {
				if (left)
					return _leftTopFar.findPartitionForBounds(minX, minY, minZ, maxX, maxY, maxZ);
				else
					return _rightTopFar.findPartitionForBounds(minX, minY, minZ, maxX, maxY, maxZ);
			}
		} else {
			if (near) {
				if (left)
					return _leftBottomNear.findPartitionForBounds(minX, minY, minZ, maxX, maxY, maxZ);
				else
					return _rightBottomNear.findPartitionForBounds(minX, minY, minZ, maxX, maxY, maxZ);
			} else {
				if (left)
					return _leftBottomFar.findPartitionForBounds(minX, minY, minZ, maxX, maxY, maxZ);
				else
					return _rightBottomFar.findPartitionForBounds(minX, minY, minZ, maxX, maxY, maxZ);
			}
		}
	}
}