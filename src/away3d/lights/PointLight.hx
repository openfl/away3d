/**
 * PointLight represents an omni-directional light. The light is emitted from a given position in the scene.
 */
package away3d.lights;


import flash.Vector;
import away3d.bounds.BoundingSphere;
import away3d.bounds.BoundingVolumeBase;
import away3d.core.base.IRenderable;
import away3d.core.math.Matrix3DUtils;
import away3d.core.partition.EntityNode;
import away3d.core.partition.PointLightNode;
import away3d.lights.shadowmaps.CubeMapShadowMapper;
import away3d.lights.shadowmaps.ShadowMapperBase;
import flash.geom.Matrix3D;
import flash.geom.Vector3D; 
class PointLight extends LightBase {
    public var radius(get_radius, set_radius):Float;
    public var fallOff(get_fallOff, set_fallOff):Float;

//private static var _pos : Vector3D = new Vector3D();
    public var _radius:Float;
    public var _fallOff:Float;
    public var _fallOffFactor:Float;
/**
	 * Creates a new PointLight object.
	 */

    public function new() {
        _radius = 90000;
        _fallOff = 100000;
        super();
        _fallOffFactor = 1 / (_fallOff * _fallOff - _radius * _radius);
    }

    override private function createShadowMapper():ShadowMapperBase {
        return new CubeMapShadowMapper();
    }

    override private function createEntityPartitionNode():EntityNode {
        return new PointLightNode(this);
    }

/**
	 * The minimum distance of the light's reach.
	 */

    public function get_radius():Float {
        return _radius;
    }

    public function set_radius(value:Float):Float {
        _radius = value;
        if (_radius < 0) _radius = 0
        else if (_radius > _fallOff) {
            _fallOff = _radius;
            invalidateBounds();
        }
        _fallOffFactor = 1 / (_fallOff * _fallOff - _radius * _radius);
        return value;
    }

    private function fallOffFactor():Float {
        return _fallOffFactor;
    }

/**
	 * The maximum distance of the light's reach
	 */

    public function get_fallOff():Float {
        return _fallOff;
    }

    public function set_fallOff(value:Float):Float {
        _fallOff = value;
        if (_fallOff < 0) _fallOff = 0;
        if (_fallOff < _radius) _radius = _fallOff;
        _fallOffFactor = 1 / (_fallOff * _fallOff - _radius * _radius);
        invalidateBounds();
        return value;
    }

/**
	 * @inheritDoc
	 */

    override private function updateBounds():Void {
//			super.updateBounds();
//			_bounds.fromExtremes(-_fallOff, -_fallOff, -_fallOff, _fallOff, _fallOff, _fallOff);
        _bounds.fromSphere(new Vector3D(), _fallOff);
        _boundsInvalid = false;
    }

/**
	 * @inheritDoc
	 */

    override private function getDefaultBoundingVolume():BoundingVolumeBase {
        return new BoundingSphere();
    }

/**
	 * @inheritDoc
	 */

    override public function getObjectProjectionMatrix(renderable:IRenderable, target:Matrix3D = null):Matrix3D {
        var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
        var bounds:BoundingVolumeBase = renderable.sourceEntity.bounds;
        var m:Matrix3D = new Matrix3D();
// todo: do not use lookAt on Light
        m.copyFrom(renderable.sceneTransform);
        m.append(_parent.inverseSceneTransform);
        lookAt(m.position);
        m.copyFrom(renderable.sceneTransform);
        m.append(inverseSceneTransform);
        m.copyColumnTo(3, _pos);
        var v1:Vector3D = m.deltaTransformVector(bounds.min);
        var v2:Vector3D = m.deltaTransformVector(bounds.max);
        var z:Float = _pos.z;
        var d1:Float = v1.x * v1.x + v1.y * v1.y + v1.z * v1.z;
        var d2:Float = v2.x * v2.x + v2.y * v2.y + v2.z * v2.z;
        var d:Float = Math.sqrt(d1 > (d2) ? d1 : d2);
        var zMin:Float;
        var zMax:Float;
        zMin = z - d;
        zMax = z + d;
        raw[(5)] = raw[(0)] = zMin / d;
        raw[(10)] = zMax / (zMax - zMin);
        raw[(11)] = 1;
        raw[(1)] = raw[(2)] = raw[(3)] = raw[(4)] = raw[(6)] = raw[(7)] = raw[(8)] = raw[(9)] = raw[(12)] = raw[(13)] = raw[(15)] = 0;
        raw[(14)] = -zMin * raw[(10)];
        if (target == null)
            target = new Matrix3D();
        target.copyRawDataFrom(raw);
        target.prepend(m);
        return target;
    }

}

