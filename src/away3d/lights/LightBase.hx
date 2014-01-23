/**
 * LightBase provides an abstract base class for subtypes representing lights.
 */
package away3d.lights;


import away3d.core.base.IRenderable;
import away3d.core.partition.EntityNode;
import away3d.core.partition.LightNode;
import away3d.entities.Entity;
import away3d.errors.AbstractMethodError;
import away3d.events.LightEvent;
import away3d.library.assets.AssetType;
import away3d.lights.shadowmaps.ShadowMapperBase;
import flash.geom.Matrix3D;

class LightBase extends Entity {
    public var castsShadows(get_castsShadows, set_castsShadows):Bool;
    public var specular(get_specular, set_specular):Float;
    public var diffuse(get_diffuse, set_diffuse):Float;
    public var color(get_color, set_color):Int;
    public var ambient(get_ambient, set_ambient):Float;
    public var ambientColor(get_ambientColor, set_ambientColor):Int;
    public var shadowMapper(get_shadowMapper, set_shadowMapper):ShadowMapperBase;

    private var _color:Int;
    private var _colorR:Float;
    private var _colorG:Float;
    private var _colorB:Float;
    public var _ambientColor:Int;
    public var _ambient:Float;
    public var _ambientR:Float;
    public var _ambientG:Float;
    public var _ambientB:Float;
    public var _specular:Float;
    public var _specularR:Float;
    public var _specularG:Float;
    public var _specularB:Float;
    public var _diffuse:Float;
    public var _diffuseR:Float;
    public var _diffuseG:Float;
    public var _diffuseB:Float;
    public var _castsShadows:Bool;
    public var _shadowMapper:ShadowMapperBase;
/**
	 * Create a new LightBase object.
	 * @param positionBased Indicates whether or not the light has a valid position, or is "infinite" such as a DirectionalLight.
	 */

    public function new() {
        _color = 0xffffff;
        _colorR = 1;
        _colorG = 1;
        _colorB = 1;
        _ambientColor = 0xffffff;
        _ambient = 0;
        _ambientR = 0;
        _ambientG = 0;
        _ambientB = 0;
        _specular = 1;
        _specularR = 1;
        _specularG = 1;
        _specularB = 1;
        _diffuse = 1;
        _diffuseR = 1;
        _diffuseG = 1;
        _diffuseB = 1;
        super();
    }

    public function get_castsShadows():Bool {
        return _castsShadows;
    }

    public function set_castsShadows(value:Bool):Bool {
        if (_castsShadows == value) return value;
        _castsShadows = value;
        if (value) {
            if (_shadowMapper == null)
                _shadowMapper = createShadowMapper();
            _shadowMapper.light = this;
        }

        else {
            _shadowMapper.dispose();
            _shadowMapper = null;
        }

        dispatchEvent(new LightEvent(LightEvent.CASTS_SHADOW_CHANGE));
        return value;
    }

    private function createShadowMapper():ShadowMapperBase {
        throw new AbstractMethodError();
        return null;
    }

/**
	 * The specular emission strength of the light. Default value is <code>1</code>.
	 */

    public function get_specular():Float {
        return _specular;
    }

    public function set_specular(value:Float):Float {
        if (value < 0) value = 0;
        _specular = value;
        updateSpecular();
        return value;
    }

/**
	 * The diffuse emission strength of the light. Default value is <code>1</code>.
	 */

    public function get_diffuse():Float {
        return _diffuse;
    }

    public function set_diffuse(value:Float):Float {
        if (value < 0) value = 0;
        _diffuse = value;
        updateDiffuse();
        return value;
    }

/**
	 * The color of the light. Default value is <code>0xffffff</code>.
	 */

    public function get_color():Int {
        return _color;
    }

    public function set_color(value:Int):Int {
        _color = value;
        _colorR = ((_color >> 16) & 0xff) / 0xff;
        _colorG = ((_color >> 8) & 0xff) / 0xff;
        _colorB = (_color & 0xff) / 0xff;
        updateDiffuse();
        updateSpecular();
        return value;
    }

/**
	 * The ambient emission strength of the light. Default value is <code>0</code>.
	 */

    public function get_ambient():Float {
        return _ambient;
    }

    public function set_ambient(value:Float):Float {
        if (value < 0) value = 0
        else if (value > 1) value = 1;
        _ambient = value;
        updateAmbient();
        return value;
    }

    public function get_ambientColor():Int {
        return _ambientColor;
    }

/**
	 * The ambient emission colour of the light. Default value is <code>0xffffff</code>.
	 */

    public function set_ambientColor(value:Int):Int {
        _ambientColor = value;
        updateAmbient();
        return value;
    }

    private function updateAmbient():Void {
        _ambientR = ((_ambientColor >> 16) & 0xff) / 0xff * _ambient;
        _ambientG = ((_ambientColor >> 8) & 0xff) / 0xff * _ambient;
        _ambientB = (_ambientColor & 0xff) / 0xff * _ambient;
    }

/**
	 * Gets the optimal projection matrix to render a light-based depth map for a single object.
	 * @param renderable The IRenderable object to render to a depth map.
	 * @param target An optional target Matrix3D object. If not provided, an instance will be created.
	 * @return A Matrix3D object containing the projection transformation.
	 */

    public function getObjectProjectionMatrix(renderable:IRenderable, target:Matrix3D = null):Matrix3D {
        throw new AbstractMethodError();
        return null;
    }

/**
	 * @inheritDoc
	 */

    override private function createEntityPartitionNode():EntityNode {
        return new LightNode(this);
    }

/**
	 * @inheritDoc
	 */

    override public function get_assetType():String {
        return AssetType.LIGHT;
    }

/**
	 * Updates the total specular components of the light.
	 */

    private function updateSpecular():Void {
        _specularR = _colorR * _specular;
        _specularG = _colorG * _specular;
        _specularB = _colorB * _specular;
    }

/**
	 * Updates the total diffuse components of the light.
	 */

    private function updateDiffuse():Void {
        _diffuseR = _colorR * _diffuse;
        _diffuseG = _colorG * _diffuse;
        _diffuseB = _colorB * _diffuse;
    }

    public function get_shadowMapper():ShadowMapperBase {
        return _shadowMapper;
    }

    public function set_shadowMapper(value:ShadowMapperBase):ShadowMapperBase {
        _shadowMapper = value;
        _shadowMapper.light = this;
        return value;
    }

}

