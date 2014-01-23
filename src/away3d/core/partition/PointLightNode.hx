/**
 * LightNode is a space partitioning leaf node that contains a LightBase object.
 */
package away3d.core.partition;

import away3d.core.traverse.PartitionTraverser;
import away3d.lights.PointLight;

class PointLightNode extends EntityNode {
    public var light(get_light, never):PointLight;

    private var _light:PointLight;
/**
	 * Creates a new LightNode object.
	 * @param light The light to be contained in the node.
	 */

    public function new(light:PointLight) {
        super(light);
        _light = light;
    }

/**
	 * The light object contained in this node.
	 */

    public function get_light():PointLight {
        return _light;
    }

/**
	 * @inheritDoc
	 */

    override public function acceptTraverser(traverser:PartitionTraverser):Void {
        if (traverser.enterNode(this)) {
            super.acceptTraverser(traverser);
            traverser.applyPointLight(_light);
        }
    }

}

