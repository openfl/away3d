package away3d.materials.methods;

	//import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.events.ShadingMethodEvent;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterData;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	
	//use namespace arcane;
	
	/**
	 * CompositeDiffuseMethod provides a base class for diffuse methods that wrap a diffuse method to alter the
	 * calculated diffuse reflection strength.
	 */
	class CompositeDiffuseMethod extends BasicDiffuseMethod
	{
		var _baseMethod:BasicDiffuseMethod;

		/**
		 * Creates a new WrapDiffuseMethod object.
		 * @param modulateMethod The method which will add the code to alter the base method's strength. It needs to have the signature clampDiffuse(t : ShaderRegisterElement, regCache : ShaderRegisterCache) : String, in which t.w will contain the diffuse strength.
		 * @param baseDiffuseMethod The base diffuse method on which this method's shading is based.
		 */
		public function new(modulateMethod:xxx->yyy = null, baseDiffuseMethod:BasicDiffuseMethod = null)
		{
			_baseMethod = baseDiffuseMethod || new BasicDiffuseMethod();
			_baseMethod._modulateMethod = modulateMethod;
			_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		}

		/**
		 * The base diffuse method on which this method's shading is based.
		 */
		public var baseMethod(get, set) : BasicDiffuseMethod;
		public function get_baseMethod() : BasicDiffuseMethod
		{
			return _baseMethod;
		}

		public function set_baseMethod(value:BasicDiffuseMethod) : BasicDiffuseMethod
		{
			if (_baseMethod == value)
				return;
			_baseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_baseMethod = value;
			_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated, false, 0, true);
			invalidateShaderProgram();
		}

		/**
		 * @inheritDoc
		 */
		override public function initVO(vo:MethodVO):Void
		{
			_baseMethod.initVO(vo);
		}

		/**
		 * @inheritDoc
		 */
		override public function initConstants(vo:MethodVO):Void
		{
			_baseMethod.initConstants(vo);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():Void
		{
			_baseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_baseMethod.dispose();
		}

		/**
		 * @inheritDoc
		 */
		public var alphaThreshold(get, set) : Float;
		override public function get_alphaThreshold() : Float
		{
			return _baseMethod.alphaThreshold;
		}
		
		override public function set_alphaThreshold(value:Float) : Float
		{
			_baseMethod.alphaThreshold = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public var texture(get, set) : Texture2DBase;
		override public function get_texture() : Texture2DBase
		{
			return _baseMethod.texture;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set_texture(value:Texture2DBase) : Texture2DBase
		{
			_baseMethod.texture = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public var diffuseAlpha(get, set) : Float;
		override public function get_diffuseAlpha() : Float
		{
			return _baseMethod.diffuseAlpha;
		}
		
		/**
		 * @inheritDoc
		 */
		public var diffuseColor(get, set) : UInt;
		override public function get_diffuseColor() : UInt
		{
			return _baseMethod.diffuseColor;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set_diffuseColor(diffuseColor:UInt) : UInt
		{
			_baseMethod.diffuseColor = diffuseColor;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set_diffuseAlpha(value:Float) : Float
		{
			_baseMethod.diffuseAlpha = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			return _baseMethod.getFragmentPreLightingCode(vo, regCache);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getFragmentCodePerLight(vo:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String
		{
			var code:String = _baseMethod.getFragmentCodePerLight(vo, lightDirReg, lightColReg, regCache);
			_totalLightColorReg = _baseMethod._totalLightColorReg;
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override function getFragmentCodePerProbe(vo:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, regCache:ShaderRegisterCache):String
		{
			var code:String = _baseMethod.getFragmentCodePerProbe(vo, cubeMapReg, weightRegister, regCache);
			_totalLightColorReg = _baseMethod._totalLightColorReg;
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			_baseMethod.activate(vo, stage3DProxy);
		}

		/**
		 * @inheritDoc
		 */
		override function deactivate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			_baseMethod.deactivate(vo, stage3DProxy);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			return _baseMethod.getVertexCode(vo, regCache);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			return _baseMethod.getFragmentPostLightingCode(vo, regCache, targetReg);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function reset():Void
		{
			_baseMethod.reset();
		}

		/**
		 * @inheritDoc
		 */
		override function cleanCompilationData():Void
		{
			super.cleanCompilationData();
			_baseMethod.cleanCompilationData();
		}
		
		/**
		 * @inheritDoc
		 */
		public var sharedRegisters(null, set) : Void;
		override public function set_sharedRegisters(value:ShaderRegisterData) : Void
		{
			super.sharedRegisters = _baseMethod.sharedRegisters = value;
		}

		/**
		 * @inheritDoc
		 */
		public var shadowRegister(null, set) : Void;
		override public function set_shadowRegister(value:ShaderRegisterElement) : Void
		{
			super.shadowRegister = value;
			_baseMethod.shadowRegister = value;
		}

		/**
		 * Called when the base method's shader code is invalidated.
		 */
		private function onShaderInvalidated(event:ShadingMethodEvent):Void
		{
			invalidateShaderProgram();
		}
	}

