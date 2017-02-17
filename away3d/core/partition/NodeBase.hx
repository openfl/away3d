package away3d.core.partition;

import away3d.core.math.Plane3D;
import away3d.core.traverse.PartitionTraverser;
import away3d.entities.Entity;
import away3d.primitives.WireframePrimitiveBase;

import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * The NodeBase class is an abstract base class for any type of space partition tree node. The concrete
 * subtype will control the creation of its child nodes, which are necessarily of the same type. The exception is
 * the creation of leaf entity nodes, which is handled by the Partition3D class.
 *
 * @see away3d.partition.EntityNode
 * @see away3d.partition.Partition3D
 * @see away3d.containers.Scene3D
 */
class NodeBase
{
	public var showDebugBounds(get, set):Bool;
	public var parent(get, never):NodeBase;
	private var numEntities(get, never):Int;
	
	@:allow(away3d) private var _parent:NodeBase;
	private var _childNodes:Vector<NodeBase>;
	private var _numChildNodes:Int;
	private var _debugPrimitive:WireframePrimitiveBase;
	
	@:allow(away3d) private var _numEntities:Int;
	@:allow(away3d) private var _collectionMark:Int;
	
	/**
	 * Creates a new NodeBase object.
	 */
	public function new()
	{
		_childNodes = new Vector<NodeBase>();
		_numEntities = 0;
		_collectionMark = 0;
		_numChildNodes= 0;
	}
	
	private function get_showDebugBounds():Bool
	{
		return _debugPrimitive != null;
	}
	
	private function set_showDebugBounds(value:Bool):Bool
	{
		if ((_debugPrimitive != null) == value)
			return value;
		
		if (value)
			_debugPrimitive = createDebugBounds();
		else {
			_debugPrimitive.dispose();
			_debugPrimitive = null;
		}
		
		for (i in 0..._numChildNodes)
			_childNodes[i].showDebugBounds = value;
		
		return value;
	}
	
	/**
	 * The parent node. Null if this node is the root.
	 */
	private function get_parent():NodeBase
	{
		return _parent;
	}
	
	/**
	 * Adds a node to the tree. By default, this is used for both static as dynamic nodes, but for some data
	 * structures such as BSP trees, it can be more efficient to only use this for dynamic nodes, and add the
	 * static child nodes using custom links.
	 *
	 * @param node The node to be added as a child of the current node.
	 */
	@:allow(away3d) private function addNode(node:NodeBase):Void
	{
		node._parent = this;
		_numEntities += node._numEntities;
		_childNodes[_numChildNodes++] = node;
		node.showDebugBounds = _debugPrimitive != null;
		
		// update numEntities in the tree
		var numEntities:Int = node._numEntities;
		node = this;
		
		do {
			node._numEntities += numEntities;
		} while ((node = node._parent) != null);
	}
	
	/**
	 * Removes a child node from the tree.
	 * @param node The child node to be removed.
	 */
	@:allow(away3d) private function removeNode(node:NodeBase):Void
	{
		// a bit faster than splice(i, 1), works only if order is not important
		// override item to be removed with the last in the list, then remove that last one
		// Also, the "real partition nodes" of the tree will always remain unmoved, first in the list, so if there's
		// an order dependency for them, it's still okay
		var index:Int = _childNodes.indexOf(node);
		_childNodes[index] = _childNodes[--_numChildNodes];
		_childNodes.pop();
		
		// update numEntities in the tree
		var numEntities:Int = node._numEntities;
		node = this;
		
		do {
			node._numEntities -= numEntities;
		} while ((node = node._parent) != null);
	}
	
	/**
	 * Tests if the current node is at least partly inside the frustum.
	 * @param viewProjectionRaw The raw data of the view projection matrix
	 *
	 * @return Whether or not the node is at least partly inside the view frustum.
	 */
	public function isInFrustum(planes:Vector<Plane3D>, numPlanes:Int):Bool
	{
		return true;
	}
	
	/**
	 * Tests if the current node is intersecting with a ray.
	 * @param rayPosition The starting position of the ray
	 * @param rayDirection The direction vector of the ray
	 *
	 * @return Whether or not the node is at least partly intersecting the ray.
	 */
	public function isIntersectingRay(rayPosition:Vector3D, rayDirection:Vector3D):Bool
	{
		return true;
	}
	
	/**
	 * Finds the partition that contains (or should contain) the given entity.
	 */
	public function findPartitionForEntity(entity:Entity):NodeBase
	{
		return this;
	}
	
	/**
	 * Allows the traverser to visit the current node. If the traverser's enterNode method returns true, the
	 * traverser will be sent down the child nodes of the tree.
	 * This method should be overridden if the order of traversal is important (such as for BSP trees) - or if static
	 * child nodes are not added using addNode, but are linked to separately.
	 *
	 * @param traverser The traverser visiting the node.
	 *
	 * @see away3d.core.traverse.PartitionTraverser
	 */
	public function acceptTraverser(traverser:PartitionTraverser):Void
	{
		if (_numEntities == 0 && _debugPrimitive == null)
			return;
		
		if (traverser.enterNode(this)) {
			var i:Int = 0;
			while (i < _numChildNodes)
				_childNodes[i++].acceptTraverser(traverser);
			
			if (_debugPrimitive != null)
				traverser.applyRenderable(_debugPrimitive);
		}
	}
	
	private function createDebugBounds():WireframePrimitiveBase
	{
		return null;
	}
	
	private function get_numEntities():Int
	{
		return _numEntities;
	}
	
	private function updateNumEntities(value:Int):Void
	{
		var diff:Int = value - _numEntities;
		var node:NodeBase = this;
		
		do {
			node._numEntities += diff;
		} while ((node = node._parent) != null);
	}
}