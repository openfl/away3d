package away3d.materials;

import away3d.materials.passes.OrthoSegmentPass;

/**
	* OrthoSegmentMaterial is a material exclusively used to render wireframe objects
	*
	* @see away3d.entities.Lines
	*/
class OrthoSegmentMaterial extends MaterialBase
{
	private var _screenPass:OrthoSegmentPass;
	
	/**
		* Creates a new OrthoSegmentMaterial object.
		*
		* @param thickness The thickness of the wireframe lines.
		*/
	public function new(thickness:Float = 1.25)
	{
		super();
		
		bothSides = true;
		addPass(_screenPass = new OrthoSegmentPass(thickness));
		_screenPass.material = this;
	}
}