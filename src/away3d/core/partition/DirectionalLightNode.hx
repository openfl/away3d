/**
 * LightNode is a space partitioning leaf node that contains a LightBase object.
 */
package away3d.core.partition;

import away3d.core.traverse.PartitionTraverser;
import away3d.lights.DirectionalLight;

class DirectionalLightNode extends EntityNode {
    public var light(get_light, never):DirectionalLight;

    private var _light:DirectionalLight;
/**
	 * Creates a new LightNode object.
	 * @param light The light to be contained in the node.
	 */

    public function new(light:DirectionalLight) {
        super(light);
        _light = light;
    }

/**
	 * The light object contained in this node.
	 */

    public function get_light():DirectionalLight {
        return _light;
    }

/**
	 * @inheritDoc
	 */

    override public function acceptTraverser(traverser:PartitionTraverser):Void {
        if (traverser.enterNode(this)) {
            super.acceptTraverser(traverser);
            traverser.applyDirectionalLight(_light);
        }
    }

}

