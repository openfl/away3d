package away3d.materials.methods;

	import away3d.*;
	import away3d.core.managers.*;
	import away3d.events.*;
	import away3d.materials.compilation.*;
	import away3d.materials.passes.*;
	import away3d.textures.*;
	
	//use namespace arcane;
	
	/**
	 * CompositeSpecularMethod provides a base class for specular methods that wrap a specular method to alter the
	 * calculated specular reflection strength.
	 */
	class CompositeSpecularMethod extends BasicSpecularMethod
	{
		var _baseMethod:BasicSpecularMethod;
		
		/**
		 * Creates a new WrapSpecularMethod object.
		 * @param modulateMethod The method which will add the code to alter the base method's strength. It needs to have the signature modSpecular(t : ShaderRegisterElement, regCache : ShaderRegisterCache) : String, in which t.w will contain the specular strength and t.xyz will contain the half-vector or the reflection vector.
		 * @param baseSpecularMethod The base specular method on which this method's shading is based.
		 */
		public function new(modulateMethod:xxx->yyy, baseSpecularMethod:BasicSpecularMethod = null)
		{
			super();
			_baseMethod = baseSpecularMethod || new BasicSpecularMethod();
			_baseMethod._modulateMethod = modulateMethod;
			_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
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
		 * The base specular method on which this method's shading is based.
		 */
		public var baseMethod(get, set) : BasicSpecularMethod;
		public function get_baseMethod() : BasicSpecularMethod
		{
			return _baseMethod;
		}
		
		public function set_baseMethod(value:BasicSpecularMethod) : BasicSpecularMethod
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
		public var gloss(get, set) : Float;
		override public function get_gloss() : Float
		{
			return _baseMethod.gloss;
		}
		
		override public function set_gloss(value:Float) : Float
		{
			_baseMethod.gloss = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get_specular() : Float
		{
			return _baseMethod.specular;
		}
		
		override public function set_specular(value:Float) : Float
		{
			_baseMethod.specular = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get_passes() : Array<MaterialPassBase>
		{
			return _baseMethod.passes;
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
		override public function get_texture() : Texture2DBase
		{
			return _baseMethod.texture;
		}
		
		override public function set_texture(value:Texture2DBase) : Texture2DBase
		{
			_baseMethod.texture = value;
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
		override public function set_sharedRegisters(value:ShaderRegisterData) : Void
		{
			super.sharedRegisters = _baseMethod.sharedRegisters = value;
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
		override public function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			return _baseMethod.getFragmentPreLightingCode(vo, regCache);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getFragmentCodePerLight(vo:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String
		{
			return _baseMethod.getFragmentCodePerLight(vo, lightDirReg, lightColReg, regCache);
		}
		
		/**
		 * @inheritDoc
		 * @return
		 */
		override function getFragmentCodePerProbe(vo:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, regCache:ShaderRegisterCache):String
		{
			return _baseMethod.getFragmentCodePerProbe(vo, cubeMapReg, weightRegister, regCache);
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
		override function reset():Void
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

