package away3d.materials.methods;

	//import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	
	//use namespace arcane;
	
	/**
	 * BasicAmbientMethod provides the default shading method for uniform ambient lighting.
	 */
	class BasicAmbientMethod extends ShadingMethodBase
	{
		var _useTexture:Bool;
		var _texture:Texture2DBase;
		
		var _ambientInputRegister:ShaderRegisterElement;
		
		var _ambientColor:UInt = 0xffffff;
		var _ambientR:Float = 0;
		var _ambientG:Float = 0;
		var _ambientB:Float = 0;
		var _ambient:Float = 1;
		/*arcane*/ public var _lightAmbientR:Float = 0;
		/*arcane*/ public var _lightAmbientG:Float = 0;
		/*arcane*/ public var _lightAmbientB:Float = 0;
		
		/**
		 * Creates a new BasicAmbientMethod object.
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
		}

		/**
		 * @inheritDoc
		 */
		override public function initConstants(vo:MethodVO):Void
		{
			vo.fragmentData[vo.fragmentConstantsIndex + 3] = 1;
		}
		
		/**
		 * The strength of the ambient reflection of the surface.
		 */
		public var ambient(get, set) : Float;
		public function get_ambient() : Float
		{
			return _ambient;
		}
		
		public function set_ambient(value:Float) : Float
		{
			_ambient = value;
			return _ambient;
		}
		
		/**
		 * The colour of the ambient reflection of the surface.
		 */
		public var ambientColor(get, set) : UInt;
		public function get_ambientColor() : UInt
		{
			return _ambientColor;
		}
		
		public function set_ambientColor(value:UInt) : UInt
		{
			_ambientColor = value;
			return _ambientColor;
		}
		
		/**
		 * The bitmapData to use to define the diffuse reflection color per texel.
		 */
		public var texture(get, set) : Texture2DBase;
		public function get_texture() : Texture2DBase
		{
			return _texture;
		}
		
		public function set_texture(value:Texture2DBase) : Texture2DBase
		{
			if ((value!=null && _useTexture==true) ||
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
			var diff:BasicAmbientMethod = cast(method, BasicAmbientMethod);
			ambient = diff.ambient;
			ambientColor = diff.ambientColor;
		}

		/**
		 * @inheritDoc
		 */
		override function cleanCompilationData():Void
		{
			super.cleanCompilationData();
			_ambientInputRegister = null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var code:String = "";
			
			if (_useTexture) {
				_ambientInputRegister = regCache.getFreeTextureReg();
				vo.texturesIndex = _ambientInputRegister.index;
				code += getTex2DSampleCode(vo, targetReg, _ambientInputRegister, _texture) +
					// apparently, still needs to un-premultiply :s
					"div " + targetReg + ".xyz, " + targetReg + ".xyz, " + targetReg + ".w\n";
			} else {
				_ambientInputRegister = regCache.getFreeFragmentConstant();
				vo.fragmentConstantsIndex = _ambientInputRegister.index*4;
				code += "mov " + targetReg + ", " + _ambientInputRegister + "\n";
			}
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			if (_useTexture)
				stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
		}
		
		/**
		 * Updates the ambient color data used by the render state.
		 */
		private function updateAmbient():Void
		{
			_ambientR = ((_ambientColor >> 16) & 0xff)/0xff*_ambient*_lightAmbientR;
			_ambientG = ((_ambientColor >> 8) & 0xff)/0xff*_ambient*_lightAmbientG;
			_ambientB = (_ambientColor & 0xff)/0xff*_ambient*_lightAmbientB;
		}

		/**
		 * @inheritDoc
		 */
		override public function setRenderState(vo:MethodVO, renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
		{
			updateAmbient();
			
			if (!_useTexture) {
				var index:Int = vo.fragmentConstantsIndex;
				var data:Array<Float> = vo.fragmentData;
				data[index] = _ambientR;
				data[index + 1] = _ambientG;
				data[index + 2] = _ambientB;
			}
		}
	}

