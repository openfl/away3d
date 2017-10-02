package away3d.animators;

import away3d.core.managers.Stage3DProxy;
import away3d.materials.passes.MaterialPassBase;

import openfl.display3D.Context3D;
import openfl.Vector;

/**
 * The animation data set containing the Spritesheet animation state data.
 *
 * @see away3d.animators.SpriteSheetAnimator
 * @see away3d.animators.SpriteSheetAnimationState
 */
class SpriteSheetAnimationSet extends AnimationSetBase implements IAnimationSet
{
	private var _agalCode:String;
	
	public function new()
	{
		super();
	}
	
	/**
	 * @inheritDoc
	 */
	public function getAGALVertexCode(pass:MaterialPassBase, sourceRegisters:Vector<String>, targetRegisters:Vector<String>, profile:String):String
	{
		var len:Int = targetRegisters.length;
		_agalCode = "";
		for(i in 0...len) {
			_agalCode += "mov " + targetRegisters[i] + ", " + sourceRegisters[i] + "\n";
		}
		return _agalCode;
	}
	
	/**
	 * @inheritDoc
	 */
	public function activate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):Void
	{
	}
	
	/**
	 * @inheritDoc
	 */
	public function deactivate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):Void
	{
		var context:Context3D = stage3DProxy.context3D;
		context.setVertexBufferAt(0, null);
	}
	
	/**
	 * @inheritDoc
	 */
	public function getAGALFragmentCode(pass:MaterialPassBase, shadedTarget:String, profile:String):String
	{
		return "";
	}
	
	/**
	 * @inheritDoc
	 */
	public function getAGALUVCode(pass:MaterialPassBase, UVSource:String, UVTarget:String):String
	{
		var tempUV:String = "vt" + UVSource.substring(2, 3);
		var idConstant:Int = pass.numUsedVertexConstants;
		var constantRegID:String = "vc" + idConstant;
		
		_agalCode = "mov " + tempUV + ", " + UVSource + "\n";
		_agalCode += "mul " + tempUV + ".xy, " + tempUV + ".xy, " + constantRegID + ".zw \n";
		_agalCode += "add " + tempUV + ".xy, " + tempUV + ".xy, " + constantRegID + ".xy \n";
		_agalCode += "mov " + UVTarget + ", " + tempUV + "\n";
		
		return _agalCode;
		
	}
	
	/**
	 * @inheritDoc
	 */
	public function doneAGALCode(pass:MaterialPassBase):Void
	{
	}
}