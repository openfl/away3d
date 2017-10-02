package away3d.materials.compilation;

import openfl.Vector;

/**
 * LightingShaderCompiler is a ShaderCompiler that generates code for passes performing shading only (no effect passes)
 */
class LightingShaderCompiler extends ShaderCompiler
{
	public var lightVertexConstantIndex(get, never):Int;
	public var tangentSpace(get, never):Bool;
	
	public var _pointLightFragmentConstants:Vector<ShaderRegisterElement>;
	public var _pointLightVertexConstants:Vector<ShaderRegisterElement>;
	public var _dirLightFragmentConstants:Vector<ShaderRegisterElement>;
	public var _dirLightVertexConstants:Vector<ShaderRegisterElement>;
	private var _lightVertexConstantIndex:Int;
	private var _shadowRegister:ShaderRegisterElement;
	
	/**
	 * Create a new LightingShaderCompiler object.
	 * @param profile The compatibility profile of the renderer.
	 */
	public function new(profile:String)
	{
		super(profile);
	}

	/**
	 * The starting index if the vertex constant to which light data needs to be uploaded.
	 */
	private function get_lightVertexConstantIndex():Int
	{
		return _lightVertexConstantIndex;
	}

	/**
	 * @inheritDoc
	 */
	override private function initRegisterIndices():Void
	{
		super.initRegisterIndices();
		_lightVertexConstantIndex = -1;
	}

	/**
	 * @inheritDoc
	 */
	override private function createNormalRegisters():Void
	{
		// need to be created FIRST and in this order
		if (tangentSpace) {
			_sharedRegisters.animatedTangent = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(_sharedRegisters.animatedTangent, 1);
			_sharedRegisters.bitangent = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(_sharedRegisters.bitangent, 1);
			
			_sharedRegisters.tangentInput = _registerCache.getFreeVertexAttribute();
			_tangentBufferIndex = _sharedRegisters.tangentInput.index;
			
			_animatableAttributes.push(_sharedRegisters.tangentInput.toString());
			_animationTargetRegisters.push(_sharedRegisters.animatedTangent.toString());
		}
		
		_sharedRegisters.normalInput = _registerCache.getFreeVertexAttribute();
		_normalBufferIndex = _sharedRegisters.normalInput.index;
		
		_sharedRegisters.animatedNormal = _registerCache.getFreeVertexVectorTemp();
		_registerCache.addVertexTempUsages(_sharedRegisters.animatedNormal, 1);
		
		_animatableAttributes.push(_sharedRegisters.normalInput.toString());
		_animationTargetRegisters.push(_sharedRegisters.animatedNormal.toString());
	}

	/**
	 * Indicates whether or not lighting happens in tangent space. This is only the case if no world-space
	 * dependencies exist.
	 */
	private function get_tangentSpace():Bool
	{
		return _numLightProbes == 0 && methodSetup._normalMethod.hasOutput && _methodSetup._normalMethod.tangentSpace;
	}

