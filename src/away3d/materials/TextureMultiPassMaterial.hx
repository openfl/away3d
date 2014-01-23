/**
 * TextureMultiPassMaterial is a multi-pass material that uses a texture to define the surface's diffuse reflection colour (albedo).
 */
package away3d.materials;

import away3d.textures.Texture2DBase;


class TextureMultiPassMaterial extends MultiPassMaterialBase {
    public var animateUVs(get_animateUVs, set_animateUVs):Bool;
    public var texture(get_texture, set_texture):Texture2DBase;
    public var ambientTexture(get_ambientTexture, set_ambientTexture):Texture2DBase;

    private var _animateUVs:Bool;
/**
	 * Creates a new TextureMultiPassMaterial.
	 * @param texture The texture used for the material's albedo color.
	 * @param smooth Indicates whether the texture should be filtered when sampled. Defaults to true.
	 * @param repeat Indicates whether the texture should be tiled when sampled. Defaults to true.
	 * @param mipmap Indicates whether or not any used textures should use mipmapping. Defaults to true.
	 */

    public function new(texture:Texture2DBase = null, smooth:Bool = true, repeat:Bool = false, mipmap:Bool = true) {
        super();
        this.texture = texture;
        this.smooth = smooth;
        this.repeat = repeat;
        this.mipmap = mipmap;
    }

/**
	 * Specifies whether or not the UV coordinates should be animated using a transformation matrix.
	 */

    public function get_animateUVs():Bool {
        return _animateUVs;
    }

    public function set_animateUVs(value:Bool):Bool {
        _animateUVs = value;
        return value;
    }

/**
	 * The texture object to use for the albedo colour.
	 */

    public function get_texture():Texture2DBase {
        return diffuseMethod.texture;
    }

    public function set_texture(value:Texture2DBase):Texture2DBase {
        diffuseMethod.texture = value;
        return value;
    }

/**
	 * The texture object to use for the ambient colour.
	 */

    public function get_ambientTexture():Texture2DBase {
        return ambientMethod.texture;
    }

    public function set_ambientTexture(value:Texture2DBase):Texture2DBase {
        ambientMethod.texture = value;
        diffuseMethod.useAmbientTexture = cast((value!=null), Bool);
        return value;
    }

    override private function updateScreenPasses():Void {
        super.updateScreenPasses();
        if (_effectsPass != null) _effectsPass.animateUVs = _animateUVs;
    }

}

