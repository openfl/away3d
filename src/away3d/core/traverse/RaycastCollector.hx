/**
 * The RaycastCollector class is a traverser for scene partitions that collects all scene graph entities that are
 * considered intersecting with the defined ray.
 *
 * @see away3d.partition.Partition3D
 * @see away3d.partition.Entity
 */
package away3d.core.traverse;


import away3d.core.base.IRenderable;
import away3d.core.partition.NodeBase;
import away3d.lights.LightBase;
import flash.geom.Vector3D;

class RaycastCollector extends EntityCollector {
    public var rayPosition(get_rayPosition, set_rayPosition):Vector3D;
    public var rayDirection(get_rayDirection, set_rayDirection):Vector3D;

    private var _rayPosition:Vector3D;
    private var _rayDirection:Vector3D;
/**
	 * Creates a new RaycastCollector object.
	 */

    public function new() {
        _rayPosition = new Vector3D();
        _rayDirection = new Vector3D();
        super();
    }

/**
	 * Provides the starting position of the ray.
	 */

    public function get_rayPosition():Vector3D {
        return _rayPosition;
    }

    public function set_rayPosition(value:Vector3D):Vector3D {
        _rayPosition = value;
        return value;
    }

/**
	 * Provides the direction vector of the ray.
	 */

    public function get_rayDirection():Vector3D {
        return _rayDirection;
    }

    public function set_rayDirection(value:Vector3D):Vector3D {
        _rayDirection = value;
        return value;
    }

/**
	 * Returns true if the current node is at least partly in the frustum. If so, the partition node knows to pass on the traverser to its children.
	 *
	 * @param node The Partition3DNode object to frustum-test.
	 */

    override public function enterNode(node:NodeBase):Bool {
        return node.isIntersectingRay(_rayPosition, _rayDirection);
    }

/**
	 * @inheritDoc
	 */

    override public function applySkyBox(renderable:IRenderable):Void {
    }

/**
	 * Adds an IRenderable object to the potentially visible objects.
	 * @param renderable The IRenderable object to add.
	 */

    override public function applyRenderable(renderable:IRenderable):Void {
    }

/**
	 * @inheritDoc
	 */

    override public function applyUnknownLight(light:LightBase):Void {
    }

}

