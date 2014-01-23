/**
 * ShadowMapMethodBase provides an abstract base method for shadow map methods.
 */
package away3d.materials.methods;


import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.errors.AbstractMethodError;
import away3d.library.assets.AssetType;
import away3d.library.assets.IAsset;
import away3d.lights.shadowmaps.ShadowMapperBase;
import away3d.lights.LightBase;
class ShadowMapMethodBase extends ShadingMethodBase implements IAsset {
    public var assetType(get_assetType, never):String;
    public var alpha(get_alpha, set_alpha):Float;
    public var castingLight(get_castingLight, never):LightBase;
    public var epsilon(get_epsilon, set_epsilon):Float;

    private var _castingLight:LightBase;
    private var _shadowMapper:ShadowMapperBase;
    private var _epsilon:Float;
    private var _alpha:Float;
/**
	 * Creates a new ShadowMapMethodBase object.
	 * @param castingLight The light used to cast shadows.
	 */

    public function new(castingLight:LightBase) {
        _epsilon = .02;
        _alpha = 1;
        super();
        _castingLight = castingLight;
        castingLight.castsShadows = true;
        _shadowMapper = castingLight.shadowMapper;
    }

/**
	 * @inheritDoc
	 */

    public function get_assetType():String {
        return AssetType.SHADOW_MAP_METHOD;
    }

/**
	 * The "transparency" of the shadows. This allows making shadows less strong.
	 */

    public function get_alpha():Float {
        return _alpha;
    }

    public function set_alpha(value:Float):Float {
        _alpha = value;
        return value;
    }

/**
	 * The light casting the shadows.
	 */

    public function get_castingLight():LightBase {
        return _castingLight;
    }

/**
	 * A small value to counter floating point precision errors when comparing values in the shadow map with the
	 * calculated depth value. Increase this if shadow banding occurs, decrease it if the shadow seems to be too detached.
	 */

    public function get_epsilon():Float {
        return _epsilon;
    }

    public function set_epsilon(value:Float):Float {
        _epsilon = value;
        return value;
    }

/**
	 * @inheritDoc
	 */

    public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String {
        throw new AbstractMethodError();
        return null;
    }

}

