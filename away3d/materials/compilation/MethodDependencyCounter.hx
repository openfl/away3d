package away3d.materials.compilation;

	import away3d.materials.LightSources;
	import away3d.materials.methods.MethodVO;

	/**
	 * MethodDependencyCounter keeps track of the number of dependencies for "named registers" used across methods.
	 * Named registers are that are not necessarily limited to a single method. They are created by the compiler and
	 * passed on to methods. The compiler uses the results to reserve usages through RegisterPool, which can be removed
	 * each time a method has been compiled into the shader.
	 *
	 * @see RegisterPool.addUsage
	 */
	class MethodDependencyCounter
	{
		var _projectionDependencies:UInt;
		var _normalDependencies:UInt;
		var _viewDirDependencies:UInt;
		var _uvDependencies:UInt;
		var _secondaryUVDependencies:UInt;
		var _globalPosDependencies:UInt;
		var _tangentDependencies:UInt;
		var _usesGlobalPosFragment:Bool = false;
		var _numPointLights:UInt;
		var _lightSourceMask:UInt;

		/**
		 * Creates a new MethodDependencyCounter object.
		 */
		public function new()
		{
		}

		/**
		 * Clears dependency counts for all registers. Called when recompiling a pass.
		 */
		public function reset():Void
		{
			_projectionDependencies = 0;
			_normalDependencies = 0;
			_viewDirDependencies = 0;
			_uvDependencies = 0;
			_secondaryUVDependencies = 0;
			_globalPosDependencies = 0;
			_tangentDependencies = 0;
			_usesGlobalPosFragment = false;
		}

		/**
		 * Sets the amount of lights that have a position associated with them.
		 * @param numPointLights The amount of point lights.
		 * @param lightSourceMask The light source types used by the material.
		 */
		public function setPositionedLights(numPointLights:UInt, lightSourceMask:UInt):Void
		{
			_numPointLights = numPointLights;
			_lightSourceMask = lightSourceMask;
		}

		/**
		 * Increases dependency counters for the named registers listed as required by the given MethodVO.
		 * @param methodVO the MethodVO object for which to include dependencies.
		 */
		public function includeMethodVO(methodVO:MethodVO):Void
		{
			if (methodVO.needsProjection)
				++_projectionDependencies;
			if (methodVO.needsGlobalVertexPos) {
				++_globalPosDependencies;
				if (methodVO.needsGlobalFragmentPos)
					_usesGlobalPosFragment = true;
			} else if (methodVO.needsGlobalFragmentPos) {
				++_globalPosDependencies;
				_usesGlobalPosFragment = true;
			}
			if (methodVO.needsNormals)
				++_normalDependencies;
			if (methodVO.needsTangents)
				++_tangentDependencies;
			if (methodVO.needsView)
				++_viewDirDependencies;
			if (methodVO.needsUV)
				++_uvDependencies;
			if (methodVO.needsSecondaryUV)
				++_secondaryUVDependencies;
		}

		/**
		 * The amount of tangent vector dependencies (fragment shader).
		 */
		public var tangentDependencies(get, null) : UInt;
		public function get_tangentDependencies() : UInt
		{
			return _tangentDependencies;
		}

		/**
		 * Indicates whether there are any dependencies on the world-space position vector.
		 */
		public var usesGlobalPosFragment(get, null) : Bool;
		public function get_usesGlobalPosFragment() : Bool
		{
			return _usesGlobalPosFragment;
		}

		/**
		 * The amount of dependencies on the projected position.
		 */
		public var projectionDependencies(get, null) : UInt;
		public function get_projectionDependencies() : UInt
		{
			return _projectionDependencies;
		}

		/**
		 * The amount of dependencies on the normal vector.
		 */
		public var normalDependencies(get, null) : UInt;
		public function get_normalDependencies() : UInt
		{
			return _normalDependencies;
		}

		/**
		 * The amount of dependencies on the view direction.
		 */
		public var viewDirDependencies(get, null) : UInt;
		public function get_viewDirDependencies() : UInt
		{
			return _viewDirDependencies;
		}

		/**
		 * The amount of dependencies on the primary UV coordinates.
		 */
		public var uvDependencies(get, null) : UInt;
		public function get_uvDependencies() : UInt
		{
			return _uvDependencies;
		}

		/**
		 * The amount of dependencies on the secondary UV coordinates.
		 */
		public var secondaryUVDependencies(get, null) : UInt;
		public function get_secondaryUVDependencies() : UInt
		{
			return _secondaryUVDependencies;
		}

		/**
		 * The amount of dependencies on the global position. This can be 0 while hasGlobalPosDependencies is true when
		 * the global position is used as a temporary value (fe to calculate the view direction)
		 */
		public var globalPosDependencies(get, null) : UInt;
		public function get_globalPosDependencies() : UInt
		{
			return _globalPosDependencies;
		}

		/**
		 * Adds any external world space dependencies, used to force world space calculations.
		 */
		public function addWorldSpaceDependencies(fragmentLights:Bool):Void
		{
			if (_viewDirDependencies > 0)
				++_globalPosDependencies;
			
			if (_numPointLights > 0 && (_lightSourceMask & LightSources.LIGHTS)!=0) {
				++_globalPosDependencies;
				if (fragmentLights)
					_usesGlobalPosFragment = true;
			}
		}
	}

