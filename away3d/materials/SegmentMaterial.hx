package away3d.materials;

import away3d.materials.passes.SegmentPass;

/**
 * SegmentMaterial is a material exclusively used to render wireframe objects
 *
 * @see away3d.entities.Lines
 */
class SegmentMaterial extends MaterialBase
{
	private var _screenPass:SegmentPass;
	
	/**
	 * Creates a new SegmentMaterial object.
	 *
	 * @param thickness The thickness of the wireframe lines.
	 */
	public function new(thickness:Float = 1.25)
	{
		super();
		
		bothSides = true;
		addPass(_screenPass = new SegmentPass(thickness));
		_screenPass.material = this;
	}
}