	/**
	 * @inheritDoc
	 */
	override private function initLightData():Void
	{
		super.initLightData();
		
		_pointLightVertexConstants = new Vector<ShaderRegisterElement>(_numPointLights, true);
		_pointLightFragmentConstants = new Vector<ShaderRegisterElement>(_numPointLights*2, true);
		if (tangentSpace) {
			_dirLightVertexConstants = new Vector<ShaderRegisterElement>(_numDirectionalLights, true);
			_dirLightFragmentConstants = new Vector<ShaderRegisterElement>(_numDirectionalLights*2, true);
		} else
			_dirLightFragmentConstants = new Vector<ShaderRegisterElement>(_numDirectionalLights*3, true);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function calculateDependencies():Void
	{
		super.calculateDependencies();
		if (!tangentSpace)
			_dependencyCounter.addWorldSpaceDependencies(false);
	}

	/**
	 * @inheritDoc
	 */
	override private function compileNormalCode():Void
	{
		_sharedRegisters.normalFragment = _registerCache.getFreeFragmentVectorTemp();
		_registerCache.addFragmentTempUsages(_sharedRegisters.normalFragment, _dependencyCounter.normalDependencies);
		
		if (_methodSetup._normalMethod.hasOutput && !_methodSetup._normalMethod.tangentSpace) {
			_vertexCode += _methodSetup._normalMethod.getVertexCode(_methodSetup._normalMethodVO, _registerCache);
			_fragmentCode += _methodSetup._normalMethod.getFragmentCode(_methodSetup._normalMethodVO, _registerCache, _sharedRegisters.normalFragment);
			return;
		}
		
		if (tangentSpace)
			compileTangentSpaceNormalMapCode();
		else {
			var normalMatrix:Vector<ShaderRegisterElement> = new Vector<ShaderRegisterElement>(3, true);
			normalMatrix[0] = _registerCache.getFreeVertexConstant();
			normalMatrix[1] = _registerCache.getFreeVertexConstant();
			normalMatrix[2] = _registerCache.getFreeVertexConstant();
			_registerCache.getFreeVertexConstant();
			_sceneNormalMatrixIndex = normalMatrix[0].index*4;
			_sharedRegisters.normalVarying = _registerCache.getFreeVarying();
			
			// no output, world space is enough
			_vertexCode += "m33 " + _sharedRegisters.normalVarying + ".xyz, " + _sharedRegisters.animatedNormal + ", " + normalMatrix[0] + "\n" +
				"mov " + _sharedRegisters.normalVarying + ".w, " + _sharedRegisters.animatedNormal + ".w	\n";
			
			_fragmentCode += "nrm " + _sharedRegisters.normalFragment + ".xyz, " + _sharedRegisters.normalVarying + "\n" +
				"mov " + _sharedRegisters.normalFragment + ".w, " + _sharedRegisters.normalVarying + ".w		\n";
			
		}
		
		if (_dependencyCounter.tangentDependencies > 0) {
			_sharedRegisters.tangentInput = _registerCache.getFreeVertexAttribute();
			_tangentBufferIndex = _sharedRegisters.tangentInput.index;
			_sharedRegisters.tangentVarying = _registerCache.getFreeVarying();
		}
	}

	/**
	 * Generates code to retrieve the tangent space normal from the normal map
	 */
	private function compileTangentSpaceNormalMapCode():Void
	{
		// normalize normal + tangent vector and generate (approximated) bitangent
		_vertexCode += "nrm " + _sharedRegisters.animatedNormal + ".xyz, " + _sharedRegisters.animatedNormal + "\n" +
			"nrm " + _sharedRegisters.animatedTangent + ".xyz, " + _sharedRegisters.animatedTangent + "\n";
		_vertexCode += "crs " + _sharedRegisters.bitangent + ".xyz, " + _sharedRegisters.animatedNormal + ", " + _sharedRegisters.animatedTangent + "\n";

		_fragmentCode += _methodSetup._normalMethod.getFragmentCode(_methodSetup._normalMethodVO, _registerCache, _sharedRegisters.normalFragment);
		
		if (_methodSetup._normalMethodVO.needsView)
			_registerCache.removeFragmentTempUsage(_sharedRegisters.viewDirFragment);
		if (_methodSetup._normalMethodVO.needsGlobalFragmentPos || _methodSetup._normalMethodVO.needsGlobalVertexPos)
			_registerCache.removeVertexTempUsage(_sharedRegisters.globalPositionVertex);
	}

	/**
	 * @inheritDoc
	 */
	override private function compileViewDirCode():Void
	{
		var cameraPositionReg:ShaderRegisterElement = _registerCache.getFreeVertexConstant();
		_sharedRegisters.viewDirVarying = _registerCache.getFreeVarying();
		_sharedRegisters.viewDirFragment = _registerCache.getFreeFragmentVectorTemp();
		_registerCache.addFragmentTempUsages(_sharedRegisters.viewDirFragment, _dependencyCounter.viewDirDependencies);
		
		_cameraPositionIndex = cameraPositionReg.index*4;
		
		if (tangentSpace) {
			var temp:ShaderRegisterElement = _registerCache.getFreeVertexVectorTemp();
			_vertexCode += "sub " + temp + ", " + cameraPositionReg + ", " + _sharedRegisters.localPosition + "\n" +
				"m33 " + _sharedRegisters.viewDirVarying + ".xyz, " + temp + ", " + _sharedRegisters.animatedTangent + "\n" +
				"mov " + _sharedRegisters.viewDirVarying + ".w, " + _sharedRegisters.localPosition + ".w\n";
		} else {
			_vertexCode += "sub " + _sharedRegisters.viewDirVarying + ", " + cameraPositionReg + ", " + _sharedRegisters.globalPositionVertex + "\n";
			_registerCache.removeVertexTempUsage(_sharedRegisters.globalPositionVertex);
		}
		
		_fragmentCode += "nrm " + _sharedRegisters.viewDirFragment + ".xyz, " + _sharedRegisters.viewDirVarying + "\n" +
			"mov " + _sharedRegisters.viewDirFragment + ".w,   " + _sharedRegisters.viewDirVarying + ".w 		\n";
	}

	/**
	 * @inheritDoc
	 */
	override private function compileLightingCode():Void
	{
		if (_methodSetup._shadowMethod != null)
			compileShadowCode();
		
		_methodSetup._diffuseMethod.shadowRegister = _shadowRegister;
		
		_sharedRegisters.shadedTarget = _registerCache.getFreeFragmentVectorTemp();
		_registerCache.addFragmentTempUsages(_sharedRegisters.shadedTarget, 1);
		
		_vertexCode += _methodSetup._diffuseMethod.getVertexCode(_methodSetup._diffuseMethodVO, _registerCache);
		_fragmentCode += _methodSetup._diffuseMethod.getFragmentPreLightingCode(_methodSetup._diffuseMethodVO, _registerCache);
		
		if (_usingSpecularMethod) {
			_vertexCode += _methodSetup._specularMethod.getVertexCode(_methodSetup._specularMethodVO, _registerCache);
			_fragmentCode += _methodSetup._specularMethod.getFragmentPreLightingCode(_methodSetup._specularMethodVO, _registerCache);
		}
		
		if (usesLights()) {
			initLightRegisters();
			compileDirectionalLightCode();
			compilePointLightCode();
		}
		
		if (usesProbes())
			compileLightProbeCode();
		
		// only need to create and reserve _shadedTargetReg here, no earlier?
		_vertexCode += _methodSetup._ambientMethod.getVertexCode(_methodSetup._ambientMethodVO, _registerCache);
		_fragmentCode += _methodSetup._ambientMethod.getFragmentCode(_methodSetup._ambientMethodVO, _registerCache, _sharedRegisters.shadedTarget);
		if (_methodSetup._ambientMethodVO.needsNormals)
			_registerCache.removeFragmentTempUsage(_sharedRegisters.normalFragment);
		if (_methodSetup._ambientMethodVO.needsView)
			_registerCache.removeFragmentTempUsage(_sharedRegisters.viewDirFragment);
		
		_fragmentCode += _methodSetup._diffuseMethod.getFragmentPostLightingCode(_methodSetup._diffuseMethodVO, _registerCache, _sharedRegisters.shadedTarget);
		
		if (_alphaPremultiplied) {
			_fragmentCode += "add " + _sharedRegisters.shadedTarget + ".w, " + _sharedRegisters.shadedTarget + ".w, " + _sharedRegisters.commons + ".z\n" +
				"div " + _sharedRegisters.shadedTarget + ".xyz, " + _sharedRegisters.shadedTarget + ", " + _sharedRegisters.shadedTarget + ".w\n" +
				"sub " + _sharedRegisters.shadedTarget + ".w, " + _sharedRegisters.shadedTarget + ".w, " + _sharedRegisters.commons + ".z\n" +
				"sat " + _sharedRegisters.shadedTarget + ".xyz, " + _sharedRegisters.shadedTarget + "\n";
		}
		
		// resolve other dependencies as well?
		if (_methodSetup._diffuseMethodVO.needsNormals)
			_registerCache.removeFragmentTempUsage(_sharedRegisters.normalFragment);
		if (_methodSetup._diffuseMethodVO.needsView)
			_registerCache.removeFragmentTempUsage(_sharedRegisters.viewDirFragment);
		
		if (_usingSpecularMethod) {
			_methodSetup._specularMethod.shadowRegister = _shadowRegister;
			_fragmentCode += _methodSetup._specularMethod.getFragmentPostLightingCode(_methodSetup._specularMethodVO, _registerCache, _sharedRegisters.shadedTarget);
			if (_methodSetup._specularMethodVO.needsNormals)
				_registerCache.removeFragmentTempUsage(_sharedRegisters.normalFragment);
			if (_methodSetup._specularMethodVO.needsView)
				_registerCache.removeFragmentTempUsage(_sharedRegisters.viewDirFragment);
		}
		
		if (_methodSetup._shadowMethod != null)
			_registerCache.removeFragmentTempUsage(_shadowRegister);
	}

	/**
	 * Provides the code to provide shadow mapping.
	 */
	private function compileShadowCode():Void
	{
		if (_sharedRegisters.normalFragment != null)
			_shadowRegister = _sharedRegisters.normalFragment;
		else
			_shadowRegister = _registerCache.getFreeFragmentVectorTemp();
		_registerCache.addFragmentTempUsages(_shadowRegister, 1);
		
		_vertexCode += _methodSetup._shadowMethod.getVertexCode(_methodSetup._shadowMethodVO, _registerCache);
		_fragmentCode += _methodSetup._shadowMethod.getFragmentCode(_methodSetup._shadowMethodVO, _registerCache, _shadowRegister);
	}

	/**
	 * Initializes constant registers to contain light data.
	 */
	private function initLightRegisters():Void
	{
		// init these first so we're sure they're in sequence
		var i:Int = 0, len:Int;
		
		if (_dirLightVertexConstants != null) {
			len = _dirLightVertexConstants.length;
			for (i in 0...len) {
				_dirLightVertexConstants[i] = _registerCache.getFreeVertexConstant();
				if (_lightVertexConstantIndex == -1)
					_lightVertexConstantIndex = _dirLightVertexConstants[i].index*4;
			}
		}
		
		len = _pointLightVertexConstants.length;
		for (i in 0...len) {
			_pointLightVertexConstants[i] = _registerCache.getFreeVertexConstant();
			if (_lightVertexConstantIndex == -1)
				_lightVertexConstantIndex = _pointLightVertexConstants[i].index*4;
		}
		
		len = _dirLightFragmentConstants.length;
		for (i in 0...len) {
			_dirLightFragmentConstants[i] = _registerCache.getFreeFragmentConstant();
			if (_lightFragmentConstantIndex == -1)
				_lightFragmentConstantIndex = _dirLightFragmentConstants[i].index*4;
		}
		
		len = _pointLightFragmentConstants.length;
		for (i in 0...len) {
			_pointLightFragmentConstants[i] = _registerCache.getFreeFragmentConstant();
			if (_lightFragmentConstantIndex == -1)
				_lightFragmentConstantIndex = _pointLightFragmentConstants[i].index*4;
		}
	}

	/**
	 * Compiles the shading code for directional lights.
	 */
	private function compileDirectionalLightCode():Void
	{
		var diffuseColorReg:ShaderRegisterElement;
		var specularColorReg:ShaderRegisterElement;
		var lightDirReg:ShaderRegisterElement;
		var vertexRegIndex:Int = 0;
		var fragmentRegIndex:Int = 0;
		var addSpec:Bool = _usingSpecularMethod && usesLightsForSpecular();
		var addDiff:Bool = usesLightsForDiffuse();
		
		if (!(addSpec || addDiff))
			return;
		
		for (i in 0..._numDirectionalLights) {
			
			if (tangentSpace) {
				lightDirReg = _dirLightVertexConstants[vertexRegIndex++];
				var lightVarying:ShaderRegisterElement = _registerCache.getFreeVarying();
				
				_vertexCode += "m33 " + lightVarying + ".xyz, " + lightDirReg + ", " + _sharedRegisters.animatedTangent + "\n" +
					"mov " + lightVarying + ".w, " + lightDirReg + ".w\n";
				
				lightDirReg = _registerCache.getFreeFragmentVectorTemp();
				_registerCache.addVertexTempUsages(lightDirReg, 1);
				_fragmentCode += "nrm " + lightDirReg + ".xyz, " + lightVarying + "\n";
				_fragmentCode += "mov " + lightDirReg + ".w, " + lightVarying + ".w\n";
			} else
				lightDirReg = _dirLightFragmentConstants[fragmentRegIndex++];
			
			diffuseColorReg = _dirLightFragmentConstants[fragmentRegIndex++];
			specularColorReg = _dirLightFragmentConstants[fragmentRegIndex++];
			if (addDiff)
				_fragmentCode += _methodSetup._diffuseMethod.getFragmentCodePerLight(_methodSetup._diffuseMethodVO, lightDirReg, diffuseColorReg, _registerCache);
			if (addSpec)
				_fragmentCode += _methodSetup._specularMethod.getFragmentCodePerLight(_methodSetup._specularMethodVO, lightDirReg, specularColorReg, _registerCache);
			
			if (tangentSpace)
				_registerCache.removeVertexTempUsage(lightDirReg);
		}
	}

	/**
	 * Compiles the shading code for point lights.
	 */
	private function compilePointLightCode():Void
	{
		var diffuseColorReg:ShaderRegisterElement;
		var specularColorReg:ShaderRegisterElement;
		var lightPosReg:ShaderRegisterElement;
		var lightDirReg:ShaderRegisterElement;
		var vertexRegIndex:Int = 0;
		var fragmentRegIndex:Int = 0;
		var addSpec:Bool = _usingSpecularMethod && usesLightsForSpecular();
		var addDiff:Bool = usesLightsForDiffuse();
		
		if (!(addSpec || addDiff))
			return;
		
		for (i in 0..._numPointLights) {
			lightPosReg = _pointLightVertexConstants[vertexRegIndex++];
			diffuseColorReg = _pointLightFragmentConstants[fragmentRegIndex++];
			specularColorReg = _pointLightFragmentConstants[fragmentRegIndex++];
			lightDirReg = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(lightDirReg, 1);
			
			var lightVarying:ShaderRegisterElement = _registerCache.getFreeVarying();
			if (tangentSpace) {
				var temp:ShaderRegisterElement = _registerCache.getFreeVertexVectorTemp();
				_vertexCode += "sub " + temp + ", " + lightPosReg + ", " + _sharedRegisters.localPosition + "\n" +
					"m33 " + lightVarying + ".xyz, " + temp + ", " + _sharedRegisters.animatedTangent + "\n" +
					"mov " + lightVarying + ".w, " + _sharedRegisters.localPosition + ".w\n";
			} else
				_vertexCode += "sub " + lightVarying + ", " + lightPosReg + ", " + _sharedRegisters.globalPositionVertex + "\n";
			
			if (_enableLightFallOff && _profile != "baselineConstrained") {
				// calculate attenuation
				_fragmentCode +=
					// attenuate
					"dp3 " + lightDirReg + ".w, " + lightVarying + ", " + lightVarying + "\n" +
					// w = d - radius
					"sub " + lightDirReg + ".w, " + lightDirReg + ".w, " + diffuseColorReg + ".w\n" +
					// w = (d - radius)/(max-min)
					"mul " + lightDirReg + ".w, " + lightDirReg + ".w, " + specularColorReg + ".w\n" +
					// w = clamp(w, 0, 1)
					"sat " + lightDirReg + ".w, " + lightDirReg + ".w\n" +
					// w = 1-w
					"sub " + lightDirReg + ".w, " + _sharedRegisters.commons + ".w, " + lightDirReg + ".w\n" +
					// normalize
					"nrm " + lightDirReg + ".xyz, " + lightVarying + "\n";
			} else {
				_fragmentCode += "nrm " + lightDirReg + ".xyz, " + lightVarying + "\n" +
					"mov " + lightDirReg + ".w, " + lightVarying + ".w\n";
			}
			if (_lightFragmentConstantIndex == -1)
				_lightFragmentConstantIndex = lightPosReg.index*4;
			
			if (addDiff)
				_fragmentCode += _methodSetup._diffuseMethod.getFragmentCodePerLight(_methodSetup._diffuseMethodVO, lightDirReg, diffuseColorReg, _registerCache);
			
			if (addSpec)
				_fragmentCode += _methodSetup._specularMethod.getFragmentCodePerLight(_methodSetup._specularMethodVO, lightDirReg, specularColorReg, _registerCache);
			
			_registerCache.removeFragmentTempUsage(lightDirReg);
			
		}
	}

	/**
	 * Compiles shading code for light probes.
	 */
	private function compileLightProbeCode():Void
	{
		var weightReg:String;
		var weightComponents:Array<Dynamic> = [ ".x", ".y", ".z", ".w" ];
		var weightRegisters:Vector<ShaderRegisterElement> = new Vector<ShaderRegisterElement>();
		var i:Int = 0;
		var texReg:ShaderRegisterElement;
		var addSpec:Bool = _usingSpecularMethod && usesProbesForSpecular();
		var addDiff:Bool = usesProbesForDiffuse();
		
		if (!(addSpec || addDiff))
			return;
		
		if (addDiff)
			_lightProbeDiffuseIndices = new Vector<UInt>();
		if (addSpec)
			_lightProbeSpecularIndices = new Vector<UInt>();
		
		for (i in 0..._numProbeRegisters) {
			weightRegisters[i] = _registerCache.getFreeFragmentConstant();
			if (i == 0)
				_probeWeightsIndex = weightRegisters[i].index*4;
		}
		
		for (i in 0..._numLightProbes) {
			weightReg = weightRegisters[Math.floor(i/4)].toString() + weightComponents[i%4];
			
			if (addDiff) {
				texReg = _registerCache.getFreeTextureReg();
				_lightProbeDiffuseIndices[i] = texReg.index;
				_fragmentCode += _methodSetup._diffuseMethod.getFragmentCodePerProbe(_methodSetup._diffuseMethodVO, texReg, weightReg, _registerCache);
			}
			
			if (addSpec) {
				texReg = _registerCache.getFreeTextureReg();
				_lightProbeSpecularIndices[i] = texReg.index;
				_fragmentCode += _methodSetup._specularMethod.getFragmentCodePerProbe(_methodSetup._specularMethodVO, texReg, weightReg, _registerCache);
			}
		}
	}
}