package away3d.core.partition;

	//import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.core.traverse.PartitionTraverser;
	import away3d.core.traverse.SceneIterator;
	import away3d.entities.Entity;
	import away3d.primitives.WireframeCube;
	import away3d.primitives.WireframePrimitiveBase;
	
	import flash.geom.Vector3D;
	
	//use namespace arcane;
	
	// todo: provide markVisibleVolume to pass in another view volume to find all statics in the scene that intersect with target ViewVolume, for constructing view volumes more easily
	class ViewVolume extends NodeBase
	{
		var _width:Float;
		var _height:Float;
		var _depth:Float;
		var _cellSize:Float;
		var _numCellsX:UInt;
		var _numCellsY:UInt;
		var _numCellsZ:UInt;
		var _cells:Array<ViewCell>;
		var _minX:Float;
		var _minY:Float;
		var _minZ:Float;
		var _maxX:Float;
		var _maxY:Float;
		var _maxZ:Float;
		/*arcane*/ public var _active:Bool;
		private static var _entityWorldBounds:Array<Float>;
		
		/**
		 * Creates a new ViewVolume with given dimensions. A ViewVolume is a region where the camera or a shadow casting light could reside in.
		 *
		 * @param minBound The minimum boundaries of the view volume (the bottom-left-near corner)
		 * @param maxBound The maximum boundaries of the view volume (the top-right-far corner)
		 * @param cellSize The size of cell subdivisions for the view volume. The default value is -1, meaning the view volume will not be subdivided. This is the value that should usually be used when setting visibility info manually.
		 */
		public function new(minBound:Vector3D, maxBound:Vector3D, cellSize:Float = -1)
		{
			_minX = minBound.x;
			_minY = minBound.y;
			_minZ = minBound.z;
			_maxX = maxBound.x;
			_maxY = maxBound.y;
			_maxZ = maxBound.z;
			_width = _maxX - _minX;
			_height = _maxY - _minY;
			_depth = _maxZ - _minZ;
			_cellSize = cellSize;
			initCells();
		}
		
		public var minBound(get, null) : Vector3D;
		
		public function get_minBound() : Vector3D
		{
			return new Vector3D(_minX, _minY, _minZ);
		}
		
		public var maxBound(get, null) : Vector3D;
		
		public function get_maxBound() : Vector3D
		{
			return new Vector3D(_maxX, _maxY, _maxZ);
		}
		
		override public function acceptTraverser(traverser:PartitionTraverser):Void
		{
			if (traverser.enterNode(this)) {
				if (_debugPrimitive)
					traverser.applyRenderable(_debugPrimitive);
				
				if (!_active)
					return;
				
				var entryPoint:Vector3D = traverser.entryPoint;
				
				var cell:ViewCell = getCellContaining(entryPoint);
				
				var visibleStatics:Array<EntityNode> = cell.visibleStatics;
				var numVisibles:UInt = visibleStatics.length;
				// For loop conversion - 				for (var i:Int = 0; i < numVisibles; ++i)
				var i:Int;
				for (i in 0...numVisibles)
					visibleStatics[i].acceptTraverser(traverser);
				
				var visibleDynamics:Array<InvertedOctreeNode> = cell.visibleDynamics;
				if (visibleDynamics) {
					numVisibles = visibleDynamics.length;
					// For loop conversion - 					for (i = 0; i < numVisibles; ++i)
					for (i in 0...numVisibles)
						visibleDynamics[i].acceptTraverser(traverser);
				}
			}
		
		}
		
		public function addVisibleStatic(entity:Entity, indexX:UInt = 0, indexY:UInt = 0, indexZ:UInt = 0):Void
		{
			if (!entity.staticNode)
				throw new Error("Entity being added as a visible static object must have static set to true");
			
			var index:Int = getCellIndex(indexX, indexY, indexZ);
			if (!_cells[index].visibleStatics) _cells[index].visibleStatics = new Array<EntityNode>();
			_cells[index].visibleStatics.push(entity.getEntityPartitionNode());
			updateNumEntities(_numEntities + 1);
		}
		
		public function addVisibleDynamicCell(cell:InvertedOctreeNode, indexX:UInt = 0, indexY:UInt = 0, indexZ:UInt = 0):Void
		{
			var index:Int = getCellIndex(indexX, indexY, indexZ);
			if (!_cells[index].visibleDynamics) _cells[index].visibleDynamics = new Array<InvertedOctreeNode>();
			_cells[index].visibleDynamics.push(cell);
			updateNumEntities(_numEntities + 1);
		}
		
		public function removeVisibleStatic(entity:Entity, indexX:UInt = 0, indexY:UInt = 0, indexZ:UInt = 0):Void
		{
			var index:Int = getCellIndex(indexX, indexY, indexZ);
			var statics:Array<EntityNode> = _cells[index].visibleStatics;
			if (!statics)
				return;
			index = statics.indexOf(entity.getEntityPartitionNode());
			if (index >= 0)
				statics.splice(index, 1);
			updateNumEntities(_numEntities - 1);
		}
		
		public function removeVisibleDynamicCell(cell:InvertedOctreeNode, indexX:UInt = 0, indexY:UInt = 0, indexZ:UInt = 0):Void
		{
			var index:Int = getCellIndex(indexX, indexY, indexZ);
			var dynamics:Array<InvertedOctreeNode> = _cells[index].visibleDynamics;
			if (!dynamics)
				return;
			index = dynamics.indexOf(cell);
			if (index >= 0)
				dynamics.splice(index, 1);
			updateNumEntities(_numEntities - 1);
		}
		
		private function initCells():Void
		{
			if (_cellSize == -1)
				_numCellsX = _numCellsY = _numCellsZ = 1;
			else {
				_numCellsX = Math.ceil(_width/_cellSize);
				_numCellsY = Math.ceil(_height/_cellSize);
				_numCellsZ = Math.ceil(_depth/_cellSize);
			}
			
			_cells = new Array<ViewCell>(_numCellsX*_numCellsY*_numCellsZ);
			
			if (_cellSize == -1)
				_cells[0] = new ViewCell();
		
			// else: do not automatically populate with cells as it may be sparse!
		}
		
		/**
		 * Enable the use of a cell. Do this if the camera or casting light can potentially be in this cell.
		 * If the ViewVolume was constructed with gridSize -1, it does not need to be called
		 * @param indexX The x-index of the cell
		 * @param indexY The y-index of the cell
		 * @param indexZ The z-index of the cell
		 */
		public function markCellAccessible(indexX:UInt, indexY:UInt, indexZ:UInt):Void
		{
			var index:Int = getCellIndex(indexX, indexY, indexZ);
			if (!_cells[index]) _cells[index] = new ViewCell();
		}
		
		/**
		 * Disables the use of a cell. Do this only if the camera or casting light can never be in this cell.
		 * @param indexX The x-index of the cell
		 * @param indexY The y-index of the cell
		 * @param indexZ The z-index of the cell
		 */
		public function markCellInaccessible(indexX:UInt, indexY:UInt, indexZ:UInt):Void
		{
			var index:Int = getCellIndex(indexX, indexY, indexZ);
			_cells[index] = null;
		}
		
		public var width(get, null) : Float;
		
		public function get_width() : Float
		{
			return _width;
		}
		
		public var height(get, null) : Float;
		
		public function get_height() : Float
		{
			return _height;
		}
		
		public var depth(get, null) : Float;
		
		public function get_depth() : Float
		{
			return _depth;
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
		
		public var minX(get, null) : Float;
		
		public function get_minX() : Float
		{
			return _minX;
		}
		
		public var minY(get, null) : Float;
		
		public function get_minY() : Float
		{
			return _minY;
		}
		
		public var minZ(get, null) : Float;
		
		public function get_minZ() : Float
		{
			return _minZ;
		}
		
		public var maxX(get, null) : Float;
		
		public function get_maxX() : Float
		{
			return _maxX;
		}
		
		public var maxY(get, null) : Float;
		
		public function get_maxY() : Float
		{
			return _maxY;
		}
		
		public var maxZ(get, null) : Float;
		
		public function get_maxZ() : Float
		{
			return _maxZ;
		}
		
		private function getCellIndex(indexX:UInt, indexY:UInt, indexZ:UInt):UInt
		{
			if (indexX >= _numCellsX || indexY >= _numCellsY || indexZ >= _numCellsZ)
				throw new Error("Index out of bounds");
			
			return indexX + (indexY + indexZ*_numCellsY)*_numCellsX;
		}
		
		public function contains(entryPoint:Vector3D):Bool
		{
			return entryPoint.x >= _minX && entryPoint.x <= _maxX &&
				entryPoint.y >= _minY && entryPoint.y <= _maxY &&
				entryPoint.z >= _minZ && entryPoint.z <= _maxZ;
		}
		
		private function getCellContaining(entryPoint:Vector3D):ViewCell
		{
			var cellIndex:UInt;
			
			if (_cellSize == -1)
				cellIndex = 0;
			else {
				var indexX:Int = (entryPoint.x - _minX)/_cellSize;
				var indexY:Int = (entryPoint.y - _minY)/_cellSize;
				var indexZ:Int = (entryPoint.z - _minZ)/_cellSize;
				cellIndex = indexX + (indexY + indexZ*_numCellsY)*_numCellsX;
			}
			return _cells[cellIndex];
		}
		
		override private function createDebugBounds():WireframePrimitiveBase
		{
			var cube:WireframeCube = new WireframeCube(_width, _height, _depth, 0xff0000);
			cube.x = (_minX + _maxX)*.5;
			cube.y = (_minY + _maxY)*.5;
			cube.z = (_minZ + _maxZ)*.5;
			return cube;
		}
		
		/**
		 * Adds all static geometry in a scene that intersects a given region, as well as the dynamic grid if provided.
		 * @param minBounds The minimum bounds of the region to be considered visible
		 * @param maxBounds The maximum bounds of the region to be considered visible
		 * @param scene The Scene3D object containing the static objects to be added.
		 * @param dynamicGrid The DynamicGrid belonging to the partition this will be used with
		 * @param indexX An optional index for the cell within ViewVolume. If created with gridSize -1, this is typically avoided.
		 * @param indexY An optional index for the cell within ViewVolume. If created with gridSize -1, this is typically avoided.
		 * @param indexZ An optional index for the cell within ViewVolume. If created with gridSize -1, this is typically avoided.
		 */
		public function addVisibleRegion(minBounds:Vector3D, maxBounds:Vector3D, scene:Scene3D, dynamicGrid:DynamicGrid = null, indexX:UInt = 0, indexY:UInt = 0, indexZ:UInt = 0):Void
		{
			var cell:ViewCell = _cells[getCellIndex(indexX, indexY, indexZ)];
			addStaticsForRegion(scene, minBounds, maxBounds, cell);
			if (dynamicGrid)
				addDynamicsForRegion(dynamicGrid, minBounds, maxBounds, cell);
		}
		
		/**
		 * A shortcut method for addVisibleRegion, that adds static geometry in a scene that intersects a given viewvolume, as well as the dynamic grid if provided.
		 * @param viewVolume The viewVolume providing the region
		 * @param scene The Scene3D object containing the static objects to be added.
		 * @param dynamicGrid The DynamicGrid belonging to the partition this will be used with
		 */
		public function addVisibleViewVolume(viewVolume:ViewVolume, scene:Scene3D, dynamicGrid:DynamicGrid = null):Void
		{
			var minBounds:Vector3D = viewVolume.minBound;
			var maxBounds:Vector3D = viewVolume.maxBound;
			
			// For loop conversion - 						for (var z:UInt = 0; z < _numCellsZ; ++z)
			
			var z:UInt;
			
			for (z in 0..._numCellsZ) {
				// For loop conversion - 				for (var y:UInt = 0; y < _numCellsY; ++y)
				var y:UInt;
				for (y in 0..._numCellsY) {
					// For loop conversion - 					for (var x:UInt = 0; x < _numCellsX; ++x)
					var x:UInt;
					for (x in 0..._numCellsX)
						addVisibleRegion(minBounds, maxBounds, scene, dynamicGrid, x, y, z);
				}
			}
		}
		
		private function addStaticsForRegion(scene:Scene3D, minBounds:Vector3D, maxBounds:Vector3D, cell:ViewCell):Void
		{
			var iterator:SceneIterator = new SceneIterator(scene);
			if (!cell.visibleStatics) cell.visibleStatics = new Array<EntityNode>();
			var visibleStatics:Array<EntityNode> = cell.visibleStatics;
			var object:ObjectContainer3D;
			var numAdded:Int = 0;
			
			_entityWorldBounds = new Array<Float>();
			
			object = iterator.next();
			
			while (object) {
				var entity:Entity = object as Entity;
				if (entity && staticIntersects(entity, minBounds, maxBounds)) {
					var node:EntityNode = entity.getEntityPartitionNode();
					if (visibleStatics.indexOf(node) == -1) {
						visibleStatics.push(node);
						++numAdded;
					}
				}
				object = iterator.next();
			}
			
			updateNumEntities(_numEntities + numAdded);
			_entityWorldBounds = null;
		}
		
		private function addDynamicsForRegion(dynamicGrid:DynamicGrid, minBounds:Vector3D, maxBounds:Vector3D, cell:ViewCell):Void
		{
			var cells:Array<InvertedOctreeNode> = dynamicGrid.getCellsIntersecting(minBounds, maxBounds);
			if (!cell.visibleDynamics) cell.visibleDynamics = new Array<InvertedOctreeNode>();
			cell.visibleDynamics = cell.visibleDynamics.concat(cells);
			updateNumEntities(_numEntities + cells.length);
		}
		
		private function staticIntersects(entity:Entity, minBounds:Vector3D, maxBounds:Vector3D):Bool
		{
			entity.sceneTransform.transformVectors(entity.bounds.aabbPoints, _entityWorldBounds);
			
			var minX:Float = _entityWorldBounds[0];
			var minY:Float = _entityWorldBounds[1];
			var minZ:Float = _entityWorldBounds[2];
			var maxX:Float = minX;
			var maxY:Float = minY;
			var maxZ:Float = minZ;
			
			// NullBounds
			if (minX != minX || minY != minY || minZ != minZ)
				return true;
			
			// For loop conversion - 						for (var i:UInt = 3; i < 24; i += 3)
			
			var i:UInt = 0;
			
			for (i in 3...24) {
				var x:Float = _entityWorldBounds[i];
				var y:Float = _entityWorldBounds[uint(i + 1)];
				var z:Float = _entityWorldBounds[uint(i + 2)];
				if (x < minX)
					minX = x;
				else if (x > maxX)
					maxX = x;
				if (y < minX)
					minY = y;
				else if (y > maxY)
					maxY = y;
				if (z < minX)
					minZ = z;
				else if (z > maxZ)
					maxZ = z;
			}
			
			var epsMinX:Float = minBounds.x + .001;
			var epsMinY:Float = minBounds.y + .001;
			var epsMinZ:Float = minBounds.z + .001;
			var epsMaxX:Float = maxBounds.x - .001;
			var epsMaxY:Float = maxBounds.y - .001;
			var epsMaxZ:Float = maxBounds.z - .001;
			
			return !((minX < epsMinX && maxX < epsMinX) ||
				(minX > epsMaxX && maxX > epsMaxX) ||
				(minY < epsMinY && maxY < epsMinY) ||
				(minY > epsMaxY && maxY > epsMaxY) ||
				(minZ < epsMinZ && maxZ < epsMinZ) ||
				(minZ > epsMaxZ && maxZ > epsMaxZ));
		}
	}
}

import away3d.core.partition.EntityNode;
import away3d.core.partition.InvertedOctreeNode;

class ViewCell
{
	public var visibleStatics:Array<EntityNode> = new Array<EntityNode>();
	public var visibleDynamics:Array<InvertedOctreeNode> = new Array<InvertedOctreeNode>();

