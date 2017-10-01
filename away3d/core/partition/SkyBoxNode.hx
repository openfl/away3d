package away3d.core.partition;

import away3d.core.math.Plane3D;
import away3d.core.traverse.PartitionTraverser;
import away3d.primitives.SkyBox;

import openfl.Vector;

/**
 * SkyBoxNode is a space partitioning leaf node that contains a SkyBox object.
 */
class SkyBoxNode extends EntityNode
{
	private var _skyBox:SkyBox;
	
	/**
	 * Creates a new SkyBoxNode object.
	 * @param skyBox The SkyBox to be contained in the node.
	 */
	public function new(skyBox:SkyBox)
	{
		super(skyBox);
		_skyBox = skyBox;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function acceptTraverser(traverser:PartitionTraverser):Void
	{
		if (traverser.enterNode(this)) {
			super.acceptTraverser(traverser);
			traverser.applySkyBox(_skyBox);
		}
	}
	
	override public function isInFrustum(planes:Vector<Plane3D>, numPlanes:Int):Bool
	{
		return true;
	}
}