/**
 * BasicAmbientMethod provides the default shading method for uniform ambient lighting.
 */
package away3d.materials.methods;


import flash.Vector;
import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.textures.Texture2DBase;

class BasicAmbientMethod extends ShadingMethodBase {
    public var ambient(get_ambient, set_ambient):Float;
    public var ambientColor(get_ambientColor, set_ambientColor):Int;
    public var texture(get_texture, set_texture):Texture2DBase;

    private var _useTexture:Bool;
    private var _texture:Texture2DBase;
    private var _ambientInputRegister:ShaderRegisterElement;
    private var _ambientColor:Int;
    private var _ambientR:Float;
    private var _ambientG:Float;
    private var _ambientB:Float;
    private var _ambient:Float;
    public var _lightAmbientR:Float;
    public var _lightAmbientG:Float;
    public var _lightAmbientB:Float;
/**
	 * Creates a new BasicAmbientMethod object.
	 */

    public function new() {
        _ambientColor = 0xffffff;
        _ambientR = 0;
        _ambientG = 0;
        _ambientB = 0;
        _ambient = 1;
        _lightAmbientR = 0;
        _lightAmbientG = 0;
        _lightAmbientB = 0;
        super();
    }

/**
	 * @inheritDoc
	 */

    override public function initVO(vo:MethodVO):Void {
        vo.needsUV = _useTexture;
    }

/**
	 * @inheritDoc
	 */

    override public function initConstants(vo:MethodVO):Void {
        vo.fragmentData[vo.fragmentConstantsIndex + 3] = 1;
    }

/**
	 * The strength of the ambient reflection of the surface.
	 */

    public function get_ambient():Float {
        return _ambient;
    }

    public function set_ambient(value:Float):Float {
        _ambient = value;
        return value;
    }

/**
	 * The colour of the ambient reflection of the surface.
	 */

    public function get_ambientColor():Int {
        return _ambientColor;
    }

    public function set_ambientColor(value:Int):Int {
        _ambientColor = value;
        return value;
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
        _useTexture = cast((value), Bool);
        _texture = value;
        return value;
    }

/**
	 * @inheritDoc
	 */

    override public function copyFrom(method:ShadingMethodBase):Void {
        var diff:BasicAmbientMethod = cast((method), BasicAmbientMethod);
        ambient = diff.ambient;
        ambientColor = diff.ambientColor;
    }

/**
	 * @inheritDoc
	 */

    override public function cleanCompilationData():Void {
        super.cleanCompilationData();
        _ambientInputRegister = null;
    }

/**
	 * @inheritDoc
	 */

    public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String {
        var code:String = "";
        if (_useTexture) {
            _ambientInputRegister = regCache.getFreeTextureReg();
            vo.texturesIndex = _ambientInputRegister.index;
            code += getTex2DSampleCode(vo, targetReg, _ambientInputRegister, _texture) + // apparently, still needs to un-premultiply :s

            "div " + targetReg + ".xyz, " + targetReg + ".xyz, " + targetReg + ".w\n";
        }

        else {
            _ambientInputRegister = regCache.getFreeFragmentConstant();
            vo.fragmentConstantsIndex = _ambientInputRegister.index * 4;
            code += "mov " + targetReg + ", " + _ambientInputRegister + "\n";
        }

        return code;
    }

/**
	 * @inheritDoc
	 */

    override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void {
        if (_useTexture) stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
    }

/**
	 * Updates the ambient color data used by the render state.
	 */

    private function updateAmbient():Void {
        _ambientR = ((_ambientColor >> 16) & 0xff) / 0xff * _ambient * _lightAmbientR;
        _ambientG = ((_ambientColor >> 8) & 0xff) / 0xff * _ambient * _lightAmbientG;
        _ambientB = (_ambientColor & 0xff) / 0xff * _ambient * _lightAmbientB;
    }

/**
	 * @inheritDoc
	 */

    override public function setRenderState(vo:MethodVO, renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):Void {
        updateAmbient();
        if (!_useTexture) {
            var index:Int = vo.fragmentConstantsIndex;
            var data:Vector<Float> = vo.fragmentData;
            data[index] = _ambientR;
            data[index + 1] = _ambientG;
            data[index + 2] = _ambientB;
        }
    }

}

