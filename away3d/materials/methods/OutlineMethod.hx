package away3d.materials.methods;

import away3d.core.managers.Stage3DProxy;
import away3d.materials.passes.MaterialPassBase;
import away3d.materials.passes.OutlinePass;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;

import openfl.Vector;

/**
 * OutlineMethod provides a shading method to add outlines to an object.
 */
class OutlineMethod extends EffectMethodBase
{
	public var showInnerLines(get, set):Bool;
	public var outlineColor(get, set):Int;
	public var outlineSize(get, set):Float;
	
	private var _outlinePass:OutlinePass;
	
	/**
	 * Creates a new OutlineMethod object.
	 * @param outlineColor The colour of the outline stroke
	 * @param outlineSize The size of the outline stroke
	 * @param showInnerLines Indicates whether or not strokes should be potentially drawn over the existing model.
	 * @param dedicatedWaterProofMesh Used to stitch holes appearing due to mismatching normals for overlapping vertices. Warning: this will create a new mesh that is incompatible with animations!
	 */
	public function new(outlineColor:Int = 0x000000, outlineSize:Float = 1, showInnerLines:Bool = true, dedicatedWaterProofMesh:Bool = false)
	{
		super();
		_passes = new Vector<MaterialPassBase>();
		_outlinePass = new OutlinePass(outlineColor, outlineSize, showInnerLines, dedicatedWaterProofMesh);
		_passes.push(_outlinePass);
	}

	/**
	 * @inheritDoc
	 */
	override private function initVO(vo:MethodVO):Void
	{
		vo.needsNormals = true;
	}
	
	/**
	 * Indicates whether or not strokes should be potentially drawn over the existing model.
	 * Set this to true to draw outlines for geometry overlapping in the view, useful to achieve a cel-shaded drawing outline.
	 * Setting this to false will only cause the outline to appear around the 2D projection of the geometry.
	 */
	private function get_showInnerLines():Bool
	{
		return _outlinePass.showInnerLines;
	}
	
	private function set_showInnerLines(value:Bool):Bool
	{
		_outlinePass.showInnerLines = value;
		return value;
	}
	
	/**
	 * The colour of the outline.
	 */
	private function get_outlineColor():Int
	{
		return _outlinePass.outlineColor;
	}
	
	private function set_outlineColor(value:Int):Int
	{
		_outlinePass.outlineColor = value;
		return value;
	}
	
	/**
	 * The size of the outline.
	 */
	private function get_outlineSize():Float
	{
		return _outlinePass.outlineSize;
	}
	
	private function set_outlineSize(value:Float):Float
	{
		_outlinePass.outlineSize = value;
		return value;
	}

	/**
	 * @inheritDoc
	 */
	override private function reset():Void
	{
		super.reset();
	}

	/**
	 * @inheritDoc
	 */
	override private function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
	}

	/**
	 * @inheritDoc
	 */
	override private function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		return "";
	}
}