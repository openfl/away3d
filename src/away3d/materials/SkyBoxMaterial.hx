/**
 * SkyBoxMaterial is a material exclusively used to render skyboxes
 *
 * @see away3d.primitives.SkyBox
 */
package away3d.materials;


import away3d.materials.passes.SkyBoxPass;
import away3d.textures.CubeTextureBase;

class SkyBoxMaterial extends MaterialBase {
    public var cubeMap(get_cubeMap, set_cubeMap):CubeTextureBase;

    private var _cubeMap:CubeTextureBase;
    private var _skyboxPass:SkyBoxPass;
/**
	 * Creates a new SkyBoxMaterial object.
	 * @param cubeMap The CubeMap to use as the skybox.
	 */

    public function new(cubeMap:CubeTextureBase) {
		super();
        _cubeMap = cubeMap;
        addPass(_skyboxPass = new SkyBoxPass());
        _skyboxPass.cubeTexture = _cubeMap;
        
    }

/**
	 * The cube texture to use as the skybox.
	 */

    public function get_cubeMap():CubeTextureBase {
        return _cubeMap;
    }

    public function set_cubeMap(value:CubeTextureBase):CubeTextureBase {
        if (value != null && _cubeMap != null && (value.hasMipMaps != _cubeMap.hasMipMaps || value.format != _cubeMap.format)) invalidatePasses(null);
        _cubeMap = value;
        _skyboxPass.cubeTexture = _cubeMap;
        return value;
    }

}

