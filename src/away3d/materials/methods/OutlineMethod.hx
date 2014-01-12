package away3d.materials.methods;

	//import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.passes.OutlinePass;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	
	//use namespace arcane;

	/**
	 * OutlineMethod provides a shading method to add outlines to an object.
	 */
	class OutlineMethod extends EffectMethodBase
	{
		var _outlinePass:OutlinePass;
		
		/**
		 * Creates a new OutlineMethod object.
		 * @param outlineColor The colour of the outline stroke
		 * @param outlineSize The size of the outline stroke
		 * @param showInnerLines Indicates whether or not strokes should be potentially drawn over the existing model.
		 * @param dedicatedWaterProofMesh Used to stitch holes appearing due to mismatching normals for overlapping vertices. Warning: this will create a new mesh that is incompatible with animations!
		 */
		public function new(outlineColor:UInt = 0x000000, outlineSize:Float = 1, showInnerLines:Bool = true, dedicatedWaterProofMesh:Bool = false)
		{
			super();
			_passes = new Array<MaterialPassBase>();
			_outlinePass = new OutlinePass(outlineColor, outlineSize, showInnerLines, dedicatedWaterProofMesh);
			_passes.push(_outlinePass);
		}

		/**
		 * @inheritDoc
		 */
		override public function initVO(vo:MethodVO):Void
		{
			vo.needsNormals = true;
		}
		
		/**
		 * Indicates whether or not strokes should be potentially drawn over the existing model.
		 * Set this to true to draw outlines for geometry overlapping in the view, useful to achieve a cel-shaded drawing outline.
		 * Setting this to false will only cause the outline to appear around the 2D projection of the geometry.
		 */
		public var showInnerLines(get, set) : Bool;
		public function get_showInnerLines() : Bool
		{
			return _outlinePass.showInnerLines;
		}
		
		public function set_showInnerLines(value:Bool) : Bool
		{
			_outlinePass.showInnerLines = value;
		}
		
		/**
		 * The colour of the outline.
		 */
		public var outlineColor(get, set) : UInt;
		public function get_outlineColor() : UInt
		{
			return _outlinePass.outlineColor;
		}
		
		public function set_outlineColor(value:UInt) : UInt
		{
			_outlinePass.outlineColor = value;
		}
		
		/**
		 * The size of the outline.
		 */
		public var outlineSize(get, set) : Float;
		public function get_outlineSize() : Float
		{
			return _outlinePass.outlineSize;
		}
		
		public function set_outlineSize(value:Float) : Float
		{
			_outlinePass.outlineSize = value;
		}

		/**
		 * @inheritDoc
		 */
		override function reset():Void
		{
			super.reset();
		}

		/**
		 * @inheritDoc
		 */
		override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
		}

		/**
		 * @inheritDoc
		 */
		override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			return "";
		}
	}

