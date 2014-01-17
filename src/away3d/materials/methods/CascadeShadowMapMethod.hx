/**
 * CascadeShadowMapMethod is a shadow map method to apply cascade shadow mapping on materials.
 * Must be used with a DirectionalLight with a CascadeShadowMapper assigned to its shadowMapper property.
 *
 * @see away3d.lights.shadowmaps.CascadeShadowMapper
 */
package away3d.materials.methods;


import away3d.core.base.IRenderable;
import away3d.cameras.Camera3D;
import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterData;
import flash.Vector;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.lights.DirectionalLight;
import away3d.lights.shadowmaps.CascadeShadowMapper;
import flash.errors.Error;
import flash.events.Event;
import away3d.events.ShadingMethodEvent;
class CascadeShadowMapMethod extends ShadowMapMethodBase {
    public var baseMethod(get_baseMethod, set_baseMethod):SimpleShadowMapMethodBase;

    private var _baseMethod:SimpleShadowMapMethodBase;
    private var _cascadeShadowMapper:CascadeShadowMapper;
    private var _depthMapCoordVaryings:Vector<ShaderRegisterElement>;
    private var _cascadeProjections:Vector<ShaderRegisterElement>;
/**
	 * Creates a new CascadeShadowMapMethod object.
	 *
	 * @param shadowMethodBase The shadow map sampling method used to sample individual cascades (fe: HardShadowMapMethod, SoftShadowMapMethod)
	 */

    public function new(shadowMethodBase:SimpleShadowMapMethodBase) {
        super(shadowMethodBase.castingLight);
        _baseMethod = shadowMethodBase;
        if (!(Std.is(_castingLight, DirectionalLight))) throw new Error("CascadeShadowMapMethod is only compatible with DirectionalLight");
        _cascadeShadowMapper = cast(_castingLight.shadowMapper, CascadeShadowMapper);
        if (_cascadeShadowMapper == null) throw new Error("CascadeShadowMapMethod requires a light that has a CascadeShadowMapper instance assigned to shadowMapper.");
        _cascadeShadowMapper.addEventListener(Event.CHANGE, onCascadeChange, false, 0, true);
        _baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated, false, 0, true);
    }

/**
	 * The shadow map sampling method used to sample individual cascades. These are typically those used in conjunction
	 * with a DirectionalShadowMapper.
	 *
	 * @see HardShadowMapMethod
	 * @see SoftShadowMapMethod
	 */

    public function get_baseMethod():SimpleShadowMapMethodBase {
        return _baseMethod;
    }

    public function set_baseMethod(value:SimpleShadowMapMethodBase):SimpleShadowMapMethodBase {
        if (_baseMethod == value) return value;
        _baseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
        _baseMethod = value;
        _baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated, false, 0, true);
        invalidateShaderProgram();
        return value;
    }

/**
	 * @inheritDoc
	 */

    override public function initVO(vo:MethodVO):Void {
        var tempVO:MethodVO = new MethodVO();
        _baseMethod.initVO(tempVO);
        vo.needsGlobalVertexPos = true;
        vo.needsProjection = true;
    }

/**
	 * @inheritDoc
	 */

    override private function set_sharedRegisters(value:ShaderRegisterData):ShaderRegisterData {
        super.sharedRegisters = value;
        _baseMethod.sharedRegisters = value;
        return value;
    }

/**
	 * @inheritDoc
	 */

    override public function initConstants(vo:MethodVO):Void {
        var fragmentData:Vector<Float> = vo.fragmentData;
        var vertexData:Vector<Float> = vo.vertexData;
        var index:Int = vo.fragmentConstantsIndex;
        fragmentData[index] = 1.0;
        fragmentData[index + 1] = 1 / 255.0;
        fragmentData[index + 2] = 1 / 65025.0;
        fragmentData[index + 3] = 1 / 16581375.0;
        fragmentData[index + 6] = .5;
        fragmentData[index + 7] = -.5;
        index = vo.vertexConstantsIndex;
        vertexData[index] = .5;
        vertexData[index + 1] = -.5;
        vertexData[index + 2] = 0;
    }

/**
	 * @inheritDoc
	 */

    override public function cleanCompilationData():Void {
        super.cleanCompilationData();
        _cascadeProjections = null;
        _depthMapCoordVaryings = null;
    }

/**
	 * @inheritDoc
	 */

    override public function getVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String {
        var code:String = "";
        var dataReg:ShaderRegisterElement = regCache.getFreeVertexConstant();
        initProjectionsRegs(regCache);
        vo.vertexConstantsIndex = dataReg.index * 4;
        var temp:ShaderRegisterElement = regCache.getFreeVertexVectorTemp();
        var i:Int = 0;
        while (i < _cascadeShadowMapper.numCascades) {
            code += "m44 " + temp + ", " + _sharedRegisters.globalPositionVertex + ", " + _cascadeProjections[i] + "\n" + "add " + _depthMapCoordVaryings[i] + ", " + temp + ", " + dataReg + ".zzwz\n";
            ++i;
        }
        return code;
    }

