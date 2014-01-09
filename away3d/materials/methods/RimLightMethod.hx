package away3d.materials.methods;

	//import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	
	//use namespace arcane;

	/**
	 * RimLightMethod provides a method to add rim lighting to a material. This adds a glow-like effect to edges of objects.
	 */
	class RimLightMethod extends EffectMethodBase
	{
		public static var ADD:String = "add";
		public static var MULTIPLY:String = "multiply";
		public static var MIX:String = "mix";
		
		var _color:UInt;
		var _blendMode:String;
		var _colorR:Float;
		var _colorG:Float;
		var _colorB:Float;
		var _strength:Float;
		var _power:Float;

		/**
		 * Creates a new RimLightMethod.
		 * @param color The colour of the rim light.
		 * @param strength The strength of the rim light.
		 * @param power The power of the rim light. Higher values will result in a higher edge fall-off.
		 * @param blend The blend mode with which to add the light to the object.
		 */
		public function new(color:UInt = 0xffffff, strength:Float = .4, power:Float = 2, blend:String = "mix")
		{
			super();
			_blendMode = blend;
			_strength = strength;
			_power = power;
			this.color = color;
		}

		/**
		 * @inheritDoc
		 */
		override public function initConstants(vo:MethodVO):Void
		{
			vo.fragmentData[vo.fragmentConstantsIndex + 3] = 1;
		}

		/**
		 * @inheritDoc
		 */
		override public function initVO(vo:MethodVO):Void
		{
			vo.needsNormals = true;
			vo.needsView = true;
		}


		/**
		 * The blend mode with which to add the light to the object.
		 *
		 * RimLightMethod.MULTIPLY multiplies the rim light with the material's colour.
		 * RimLightMethod.ADD adds the rim light with the material's colour.
		 * RimLightMethod.MIX provides normal alpha blending.
		 */
		public var blendMode(get, set) : BlendMode;
		public function get_blendMode() : BlendMode
		{
			return _blendMode;
		}

		public function set_blendMode(value : BlendMode) : BlendMode
		{
			if (_blendMode == value) return _blendMode;
			_blendMode = value;
			invalidateShaderProgram();
			return _blendMode;
		}

		/**
		 * The color of the rim light.
		 */
		public var color(get, set) : UInt;
		public function get_color() : UInt
		{
			return _color;
		}
		
		public function set_color(value:UInt) : UInt
		{
			_color = value;
			_colorR = ((value >> 16) & 0xff)/0xff;
			_colorG = ((value >> 8) & 0xff)/0xff;
			_colorB = (value & 0xff)/0xff;
		}

		/**
		 * The strength of the rim light.
		 */
		public var strength(get, set) : Float;
		public function get_strength() : Float
		{
			return _strength;
		}
		
		public function set_strength(value:Float) : Float
		{
			_strength = value;
		}

		/**
		 * The power of the rim light. Higher values will result in a higher edge fall-off.
		 */
		public var power(get, set) : Float;
		public function get_power() : Float
		{
			return _power;
		}
		
		public function set_power(value:Float) : Float
		{
			_power = value;
		}

		/**
		 * @inheritDoc
		 */
		override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			var index:Int = vo.fragmentConstantsIndex;
			var data:Array<Float> = vo.fragmentData;
			data[index] = _colorR;
			data[index + 1] = _colorG;
			data[index + 2] = _colorB;
			data[index + 4] = _strength;
			data[index + 5] = _power;
		}

		/**
		 * @inheritDoc
		 */
		override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var dataRegister:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataRegister2:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code:String = "";
			
			vo.fragmentConstantsIndex = dataRegister.index*4;
			
			code += "dp3 " + temp + ".x, " + _sharedRegisters.viewDirFragment + ".xyz, " + _sharedRegisters.normalFragment + ".xyz	\n" +
				"sat " + temp + ".x, " + temp + ".x														\n" +
				"sub " + temp + ".x, " + dataRegister + ".w, " + temp + ".x								\n" +
				"pow " + temp + ".x, " + temp + ".x, " + dataRegister2 + ".y							\n" +
				"mul " + temp + ".x, " + temp + ".x, " + dataRegister2 + ".x							\n" +
				"sub " + temp + ".x, " + dataRegister + ".w, " + temp + ".x								\n" +
				"mul " + targetReg + ".xyz, " + targetReg + ".xyz, " + temp + ".x						\n" +
				"sub " + temp + ".w, " + dataRegister + ".w, " + temp + ".x								\n";
			
			if (_blendMode == ADD) {
				code += "mul " + temp + ".xyz, " + temp + ".w, " + dataRegister + ".xyz							\n" +
					"add " + targetReg + ".xyz, " + targetReg + ".xyz, " + temp + ".xyz						\n";
			} else if (_blendMode == MULTIPLY) {
				code += "mul " + temp + ".xyz, " + temp + ".w, " + dataRegister + ".xyz							\n" +
					"mul " + targetReg + ".xyz, " + targetReg + ".xyz, " + temp + ".xyz						\n";
			} else {
				code += "sub " + temp + ".xyz, " + dataRegister + ".xyz, " + targetReg + ".xyz				\n" +
					"mul " + temp + ".xyz, " + temp + ".xyz, " + temp + ".w								\n" +
					"add " + targetReg + ".xyz, " + targetReg + ".xyz, " + temp + ".xyz					\n";
			}
			
			return code;
		}
	}

