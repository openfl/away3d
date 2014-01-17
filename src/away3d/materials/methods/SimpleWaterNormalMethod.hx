/**
 * SimpleWaterNormalMethod provides a basic normal map method to create water ripples by translating two wave normal maps.
 */
package away3d.materials.methods;


import flash.Vector;
import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.textures.Texture2DBase;

class SimpleWaterNormalMethod extends BasicNormalMethod {
    public var water1OffsetX(get_water1OffsetX, set_water1OffsetX):Float;
    public var water1OffsetY(get_water1OffsetY, set_water1OffsetY):Float;
    public var water2OffsetX(get_water2OffsetX, set_water2OffsetX):Float;
    public var water2OffsetY(get_water2OffsetY, set_water2OffsetY):Float;
    public var secondaryNormalMap(get_secondaryNormalMap, set_secondaryNormalMap):Texture2DBase;

    private var _texture2:Texture2DBase;
    private var _normalTextureRegister2:ShaderRegisterElement;
    private var _useSecondNormalMap:Bool;
    private var _water1OffsetX:Float;
    private var _water1OffsetY:Float;
    private var _water2OffsetX:Float;
    private var _water2OffsetY:Float;
/**
	 * Creates a new SimpleWaterNormalMethod object.
	 * @param waveMap1 A normal map containing one layer of a wave structure.
	 * @param waveMap2 A normal map containing a second layer of a wave structure.
	 */

    public function new(waveMap1:Texture2DBase, waveMap2:Texture2DBase) {
        _water1OffsetX = 0;
        _water1OffsetY = 0;
        _water2OffsetX = 0;
        _water2OffsetY = 0;
        super();
        normalMap = waveMap1;
        secondaryNormalMap = waveMap2;
    }

/**
	 * @inheritDoc
	 */

    override public function initConstants(vo:MethodVO):Void {
        var index:Int = vo.fragmentConstantsIndex;
        vo.fragmentData[index] = .5;
        vo.fragmentData[index + 1] = 0;
        vo.fragmentData[index + 2] = 0;
        vo.fragmentData[index + 3] = 1;
    }

/**
	 * @inheritDoc
	 */

    override public function initVO(vo:MethodVO):Void {
        super.initVO(vo);
        _useSecondNormalMap = normalMap != secondaryNormalMap;
    }

/**
	 * The translation of the first wave layer along the X-axis.
	 */

    public function get_water1OffsetX():Float {
        return _water1OffsetX;
    }

    public function set_water1OffsetX(value:Float):Float {
        _water1OffsetX = value;
        return value;
    }

/**
	 * The translation of the first wave layer along the Y-axis.
	 */

    public function get_water1OffsetY():Float {
        return _water1OffsetY;
    }

    public function set_water1OffsetY(value:Float):Float {
        _water1OffsetY = value;
        return value;
    }

/**
	 * The translation of the second wave layer along the X-axis.
	 */

    public function get_water2OffsetX():Float {
        return _water2OffsetX;
    }

    public function set_water2OffsetX(value:Float):Float {
        _water2OffsetX = value;
        return value;
    }

/**
	 * The translation of the second wave layer along the Y-axis.
	 */

    public function get_water2OffsetY():Float {
        return _water2OffsetY;
    }

    public function set_water2OffsetY(value:Float):Float {
        _water2OffsetY = value;
        return value;
    }

/**
	 * @inheritDoc
	 */

    override public function set_normalMap(value:Texture2DBase):Texture2DBase {
        if (value == null) return value;
        super.normalMap = value;
        return value;
    }

/**
	 * A second normal map that will be combined with the first to create a wave-like animation pattern.
	 */

    public function get_secondaryNormalMap():Texture2DBase {
        return _texture2;
    }

    public function set_secondaryNormalMap(value:Texture2DBase):Texture2DBase {
        _texture2 = value;
        return value;
    }

/**
	 * @inheritDoc
	 */

    override public function cleanCompilationData():Void {
        super.cleanCompilationData();
        _normalTextureRegister2 = null;
    }

/**
	 * @inheritDoc
	 */

    override public function dispose():Void {
        super.dispose();
        _texture2 = null;
    }

/**
	 * @inheritDoc
	 */

    override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void {
        super.activate(vo, stage3DProxy);
        var data:Vector<Float> = vo.fragmentData;
        var index:Int = vo.fragmentConstantsIndex;
        data[index + 4] = _water1OffsetX;
        data[index + 5] = _water1OffsetY;
        data[index + 6] = _water2OffsetX;
        data[index + 7] = _water2OffsetY;
        if (_useSecondNormalMap) stage3DProxy._context3D.setTextureAt(vo.texturesIndex + 1, _texture2.getTextureForStage3D(stage3DProxy));
    }

/**
	 * @inheritDoc
	 */

    override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String {
        var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
        var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
        var dataReg2:ShaderRegisterElement = regCache.getFreeFragmentConstant();
        _normalTextureRegister = regCache.getFreeTextureReg();
        _normalTextureRegister2 = (_useSecondNormalMap) ? regCache.getFreeTextureReg() : _normalTextureRegister;
        vo.texturesIndex = _normalTextureRegister.index;
        vo.fragmentConstantsIndex = dataReg.index * 4;
        return "add " + temp + ", " + _sharedRegisters.uvVarying + ", " + dataReg2 + ".xyxy\n" + getTex2DSampleCode(vo, targetReg, _normalTextureRegister, normalMap, temp) + "add " + temp + ", " + _sharedRegisters.uvVarying + ", " + dataReg2 + ".zwzw\n" + getTex2DSampleCode(vo, temp, _normalTextureRegister2, _texture2, temp) + "add " + targetReg + ", " + targetReg + ", " + temp + "		\n" + "mul " + targetReg + ", " + targetReg + ", " + dataReg + ".x	\n" + "sub " + targetReg + ".xyz, " + targetReg + ".xyz, " + _sharedRegisters.commons + ".xxx	\n" + "nrm " + targetReg + ".xyz, " + targetReg + ".xyz							\n";
    }

}

