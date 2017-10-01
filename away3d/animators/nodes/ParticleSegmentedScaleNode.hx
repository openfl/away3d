package away3d.animators.nodes;

import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.data.ParticlePropertiesMode;
import away3d.animators.states.ParticleSegmentedScaleState;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.materials.passes.MaterialPassBase;

import openfl.geom.Vector3D;
import openfl.Vector;

class ParticleSegmentedScaleNode extends ParticleNodeBase
{
	/** @private */
	@:allow(away3d) private static inline var START_INDEX:Int = 0;
	
	/** @private */
	@:allow(away3d) private var _startScale:Vector3D;
	/** @private */
	@:allow(away3d) private var _endScale:Vector3D;
	/** @private */
	@:allow(away3d) private var _numSegmentPoint:Int;
	/** @private */
	@:allow(away3d) private var _segmentScales:Vector<Vector3D>;
	
	/**
	 *
	 * @param	numSegmentPoint
	 * @param	startScale
	 * @param	endScale
	 * @param	segmentScales Vector.<Vector3D>. the x,y,z present the scaleX,scaleY,scaleX, and w present the life
	 */
	public function new(numSegmentPoint:Int, startScale:Vector3D, endScale:Vector3D, segmentScales:Vector<Vector3D>)
	{
		_stateConstructor = cast ParticleSegmentedScaleState.new;
		
		//because of the stage3d register limitation, it only support the global mode
		super("ParticleSegmentedScale", ParticlePropertiesMode.GLOBAL, 0, 3);
		
		_numSegmentPoint = numSegmentPoint;
		_startScale = startScale;
		_endScale = endScale;
		_segmentScales = segmentScales;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		var code:String = "";
		
		var accScale:ShaderRegisterElement;
		accScale = animationRegisterCache.getFreeVertexVectorTemp();
		animationRegisterCache.addVertexTempUsages(accScale, 1);
		
		var tempScale:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
		animationRegisterCache.addVertexTempUsages(tempScale, 1);
		
		var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
		var accTime:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 0);
		var tempTime:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 1);
		
		animationRegisterCache.removeVertexTempUsage(accScale);
		animationRegisterCache.removeVertexTempUsage(tempScale);
		
		var startValue:ShaderRegisterElement;
		var deltaValues:Vector<ShaderRegisterElement>;
		
		
		startValue = animationRegisterCache.getFreeVertexConstant();
		animationRegisterCache.setRegisterIndex(this, START_INDEX, startValue.index);
		deltaValues = new Vector<ShaderRegisterElement>();
		for (i in 0...(_numSegmentPoint + 1))
		{
			deltaValues.push(animationRegisterCache.getFreeVertexConstant());
		}
		
		
		code += "mov " + accScale + "," + startValue + "\n";
		
		for (i in 0..._numSegmentPoint)
		{
			switch (i)
			{
				case 0:
					code += "min " + tempTime + "," + animationRegisterCache.vertexLife + "," + deltaValues[i] + ".w\n";
				case 1:
					code += "sub " + accTime + "," + animationRegisterCache.vertexLife + "," + deltaValues[i - 1] + ".w\n";
					code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
					code += "min " + tempTime + "," + tempTime + "," + deltaValues[i] + ".w\n";
				default:
					code += "sub " + accTime + "," + accTime + "," + deltaValues[i - 1] + ".w\n";
					code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
					code += "min " + tempTime + "," + tempTime + "," + deltaValues[i] + ".w\n";
			}
			code += "mul " + tempScale + "," + tempTime + "," + deltaValues[i] + "\n";
			code += "add " + accScale + "," + accScale + "," + tempScale + "\n";
		}
		
		//for the last segment:
		if (_numSegmentPoint == 0)
			tempTime = animationRegisterCache.vertexLife;
		else
		{
			switch(_numSegmentPoint)
			{
				case 1:
					code += "sub " + accTime + "," + animationRegisterCache.vertexLife + "," + deltaValues[_numSegmentPoint - 1] + ".w\n";
				default:
					code += "sub " + accTime + "," + accTime + "," + deltaValues[_numSegmentPoint - 1] + ".w\n";
			}
			code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
		}
		
		code += "mul " + tempScale + "," + tempTime + "," + deltaValues[_numSegmentPoint] + "\n";
		code += "add " + accScale + "," + accScale + "," + tempScale + "\n";
		code += "mul " + animationRegisterCache.scaleAndRotateTarget + ".xyz," + animationRegisterCache.scaleAndRotateTarget + ".xyz," + accScale + ".xyz\n";
		
		return code;
	}
	
}