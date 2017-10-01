package away3d.animators.nodes;

import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.data.ColorSegmentPoint;
import away3d.animators.data.ParticlePropertiesMode;
import away3d.animators.ParticleAnimationSet;
import away3d.animators.states.ParticleSegmentedColorState;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.materials.passes.MaterialPassBase;

import openfl.errors.Error;
import openfl.geom.ColorTransform;
import openfl.Vector;

class ParticleSegmentedColorNode extends ParticleNodeBase
{
	/** @private */
	@:allow(away3d) private static inline var START_MULTIPLIER_INDEX:Int = 0;
	
	/** @private */
	@:allow(away3d) private static inline var START_OFFSET_INDEX:Int = 1;
	
	/** @private */
	@:allow(away3d) private static inline var TIME_DATA_INDEX:Int = 2;
	
	/** @private */
	@:allow(away3d) private var _usesMultiplier:Bool;
	/** @private */
	@:allow(away3d) private var _usesOffset:Bool;
	/** @private */
	@:allow(away3d) private var _startColor:ColorTransform;
	/** @private */
	@:allow(away3d) private var _endColor:ColorTransform;
	/** @private */
	@:allow(away3d) private var _numSegmentPoint:Int;
	/** @private */
	@:allow(away3d) private var _segmentPoints:Vector<ColorSegmentPoint>;
	
	public function new(usesMultiplier:Bool, usesOffset:Bool, numSegmentPoint:Int, startColor:ColorTransform, endColor:ColorTransform, segmentPoints:Vector<ColorSegmentPoint>)
	{
		_stateConstructor = cast ParticleSegmentedColorState.new;
		
		//because of the stage3d register limitation, it only support the global mode
		super("ParticleSegmentedColor", ParticlePropertiesMode.GLOBAL, 0, ParticleAnimationSet.COLOR_PRIORITY);
		
		if (numSegmentPoint > 4)
			throw(new Error("the numSegmentPoint must be less or equal 4"));
		_usesMultiplier = usesMultiplier;
		_usesOffset = usesOffset;
		_numSegmentPoint = numSegmentPoint;
		_startColor = startColor;
		_endColor = endColor;
		_segmentPoints = segmentPoints;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):Void
	{
		if (_usesMultiplier)
			particleAnimationSet.hasColorMulNode = true;
		if (_usesOffset)
			particleAnimationSet.hasColorAddNode = true;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		var code:String = "";
		if (animationRegisterCache.needFragmentAnimation) {
			var accMultiplierColor:ShaderRegisterElement = null;
			//var accOffsetColor:ShaderRegisterElement;
			if (_usesMultiplier) {
				accMultiplierColor = animationRegisterCache.getFreeVertexVectorTemp();
				animationRegisterCache.addVertexTempUsages(accMultiplierColor, 1);
			}
			
			var tempColor:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			animationRegisterCache.addVertexTempUsages(tempColor, 1);
			
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var accTime:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 0);
			var tempTime:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 1);
			
			if (_usesMultiplier)
				animationRegisterCache.removeVertexTempUsage(accMultiplierColor);
			
			animationRegisterCache.removeVertexTempUsage(tempColor);
			
			//for saving all the life values (at most 4)
			var lifeTimeRegister:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, TIME_DATA_INDEX, lifeTimeRegister.index);
			
			var startMulValue:ShaderRegisterElement = null;
			var deltaMulValues:Vector<ShaderRegisterElement> = null;
			if (_usesMultiplier) {
				startMulValue = animationRegisterCache.getFreeVertexConstant();
				animationRegisterCache.setRegisterIndex(this, START_MULTIPLIER_INDEX, startMulValue.index);
				deltaMulValues = new Vector<ShaderRegisterElement>();
				for (i in 0...(_numSegmentPoint + 1))
					deltaMulValues.push(animationRegisterCache.getFreeVertexConstant());
			}
			
			var startOffsetValue:ShaderRegisterElement = null;
			var deltaOffsetValues:Vector<ShaderRegisterElement> = null;
			if (_usesOffset) {
				startOffsetValue = animationRegisterCache.getFreeVertexConstant();
				animationRegisterCache.setRegisterIndex(this, START_OFFSET_INDEX, startOffsetValue.index);
				deltaOffsetValues = new Vector<ShaderRegisterElement>();
				for (i in 0..._numSegmentPoint)
					deltaOffsetValues.push(animationRegisterCache.getFreeVertexConstant());
			}
			
			if (_usesMultiplier)
				code += "mov " + accMultiplierColor + "," + startMulValue + "\n";
			if (_usesOffset)
				code += "add " + animationRegisterCache.colorAddTarget + "," + animationRegisterCache.colorAddTarget + "," + startOffsetValue + "\n";
			
			for (i in 0..._numSegmentPoint) {
				switch (i) {
					case 0:
						code += "min " + tempTime + "," + animationRegisterCache.vertexLife + "," + lifeTimeRegister + ".x\n";
					case 1:
						code += "sub " + accTime + "," + animationRegisterCache.vertexLife + "," + lifeTimeRegister + ".x\n";
						code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
						code += "min " + tempTime + "," + tempTime + "," + lifeTimeRegister + ".y\n";
					case 2:
						code += "sub " + accTime + "," + accTime + "," + lifeTimeRegister + ".y\n";
						code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
						code += "min " + tempTime + "," + tempTime + "," + lifeTimeRegister + ".z\n";
					case 3:
						code += "sub " + accTime + "," + accTime + "," + lifeTimeRegister + ".z\n";
						code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
						code += "min " + tempTime + "," + tempTime + "," + lifeTimeRegister + ".w\n";
				}
				if (_usesMultiplier) {
					code += "mul " + tempColor + "," + tempTime + "," + deltaMulValues[i] + "\n";
					code += "add " + accMultiplierColor + "," + accMultiplierColor + "," + tempColor + "\n";
				}
				if (_usesOffset) {
					code += "mul " + tempColor + "," + tempTime + "," + deltaOffsetValues[i] + "\n";
					code += "add " + animationRegisterCache.colorAddTarget + "," + animationRegisterCache.colorAddTarget + "," + tempColor + "\n";
				}
			}
			
			//for the last segment:
			if (_numSegmentPoint == 0)
				tempTime = animationRegisterCache.vertexLife;
			else {
				switch (_numSegmentPoint) {
					case 1:
						code += "sub " + accTime + "," + animationRegisterCache.vertexLife + "," + lifeTimeRegister + ".x\n";
					case 2:
						code += "sub " + accTime + "," + accTime + "," + lifeTimeRegister + ".y\n";
					case 3:
						code += "sub " + accTime + "," + accTime + "," + lifeTimeRegister + ".z\n";
					case 4:
						code += "sub " + accTime + "," + accTime + "," + lifeTimeRegister + ".w\n";
				}
				code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
			}
			if (_usesMultiplier) {
				code += "mul " + tempColor + "," + tempTime + "," + deltaMulValues[_numSegmentPoint] + "\n";
				code += "add " + accMultiplierColor + "," + accMultiplierColor + "," + tempColor + "\n";
				code += "mul " + animationRegisterCache.colorMulTarget + "," + animationRegisterCache.colorMulTarget + "," + accMultiplierColor + "\n";
			}
			if (_usesOffset) {
				code += "mul " + tempColor + "," + tempTime + "," + deltaOffsetValues[_numSegmentPoint] + "\n";
				code += "add " + animationRegisterCache.colorAddTarget + "," + animationRegisterCache.colorAddTarget + "," + tempColor + "\n";
			}
			
		}
		return code;
	}
	
}