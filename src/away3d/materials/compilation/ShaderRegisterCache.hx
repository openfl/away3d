/**
 * ShaderRegister Cache provides the usage management system for all registers during shading compilation.
 */
package away3d.materials.compilation;

class ShaderRegisterCache {
    public var vertexConstantOffset(get_vertexConstantOffset, set_vertexConstantOffset):Int;
    public var vertexAttributesOffset(get_vertexAttributesOffset, set_vertexAttributesOffset):Int;
    public var varyingsOffset(get_varyingsOffset, set_varyingsOffset):Int;
    public var fragmentConstantOffset(get_fragmentConstantOffset, set_fragmentConstantOffset):Int;
    public var fragmentOutputRegister(get_fragmentOutputRegister, never):ShaderRegisterElement;
    public var numUsedVertexConstants(get_numUsedVertexConstants, never):Int;
    public var numUsedFragmentConstants(get_numUsedFragmentConstants, never):Int;
    public var numUsedStreams(get_numUsedStreams, never):Int;
    public var numUsedTextures(get_numUsedTextures, never):Int;
    public var numUsedVaryings(get_numUsedVaryings, never):Int;

    private var _fragmentTempCache:RegisterPool;
    private var _vertexTempCache:RegisterPool;
    private var _varyingCache:RegisterPool;
    private var _fragmentConstantsCache:RegisterPool;
    private var _vertexConstantsCache:RegisterPool;
    private var _textureCache:RegisterPool;
    private var _vertexAttributesCache:RegisterPool;
    private var _vertexConstantOffset:Int;
    private var _vertexAttributesOffset:Int;
    private var _varyingsOffset:Int;
    private var _fragmentConstantOffset:Int;
    private var _fragmentOutputRegister:ShaderRegisterElement;
    private var _vertexOutputRegister:ShaderRegisterElement;
    private var _numUsedVertexConstants:Int;
    private var _numUsedFragmentConstants:Int;
    private var _numUsedStreams:Int;
    private var _numUsedTextures:Int;
    private var _numUsedVaryings:Int;
    private var _profile:String;
/**
	 * Create a new ShaderRegisterCache object.
	 *
	 * @param profile The compatibility profile used by the renderer.
	 */

    public function new(profile:String) {
        _profile = profile;
    }

/**
	 * Resets all registers.
	 */

    public function reset():Void {
        _fragmentTempCache = new RegisterPool("ft", 8, false);
        _vertexTempCache = new RegisterPool("vt", 8, false);
        _varyingCache = new RegisterPool("v", 8);
        _textureCache = new RegisterPool("fs", 8);
        _vertexAttributesCache = new RegisterPool("va", 8);
        _fragmentConstantsCache = new RegisterPool("fc", 28);
        _vertexConstantsCache = new RegisterPool("vc", 128);
        _fragmentOutputRegister = new ShaderRegisterElement("oc", -1);
        _vertexOutputRegister = new ShaderRegisterElement("op", -1);
        _numUsedVertexConstants = 0;
        _numUsedStreams = 0;
        _numUsedTextures = 0;
        _numUsedVaryings = 0;
        _numUsedFragmentConstants = 0;
        var i:Int;
        i = 0;
        while (i < _vertexAttributesOffset) {
            getFreeVertexAttribute();
            ++i;
        }
        i = 0;
        while (i < _vertexConstantOffset) {
            getFreeVertexConstant();
            ++i;
        }
        i = 0;
        while (i < _varyingsOffset) {
            getFreeVarying();
            ++i;
        }
        i = 0;
        while (i < _fragmentConstantOffset) {
            getFreeFragmentConstant();
            ++i;
        }
    }

/**
	 * Disposes all resources used.
	 */

    public function dispose():Void {
        _fragmentTempCache.dispose();
        _vertexTempCache.dispose();
        _varyingCache.dispose();
        _fragmentConstantsCache.dispose();
        _vertexAttributesCache.dispose();
        _fragmentTempCache = null;
        _vertexTempCache = null;
        _varyingCache = null;
        _fragmentConstantsCache = null;
        _vertexAttributesCache = null;
        _fragmentOutputRegister = null;
        _vertexOutputRegister = null;
    }

/**
	 * Marks a fragment temporary register as used, so it cannot be retrieved. The register won't be able to be used until removeUsage
	 * has been called usageCount times again.
	 * @param register The register to mark as used.
	 * @param usageCount The amount of usages to add.
	 */

    public function addFragmentTempUsages(register:ShaderRegisterElement, usageCount:Int):Void {
        _fragmentTempCache.addUsage(register, usageCount);
    }

/**
	 * Removes a usage from a fragment temporary register. When usages reach 0, the register is freed again.
	 * @param register The register for which to remove a usage.
	 */

