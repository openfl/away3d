package away3d.core.partition;

	//import away3d.arcane;
	import away3d.bounds.BoundingVolumeBase;
	import away3d.entities.Entity;
	
	import flash.geom.Vector3D;
	
	//use namespace arcane;
	
	/**
	 * DynamicGrid is used by certain partitioning systems that require vislists for regions of dynamic data.
	 */
	class DynamicGrid
	{
		var _minX:Float;
		var _minY:Float;
		var _minZ:Float;
		var _leaves:Array<InvertedOctreeNode>;
		var _numCellsX:UInt;
		var _numCellsY:UInt;
		var _numCellsZ:UInt;
		var _cellWidth:Float;
		var _cellHeight:Float;
		var _cellDepth:Float;
		var _showDebugBounds:Bool;
		
		public function new(minBounds:Vector3D, maxBounds:Vector3D, numCellsX:UInt, numCellsY:UInt, numCellsZ:UInt)
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
		
		public var numCellsX(get, null) : UInt;
		
		public function get_numCellsX() : UInt
		{
			return _numCellsX;
		}
		
		public var numCellsY(get, null) : UInt;
		
		public function get_numCellsY() : UInt
		{
			return _numCellsY;
		}
		
		public var numCellsZ(get, null) : UInt;
		
		public function get_numCellsZ() : UInt
		{
			return _numCellsZ;
		}
		
		public function getCellAt(x:UInt, y:UInt, z:UInt):InvertedOctreeNode
		{
			if (x >= _numCellsX || y >= _numCellsY || z >= _numCellsZ)
				throw new Error("Index out of bounds!");
			
			return _leaves[x + (y + z*_numCellsY)*_numCellsX];
		}
		
		private function createLevel(numCellsX:UInt, numCellsY:UInt, numCellsZ:UInt, cellWidth:Float, cellHeight:Float, cellDepth:Float):Array<InvertedOctreeNode>
		{
			var nodes:Array<InvertedOctreeNode> = new Array<InvertedOctreeNode>(numCellsX*numCellsY*numCellsZ);
			var parents:Array<InvertedOctreeNode>;
			var node:InvertedOctreeNode;
			var i:UInt = 0;
			var minX:Float, minY:Float, minZ:Float;
			var numParentsX:UInt, numParentsY:UInt, numParentsZ:UInt;
			
			if (numCellsX != 1 || numCellsY != 1 || numCellsZ != 1) {
				numParentsX = Math.ceil(numCellsX/2);
				numParentsY = Math.ceil(numCellsY/2);
				numParentsZ = Math.ceil(numCellsZ/2);
				parents = createLevel(numParentsX, numParentsY, numParentsZ, cellWidth*2, cellHeight*2, cellDepth*2);
			}
			
			minZ = _minZ;
			// For loop conversion - 			for (var z:UInt = 0; z < numCellsZ; ++z)
			var z:UInt;
			for (z in 0...numCellsZ) {
				minY = _minY;
				// For loop conversion - 				for (var y:UInt = 0; y < numCellsY; ++y)
				var y:UInt;
				for (y in 0...numCellsY) {
					minX = _minX;
					// For loop conversion - 					for (var x:UInt = 0; x < numCellsX; ++x)
					var x:UInt;
					for (x in 0...numCellsX) {
						node = new InvertedOctreeNode(new Vector3D(minX, minY, minZ), new Vector3D(minX + cellWidth, minY + cellHeight, minZ + cellDepth));
						if (parents) {
							var index:Int = (x >> 1) + ((y >> 1) + (z >> 1)*numParentsY)*numParentsX;
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
			
			var minIndexX:Int = (minX - _minX)/_cellWidth;
			var maxIndexX:Int = (maxX - _minX)/_cellWidth;
			var minIndexY:Int = (minY - _minY)/_cellHeight;
			var maxIndexY:Int = (maxY - _minY)/_cellHeight;
			var minIndexZ:Int = (minZ - _minZ)/_cellDepth;
			var maxIndexZ:Int = (maxZ - _minZ)/_cellDepth;
			
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
		
		public var showDebugBounds(get, set) : Bool;
		
		public function get_showDebugBounds() : Bool
		{
			return _showDebugBounds;
		}
		
		public function set_showDebugBounds(value:Bool) : Bool
		{
			var numLeaves:UInt = _leaves.length;
			_showDebugBounds = showDebugBounds;
			// For loop conversion - 			for (var i:Int = 0; i < numLeaves; ++i)
			var i:Int;
			for (i in 0...numLeaves)
				_leaves[i].showDebugBounds = value;
		}
		
		public function getCellsIntersecting(minBounds:Vector3D, maxBounds:Vector3D):Array<InvertedOctreeNode>
		{
			var cells:Array<InvertedOctreeNode> = new Array<InvertedOctreeNode>();
			var minIndexX:Int = (minBounds.x - _minX)/_cellWidth;
			var maxIndexX:Int = (maxBounds.x - _minX)/_cellWidth;
			var minIndexY:Int = (minBounds.y - _minY)/_cellHeight;
			var maxIndexY:Int = (maxBounds.y - _minY)/_cellHeight;
			var minIndexZ:Int = (minBounds.z - _minZ)/_cellDepth;
			var maxIndexZ:Int = (maxBounds.z - _minZ)/_cellDepth;
			
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
			
			var i:UInt = 0;
			// For loop conversion - 			for (var z:UInt = minIndexZ; z <= maxIndexZ; ++z)
			var z:UInt;
			for (z in minIndexZ...maxIndexZ) {
				// For loop conversion - 				for (var y:UInt = minIndexY; y <= maxIndexY; ++y)
				var y:UInt;
				for (y in minIndexY...maxIndexY) {
					// For loop conversion - 					for (var x:UInt = minIndexX; x <= maxIndexX; ++x)
					var x:UInt;
					for (x in minIndexX...maxIndexX)
						cells[i++] = getCellAt(x, y, z);
				}
			}
			
			return cells;
		}
	}

