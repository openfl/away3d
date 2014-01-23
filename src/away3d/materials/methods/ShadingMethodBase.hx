/**
 * ShadingMethodBase provides an abstract base method for shading methods, used by compiled passes to compile
 * the final shading program.
 */
package away3d.materials.methods;


import away3d.events.ShadingMethodEvent;
import away3d.events.ShadingMethodEvent;
import flash.display3D.Context3DTextureFormat;
import away3d.textures.TextureProxyBase;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.library.assets.NamedAssetBase;
import away3d.materials.compilation.ShaderRegisterData;
import flash.Vector;
import away3d.materials.passes.MaterialPassBase;
class ShadingMethodBase extends NamedAssetBase {
    public var sharedRegisters(get_sharedRegisters, set_sharedRegisters):ShaderRegisterData;
    public var passes(get_passes, never):Vector<MaterialPassBase>;

    private var _sharedRegisters:ShaderRegisterData;
    private var _passes:Vector<MaterialPassBase>;
/**
	 * Create a new ShadingMethodBase object.
	 * @param needsNormals Defines whether or not the method requires normals.
	 * @param needsView Defines whether or not the method requires the view direction.
	 */

    public function new() {
        super();
    }

/**
	 * Initializes the properties for a MethodVO, including register and texture indices.
	 * @param vo The MethodVO object linking this method with the pass currently being compiled.
	 */

    public function initVO(vo:MethodVO):Void {
    }

/**
	 * Initializes unchanging shader constants using the data from a MethodVO.
	 * @param vo The MethodVO object linking this method with the pass currently being compiled.
	 */

    public function initConstants(vo:MethodVO):Void {
    }

/**
	 * The shared registers created by the compiler and possibly used by methods.
	 */

    private function get_sharedRegisters():ShaderRegisterData {
        return _sharedRegisters;
    }

    private function set_sharedRegisters(value:ShaderRegisterData):ShaderRegisterData {
        _sharedRegisters = value;
        return value;
    }

/**
	 * Any passes required that render to a texture used by this method.
	 */

    public function get_passes():Vector<MaterialPassBase> {
        return _passes;
    }

/**
	 * Cleans up any resources used by the current object.
	 */

    public function dispose():Void {
    }

/**
	 * Creates a data container that contains material-dependent data. Provided as a factory method so a custom subtype can be overridden when needed.
	 */

    public function createMethodVO():MethodVO {
        return new MethodVO();
    }

/**
	 * Resets the compilation state of the method.
	 */

    public function reset():Void {
        cleanCompilationData();
    }

/**
	 * Resets the method's state for compilation.
	 * @private
	 */

    public function cleanCompilationData():Void {
    }

/**
	 * Get the vertex shader code for this method.
	 * @param vo The MethodVO object linking this method with the pass currently being compiled.
	 * @param regCache The register cache used during the compilation.
	 * @private
	 */

    public function getVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String {
        return "";
    }

/**
	 * Sets the render state for this method.
	 *
	 * @param vo The MethodVO object linking this method with the pass currently being compiled.
	 * @param stage3DProxy The Stage3DProxy object currently used for rendering.
	 * @private
	 */

    public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void {
    }

/**
	 * Sets the render state for a single renderable.
	 *
	 * @param vo The MethodVO object linking this method with the pass currently being compiled.
	 * @param renderable The renderable currently being rendered.
	 * @param stage3DProxy The Stage3DProxy object currently used for rendering.
	 * @param camera The camera from which the scene is currently rendered.
	 */

    public function setRenderState(vo:MethodVO, renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):Void {
    }

/**
	 * Clears the render state for this method.
	 * @param vo The MethodVO object linking this method with the pass currently being compiled.
	 * @param stage3DProxy The Stage3DProxy object currently used for rendering.
	 */

    public function deactivate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void {
    }

/**
	 * A helper method that generates standard code for sampling from a texture using the normal uv coordinates.
	 * @param vo The MethodVO object linking this method with the pass currently being compiled.
	 * @param targetReg The register in which to store the sampled colour.
	 * @param inputReg The texture stream register.
	 * @param texture The texture which will be assigned to the given slot.
	 * @param uvReg An optional uv register if coordinates different from the primary uv coordinates are to be used.
	 * @param forceWrap If true, texture wrapping is enabled regardless of the material setting.
	 * @return The fragment code that performs the sampling.
	 */

    private function getTex2DSampleCode(vo:MethodVO, targetReg:ShaderRegisterElement, inputReg:ShaderRegisterElement, texture:TextureProxyBase, uvReg:ShaderRegisterElement = null, forceWrap:String = null):String {
        var wrap:String = ((vo.repeatTextures) ? "wrap" : "clamp");
        if (forceWrap != null)wrap = forceWrap;
        var filter:String;
        var format:String = getFormatStringForTexture(texture);
        var enableMipMaps:Bool = vo.useMipmapping && texture.hasMipMaps;
        if (vo.useSmoothTextures) filter = (enableMipMaps) ? "linear,miplinear" : "linear"
        else filter = (enableMipMaps) ? "nearest,mipnearest" : "nearest";

        if (uvReg == null)
            uvReg = _sharedRegisters.uvVarying;
        return "tex " + targetReg + ", " + uvReg + ", " + inputReg + " <2d," + filter + "," + format + wrap + ">\n";
    }

/**
	 * A helper method that generates standard code for sampling from a cube texture.
	 * @param vo The MethodVO object linking this method with the pass currently being compiled.
	 * @param targetReg The register in which to store the sampled colour.
	 * @param inputReg The texture stream register.
	 * @param texture The cube map which will be assigned to the given slot.
	 * @param uvReg The direction vector with which to sample the cube map.
	 */

    private function getTexCubeSampleCode(vo:MethodVO, targetReg:ShaderRegisterElement, inputReg:ShaderRegisterElement, texture:TextureProxyBase, uvReg:ShaderRegisterElement):String {
        var filter:String;
        var format:String = getFormatStringForTexture(texture);
        var enableMipMaps:Bool = vo.useMipmapping && texture.hasMipMaps;
        if (vo.useSmoothTextures) filter = (enableMipMaps) ? "linear,miplinear" : "linear"
        else filter = (enableMipMaps) ? "nearest,mipnearest" : "nearest";
        return "tex " + targetReg + ", " + uvReg + ", " + inputReg + " <cube," + format + filter + ">\n";
    }

/**
	 * Generates a texture format string for the sample instruction.
	 * @param texture The texture for which to get the format string.
	 * @return
	 */

    private function getFormatStringForTexture(texture:TextureProxyBase):String {
        var _sw0_ = (texture.format);
        switch(_sw0_) {
            case Context3DTextureFormat.COMPRESSED:
                return "dxt1,";
            case Context3DTextureFormat.COMPRESSED_ALPHA:
                return "dxt5,";
            default:
                return "";
        }
    }

/**
	 * Marks the shader program as invalid, so it will be recompiled before the next render.
	 */

    private function invalidateShaderProgram():Void {
        dispatchEvent(new ShadingMethodEvent(ShadingMethodEvent.SHADER_INVALIDATED));
    }

/**
	 * Copies the state from a ShadingMethodBase object into the current object.
	 */

    public function copyFrom(method:ShadingMethodBase):Void {
    }

}

