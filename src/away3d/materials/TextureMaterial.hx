/**
 * TextureMaterial is a single-pass material that uses a texture to define the surface's diffuse reflection colour (albedo).
 */
package away3d.materials;

import flash.display.BlendMode;
import flash.geom.ColorTransform;
import away3d.textures.Texture2DBase;
class TextureMaterial extends SinglePassMaterialBase {
    public var animateUVs(get_animateUVs, set_animateUVs):Bool;
    public var alpha(get_alpha, set_alpha):Float;
    public var texture(get_texture, set_texture):Texture2DBase;
    public var ambientTexture(get_ambientTexture, set_ambientTexture):Texture2DBase;

/**
	 * Creates a new TextureMaterial.
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
	 * Specifies whether or not the UV coordinates should be animated using IRenderable's uvTransform matrix.
	 *
	 * @see IRenderable.uvTransform
	 */

    public function get_animateUVs():Bool {
        return _screenPass.animateUVs;
    }

    public function set_animateUVs(value:Bool):Bool {
        _screenPass.animateUVs = value;
        return value;
    }

/**
	 * The alpha of the surface.
	 */

    public function get_alpha():Float {
        return (_screenPass.colorTransform != null) ? _screenPass.colorTransform.alphaMultiplier : 1;
    }

    public function set_alpha(value:Float):Float {
        if (value > 1) value = 1
        else if (value < 0) value = 0;
        if (colorTransform == null)
            colorTransform = new ColorTransform();
        colorTransform.alphaMultiplier = value;
        _screenPass.preserveAlpha = requiresBlending;
        _screenPass.setBlendMode(blendMode == BlendMode.NORMAL && (requiresBlending) ? BlendMode.LAYER : blendMode);
        return value;
    }

/**
	 * The texture object to use for the albedo colour.
	 */

    public function get_texture():Texture2DBase {
        return _screenPass.diffuseMethod.texture;
    }

    public function set_texture(value:Texture2DBase):Texture2DBase {
        _screenPass.diffuseMethod.texture = value;
        return value;
    }

/**
	 * The texture object to use for the ambient colour.
	 */

    public function get_ambientTexture():Texture2DBase {
        return _screenPass.ambientMethod.texture;
    }

    public function set_ambientTexture(value:Texture2DBase):Texture2DBase {
        _screenPass.ambientMethod.texture = value;
        _screenPass.diffuseMethod.useAmbientTexture = cast((value != null), Bool);
        return value;
    }

}

