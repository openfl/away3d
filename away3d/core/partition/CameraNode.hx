package away3d.core.partition;

import away3d.cameras.Camera3D;
import away3d.core.traverse.PartitionTraverser;

/**
 * CameraNode is a space partitioning leaf node that contains a Camera3D object.
 */
class CameraNode extends EntityNode
{
	/**
	 * Creates a new CameraNode object.
	 * @param camera The camera to be contained in the node.
	 */
	public function new(camera:Camera3D)
	{
		super(camera);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function acceptTraverser(traverser:PartitionTraverser):Void
	{
		// todo: dead end for now, if it has a debug mesh, then sure accept that
	}
}