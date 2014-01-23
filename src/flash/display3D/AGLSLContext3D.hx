/****
* 
****/

package flash.display3D;
import flash.geom.Matrix3D;
import openfl.gl.GL;
import openfl.gl.GLUniformLocation;

/**
 * ...
 * @author 
 */
class AGLSLContext3D extends Context3D
{
	private var _yFlip:Float;
 
	public function new ()
	{
		super();
		_yFlip =-1;
	}
    override public function setCulling(triangleFaceToCull:Int):Void 
    {
	   super.setCulling(triangleFaceToCull); 
		switch (triangleFaceToCull) 
		{
			case Context3DTriangleFace.FRONT:
				this._yFlip = -1;
	 
			case Context3DTriangleFace.BACK:
				this._yFlip = 1; // checked
		 
			case Context3DTriangleFace.FRONT_AND_BACK:
				this._yFlip = 1;
			 
			case Context3DTriangleFace.NONE:
				this._yFlip = 1; // checked
			 
			default:
				throw "Unknown culling mode " + triangleFaceToCull + ".";
			 
		}
    }
	 
   /**
    * A flash.geom.Matrix3D equivalent of the current Matrix
    */


  
    override public function setProgramConstantsFromMatrix(programType:Context3DProgramType, firstRegister:Int, matrix:Matrix3D, transposedMatrix:Bool = false):Void 
    {
	  //todo
		var d = matrix.rawData;
		if (transposedMatrix) {
			this.setProgramConstantsFromVector(programType, firstRegister, flash.Vector.ofArray([ d[0], d[4], d[8], d[12] ]), 1);  
			this.setProgramConstantsFromVector(programType, firstRegister + 1, flash.Vector.ofArray([ d[1], d[5], d[9], d[13] ]), 1);
			this.setProgramConstantsFromVector(programType, firstRegister + 2, flash.Vector.ofArray([ d[2], d[6], d[10], d[14] ]), 1);
			this.setProgramConstantsFromVector(programType, firstRegister + 3, flash.Vector.ofArray([ d[3], d[7], d[11], d[15] ]), 1);
		} else {
			this.setProgramConstantsFromVector(programType, firstRegister, flash.Vector.ofArray([ d[0], d[1], d[2], d[3] ]), 1);
			this.setProgramConstantsFromVector(programType, firstRegister + 1, flash.Vector.ofArray([ d[4], d[5], d[6], d[7] ]), 1);
			this.setProgramConstantsFromVector(programType, firstRegister + 2, flash.Vector.ofArray([ d[8], d[9], d[10], d[11] ]), 1);
			this.setProgramConstantsFromVector(programType, firstRegister + 3, flash.Vector.ofArray([ d[12], d[13], d[14], d[15] ]), 1);
		}
    }
    override public function drawTriangles(indexBuffer:IndexBuffer3D, firstIndex:Int = 0, numTriangles:Int = -1):Void  
	{ 
	     //todo 
		var location:GLUniformLocation = GL.getUniformLocation(currentProgram.glProgram, "yflip");   
		GL.uniform1f(location, this._yFlip);
		super.drawTriangles(indexBuffer, firstIndex, numTriangles);
	}
	
	 override public function present():Void  
	{
		#if html5
		     this.drawing = false;
		#else
	         super.present();
		#end
		
		 
	}

	
}