/**
	 * Creates the registers for the cascades' projection coordinates.
	 */

    private function initProjectionsRegs(regCache:ShaderRegisterCache):Void {
        _cascadeProjections = new Vector<ShaderRegisterElement>(_cascadeShadowMapper.numCascades);
        _depthMapCoordVaryings = new Vector<ShaderRegisterElement>(_cascadeShadowMapper.numCascades);
        var i:Int = 0;
        while (i < _cascadeShadowMapper.numCascades) {
            _depthMapCoordVaryings[i] = regCache.getFreeVarying();
            _cascadeProjections[i] = regCache.getFreeVertexConstant();
            regCache.getFreeVertexConstant();
            regCache.getFreeVertexConstant();
            regCache.getFreeVertexConstant();
            ++i;
        }
    }

/**
	 * @inheritDoc
	 */

    override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String {
        var numCascades:Int = _cascadeShadowMapper.numCascades;
        var depthMapRegister:ShaderRegisterElement = regCache.getFreeTextureReg();
        var decReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
        var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
        var planeDistanceReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
        var planeDistances:Vector<String> = Vector.ofArray([planeDistanceReg + ".x", planeDistanceReg + ".y", planeDistanceReg + ".z", planeDistanceReg + ".w"]);
        var code:String;
        vo.fragmentConstantsIndex = decReg.index * 4;
        vo.texturesIndex = depthMapRegister.index;
        var inQuad:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
        regCache.addFragmentTempUsages(inQuad, 1);
        var uvCoord:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
        regCache.addFragmentTempUsages(uvCoord, 1);
// assume lowest partition is selected, will be overwritten later otherwise
        code = "mov " + uvCoord + ", " + _depthMapCoordVaryings[numCascades - 1] + "\n";
        var i:Int = numCascades - 2;
        while (i >= 0) {
            var uvProjection:ShaderRegisterElement = _depthMapCoordVaryings[i];
// calculate if in texturemap (result == 0 or 1, only 1 for a single partition)
            code += "slt " + inQuad + ".z, " + _sharedRegisters.projectionFragment + ".z, " + planeDistances[i] + "\n";
// z = x > minX, w = y > minY
            var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
// linearly interpolate between old and new uv coords using predicate value == conditional toggle to new value if predicate == 1 (true)
            code += "sub " + temp + ", " + uvProjection + ", " + uvCoord + "\n" + "mul " + temp + ", " + temp + ", " + inQuad + ".z\n" + "add " + uvCoord + ", " + uvCoord + ", " + temp + "\n";
            --i;
        }
        regCache.removeFragmentTempUsage(inQuad);
        code += "div " + uvCoord + ", " + uvCoord + ", " + uvCoord + ".w\n" + "mul " + uvCoord + ".xy, " + uvCoord + ".xy, " + dataReg + ".zw\n" + "add " + uvCoord + ".xy, " + uvCoord + ".xy, " + dataReg + ".zz\n";
        code += _baseMethod.getCascadeFragmentCode(vo, regCache, decReg, depthMapRegister, uvCoord, targetReg) + "add " + targetReg + ".w, " + targetReg + ".w, " + dataReg + ".y\n";
        regCache.removeFragmentTempUsage(uvCoord);
        return code;
    }

/**
	 * @inheritDoc
	 */

    override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void {
        stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _castingLight.shadowMapper.depthMap.getTextureForStage3D(stage3DProxy));
        var vertexData:Vector<Float> = vo.vertexData;
        var vertexIndex:Int = vo.vertexConstantsIndex;
        vo.vertexData[vo.vertexConstantsIndex + 3] = -1 / (_cascadeShadowMapper.depth * _epsilon);
        var numCascades:Int = _cascadeShadowMapper.numCascades;
        vertexIndex += 4;
        var k:Int = 0;
        while (k < numCascades) {
            _cascadeShadowMapper.getDepthProjections(k).copyRawDataTo(vertexData, vertexIndex, true);
            vertexIndex += 16;
            ++k;
        }
        var fragmentData:Vector<Float> = vo.fragmentData;
        var fragmentIndex:Int = vo.fragmentConstantsIndex;
        fragmentData[(fragmentIndex + 5)] = 1 - _alpha;
        var nearPlaneDistances:Vector<Float> = _cascadeShadowMapper.nearPlaneDistances;
        fragmentIndex += 8;
        var i:Int = 0;
        while (i < numCascades) {
            fragmentData[(fragmentIndex + i)] = nearPlaneDistances[i];
            ++i;
        }
        _baseMethod.activateForCascade(vo, stage3DProxy);
    }

/**
	 * @inheritDoc
	 */

    override public function setRenderState(vo:MethodVO, renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):Void {
    }

/**
	 * Called when the shadow mappers cascade configuration changes.
	 */

    private function onCascadeChange(event:Event):Void {
        invalidateShaderProgram();
    }

/**
	 * Called when the base method's shader code is invalidated.
	 */

    private function onShaderInvalidated(event:ShadingMethodEvent):Void {
        invalidateShaderProgram();
    }

}

