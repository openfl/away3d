/**
 * BasicDiffuseMethod provides the default shading method for Lambert (dot3) diffuse lighting.
 */
package away3d.materials.methods;


import flash.Vector;
import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.textures.Texture2DBase;

class BasicDiffuseMethod extends LightingMethodBase {
    public var useAmbientTexture(get_useAmbientTexture, set_useAmbientTexture):Bool;
    public var diffuseAlpha(get_diffuseAlpha, set_diffuseAlpha):Float;
    public var diffuseColor(get_diffuseColor, set_diffuseColor):Int;
    public var texture(get_texture, set_texture):Texture2DBase;
    public var alphaThreshold(get_alphaThreshold, set_alphaThreshold):Float;
    public var shadowRegister(never, set_shadowRegister):ShaderRegisterElement;

    private var _useAmbientTexture:Bool;
    private var _useTexture:Bool;
    public var _totalLightColorReg:ShaderRegisterElement;
// TODO: are these registers at all necessary to be members?
    private var _diffuseInputRegister:ShaderRegisterElement;
    private var _texture:Texture2DBase;
    private var _diffuseColor:Int;
    private var _diffuseR:Float;
    private var _diffuseG:Float;
    private var _diffuseB:Float;
    private var _diffuseA:Float;
    private var _shadowRegister:ShaderRegisterElement;
    private var _alphaThreshold:Float;
    private var _isFirstLight:Bool;
/**
	 * Creates a new BasicDiffuseMethod object.
	 */

    public function new() {
        _diffuseColor = 0xffffff;
        _diffuseR = 1;
        _diffuseG = 1;
        _diffuseB = 1;
        _diffuseA = 1;
        _alphaThreshold = 0;
        super();
    }

/**
	 * Set internally if the ambient method uses a texture.
	 */

    private function get_useAmbientTexture():Bool {
        return _useAmbientTexture;
    }

    private function set_useAmbientTexture(value:Bool):Bool {
        if (_useAmbientTexture == value) return value;
        _useAmbientTexture = value;
        invalidateShaderProgram();
        return value;
    }

    override public function initVO(vo:MethodVO):Void {
        vo.needsUV = _useTexture;
        vo.needsNormals = vo.numLights > 0;
    }

/**
	 * Forces the creation of the texture.
	 * @param stage3DProxy The Stage3DProxy used by the renderer
	 */

    public function generateMip(stage3DProxy:Stage3DProxy):Void {
        if (_useTexture) _texture.getTextureForStage3D(stage3DProxy);
    }

/**
	 * The alpha component of the diffuse reflection.
	 */

    public function get_diffuseAlpha():Float {
        return _diffuseA;
    }

    public function set_diffuseAlpha(value:Float):Float {
        _diffuseA = value;
        return value;
    }

/**
	 * The color of the diffuse reflection when not using a texture.
	 */

    public function get_diffuseColor():Int {
        return _diffuseColor;
    }

    public function set_diffuseColor(diffuseColor:Int):Int {
        _diffuseColor = diffuseColor;
        updateDiffuse();
        return diffuseColor;
    }

/**
	 * The bitmapData to use to define the diffuse reflection color per texel.
	 */

    public function get_texture():Texture2DBase {
        return _texture;
    }

    public function set_texture(value:Texture2DBase):Texture2DBase {
        if (cast((value != null), Bool) != _useTexture || (value != null && _texture != null && (value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format))) {
            invalidateShaderProgram();
        }
        _useTexture = cast((value!=null), Bool);
        _texture = value;
        return value;
    }

/**
	 * The minimum alpha value for which pixels should be drawn. This is used for transparency that is either
	 * invisible or entirely opaque, often used with textures for foliage, etc.
	 * Recommended values are 0 to disable alpha, or 0.5 to create smooth edges. Default value is 0 (disabled).
	 */

    public function get_alphaThreshold():Float {
        return _alphaThreshold;
    }

