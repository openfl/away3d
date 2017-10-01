package away3d.materials;

/**
 * Enumeration class for defining which lighting types affect the specific material
 * lighting component (diffuse and specular). This can be useful if, for example, you
 * want to use light probes for diffuse global lighting, but want specular reflections from
 * traditional light sources without those affecting the diffuse light.
 *
 * @see away3d.materials.ColorMaterial.diffuseLightSources
 * @see away3d.materials.ColorMaterial.specularLightSources
 * @see away3d.materials.TextureMaterial.diffuseLightSources
 * @see away3d.materials.TextureMaterial.specularLightSources
 */
class LightSources
{
	/**
	 * Defines normal lights are to be used as the source for the lighting
	 * component.
	 */
	public static inline var LIGHTS:Int = 0x01;
	
	/**
	 * Defines that global lighting probes are to be used as the source for the
	 * lighting component.
	 */
	public static inline var PROBES:Int = 0x02;
	
	/**
	 * Defines that both normal and global lighting probes  are to be used as the
	 * source for the lighting component. This is equivalent to LIGHTS | PROBES.
	 */
	public static inline var ALL:Int = 0x03;
}