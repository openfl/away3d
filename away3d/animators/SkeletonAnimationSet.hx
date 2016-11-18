package away3d.animators;

import away3d.core.managers.Stage3DProxy;
import away3d.materials.passes.MaterialPassBase;

import openfl.display3D.Context3D;
import openfl.Vector;

/**
 * The animation data set used by skeleton-based animators, containing skeleton animation data.
 *
 * @see away3d.animators.SkeletonAnimator
 */
class SkeletonAnimationSet extends AnimationSetBase implements IAnimationSet
{
	public var jointsPerVertex(get, never):Int;
	
	private var _jointsPerVertex:Int;
	
	/**
	 * Returns the amount of skeleton joints that can be linked to a single vertex via skinned weight values. For GPU-base animation, the
	 * maximum allowed value is 4.
	 */
	private function get_jointsPerVertex():Int
	{
		return _jointsPerVertex;
	}
	
	/**
	 * Creates a new <code>SkeletonAnimationSet</code> object.
	 *
	 * @param jointsPerVertex Sets the amount of skeleton joints that can be linked to a single vertex via skinned weight values. For GPU-base animation, the maximum allowed value is 4. Defaults to 4.
	 */
	public function new(jointsPerVertex:Int = 4)
	{
		_jointsPerVertex = jointsPerVertex;
		super();
	}
	
	/**
	 * @inheritDoc
	 */
	public function getAGALVertexCode(pass:MaterialPassBase, sourceRegisters:Vector<String>, targetRegisters:Vector<String>, profile:String):String
	{
		var len:Int = sourceRegisters.length;
		
		var indexOffset0:Int = pass.numUsedVertexConstants;
		var indexOffset1:Int = indexOffset0 + 1;
		var indexOffset2:Int = indexOffset0 + 2;
		var indexStream:String = "va" + pass.numUsedStreams;
		var weightStream:String = "va" + (pass.numUsedStreams + 1);
		var indices:Array<String> = [indexStream + ".x", indexStream + ".y", indexStream + ".z", indexStream + ".w"];
		var weights:Array<String> = [weightStream + ".x", weightStream + ".y", weightStream + ".z", weightStream + ".w"];
		var temp1:String = findTempReg(targetRegisters);
		var temp2:String = findTempReg(targetRegisters, temp1);
		var dot:String = "dp4";
		var code:String = "";
		
		for (i in 0...len) {
			
			var src:String = sourceRegisters[i];
			
			for (j in 0..._jointsPerVertex) {
				code += dot + " " + temp1 + ".x, " + src + ", vc[" + indices[j] + "+" + indexOffset0 + "]		\n" +
					dot + " " + temp1 + ".y, " + src + ", vc[" + indices[j] + "+" + indexOffset1 + "]    	\n" +
					dot + " " + temp1 + ".z, " + src + ", vc[" + indices[j] + "+" + indexOffset2 + "]		\n" +
					"mov " + temp1 + ".w, " + src + ".w		\n" +
					"mul " + temp1 + ", " + temp1 + ", " + weights[j] + "\n"; // apply weight
				
				// add or mov to target. Need to write to a temp reg first, because an output can be a target
				if (j == 0)
					code += "mov " + temp2 + ", " + temp1 + "\n";
				else
					code += "add " + temp2 + ", " + temp2 + ", " + temp1 + "\n";
			}
			// switch to dp3 once positions have been transformed, from now on, it should only be vectors instead of points
			dot = "dp3";
			code += "mov " + targetRegisters[i] + ", " + temp2 + "\n";
		}
		
		return code;
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
		var streamOffset:Int = pass.numUsedStreams;
		var context:Context3D = stage3DProxy._context3D;
		context.setVertexBufferAt(streamOffset, null);
		context.setVertexBufferAt(streamOffset + 1, null);
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
		return "mov " + UVTarget + "," + UVSource + "\n";
	}
	
	/**
	 * @inheritDoc
	 */
	public function doneAGALCode(pass:MaterialPassBase):Void
	{
	}
}