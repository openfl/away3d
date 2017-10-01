package away3d.materials.methods;

import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterData;
import away3d.materials.compilation.ShaderRegisterElement;

import openfl.Vector;

/**
 * CelDiffuseMethod provides a shading method to add diffuse cel (cartoon) shading.
 */
class CelDiffuseMethod extends CompositeDiffuseMethod
{
	public var levels(get, set):Int;
	public var smoothness(get, set):Float;
	
	private var _levels:Int;
	private var _dataReg:ShaderRegisterElement;
	private var _smoothness:Float = .1;
	
	/**
	 * Creates a new CelDiffuseMethod object.
	 * @param levels The amount of shadow gradations.
	 * @param baseDiffuseMethod An optional diffuse method on which the cartoon shading is based. If omitted, BasicDiffuseMethod is used.
	 */
	public function new(levels:Int = 3, baseDiffuseMethod:BasicDiffuseMethod = null)
	{
		super(clampDiffuse, baseDiffuseMethod);
		
		_levels = levels;
	}

	/**
	 * @inheritDoc
	 */
	override private function initConstants(vo:MethodVO):Void
	{
		var data:Vector<Float> = vo.fragmentData;
		var index:Int = vo.secondaryFragmentConstantsIndex;
		super.initConstants(vo);
		data[index + 1] = 1;
		data[index + 2] = 0;
	}

	/**
	 * The amount of shadow gradations.
	 */
	private function get_levels():Int
	{
		return _levels;
	}
	
	private function set_levels(value:Int):Int
	{
		_levels = value;
		return value;
	}
	
	/**
	 * The smoothness of the edge between 2 shading levels.
	 */
	private function get_smoothness():Float
	{
		return _smoothness;
	}
	
	private function set_smoothness(value:Float):Float
	{
		_smoothness = value;
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function cleanCompilationData():Void
	{
		super.cleanCompilationData();
		_dataReg = null;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		_dataReg = regCache.getFreeFragmentConstant();
		vo.secondaryFragmentConstantsIndex = _dataReg.index*4;
		return super.getFragmentPreLightingCode(vo, regCache);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		super.activate(vo, stage3DProxy);
		var data:Vector<Float> = vo.fragmentData;
		var index:Int = vo.secondaryFragmentConstantsIndex;
		data[index] = _levels;
		data[index + 3] = _smoothness;
	}
	
	/**
	 * Snaps the diffuse shading of the wrapped method to one of the levels.
	 * @param vo The MethodVO used to compile the current shader.
	 * @param t The register containing the diffuse strength in the "w" component.
	 * @param regCache The register cache used for the shader compilation.
	 * @param sharedRegisters The shared register data for this shader.
	 * @return The AGAL fragment code for the method.
	 */
	private function clampDiffuse(vo:MethodVO, t:ShaderRegisterElement, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
	{
		return "mul " + t + ".w, " + t + ".w, " + _dataReg + ".x\n" +
			"frc " + t + ".z, " + t + ".w\n" +
			"sub " + t + ".y, " + t + ".w, " + t + ".z\n" +
			"mov " + t + ".x, " + _dataReg + ".x\n" +
			"sub " + t + ".x, " + t + ".x, " + _dataReg + ".y\n" +
			"rcp " + t + ".x," + t + ".x\n" +
			"mul " + t + ".w, " + t + ".y, " + t + ".x\n" +
			
			// previous clamped strength
			"sub " + t + ".y, " + t + ".w, " + t + ".x\n" +
			
			// fract/epsilon (so 0 - epsilon will become 0 - 1)
			"div " + t + ".z, " + t + ".z, " + _dataReg + ".w\n" +
			"sat " + t + ".z, " + t + ".z\n" +
			
			"mul " + t + ".w, " + t + ".w, " + t + ".z\n" +
			// 1-z
			"sub " + t + ".z, " + _dataReg + ".y, " + t + ".z\n" +
			"mul " + t + ".y, " + t + ".y, " + t + ".z\n" +
			"add " + t + ".w, " + t + ".w, " + t + ".y\n" +
			"sat " + t + ".w, " + t + ".w\n";
	}
}