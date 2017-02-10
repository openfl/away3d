package away3d.materials;

import away3d.textures.Texture2DBase;
import away3d.textures.Anisotropy;

import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

/**
 * TextureMaterial is a single-pass material that uses a texture to define the surface's diffuse reflection colour (albedo).
 */
class TextureMaterial extends SinglePassMaterialBase
{
	public var animateUVs(get, set):Bool;
	public var animateUVs2(get, set):Bool;
	public var alpha(get, set):Float;
	public var texture(get, set):Texture2DBase;
	public var ambientTexture(get, set):Texture2DBase;
	
	/**
	 * Creates a new TextureMaterial.
	 * @param texture The texture used for the material's albedo color.
	 * @param smooth Indicates whether the texture should be filtered when sampled. Defaults to true.
	 * @param repeat Indicates whether the texture should be tiled when sampled. Defaults to true.
	 * @param mipmap Indicates whether or not any used textures should use mipmapping. Defaults to true.
	 * @param anisotropy Indicates the number of samples to use if Anisotropic mipmap filtering is applied
	 */
	public function new(texture:Texture2DBase = null, smooth:Bool = true, repeat:Bool = false, mipmap:Bool = true, anisotropy:Anisotropy = ANISOTROPIC2X)
	{
		super();
		this.texture = texture;
		this.smooth = smooth;
		this.repeat = repeat;
		this.mipmap = mipmap;
		this.anisotropy = anisotropy;
	}

	/**
	 * Specifies whether or not the UV coordinates should be animated using IRenderable's uvTransform matrix.
	 *
	 * @see IRenderable.uvTransform
	 */
	private function get_animateUVs():Bool
	{
		return _screenPass.animateUVs;
	}
	
	private function set_animateUVs(value:Bool):Bool
	{
		_screenPass.animateUVs = value;
		return value;
	}
	
	/**
	 * Specifies whether or not the UV coordinates should be animated using IRenderable's uvTransform matrix.
	 *
	 * @see IRenderable.uvTransform
	 */
	private function get_animateUVs2():Bool
	{
		return _screenPass.animateUVs2;
	}
	
	private function set_animateUVs2(value:Bool):Bool
	{
		_screenPass.animateUVs2 = value;
		return value;
	}
	
	/**
	 * The alpha of the surface.
	 */
	private function get_alpha():Float
	{
		return (_screenPass.colorTransform != null)? _screenPass.colorTransform.alphaMultiplier : 1;
	}
	
	private function set_alpha(value:Float):Float
	{
		if (value > 1)
			value = 1;
		else if (value < 0)
			value = 0;
		
		if (colorTransform == null)
			colorTransform = new ColorTransform();
		colorTransform.alphaMultiplier = value;
		_screenPass.preserveAlpha = requiresBlending;
		_screenPass.setBlendMode(blendMode == BlendMode.NORMAL && requiresBlending? BlendMode.LAYER : blendMode);
		return value;
	}
	
	/**
	 * The texture object to use for the albedo colour.
	 */
	private function get_texture():Texture2DBase
	{
		return _screenPass.diffuseMethod.texture;
	}
	
	private function set_texture(value:Texture2DBase):Texture2DBase
	{
		_screenPass.diffuseMethod.texture = value;
		return value;
	}
	
	/**
	 * The texture object to use for the ambient colour.
	 */
	private function get_ambientTexture():Texture2DBase
	{
		return _screenPass.ambientMethod.texture;
	}
	
	private function set_ambientTexture(value:Texture2DBase):Texture2DBase
	{
		_screenPass.ambientMethod.texture = value;
		_screenPass.diffuseMethod.useAmbientTexture = (value != null);
		return value;
	}
}