    public function set_alphaThreshold(value:Float):Float {
        if (value < 0) value = 0
        else if (value > 1) value = 1;
        if (value == _alphaThreshold) return value;
        if (value == 0 || _alphaThreshold == 0) invalidateShaderProgram();
        _alphaThreshold = value;
        return value;
    }

/**
	 * @inheritDoc
	 */

    override public function dispose():Void {
        _texture = null;
    }

/**
	 * @inheritDoc
	 */

    override public function copyFrom(method:ShadingMethodBase):Void {
        var diff:BasicDiffuseMethod = cast((method), BasicDiffuseMethod);
        alphaThreshold = diff.alphaThreshold;
        texture = diff.texture;
        useAmbientTexture = diff.useAmbientTexture;
        diffuseAlpha = diff.diffuseAlpha;
        diffuseColor = diff.diffuseColor;
    }

/**
	 * @inheritDoc
	 */

    override public function cleanCompilationData():Void {
        super.cleanCompilationData();
        _shadowRegister = null;
        _totalLightColorReg = null;
        _diffuseInputRegister = null;
    }

/**
	 * @inheritDoc
	 */

    override public function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String {
        var code:String = "";
        _isFirstLight = true;
        if (vo.numLights > 0) {
            _totalLightColorReg = regCache.getFreeFragmentVectorTemp();
            regCache.addFragmentTempUsages(_totalLightColorReg, 1);
        }
        return code;
    }

/**
	 * @inheritDoc
	 */

