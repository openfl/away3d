package away3d.materials;

import openfl.display.BlendMode;

/**
 * ColorMaterial is a single-pass material that uses a flat color as the surface's diffuse reflection value.
 */
class ColorMaterial extends SinglePassMaterialBase
{
	public var alpha(get, set):Float;
	public var color(get, set):Int;
	
	private var _diffuseAlpha:Float = 1;
	
	/**
	 * Creates a new ColorMaterial object.
	 * @param color The material's diffuse surface color.
	 * @param alpha The material's surface alpha.
	 */
	public function new(color:Int = 0xcccccc, alpha:Float = 1)
	{
		super();
		this.color = color;
		this.alpha = alpha;
	}
	
	/**
	 * The alpha of the surface.
	 */
	private function get_alpha():Float
	{
		return _screenPass.diffuseMethod.diffuseAlpha;
	}
	
	private function set_alpha(value:Float):Float
	{
		if (value > 1)
			value = 1;
		else if (value < 0)
			value = 0;
		_screenPass.diffuseMethod.diffuseAlpha = _diffuseAlpha = value;
		_screenPass.preserveAlpha = requiresBlending;
		_screenPass.setBlendMode(blendMode == BlendMode.NORMAL && requiresBlending? BlendMode.LAYER : blendMode);
		return value;
	}
	
	/**
	 * The diffuse reflectivity color of the surface.
	 */
	private function get_color():Int
	{
		return _screenPass.diffuseMethod.diffuseColor;
	}
	
	private function set_color(value:Int):Int
	{
		_screenPass.diffuseMethod.diffuseColor = value;
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function get_requiresBlending():Bool
	{
		return super.requiresBlending || _diffuseAlpha < 1;
	}
}