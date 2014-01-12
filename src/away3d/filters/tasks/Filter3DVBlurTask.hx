package away3d.filters.tasks;

	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	
	import flash.display3D.Context3DProgramType;
	import flash.display3D.textures.Texture;
	
	class Filter3DVBlurTask extends Filter3DTaskBase
	{
		private static var MAX_AUTO_SAMPLES:Int = 15;
		var _amount:UInt;
		var _data:Array<Float>;
		var _stepSize:Int = 1;
		var _realStepSize:Float;
		
		/**
		 *
		 * @param amount
		 * @param stepSize The distance between samples. Set to -1 to autodetect with acceptable quality.
		 */
		public function new(amount:UInt, stepSize:Int = -1)
		{
			super();
			_amount = amount;
			_data = Array<Float>([0, 0, 0, 1]);
			this.stepSize = stepSize;
		}
		
		public var amount(get, set) : UInt;
		
		public function get_amount() : UInt
		{
			return _amount;
		}
		
		public function set_amount(value:UInt) : UInt
		{
			if (value == _amount)
				return;
			_amount = value;
			
			invalidateProgram3D();
			updateBlurData();
		}
		
		public var stepSize(get, set) : Int;
		
		public function get_stepSize() : Int
		{
			return _stepSize;
		}
		
		public function set_stepSize(value:Int) : Int
		{
			if (value == _stepSize)
				return;
			_stepSize = value;
			calculateStepSize();
			invalidateProgram3D();
			updateBlurData();
		}
		
		override private function getFragmentCode():String
		{
			var code:String;
			var numSamples:Int = 1;
			
			code = "mov ft0, v0	\n" +
				"sub ft0.y, v0.y, fc0.x\n";
			
			code += "tex ft1, ft0, fs0 <2d,linear,clamp>\n";
			
			// For loop conversion - 						for (var x:Float = _realStepSize; x <= _amount; x += _realStepSize)
			
			var x:Float;
			
			for (x in _realStepSize..._amount) {
				code += "add ft0.y, ft0.y, fc0.y	\n";
				code += "tex ft2, ft0, fs0 <2d,linear,clamp>\n" +
					"add ft1, ft1, ft2 \n";
				++numSamples;
			}
			
			code += "mul oc, ft1, fc0.z";
			
			_data[2] = 1/numSamples;
			
			return code;
		}
		
		override public function activate(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:Texture):Void
		{
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 1);
		}
		
		override private function updateTextures(stage:Stage3DProxy):Void
		{
			super.updateTextures(stage);
			
			updateBlurData();
		}
		
		private function updateBlurData():Void
		{
			// todo: must be normalized using view size ratio instead of texture
			var invH:Float = 1/_textureHeight;
			
			_data[0] = _amount*.5*invH;
			_data[1] = _realStepSize*invH;
		}
		
		private function calculateStepSize():Void
		{
			_realStepSize = _stepSize > 0? _stepSize :
				_amount > MAX_AUTO_SAMPLES? _amount/MAX_AUTO_SAMPLES :
				1;
		}
	}

