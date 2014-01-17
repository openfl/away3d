package away3d.lights;


import flash.errors.Error;
import away3d.bounds.BoundingVolumeBase;
import away3d.bounds.NullBounds;
import away3d.core.base.IRenderable;
import away3d.core.partition.EntityNode;
import away3d.core.partition.LightProbeNode;
import away3d.textures.CubeTextureBase;
import flash.geom.Matrix3D;

class LightProbe extends LightBase {
    public var diffuseMap(get_diffuseMap, set_diffuseMap):CubeTextureBase;
    public var specularMap(get_specularMap, set_specularMap):CubeTextureBase;

    private var _diffuseMap:CubeTextureBase;
    private var _specularMap:CubeTextureBase;
/**
	 * Creates a new LightProbe object.
	 */

    public function new(diffuseMap:CubeTextureBase, specularMap:CubeTextureBase = null) {
        super();
        _diffuseMap = diffuseMap;
        _specularMap = specularMap;
    }

    override private function createEntityPartitionNode():EntityNode {
        return new LightProbeNode(this);
    }

    public function get_diffuseMap():CubeTextureBase {
        return _diffuseMap;
    }

    public function set_diffuseMap(value:CubeTextureBase):CubeTextureBase {
        _diffuseMap = value;
        return value;
    }

    public function get_specularMap():CubeTextureBase {
        return _specularMap;
    }

    public function set_specularMap(value:CubeTextureBase):CubeTextureBase {
        _specularMap = value;
        return value;
    }

/**
	 * @inheritDoc
	 */

    override private function updateBounds():Void {
//			super.updateBounds();
        _boundsInvalid = false;
    }

/**
	 * @inheritDoc
	 */

    override private function getDefaultBoundingVolume():BoundingVolumeBase {
// todo: consider if this can be culled?
        return new NullBounds();
    }

/**
	 * @inheritDoc
	 */

    override public function getObjectProjectionMatrix(renderable:IRenderable, target:Matrix3D = null):Matrix3D {
// TODO: not used

        throw new Error("Object projection matrices are not supported for LightProbe objects!");
        return null;
    }

}

