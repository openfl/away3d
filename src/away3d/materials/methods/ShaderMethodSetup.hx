package away3d.materials.methods;

	//import away3d.arcane;
	import away3d.events.ShadingMethodEvent;
	
	import flash.events.EventDispatcher;
	
	//use namespace arcane;

	/**
	 * ShaderMethodSetup contains the method configuration for an entire material.
	 */
	class ShaderMethodSetup extends EventDispatcher
	{
		/*arcane*/ public var _colorTransformMethod:ColorTransformMethod;
		/*arcane*/ public var _colorTransformMethodVO:MethodVO;
		/*arcane*/ public var _normalMethod:BasicNormalMethod;
		/*arcane*/ public var _normalMethodVO:MethodVO;
		/*arcane*/ public var _ambientMethod:BasicAmbientMethod;
		/*arcane*/ public var _ambientMethodVO:MethodVO;
		/*arcane*/ public var _shadowMethod:ShadowMapMethodBase;
		/*arcane*/ public var _shadowMethodVO:MethodVO;
		/*arcane*/ public var _diffuseMethod:BasicDiffuseMethod;
		/*arcane*/ public var _diffuseMethodVO:MethodVO;
		/*arcane*/ public var _specularMethod:BasicSpecularMethod;
		/*arcane*/ public var _specularMethodVO:MethodVO;
		/*arcane*/ public var _methods:Array<MethodVOSet>;

		/**
		 * Creates a new ShaderMethodSetup object.
		 */
		public function new()
		{
			super();
			_methods = new Array<MethodVOSet>();
			_normalMethod = new BasicNormalMethod();
			_ambientMethod = new BasicAmbientMethod();
			_diffuseMethod = new BasicDiffuseMethod();
			_specularMethod = new BasicSpecularMethod();
			_normalMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_diffuseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_specularMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_ambientMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_normalMethodVO = _normalMethod.createMethodVO();
			_ambientMethodVO = _ambientMethod.createMethodVO();
			_diffuseMethodVO = _diffuseMethod.createMethodVO();
			_specularMethodVO = _specularMethod.createMethodVO();
		}

		/**
		 * Called when any method's code is invalidated.
		 */
		private function onShaderInvalidated(event:ShadingMethodEvent):Void
		{
			invalidateShaderProgram();
		}

		/**
		 * Invalidates the material's shader code.
		 */
		private function invalidateShaderProgram():Void
		{
			dispatchEvent(new ShadingMethodEvent(ShadingMethodEvent.SHADER_INVALIDATED));
		}

		/**
		 *  The method used to generate the per-pixel normals.
		 */
		public var normalMethod(get, set) : BasicNormalMethod;
		public function get_normalMethod() : BasicNormalMethod
		{
			return _normalMethod;
		}
		
		public function set_normalMethod(value:BasicNormalMethod) : BasicNormalMethod
		{
			if (_normalMethod!=null)
				_normalMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			
			if (value!=null) {
				if (_normalMethod!=null)
					value.copyFrom(_normalMethod);
				_normalMethodVO = value.createMethodVO();
				value.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			}
			
			_normalMethod = value;
			
			if (value!=null)
				invalidateShaderProgram();

			return _normalMethod;
		}

		/**
		 * The method that provides the ambient lighting contribution.
		 */
		public var ambientMethod(get, set) : BasicAmbientMethod;
		public function get_ambientMethod() : BasicAmbientMethod
		{
			return _ambientMethod;
		}
		
		public function set_ambientMethod(value:BasicAmbientMethod) : BasicAmbientMethod
		{
			if (_ambientMethod!=null)
				_ambientMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			if (value!=null) {
				if (_ambientMethod!=null)
					value.copyFrom(_ambientMethod);
				value.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_ambientMethodVO = value.createMethodVO();
			}
			_ambientMethod = value;
			
			if (value!=null)
				invalidateShaderProgram();

			return _ambientMethod;
		}

		/**
		 * The method used to render shadows cast on this surface, or null if no shadows are to be rendered.
		 */
		public var shadowMethod(get, set) : ShadowMapMethodBase;
		public function get_shadowMethod() : ShadowMapMethodBase
		{
			return _shadowMethod;
		}
		
		public function set_shadowMethod(value:ShadowMapMethodBase) : ShadowMapMethodBase
		{
			if (_shadowMethod!=null)
				_shadowMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_shadowMethod = value;
			if (_shadowMethod!=null) {
				_shadowMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_shadowMethodVO = _shadowMethod.createMethodVO();
			} else
				_shadowMethodVO = null;
			invalidateShaderProgram();

			return _shadowMethod;
		}

		/**
		 * The method that provides the diffuse lighting contribution.
		 */
		 public var diffuseMethod(get, set) : BasicDiffuseMethod;
		 public function get_diffuseMethod() : BasicDiffuseMethod
		{
			return _diffuseMethod;
		}
		
		public function set_diffuseMethod(value:BasicDiffuseMethod) : BasicDiffuseMethod
		{
			if (_diffuseMethod!=null)
				_diffuseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			
			if (value!=null) {
				if (_diffuseMethod!=null)
					value.copyFrom(_diffuseMethod);
				value.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_diffuseMethodVO = value.createMethodVO();
			}
			
			_diffuseMethod = value;
			
			if (value!=null)
				invalidateShaderProgram();

			return _diffuseMethod;
		}
		
		/**
		 * The method to perform specular shading.
		 */
		public var specularMethod(get, set) : BasicSpecularMethod;
		public function get_specularMethod() : BasicSpecularMethod
		{
			return _specularMethod;
		}
		
		public function set_specularMethod(value:BasicSpecularMethod) : BasicSpecularMethod
		{
			if (_specularMethod!=null) {
				_specularMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				if (value!=null)
					value.copyFrom(_specularMethod);
			}
			
			_specularMethod = value;
			if (_specularMethod!=null) {
				_specularMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_specularMethodVO = _specularMethod.createMethodVO();
			} else
				_specularMethodVO = null;
			
			invalidateShaderProgram();

			return _specularMethod;
		}
		
		/**
		 * @private
		 */
		public var colorTransformMethod(get, set) : ColorTransformMethod;
		public function get_colorTransformMethod() : ColorTransformMethod
		{
			return _colorTransformMethod;
		}
		
		public function set_colorTransformMethod(value:ColorTransformMethod) : ColorTransformMethod
		{
			if (_colorTransformMethod == value)
				return _colorTransformMethod;
			if (_colorTransformMethod!=null)
				_colorTransformMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			if (_colorTransformMethod==null || value==null)
				invalidateShaderProgram();
			
			_colorTransformMethod = value;
			if (_colorTransformMethod!=null) {
				_colorTransformMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_colorTransformMethodVO = _colorTransformMethod.createMethodVO();
			} else
				_colorTransformMethodVO = null;

			return _colorTransformMethod;
		}

		/**
		 * Disposes the object.
		 */
		public function dispose():Void
		{
			clearListeners(_normalMethod);
			clearListeners(_diffuseMethod);
			clearListeners(_shadowMethod);
			clearListeners(_ambientMethod);
			clearListeners(_specularMethod);
			
			// For loop conversion - 						for (var i:Int = 0; i < _methods.length; ++i)
			
			var i:Int;
			
			for (i in 0..._methods.length)
				clearListeners(_methods[i].method);
			
			_methods = null;
		}

		/**
		 * Removes all listeners from a method.
		 */
		private function clearListeners(method:ShadingMethodBase):Void
		{
			if (method!=null)
				method.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		}
		
		/**
		 * Adds a method to change the material after all lighting is performed.
		 * @param method The method to be added.
		 */
		public function addMethod(method:EffectMethodBase):Void
		{
			_methods.push(new MethodVOSet(method));
			method.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			invalidateShaderProgram();
		}

		/**
		 * Queries whether a given effect method was added to the material.
		 *
		 * @param method The method to be queried.
		 * @return true if the method was added to the material, false otherwise.
		 */
		public function hasMethod(method:EffectMethodBase):Bool
		{
			return getMethodSetForMethod(method) != null;
		}
		
		/**
		 * Inserts a method to change the material after all lighting is performed at the given index.
		 * @param method The method to be added.
		 * @param index The index of the method's occurrence
		 */
		public function addMethodAt(method:EffectMethodBase, index:Int):Void
		{
			_methods.insert(index, new MethodVOSet(method));
			method.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			invalidateShaderProgram();
		}

		/**
		 * Returns the method added at the given index.
		 * @param index The index of the method to retrieve.
		 * @return The method at the given index.
		 */
		public function getMethodAt(index:Int):EffectMethodBase
		{
			if (index > _methods.length - 1)
				return null;
			
			return _methods[index].method;
		}

		/**
		 * The number of "effect" methods added to the material.
		 */
		public var numMethods(get, null) : Int;
		public function get_numMethods() : Int
		{
			return _methods.length;
		}
		
		/**
		 * Removes a method from the pass.
		 * @param method The method to be removed.
		 */
		public function removeMethod(method:EffectMethodBase):Void
		{
			var methodSet:MethodVOSet = getMethodSetForMethod(method);
			if (methodSet != null) {
				var index:Int = Lambda.indexOf(_methods, methodSet);
				_methods.splice(index, 1);
				method.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				invalidateShaderProgram();
			}
		}
		
		private function getMethodSetForMethod(method:EffectMethodBase):MethodVOSet
		{
			var len:Int = _methods.length;
			// For loop conversion - 			for (var i:Int = 0; i < len; ++i)
			var i:Int;
			for (i in 0...len) {
				if (_methods[i].method == method)
					return _methods[i];
			}
			
			return null;
		}
	}

