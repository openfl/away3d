/**
 * ProjectiveTextureMethod is a material method used to project a texture unto the surface of an object.
 * This can be used for various effects apart from acting like a normal projector, such as projecting fake shadows
 * unto a surface, the impact of light coming through a stained glass window, ...
 */
package away3d.materials.methods;


import flash.display.BlendMode;
import flash.errors.Error;
import flash.Vector;
import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.entities.TextureProjector;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import flash.geom.Matrix3D;

class ProjectiveTextureMethod extends EffectMethodBase {
    public var mode(get_mode, set_mode):BlendMode;
    public var projector(get_projector, set_projector):TextureProjector;

    static public var MULTIPLY:BlendMode = BlendMode.MULTIPLY;
    static public var ADD:BlendMode = BlendMode.ADD;
    static public var MIX:BlendMode = BlendMode.DIFFERENCE;
    private var _projector:TextureProjector;
    private var _uvVarying:ShaderRegisterElement;
    private var _projMatrix:Matrix3D;
    private var _mode:BlendMode;
/**
	 * Creates a new ProjectiveTextureMethod object.
	 *
	 * @param projector The TextureProjector object that defines the projection properties as well as the texture.
	 * @param mode The blend mode with which the texture is blended unto the surface.
	 *
	 * @see away3d.entities.TextureProjector
	 */

    public function new(projector:TextureProjector, mode:BlendMode) {
        _projMatrix = new Matrix3D();
        super();
        _projector = projector;
        _mode = mode;
    }

/**
	 * @inheritDoc
	 */

    override public function initConstants(vo:MethodVO):Void {
        var index:Int = vo.fragmentConstantsIndex;
        var data:Vector<Float> = vo.fragmentData;
        data[index] = .5;
        data[index + 1] = -.5;
        data[index + 2] = 1.0;
        data[index + 3] = 1.0;
    }

/**
	 * @inheritDoc
	 */

    override public function cleanCompilationData():Void {
        super.cleanCompilationData();
        _uvVarying = null;
    }

/**
	 * The blend mode with which the texture is blended unto the object.
	 * ProjectiveTextureMethod.MULTIPLY can be used to project shadows. To prevent clamping, the texture's alpha should be white!
	 * ProjectiveTextureMethod.ADD can be used to project light, such as a slide projector or light coming through stained glass. To prevent clamping, the texture's alpha should be black!
	 * ProjectiveTextureMethod.MIX provides normal alpha blending. To prevent clamping, the texture's alpha should be transparent!
	 */

    public function get_mode():BlendMode {
        return _mode;
    }

    public function set_mode(value:BlendMode):BlendMode {
        if (_mode == value) return value;
        _mode = value;
        invalidateShaderProgram();
        return value;
    }

/**
	 * The TextureProjector object that defines the projection properties as well as the texture.
	 *
	 * @see away3d.entities.TextureProjector
	 */

    public function get_projector():TextureProjector {
        return _projector;
    }

    public function set_projector(value:TextureProjector):TextureProjector {
        _projector = value;
        return value;
    }

/**
	 * @inheritDoc
	 */

    override public function getVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String {
        var projReg:ShaderRegisterElement = regCache.getFreeVertexConstant();
        regCache.getFreeVertexConstant();
        regCache.getFreeVertexConstant();
        regCache.getFreeVertexConstant();
        regCache.getFreeVertexVectorTemp();
        vo.vertexConstantsIndex = projReg.index * 4;
        _uvVarying = regCache.getFreeVarying();
        return "m44 " + _uvVarying + ", vt0, " + projReg + "\n";
    }

/**
	 * @inheritDoc
	 */

    override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String {
        var code:String = "";
        var mapRegister:ShaderRegisterElement = regCache.getFreeTextureReg();
        var col:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
        var toTexReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
        vo.fragmentConstantsIndex = toTexReg.index * 4;
        vo.texturesIndex = mapRegister.index;
        code += "div " + col + ", " + _uvVarying + ", " + _uvVarying + ".w						\n" + "mul " + col + ".xy, " + col + ".xy, " + toTexReg + ".xy	\n" + "add " + col + ".xy, " + col + ".xy, " + toTexReg + ".xx	\n";
        code += getTex2DSampleCode(vo, col, mapRegister, _projector.texture, col, "clamp");
        if (_mode == MULTIPLY) code += "mul " + targetReg + ".xyz, " + targetReg + ".xyz, " + col + ".xyz			\n"
        else if (_mode == ADD) code += "add " + targetReg + ".xyz, " + targetReg + ".xyz, " + col + ".xyz			\n"
        else if (_mode == MIX) {
            code += "sub " + col + ".xyz, " + col + ".xyz, " + targetReg + ".xyz				\n" + "mul " + col + ".xyz, " + col + ".xyz, " + col + ".w						\n" + "add " + targetReg + ".xyz, " + targetReg + ".xyz, " + col + ".xyz			\n";
        }

        else throw new Error("Unknown mode \"" + _mode + "\"");
        return code;
    }

/**
	 * @inheritDoc
	 */

    override public function setRenderState(vo:MethodVO, renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):Void {
        _projMatrix.copyFrom(_projector.viewProjection);
        _projMatrix.prepend(renderable.getRenderSceneTransform(camera));
        _projMatrix.copyRawDataTo(vo.vertexData, vo.vertexConstantsIndex, true);
    }

/**
	 * @inheritDoc
	 */

    override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void {
        stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _projector.texture.getTextureForStage3D(stage3DProxy));
    }

}