    override public function getFragmentCodePerLight(vo:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String {
        var code:String = "";
        var t:ShaderRegisterElement;
// write in temporary if not first light, so we can add to total diffuse colour
        if (_isFirstLight) t = _totalLightColorReg
        else {
            t = regCache.getFreeFragmentVectorTemp();
            regCache.addFragmentTempUsages(t, 1);
        }

        code += "dp3 " + t + ".x, " + lightDirReg + ", " + _sharedRegisters.normalFragment + "\n" + "max " + t + ".w, " + t + ".x, " + _sharedRegisters.commons + ".y\n";
        if (vo.useLightFallOff) code += "mul " + t + ".w, " + t + ".w, " + lightDirReg + ".w\n";
        if (_modulateMethod != null) code += _modulateMethod(vo, t, regCache, _sharedRegisters);
        code += "mul " + t + ", " + t + ".w, " + lightColReg + "\n";
        if (!_isFirstLight) {
            code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + t + "\n";
            regCache.removeFragmentTempUsage(t);
        }
        _isFirstLight = false;
        return code;
    }

/**
	 * @inheritDoc
	 */

    override public function getFragmentCodePerProbe(vo:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, regCache:ShaderRegisterCache):String {
        var code:String = "";
        var t:ShaderRegisterElement;
// write in temporary if not first light, so we can add to total diffuse colour
        if (_isFirstLight) t = _totalLightColorReg
        else {
            t = regCache.getFreeFragmentVectorTemp();
            regCache.addFragmentTempUsages(t, 1);
        }

        code += "tex " + t + ", " + _sharedRegisters.normalFragment + ", " + cubeMapReg + " <cube,linear,miplinear>\n" + "mul " + t + ".xyz, " + t + ".xyz, " + weightRegister + "\n";
        if (_modulateMethod != null) code += _modulateMethod(vo, t, regCache, _sharedRegisters);
        if (!_isFirstLight) {
            code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + t + "\n";
            regCache.removeFragmentTempUsage(t);
        }
        _isFirstLight = false;
        return code;
    }

/**
	 * @inheritDoc
	 */

    override public function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String {
        var code:String = "";
        var albedo:ShaderRegisterElement;
        var cutOffReg:ShaderRegisterElement;
// incorporate input from ambient
        if (vo.numLights > 0) {
            if (_shadowRegister != null) code += applyShadow(vo, regCache);
            albedo = regCache.getFreeFragmentVectorTemp();
            regCache.addFragmentTempUsages(albedo, 1);
        }

        else albedo = targetReg;
        if (_useTexture) {
            _diffuseInputRegister = regCache.getFreeTextureReg();
            vo.texturesIndex = _diffuseInputRegister.index;
            code += getTex2DSampleCode(vo, albedo, _diffuseInputRegister, _texture);
            if (_alphaThreshold > 0) {
                cutOffReg = regCache.getFreeFragmentConstant();
                vo.fragmentConstantsIndex = cutOffReg.index * 4;
                code += "sub " + albedo + ".w, " + albedo + ".w, " + cutOffReg + ".x\n" + "kil " + albedo + ".w\n" + "add " + albedo + ".w, " + albedo + ".w, " + cutOffReg + ".x\n";
            }
        }

        else {
            _diffuseInputRegister = regCache.getFreeFragmentConstant();
            vo.fragmentConstantsIndex = _diffuseInputRegister.index * 4;
            code += "mov " + albedo + ", " + _diffuseInputRegister + "\n";
        }

        if (vo.numLights == 0) return code;
        code += "sat " + _totalLightColorReg + ", " + _totalLightColorReg + "\n";
        if (_useAmbientTexture) {
            code += "mul " + albedo + ".xyz, " + albedo + ", " + _totalLightColorReg + "\n" + "mul " + _totalLightColorReg + ".xyz, " + targetReg + ", " + _totalLightColorReg + "\n" + "sub " + targetReg + ".xyz, " + targetReg + ", " + _totalLightColorReg + "\n" + "add " + targetReg + ".xyz, " + albedo + ", " + targetReg + "\n";
        }

        else {
            code += "add " + targetReg + ".xyz, " + _totalLightColorReg + ", " + targetReg + "\n";
            if (_useTexture) {
                code += "mul " + targetReg + ".xyz, " + albedo + ", " + targetReg + "\n" + "mov " + targetReg + ".w, " + albedo + ".w\n";
            }

            else {
                code += "mul " + targetReg + ".xyz, " + _diffuseInputRegister + ", " + targetReg + "\n" + "mov " + targetReg + ".w, " + _diffuseInputRegister + ".w\n";
            }

        }

        regCache.removeFragmentTempUsage(_totalLightColorReg);
        regCache.removeFragmentTempUsage(albedo);
        return code;
    }

/**
	 * Generate the code that applies the calculated shadow to the diffuse light
	 * @param vo The MethodVO object for which the compilation is currently happening.
	 * @param regCache The register cache the compiler is currently using for the register management.
	 */

    private function applyShadow(vo:MethodVO, regCache:ShaderRegisterCache):String {
        return "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + _shadowRegister + ".w\n";
    }

/**
	 * @inheritDoc
	 */

    override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void {
        if (_useTexture) {
            stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
            if (_alphaThreshold > 0) vo.fragmentData[vo.fragmentConstantsIndex] = _alphaThreshold;
        }

        else {
            var index:Int = vo.fragmentConstantsIndex;
            var data:Vector<Float> = vo.fragmentData;

            data[index] = _diffuseR;
            data[index + 1] = _diffuseG;
            data[index + 2] = _diffuseB;
            data[index + 3] = _diffuseA;
        }

    }

/**
	 * Updates the diffuse color data used by the render state.
	 */

    private function updateDiffuse():Void {
        _diffuseR = ((_diffuseColor >> 16) & 0xff) / 0xff;
        _diffuseG = ((_diffuseColor >> 8) & 0xff) / 0xff;
        _diffuseB = (_diffuseColor & 0xff) / 0xff;
    }

/**
	 * Set internally by the compiler, so the method knows the register containing the shadow calculation.
	 */

    private function set_shadowRegister(value:ShaderRegisterElement):ShaderRegisterElement {
        _shadowRegister = value;
        return value;
    }

}

