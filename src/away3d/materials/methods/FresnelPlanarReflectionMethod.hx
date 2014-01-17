/**
 * FresnelPlanarReflectionMethod provides a method to add fresnel-based planar reflections from a
 * PlanarReflectionTexture object.to a surface, which get stronger as the viewing angle becomes more grazing. This
 * method can be used for (near-)planar objects such as mirrors or water.
 *
 * @see away3d.textures.PlanarReflectionTexture
 */
package away3d.materials.methods;


import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.textures.PlanarReflectionTexture;

class FresnelPlanarReflectionMethod extends EffectMethodBase {
    public var alpha(get_alpha, set_alpha):Float;
    public var fresnelPower(get_fresnelPower, set_fresnelPower):Float;
    public var normalReflectance(get_normalReflectance, set_normalReflectance):Float;
    public var texture(get_texture, set_texture):PlanarReflectionTexture;
    public var normalDisplacement(get_normalDisplacement, set_normalDisplacement):Float;

    private var _texture:PlanarReflectionTexture;
    private var _alpha:Float;
    private var _normalDisplacement:Float;
    private var _normalReflectance:Float;
    private var _fresnelPower:Float;
/**
	 * Creates a new FresnelPlanarReflectionMethod object.
	 * @param texture The PlanarReflectionTexture containing a render of the mirrored scene.
	 * @param alpha The maximum reflectivity of the surface.
	 *
	 * @see away3d.textures.PlanarReflectionTexture
	 */

    public function new(texture:PlanarReflectionTexture, alpha:Float = 1) {
        _alpha = 1;
        _normalDisplacement = 0;
        _normalReflectance = 0;
        _fresnelPower = 5;
        super();
        _texture = texture;
        _alpha = alpha;
    }

/**
	 * The reflectivity of the surface.
	 */

    public function get_alpha():Float {
        return _alpha;
    }

    public function set_alpha(value:Float):Float {
        _alpha = value;
        return value;
    }

/**
	 * The power used in the Fresnel equation. Higher values make the fresnel effect more pronounced. Defaults to 5.
	 */

    public function get_fresnelPower():Float {
        return _fresnelPower;
    }

    public function set_fresnelPower(value:Float):Float {
        _fresnelPower = value;
        return value;
    }

/**
	 * The minimum amount of reflectance, ie the reflectance when the view direction is normal to the surface or light direction.
	 */

    public function get_normalReflectance():Float {
        return _normalReflectance;
    }

    public function set_normalReflectance(value:Float):Float {
        _normalReflectance = value;
        return value;
    }

/**
	 * @inheritDoc
	 */

    override public function initVO(vo:MethodVO):Void {
        vo.needsProjection = true;
        vo.needsNormals = true;
        vo.needsView = true;
    }

/**
	 * The PlanarReflectionTexture containing a render of the mirrored scene.
	 *
	 * @see away3d.textures.PlanarReflectionTexture
	 */

    public function get_texture():PlanarReflectionTexture {
        return _texture;
    }

    public function set_texture(value:PlanarReflectionTexture):PlanarReflectionTexture {
        _texture = value;
        return value;
    }

/**
	 * The amount of displacement caused by per-pixel normals.
	 */

    public function get_normalDisplacement():Float {
        return _normalDisplacement;
    }

    public function set_normalDisplacement(value:Float):Float {
        if (_normalDisplacement == value) return value;
        if (_normalDisplacement == 0 || value == 0) invalidateShaderProgram();
        _normalDisplacement = value;
        return value;
    }

/**
	 * @inheritDoc
	 */

    override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void {
        stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
        vo.fragmentData[vo.fragmentConstantsIndex] = _texture.textureRatioX * .5;
        vo.fragmentData[vo.fragmentConstantsIndex + 1] = _texture.textureRatioY * .5;
        vo.fragmentData[vo.fragmentConstantsIndex + 3] = _alpha;
        vo.fragmentData[vo.fragmentConstantsIndex + 4] = _normalReflectance;
        vo.fragmentData[vo.fragmentConstantsIndex + 5] = _fresnelPower;
        if (_normalDisplacement > 0) {
            vo.fragmentData[vo.fragmentConstantsIndex + 2] = _normalDisplacement;
            vo.fragmentData[vo.fragmentConstantsIndex + 6] = .5 + _texture.textureRatioX * .5 - 1 / _texture.width;
            vo.fragmentData[vo.fragmentConstantsIndex + 7] = .5 - _texture.textureRatioX * .5 + 1 / _texture.width;
        }
    }

/**
	 * @inheritDoc
	 */

    override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String {
        var textureReg:ShaderRegisterElement = regCache.getFreeTextureReg();
        var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
        var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
        var dataReg2:ShaderRegisterElement = regCache.getFreeFragmentConstant();
        var filter:String = (vo.useSmoothTextures) ? "linear" : "nearest";
        var code:String;
        vo.texturesIndex = textureReg.index;
        vo.fragmentConstantsIndex = dataReg.index * 4;
// fc0.x = .5
        var projectionReg:ShaderRegisterElement = _sharedRegisters.projectionFragment;
        var normalReg:ShaderRegisterElement = _sharedRegisters.normalFragment;
        var viewDirReg:ShaderRegisterElement = _sharedRegisters.viewDirFragment;
        code = "div " + temp + ", " + projectionReg + ", " + projectionReg + ".w\n" + "mul " + temp + ", " + temp + ", " + dataReg + ".xyww\n" + "add " + temp + ".xy, " + temp + ".xy, fc0.xx\n";
        if (_normalDisplacement > 0) {
            code += "add " + temp + ".w, " + projectionReg + ".w, " + "fc0.w\n" + "sub " + temp + ".z, fc0.w, " + normalReg + ".y\n" + "div " + temp + ".z, " + temp + ".z, " + temp + ".w\n" + "mul " + temp + ".z, " + dataReg + ".z, " + temp + ".z\n" + "add " + temp + ".x, " + temp + ".x, " + temp + ".z\n" + "min " + temp + ".x, " + temp + ".x, " + dataReg2 + ".z\n" + "max " + temp + ".x, " + temp + ".x, " + dataReg2 + ".w\n";
        }
        code += "tex " + temp + ", " + temp + ", " + textureReg + " <2d," + filter + ">\n" + "sub " + viewDirReg + ".w, " + temp + ".w,  fc0.x\n" + "kil " + viewDirReg + ".w\n";
// calculate fresnel term
        code += "dp3 " + viewDirReg + ".w, " + viewDirReg + ".xyz, " + normalReg + ".xyz\n" + // dot(V, H)

        "sub " + viewDirReg + ".w, fc0.w, " + viewDirReg + ".w\n" + // base = 1-dot(V, H)

        "pow " + viewDirReg + ".w, " + viewDirReg + ".w, " + dataReg2 + ".y\n" + // exp = pow(base, 5)

        "sub " + normalReg + ".w, fc0.w, " + viewDirReg + ".w\n" + // 1 - exp

        "mul " + normalReg + ".w, " + dataReg2 + ".x, " + normalReg + ".w\n" + // f0*(1 - exp)

        "add " + viewDirReg + ".w, " + viewDirReg + ".w, " + normalReg + ".w\n" + // exp + f0*(1 - exp)

// total alpha
        "mul " + viewDirReg + ".w, " + dataReg + ".w, " + viewDirReg + ".w\n" + "sub " + temp + ", " + temp + ", " + targetReg + "\n" + "mul " + temp + ", " + temp + ", " + viewDirReg + ".w\n" + "add " + targetReg + ", " + targetReg + ", " + temp + "\n";
        return code;
    }

}

