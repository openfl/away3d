package away3d.filters.tasks;

	//import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	
	import flash.display3D.Context3D;
	
	import flash.display3D.Context3DProgramType;
	
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	
	//use namespace arcane;
	
	class Filter3DCompositeTask extends Filter3DTaskBase
	{
		var _data:Array<Float>;
		var _overlayTexture:TextureBase;
		var _blendMode:String;
		
		public function new(blendMode:String, exposure:Float = 1)
		{
			super();
			_data = Array<Float>([ exposure, 0, 0, 0 ]);
			_blendMode = blendMode;
		}
		
		public var overlayTexture(get, set) : TextureBase;
		
		public function get_overlayTexture() : TextureBase
		{
			return _overlayTexture;
		}
		
		public function set_overlayTexture(value:TextureBase) : TextureBase
		{
			_overlayTexture = value;
		}
		
		public var exposure(get, set) : Float;
		
		public function get_exposure() : Float
		{
			return _data[0];
		}
		
		public function set_exposure(value:Float) : Float
		{
			_data[0] = value;
		}
		
		override private function getFragmentCode():String
		{
			var code:String;
			var op:String;
			code = "tex ft0, v0, fs0 <2d,linear,clamp>	\n" +
				"tex ft1, v0, fs1 <2d,linear,clamp>	\n" +
				"mul ft0, ft0, fc0.x				\n";
			switch (_blendMode) {
				case "multiply":
					op = "mul";
					break;
				case "add":
					op = "add";
					break;
				case "subtract":
					op = "sub";
					break;
				case "normal":
					// for debugging purposes
					op = "mov";
					break;
				default:
					throw new Error("Unknown blend mode");
			}
			if (op != "mov")
				code += op + " oc, ft0, ft1					\n";
			else
				code += "mov oc, ft0						\n";
			return code;
		}
		
		override public function activate(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:Texture):Void
		{
			var context:Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 1);
			context.setTextureAt(1, _overlayTexture);
		}
		
		override public function deactivate(stage3DProxy:Stage3DProxy):Void
		{
			stage3DProxy._context3D.setTextureAt(1, null);
		}
	}

