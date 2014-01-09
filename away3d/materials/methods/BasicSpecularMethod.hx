package away3d.materials.methods;

	import away3d.*;
	import away3d.core.managers.*;
	import away3d.materials.compilation.*;
	import away3d.textures.*;
	
	//use namespace arcane;
	
	/**
	 * BasicSpecularMethod provides the default shading method for Blinn-Phong specular highlights (an optimized but approximated
	 * version of Phong specularity).
	 */
	class BasicSpecularMethod extends LightingMethodBase
	{
		var _useTexture:Bool;
		var _totalLightColorReg:ShaderRegisterElement;
		var _specularTextureRegister:ShaderRegisterElement;
		var _specularTexData:ShaderRegisterElement;
		var _specularDataRegister:ShaderRegisterElement;
		
		var _texture:Texture2DBase;
		
		var _gloss:Float = 50;
		var _specular:Float = 1;
		var _specularColor:UInt = 0xffffff;
		/*arcane*/ public var _specularR:Float = 1;
		/*arcane*/ public var _specularG:Float = 1;
		/*arcane*/ public var _specularB:Float = 1;
		var _shadowRegister:ShaderRegisterElement;
		var _isFirstLight:Bool;
		
		/**
		 * Creates a new BasicSpecularMethod object.
		 */
		public function new()
		{
			super();
		}

		/**
		 * @inheritDoc
		 */
		override public function initVO(vo:MethodVO):Void
		{
			vo.needsUV = _useTexture;
			vo.needsNormals = vo.numLights > 0;
			vo.needsView = vo.numLights > 0;
		}
		
		/**
		 * The sharpness of the specular highlight.
		 */
		public var gloss(get, set) : Float;
		public function get_gloss() : Float
		{
			return _gloss;
		}
		
		public function set_gloss(value:Float) : Float
		{
			_gloss = value;
			return _gloss;
		}
		
		/**
		 * The overall strength of the specular highlights.
		 */
		public var specular(get, set) : Float;
		public function get_specular() : Float
		{
			return _specular;
		}
		
		public function set_specular(value:Float) : Float
		{
			if (value == _specular)
				return _specular;
			
			_specular = value;
			updateSpecular();
			return _specular;
		}
		
		/**
		 * The colour of the specular reflection of the surface.
		 */
		public var specularColor(get, set) : UInt;
		public function get_specularColor() : UInt
		{
			return _specularColor;
		}
		
		public function set_specularColor(value:UInt) : UInt
		{
			if (_specularColor == value)
				return _specularColor;
			
			// specular is now either enabled or disabled
			if (_specularColor == 0 || value == 0)
				invalidateShaderProgram();
			_specularColor = value;
			updateSpecular();

			return _specularColor;
		}
		
		/**
		 * The bitmapData that encodes the specular highlight strength per texel in the red channel, and the sharpness
		 * in the green channel. You can use SpecularBitmapTexture if you want to easily set specular and gloss maps
		 * from grayscale images, but prepared images are preferred.
		 */
		public var texture(get, set) : Texture2DBase;
		public function get_texture() : Texture2DBase
		{
			return _texture;
		}
		
		public function set_texture(value:Texture2DBase) : Texture2DBase
		{
			if ((value!=null && _useTexture) ||
				(value!=null && _texture!=null && (value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format))) {
				invalidateShaderProgram();
			}
			_useTexture = (value!=null);
			_texture = value;
			return _texture;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function copyFrom(method:ShadingMethodBase):Void
		{
			var spec:BasicSpecularMethod = cast(method, BasicSpecularMethod);
			texture = spec.texture;
			specular = spec.specular;
			specularColor = spec.specularColor;
			gloss = spec.gloss;
		}
		
		/**
		 * @inheritDoc
		 */
		override function cleanCompilationData():Void
		{
			super.cleanCompilationData();
			_shadowRegister = null;
			_totalLightColorReg = null;
			_specularTextureRegister = null;
			_specularTexData = null;
			_specularDataRegister = null;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			var code:String = "";
			
			_isFirstLight = true;
			
			if (vo.numLights > 0) {
				_specularDataRegister = regCache.getFreeFragmentConstant();
				vo.fragmentConstantsIndex = _specularDataRegister.index*4;
				
				if (_useTexture) {
					_specularTexData = regCache.getFreeFragmentVectorTemp();
					regCache.addFragmentTempUsages(_specularTexData, 1);
					_specularTextureRegister = regCache.getFreeTextureReg();
					vo.texturesIndex = _specularTextureRegister.index;
					code = getTex2DSampleCode(vo, _specularTexData, _specularTextureRegister, _texture);
				} else
					_specularTextureRegister = null;
				
				_totalLightColorReg = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(_totalLightColorReg, 1);
			}
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getFragmentCodePerLight(vo:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String
		{
			var code:String = "";
			var t:ShaderRegisterElement;
			
			if (_isFirstLight)
				t = _totalLightColorReg;
			else {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}
			
			var viewDirReg:ShaderRegisterElement = _sharedRegisters.viewDirFragment;
			var normalReg:ShaderRegisterElement = _sharedRegisters.normalFragment;
			
			// blinn-phong half vector model
			code += "add " + t + ", " + lightDirReg + ", " + viewDirReg + "\n" +
				"nrm " + t + ".xyz, " + t + "\n" +
				"dp3 " + t + ".w, " + normalReg + ", " + t + "\n" +
				"sat " + t + ".w, " + t + ".w\n";
			
			if (_useTexture) {
				// apply gloss modulation from texture
				code += "mul " + _specularTexData + ".w, " + _specularTexData + ".y, " + _specularDataRegister + ".w\n" +
					"pow " + t + ".w, " + t + ".w, " + _specularTexData + ".w\n";
			} else
				code += "pow " + t + ".w, " + t + ".w, " + _specularDataRegister + ".w\n";
			
			// attenuate
			if (vo.useLightFallOff)
				code += "mul " + t + ".w, " + t + ".w, " + lightDirReg + ".w\n";
			
			if (_modulateMethod != null)
				code += _modulateMethod(vo, t, regCache, _sharedRegisters);
			
			code += "mul " + t + ".xyz, " + lightColReg + ", " + t + ".w\n";
			
			if (!_isFirstLight) {
				code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + t + "\n";
				regCache.removeFragmentTempUsage(t);
			}
			
			_isFirstLight = false;
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override function getFragmentCodePerProbe(vo:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, regCache:ShaderRegisterCache):String
		{
			var code:String = "";
			var t:ShaderRegisterElement;
			
			// write in temporary if not first light, so we can add to total diffuse colour
			if (_isFirstLight)
				t = _totalLightColorReg;
			else {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}
			
			var normalReg:ShaderRegisterElement = _sharedRegisters.normalFragment;
			var viewDirReg:ShaderRegisterElement = _sharedRegisters.viewDirFragment;
			code += "dp3 " + t + ".w, " + normalReg + ", " + viewDirReg + "\n" +
				"add " + t + ".w, " + t + ".w, " + t + ".w\n" +
				"mul " + t + ", " + t + ".w, " + normalReg + "\n" +
				"sub " + t + ", " + t + ", " + viewDirReg + "\n" +
				"tex " + t + ", " + t + ", " + cubeMapReg + " <cube," + (vo.useSmoothTextures? "linear" : "nearest") + ",miplinear>\n" +
				"mul " + t + ".xyz, " + t + ", " + weightRegister + "\n";
			
			if (_modulateMethod != null)
				code += _modulateMethod(vo, t, regCache, _sharedRegisters);
			
			if (!_isFirstLight) {
				code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + t + "\n";
				regCache.removeFragmentTempUsage(t);
			}
			
			_isFirstLight = false;
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var code:String = "";
			
			if (vo.numLights == 0)
				return code;
			
			if (_shadowRegister!=null)
				code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + _shadowRegister + ".w\n";
			
			if (_useTexture) {
				// apply strength modulation from texture
				code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + _specularTexData + ".x\n";
				regCache.removeFragmentTempUsage(_specularTexData);
			}
			
			// apply material's specular reflection
			code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + _specularDataRegister + "\n" +
				"add " + targetReg + ".xyz, " + targetReg + ", " + _totalLightColorReg + "\n";
			regCache.removeFragmentTempUsage(_totalLightColorReg);
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			//var context : Context3D = stage3DProxy._context3D;
			
			if (vo.numLights == 0)
				return;
			
			if (_useTexture)
				stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
			var index:Int = vo.fragmentConstantsIndex;
			var data:Array<Float> = vo.fragmentData;
			data[index] = _specularR;
			data[index + 1] = _specularG;
			data[index + 2] = _specularB;
			data[index + 3] = _gloss;
		}
		
		/**
		 * Updates the specular color data used by the render state.
		 */
		private function updateSpecular():Void
		{
			_specularR = ((_specularColor >> 16) & 0xff)/0xff*_specular;
			_specularG = ((_specularColor >> 8) & 0xff)/0xff*_specular;
			_specularB = (_specularColor & 0xff)/0xff*_specular;
		}

		/**
		 * Set internally by the compiler, so the method knows the register containing the shadow calculation.
		 */
		public var shadowRegister(default, set) : ShaderRegisterElement;
		public function set_shadowRegister(shadowReg:ShaderRegisterElement) : ShaderRegisterElement
		{
			_shadowRegister = shadowReg;
			return _shadowRegister;
		}
	}

