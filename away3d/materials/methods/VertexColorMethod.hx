package away3d.materials.methods;

import away3d.materials.compilation.ShaderRegisterCache;
import openfl.display.BlendMode;
import away3d.core.base.data.VertexDefinition.AttributeDefinition;
import away3d.materials.compilation.ShaderRegisterElement;

/**
 * A method that applies per-vertex colors from the "color" attribute. Overwites
 * colors from other sources (e.g., the color applied by `ColorMaterial`).
 */
class VertexColorMethod extends EffectMethodBase
{
	/**
	 * The vertex's color, in RGB format.
	 */
	public static var COLOR(default, null):AttributeDefinition = new AttributeDefinition("color", 3);
	
	/**
	 * The vertex's color, in RGBA format.
	 */
	public static var COLOR_WITH_ALPHA(default, null):AttributeDefinition = new AttributeDefinition("color", 4);
	
	/**
	 * Whether this method supports alpha blending. If this is true, the
	 * material must have an appropriate `blendMode` (typically `LAYER`).
	 */
	public var alphaEnabled(default, null):Bool;
	
	private var colorVarying:ShaderRegisterElement;
	
	public function new(?enableAlpha:Bool = false)
	{
		super(enableAlpha ? [COLOR_WITH_ALPHA] : [COLOR]);
		alphaEnabled = enableAlpha;
	}
	
	override private function getVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		var color:ShaderRegisterElement = sharedRegisters.custom["color"];
		colorVarying = regCache.getFreeVarying();
		
		return 'mov $colorVarying, $color\n';
	}

	override private function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		if (alphaEnabled) {
			return 'mov $targetReg, $colorVarying\n';
		} else {
			return 'mov $targetReg.xyz, $colorVarying.xyz\n';
		}
	}
}
