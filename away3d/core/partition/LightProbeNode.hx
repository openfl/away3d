package away3d.core.partition;

import away3d.core.traverse.PartitionTraverser;
import away3d.lights.LightProbe;

/**
 * LightNode is a space partitioning leaf node that contains a LightBase object.
 */
class LightProbeNode extends EntityNode
{
	public var light(get, never):LightProbe;
	
	private var _light:LightProbe;
	
	/**
	 * Creates a new LightNode object.
	 * @param light The light to be contained in the node.
	 */
	public function new(light:LightProbe)
	{
		super(light);
		_light = light;
	}
	
	/**
	 * The light object contained in this node.
	 */
	private function get_light():LightProbe
	{
		return _light;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function acceptTraverser(traverser:PartitionTraverser):Void
	{
		if (traverser.enterNode(this)) {
			super.acceptTraverser(traverser);
			traverser.applyLightProbe(_light);
		}
	}
}