    public function removeFragmentTempUsage(register:ShaderRegisterElement):Void {
        _fragmentTempCache.removeUsage(register);
    }

/**
	 * Marks a vertex temporary register as used, so it cannot be retrieved. The register won't be able to be used
	 * until removeUsage has been called usageCount times again.
	 * @param register The register to mark as used.
	 * @param usageCount The amount of usages to add.
	 */

    public function addVertexTempUsages(register:ShaderRegisterElement, usageCount:Int):Void {
        _vertexTempCache.addUsage(register, usageCount);
    }

/**
	 * Removes a usage from a vertex temporary register. When usages reach 0, the register is freed again.
	 * @param register The register for which to remove a usage.
	 */

    public function removeVertexTempUsage(register:ShaderRegisterElement):Void {
        _vertexTempCache.removeUsage(register);
    }

/**
	 * Retrieve an entire fragment temporary register that's still available. The register won't be able to be used until removeUsage
	 * has been called usageCount times again.
	 */

    public function getFreeFragmentVectorTemp():ShaderRegisterElement {
        return _fragmentTempCache.requestFreeVectorReg();
    }

/**
	 * Retrieve a single component from a fragment temporary register that's still available.
	 */

    public function getFreeFragmentSingleTemp():ShaderRegisterElement {
        return _fragmentTempCache.requestFreeRegComponent();
    }

/**
	 * Retrieve an available varying register
	 */

    public function getFreeVarying():ShaderRegisterElement {
        ++_numUsedVaryings;
        return _varyingCache.requestFreeVectorReg();
    }

/**
	 * Retrieve an available fragment constant register
	 */

    public function getFreeFragmentConstant():ShaderRegisterElement {
        ++_numUsedFragmentConstants;
        return _fragmentConstantsCache.requestFreeVectorReg();
    }

/**
	 * Retrieve an available vertex constant register
	 */

    public function getFreeVertexConstant():ShaderRegisterElement {
        ++_numUsedVertexConstants;
        return _vertexConstantsCache.requestFreeVectorReg();
    }

/**
	 * Retrieve an entire vertex temporary register that's still available.
	 */

    public function getFreeVertexVectorTemp():ShaderRegisterElement {
        return _vertexTempCache.requestFreeVectorReg();
    }

/**
	 * Retrieve a single component from a vertex temporary register that's still available.
	 */

    public function getFreeVertexSingleTemp():ShaderRegisterElement {
        return _vertexTempCache.requestFreeRegComponent();
    }

/**
	 * Retrieve an available vertex attribute register
	 */

    public function getFreeVertexAttribute():ShaderRegisterElement {
        ++_numUsedStreams;
        return _vertexAttributesCache.requestFreeVectorReg();
    }

/**
	 * Retrieve an available texture register
	 */

    public function getFreeTextureReg():ShaderRegisterElement {
        ++_numUsedTextures;
        return _textureCache.requestFreeVectorReg();
    }

/**
	 * Indicates the start index from which to retrieve vertex constants.
	 */

    public function get_vertexConstantOffset():Int {
        return _vertexConstantOffset;
    }

    public function set_vertexConstantOffset(vertexConstantOffset:Int):Int {
        _vertexConstantOffset = vertexConstantOffset;
        return vertexConstantOffset;
    }

/**
	 * Indicates the start index from which to retrieve vertex attributes.
	 */

    public function get_vertexAttributesOffset():Int {
        return _vertexAttributesOffset;
    }

    public function set_vertexAttributesOffset(value:Int):Int {
        _vertexAttributesOffset = value;
        return value;
    }

/**
	 * Indicates the start index from which to retrieve varying registers.
	 */

    public function get_varyingsOffset():Int {
        return _varyingsOffset;
    }

    public function set_varyingsOffset(value:Int):Int {
        _varyingsOffset = value;
        return value;
    }

/**
	 * Indicates the start index from which to retrieve fragment constants.
	 */

    public function get_fragmentConstantOffset():Int {
        return _fragmentConstantOffset;
    }

    public function set_fragmentConstantOffset(value:Int):Int {
        _fragmentConstantOffset = value;
        return value;
    }

/**
	 * The fragment output register.
	 */

    public function get_fragmentOutputRegister():ShaderRegisterElement {
        return _fragmentOutputRegister;
    }

/**
	 * The amount of used vertex constant registers.
	 */

    public function get_numUsedVertexConstants():Int {
        return _numUsedVertexConstants;
    }

/**
	 * The amount of used fragment constant registers.
	 */

    public function get_numUsedFragmentConstants():Int {
        return _numUsedFragmentConstants;
    }

/**
	 * The amount of used vertex streams.
	 */

    public function get_numUsedStreams():Int {
        return _numUsedStreams;
    }

/**
	 * The amount of used texture slots.
	 */

    public function get_numUsedTextures():Int {
        return _numUsedTextures;
    }

/**
	 * The amount of used varying registers.
	 */

    public function get_numUsedVaryings():Int {
        return _numUsedVaryings;
    }

}

