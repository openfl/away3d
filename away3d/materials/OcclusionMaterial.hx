package away3d.materials;

import away3d.cameras.Camera3D;
import away3d.core.managers.Stage3DProxy;

/**
 * OcclusionMaterial is a ColorMaterial for an object to prevents drawing anything that is placed behind it.
 */
class OcclusionMaterial extends ColorMaterial
{
	public var occlude(get, set):Bool;
	
	private var _occlude:Bool = true;
	
	/**
	 * Creates a new OcclusionMaterial object.
	 * @param occlude Whether or not to occlude other objects.
	 * @param color The material's diffuse surface color.
	 * @param alpha The material's surface alpha.
	 */
	public function new(occlude:Bool = true, color:Int = 0xcccccc, alpha:Float = 1)
	{
		super(color, alpha);
		this.occlude = occlude;
	}
	
	/**
	 * Whether or not an object with this material applied hides other objects.
	 */
	private function get_occlude():Bool
	{
		return _occlude;
	}
	
	private function set_occlude(value:Bool):Bool
	{
		_occlude = value;
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function activatePass(index:Int, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		if (occlude)
			stage3DProxy._context3D.setColorMask(false, false, false, false);
		super.activatePass(index, stage3DProxy, camera);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function deactivatePass(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		super.deactivatePass(index, stage3DProxy);
		stage3DProxy._context3D.setColorMask(true, true, true, true);
	}
}