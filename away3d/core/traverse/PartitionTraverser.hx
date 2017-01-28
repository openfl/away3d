package away3d.core.traverse;

import away3d.containers.Scene3D;
import away3d.core.base.IRenderable;
import away3d.core.partition.NodeBase;
import away3d.entities.Entity;
import away3d.errors.AbstractMethodError;
import away3d.lights.DirectionalLight;
import away3d.lights.LightBase;
import away3d.lights.LightProbe;
import away3d.lights.PointLight;

import openfl.geom.Vector3D;

/**
 * IPartitionTraverser is a hierarchical visitor pattern that traverses through a Partition3D data structure.
 *
 * @see away3d.partition.Partition3D
 */
class PartitionTraverser
{
	@:allow(away3d) private var entryPoint(get, never):Vector3D;
	
	/**
	 * The scene being traversed.
	 */
	public var scene:Scene3D;
	
	@:allow(away3d) private var _entryPoint:Vector3D;
	
	/**
	 * A property that can be used to avoid processing a partition more than once.
	 */
	@:allow(away3d) private static var _collectionMark:Int = 0;
	
	public function new()
	{
	
	}
	
	/**
	 * Called when the traversers enters a node. At minimum, it notifies the currently visited Partition3DNode whether or not further recursion is necessary.
	 * @param node The currently entered node.
	 * @return true if further recursion down children is necessary, false if not.
	 */
	public function enterNode(node:NodeBase):Bool
	{
		return true;
	}
	
	/**
	 * Passes a skybox to be processed by the traverser.
	 */
	public function applySkyBox(renderable:IRenderable):Void
	{
		throw new AbstractMethodError();
	}
	
	/**
	 * Passes an IRenderable object to be processed by the traverser.
	 */
	public function applyRenderable(renderable:IRenderable):Void
	{
		throw new AbstractMethodError();
	}
	
	/**
	 * Passes a light to be processed by the traverser.
	 */
	public function applyUnknownLight(light:LightBase):Void
	{
		throw new AbstractMethodError();
	}
	
	public function applyDirectionalLight(light:DirectionalLight):Void
	{
		throw new AbstractMethodError();
	}
	
	public function applyPointLight(light:PointLight):Void
	{
		throw new AbstractMethodError();
	}
	
	public function applyLightProbe(light:LightProbe):Void
	{
		throw new AbstractMethodError();
	}
	
	/**
	 * Registers an entity for use.
	 */
	public function applyEntity(entity:Entity):Void
	{
		throw new AbstractMethodError();
	}
	
	/**
	 * The entry point for scene graph traversal, ie the point that will be used for traversing the graph
	 * position-dependently. For example: BSP visibility determination or collision detection.
	 * For the EntityCollector, this is the camera's scene position for example.
	 */
	private function get_entryPoint():Vector3D
	{
		return _entryPoint;
	}
}