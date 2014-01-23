/**
 * FresnelEnvMapMethod provides a method to add fresnel-based reflectivity to an object using cube maps, which gets
 * stronger as the viewing angle becomes more grazing.
 */
package away3d.materials.methods;


import flash.Vector;
import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.textures.CubeTextureBase;
import away3d.textures.Texture2DBase;
import flash.display3D.Context3D;

class FresnelEnvMapMethod extends EffectMethodBase {
    public var mask(get_mask, set_mask):Texture2DBase;
    public var fresnelPower(get_fresnelPower, set_fresnelPower):Float;
    public var envMap(get_envMap, set_envMap):CubeTextureBase;
    public var alpha(get_alpha, set_alpha):Float;
    public var normalReflectance(get_normalReflectance, set_normalReflectance):Float;

    private var _cubeTexture:CubeTextureBase;
    private var _fresnelPower:Float;
    private var _normalReflectance:Float;
    private var _alpha:Float;
    private var _mask:Texture2DBase;
/**
	 * Creates an FresnelEnvMapMethod object.
	 * @param envMap The environment map containing the reflected scene.
	 * @param alpha The reflectivity of the material.
	 */

    public function new(envMap:CubeTextureBase, alpha:Float = 1) {
        _fresnelPower = 5;
        _normalReflectance = 0;
        super();
        _cubeTexture = envMap;
        _alpha = alpha;
    }

/**
	 * @inheritDoc
	 */

    override public function initVO(vo:MethodVO):Void {
        vo.needsNormals = true;
        vo.needsView = true;
        vo.needsUV = _mask != null;
    }

/**
	 * @inheritDoc
	 */

    override public function initConstants(vo:MethodVO):Void {
        vo.fragmentData[vo.fragmentConstantsIndex + 3] = 1;
    }

/**
	 * An optional texture to modulate the reflectivity of the surface.
	 */

    public function get_mask():Texture2DBase {
        return _mask;
    }

    public function set_mask(value:Texture2DBase):Texture2DBase {
        if (cast((value != null), Bool) != cast((_mask != null), Bool) || (value != null && _mask != null && (value.hasMipMaps != _mask.hasMipMaps || value.format != _mask.format))) {
            invalidateShaderProgram();
        }
        _mask = value;
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
	 * The cubic environment map containing the reflected scene.
	 */

    public function get_envMap():CubeTextureBase {
        return _cubeTexture;
    }

    public function set_envMap(value:CubeTextureBase):CubeTextureBase {
        _cubeTexture = value;
        return value;
    }

/**
	 * @inheritDoc
	 */

    override public function dispose():Void {
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

    override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void {
        var data:Vector<Float> = vo.fragmentData;
        var index:Int = vo.fragmentConstantsIndex;
        var context:Context3D = stage3DProxy._context3D;
        data[index] = _alpha;
        data[index + 1] = _normalReflectance;
        data[index + 2] = _fresnelPower;
        context.setTextureAt(vo.texturesIndex, _cubeTexture.getTextureForStage3D(stage3DProxy));
        if (_mask != null) context.setTextureAt(vo.texturesIndex + 1, _mask.getTextureForStage3D(stage3DProxy));
    }

/**
	 * @inheritDoc
	 */

    override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String {
        var dataRegister:ShaderRegisterElement = regCache.getFreeFragmentConstant();
        var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
        var code:String = "";
        var cubeMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
        var viewDirReg:ShaderRegisterElement = _sharedRegisters.viewDirFragment;
        var normalReg:ShaderRegisterElement = _sharedRegisters.normalFragment;
        vo.texturesIndex = cubeMapReg.index;
        vo.fragmentConstantsIndex = dataRegister.index * 4;
        regCache.addFragmentTempUsages(temp, 1);
        var temp2:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
// r = V - 2(V.N)*N
        code += "dp3 " + temp + ".w, " + viewDirReg + ".xyz, " + normalReg + ".xyz		\n" + "add " + temp + ".w, " + temp + ".w, " + temp + ".w											\n" + "mul " + temp + ".xyz, " + normalReg + ".xyz, " + temp + ".w						\n" + "sub " + temp + ".xyz, " + temp + ".xyz, " + viewDirReg + ".xyz					\n" + getTexCubeSampleCode(vo, temp, cubeMapReg, _cubeTexture, temp) + "sub " + temp2 + ".w, " + temp + ".w, fc0.x									\n" + // -.5

        "kil " + temp2 + ".w\n" + // used for real time reflection mapping - if alpha is not 1 (mock texture) kil output

        "sub " + temp + ", " + temp + ", " + targetReg + "											\n";
// calculate fresnel term
        code += "dp3 " + viewDirReg + ".w, " + viewDirReg + ".xyz, " + normalReg + ".xyz\n" + // dot(V, H)

        "sub " + viewDirReg + ".w, " + dataRegister + ".w, " + viewDirReg + ".w\n" + // base = 1-dot(V, H)
        "pow " + viewDirReg + ".w, " + viewDirReg + ".w, " + dataRegister + ".z\n" + // exp = pow(base, 5)

        "sub " + normalReg + ".w, " + dataRegister + ".w, " + viewDirReg + ".w\n" + // 1 - exp

        "mul " + normalReg + ".w, " + dataRegister + ".y, " + normalReg + ".w\n" + // f0*(1 - exp)

        "add " + viewDirReg + ".w, " + viewDirReg + ".w, " + normalReg + ".w\n" + // exp + f0*(1 - exp)

// total alpha
        "mul " + viewDirReg + ".w, " + dataRegister + ".x, " + viewDirReg + ".w\n";
        if (_mask != null) {
            var maskReg:ShaderRegisterElement = regCache.getFreeTextureReg();
            code += getTex2DSampleCode(vo, temp2, maskReg, _mask, _sharedRegisters.uvVarying) + "mul " + viewDirReg + ".w, " + temp2 + ".x, " + viewDirReg + ".w\n";
        }
        code += "mul " + temp + ", " + temp + ", " + viewDirReg + ".w						\n" + "add " + targetReg + ", " + targetReg + ", " + temp + "						\n";
        regCache.removeFragmentTempUsage(temp);
        return code;
    }

}

