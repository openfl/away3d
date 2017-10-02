package away3d.materials;

import away3d.textures.Texture2DBase;
import away3d.textures.Anisotropy;

/**
 * TextureMultiPassMaterial is a multi-pass material that uses a texture to define the surface's diffuse reflection colour (albedo).
 */
class TextureMultiPassMaterial extends MultiPassMaterialBase
{
	public var animateUVs(get, set):Bool;
	public var texture(get, set):Texture2DBase;
	public var ambientTexture(get, set):Texture2DBase;
	
	private var _animateUVs:Bool;

	/**
	 * Creates a new TextureMultiPassMaterial.
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
	 * Specifies whether or not the UV coordinates should be animated using a transformation matrix.
	 */
	private function get_animateUVs():Bool
	{
		return _animateUVs;
	}
	
	private function set_animateUVs(value:Bool):Bool
	{
		_animateUVs = value;
		return value;
	}
	
	/**
	 * The texture object to use for the albedo colour.
	 */
	private function get_texture():Texture2DBase
	{
		return diffuseMethod.texture;
	}
	
	private function set_texture(value:Texture2DBase):Texture2DBase
	{
		diffuseMethod.texture = value;
		return value;
	}
	
	/**
	 * The texture object to use for the ambient colour.
	 */
	private function get_ambientTexture():Texture2DBase
	{
		return ambientMethod.texture;
	}
	
	private function set_ambientTexture(value:Texture2DBase):Texture2DBase
	{
		ambientMethod.texture = value;
		diffuseMethod.useAmbientTexture = (value != null);
		return value;
	}
	
	override private function updateScreenPasses():Void
	{
		super.updateScreenPasses();

		if (_effectsPass != null) {
			_effectsPass.animateUVs = _animateUVs;
		}
		if (_casterLightPass != null) {
			_casterLightPass.animateUVs = _animateUVs;
		}
		if (_nonCasterLightPasses != null) {
			var length:UInt = _nonCasterLightPasses.length;
			for (i in 0...length) {
				_nonCasterLightPasses[i].animateUVs = _animateUVs;
			}
		}
	}
}