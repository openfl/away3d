/**
 * FresnelSpecularMethod provides a specular shading method that causes stronger highlights on grazing view angles.
 */
package away3d.materials.methods;


import flash.Vector;
import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterData;
import away3d.materials.compilation.ShaderRegisterElement;

class FresnelSpecularMethod extends CompositeSpecularMethod {
    public var basedOnSurface(get_basedOnSurface, set_basedOnSurface):Bool;
    public var fresnelPower(get_fresnelPower, set_fresnelPower):Float;
    public var normalReflectance(get_normalReflectance, set_normalReflectance):Float;

    private var _dataReg:ShaderRegisterElement;
    private var _incidentLight:Bool;
    private var _fresnelPower:Float;
    private var _normalReflectance:Float;
// default value for skin
/**
	 * Creates a new FresnelSpecularMethod object.
	 * @param basedOnSurface Defines whether the fresnel effect should be based on the view angle on the surface (if true), or on the angle between the light and the view.
	 * @param baseSpecularMethod The specular method to which the fresnel equation. Defaults to BasicSpecularMethod.
	 */

    public function new(basedOnSurface:Bool = true, baseSpecularMethod:BasicSpecularMethod = null) {
        _fresnelPower = 5;
        _normalReflectance = .028;
// may want to offer diff speculars
        super(modulateSpecular, baseSpecularMethod);
        _incidentLight = !basedOnSurface;
    }

/**
	 * @inheritDoc
	 */

    override public function initConstants(vo:MethodVO):Void {
        var index:Int = vo.secondaryFragmentConstantsIndex;
        vo.fragmentData[index + 2] = 1;
        vo.fragmentData[index + 3] = 0;
    }

/**
	 * Defines whether the fresnel effect should be based on the view angle on the surface (if true), or on the angle between the light and the view.
	 */

    public function get_basedOnSurface():Bool {
        return !_incidentLight;
    }

    public function set_basedOnSurface(value:Bool):Bool {
        if (_incidentLight != value) return value;
        _incidentLight = !value;
        invalidateShaderProgram();
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
	 * @inheritDoc
	 */

    override public function cleanCompilationData():Void {
        super.cleanCompilationData();
        _dataReg = null;
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
        super.activate(vo, stage3DProxy);
        var fragmentData:Vector<Float> = vo.fragmentData;
        var index:Int = vo.secondaryFragmentConstantsIndex;
        fragmentData[index] = _normalReflectance;
        fragmentData[index + 1] = _fresnelPower;
    }

/**
	 * @inheritDoc
	 */

    override public function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String {
        _dataReg = regCache.getFreeFragmentConstant();
        vo.secondaryFragmentConstantsIndex = _dataReg.index * 4;
        return super.getFragmentPreLightingCode(vo, regCache);
    }

/**
	 * Applies the fresnel effect to the specular strength.
	 *
	 * @param vo The MethodVO object containing the method data for the currently compiled material pass.
	 * @param target The register containing the specular strength in the "w" component, and the half-vector/reflection vector in "xyz".
	 * @param regCache The register cache used for the shader compilation.
	 * @param sharedRegisters The shared registers created by the compiler.
	 * @return The AGAL fragment code for the method.
	 */

    private function modulateSpecular(vo:MethodVO, target:ShaderRegisterElement, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String {
        var code:String;
        code = "dp3 " + target + ".y, " + sharedRegisters.viewDirFragment + ".xyz, " + ((_incidentLight) ? target + ".xyz\n" : sharedRegisters.normalFragment + ".xyz\n") + // dot(V, H)

        "sub " + target + ".y, " + _dataReg + ".z, " + target + ".y\n" + // base = 1-dot(V, H)

        "pow " + target + ".x, " + target + ".y, " + _dataReg + ".y\n" + // exp = pow(base, 5)

        "sub " + target + ".y, " + _dataReg + ".z, " + target + ".y\n" + // 1 - exp

        "mul " + target + ".y, " + _dataReg + ".x, " + target + ".y\n" + // f0*(1 - exp)

        "add " + target + ".y, " + target + ".x, " + target + ".y\n" + // exp + f0*(1 - exp)

        "mul " + target + ".w, " + target + ".w, " + target + ".y\n";
        return code;
    }

}

