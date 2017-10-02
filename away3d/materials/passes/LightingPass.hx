package away3d.materials.passes;

import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.lights.DirectionalLight;
import away3d.lights.LightProbe;
import away3d.lights.PointLight;
import away3d.materials.LightSources;
import away3d.materials.MaterialBase;
import away3d.materials.compilation.LightingShaderCompiler;
import away3d.materials.compilation.ShaderCompiler;

import openfl.display3D.Context3D;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * LightingPass is a shader pass that uses shader methods to compile a complete program. It only includes the lighting
 * methods. It's used by multipass materials to accumulate lighting passes.
 *
 * @see away3d.materials.MultiPassMaterialBase
 */

class LightingPass extends CompiledPass
{
	var _includeCasters:Bool = true;
	var _tangentSpace:Bool;
	var _lightVertexConstantIndex:Int;
	var _inverseSceneMatrix:Vector<Float> = new Vector<Float>();
	
	var _directionalLightsOffset:UInt;
	var _pointLightsOffset:UInt;
	var _lightProbesOffset:UInt;
	var _maxLights:Int = 3;
	
	/**
	 * Creates a new LightingPass objects.
	 *
	 * @param material The material to which this pass belongs.
	 */
	public function new(material:MaterialBase)
	{
		super(material);
	}

	/**
	 * Indicates the offset in the light picker's directional light vector for which to start including lights.
	 * This needs to be set before the light picker is assigned.
	 */
	public var directionalLightsOffset(get, set):UInt;
	
	private function get_directionalLightsOffset():UInt
	{
		return _directionalLightsOffset;
	}
	
	private function set_directionalLightsOffset(value:UInt):UInt
	{
		_directionalLightsOffset = value;
		return value;
	}

	/**
	 * Indicates the offset in the light picker's point light vector for which to start including lights.
	 * This needs to be set before the light picker is assigned.
	 */
	public var pointLightsOffset(get, set):UInt;
	
	private function get_pointLightsOffset():UInt
	{
		return _pointLightsOffset;
	}
	
	private function set_pointLightsOffset(value:UInt):UInt
	{
		_pointLightsOffset = value;
		return value;
	}

	/**
	 * Indicates the offset in the light picker's light probes vector for which to start including lights.
	 * This needs to be set before the light picker is assigned.
	 */
	public var lightProbesOffset(get, set):UInt;
	
	private function get_lightProbesOffset():UInt
	{
		return _lightProbesOffset;
	}
	
	private function set_lightProbesOffset(value:UInt):UInt
	{
		_lightProbesOffset = value;
		return value;
	}

	/**
	 * @inheritDoc
	 */
	override private function createCompiler(profile:String):ShaderCompiler
	{
		_maxLights = profile == "baselineConstrained"? 1 : 3;
		return new LightingShaderCompiler(profile);
	}

	/**
	 * Indicates whether or not shadow casting lights need to be included.
	 */
	public var includeCasters(get, set):Bool;
	
	private function get_includeCasters():Bool
	{
		return _includeCasters;
	}
	
	private function set_includeCasters(value:Bool):Bool
	{
		if (_includeCasters == value)
			return value;
		_includeCasters = value;
		invalidateShaderProgram();
		return value;
	}

	/**
	 * @inheritDoc
	 */
	override private function updateLights():Void
	{
		super.updateLights();
		var numDirectionalLights:Int = _numDirectionalLights;
		var numPointLights:Int = _numPointLights;
		var numLightProbes:Int = _numLightProbes;
		
		if (_lightPicker != null) {
			_numDirectionalLights = calculateNumDirectionalLights(_lightPicker.numDirectionalLights);
			_numPointLights = calculateNumPointLights(_lightPicker.numPointLights);
			_numLightProbes = calculateNumProbes(_lightPicker.numLightProbes);
			
			if (_includeCasters) {
				_numPointLights += _lightPicker.numCastingPointLights;
				_numDirectionalLights += _lightPicker.numCastingDirectionalLights;
			}
		} else {
			_numDirectionalLights = 0;
			_numPointLights = 0;
			_numLightProbes = 0;
		}
		
		
		if (numPointLights != _numPointLights || numDirectionalLights != _numDirectionalLights || numLightProbes != _numLightProbes) {
			invalidateShaderProgram();
		}
	
	}

	/**
	 * Calculates the amount of directional lights this material will support.
	 * @param numDirectionalLights The maximum amount of directional lights to support.
	 * @return The amount of directional lights this material will support, bounded by the amount necessary.
	 */
	private function calculateNumDirectionalLights(numDirectionalLights:UInt):Int
	{
		return Std.int(Math.min(numDirectionalLights - _directionalLightsOffset, _maxLights));
	}

	/**
	 * Calculates the amount of point lights this material will support.
	 * @param numDirectionalLights The maximum amount of point lights to support.
	 * @return The amount of point lights this material will support, bounded by the amount necessary.
	 */
	private function calculateNumPointLights(numPointLights:UInt):Int
	{
		var numFree:Int = _maxLights - _numDirectionalLights;
		return Std.int(Math.min(numPointLights - _pointLightsOffset, numFree));
	}

	/**
	 * Calculates the amount of light probes this material will support.
	 * @param numDirectionalLights The maximum amount of light probes to support.
	 * @return The amount of light probes this material will support, bounded by the amount necessary.
	 */
	private function calculateNumProbes(numLightProbes:UInt):Int
	{
		var numChannels:Int = 0;
		if ((_specularLightSources & LightSources.PROBES) != 0)
			++numChannels;
		if ((_diffuseLightSources & LightSources.PROBES) != 0)
			++numChannels;
		
		// 4 channels available
		return Std.int(Math.min(numLightProbes - _lightProbesOffset, Std.int(4/numChannels)));
	}

	/**
	 * @inheritDoc
	 */
	override private function updateShaderProperties():Void
	{
		super.updateShaderProperties();
		_tangentSpace = cast(_compiler, LightingShaderCompiler).tangentSpace;
	}

	/**
	 * @inheritDoc
	 */
	override private function updateRegisterIndices():Void
	{
		super.updateRegisterIndices();
		_lightVertexConstantIndex = cast(_compiler, LightingShaderCompiler).lightVertexConstantIndex;
	}

	/**
	 * @inheritDoc
	 */
	override private function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):Void
	{
		renderable.inverseSceneTransform.copyRawDataTo(_inverseSceneMatrix);
		
		if (_tangentSpace && _cameraPositionIndex >= 0) {
			var pos:Vector3D = camera.scenePosition;
			var x:Float = pos.x;
			var y:Float = pos.y;
			var z:Float = pos.z;
			_vertexConstantData[_cameraPositionIndex] = _inverseSceneMatrix[0]*x + _inverseSceneMatrix[4]*y + _inverseSceneMatrix[8]*z + _inverseSceneMatrix[12];
			_vertexConstantData[_cameraPositionIndex + 1] = _inverseSceneMatrix[1]*x + _inverseSceneMatrix[5]*y + _inverseSceneMatrix[9]*z + _inverseSceneMatrix[13];
			_vertexConstantData[_cameraPositionIndex + 2] = _inverseSceneMatrix[2]*x + _inverseSceneMatrix[6]*y + _inverseSceneMatrix[10]*z + _inverseSceneMatrix[14];
		}
		
		super.render(renderable, stage3DProxy, camera, viewProjection);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		super.activate(stage3DProxy, camera);
		
		if (!_tangentSpace && _cameraPositionIndex >= 0) {
			var pos:Vector3D = camera.scenePosition;
			_vertexConstantData[_cameraPositionIndex] = pos.x;
			_vertexConstantData[_cameraPositionIndex + 1] = pos.y;
			_vertexConstantData[_cameraPositionIndex + 2] = pos.z;
		}
	}

	/**
	 * Indicates whether any light probes are used to contribute to the specular shading.
	 */
	private function usesProbesForSpecular():Bool
	{
		return _numLightProbes > 0 && (_specularLightSources & LightSources.PROBES) != 0;
	}

	/**
	 * Indicates whether any light probes are used to contribute to the diffuse shading.
	 */
	private function usesProbesForDiffuse():Bool
	{
		return _numLightProbes > 0 && (_diffuseLightSources & LightSources.PROBES) != 0;
	}

	/**
	 * @inheritDoc
	 */
	override private function updateLightConstants():Void
	{
		var dirLight:DirectionalLight;
		var pointLight:PointLight;
		var i:UInt, k:UInt;
		var len:Int;
		var dirPos:Vector3D;
		var total:Int = 0;
		var numLightTypes:Int = _includeCasters? 2 : 1;
		var l:Int;
		var offset:Int;
		
		l = _lightVertexConstantIndex;
		k = _lightFragmentConstantIndex;
		
		var caster:Int = 0;
		var dirLights:Vector<DirectionalLight> = _lightPicker.directionalLights;
		offset = _directionalLightsOffset;
		len = _lightPicker.directionalLights.length;
		if (offset > len) {
			caster = 1;
			offset -= len;
		}
		
		while (caster < numLightTypes) {
			if (caster != 0)
				dirLights = _lightPicker.castingDirectionalLights;
			len = dirLights.length;
			if (len > _numDirectionalLights)
				len = _numDirectionalLights;
			for (i in 0...len) {
				dirLight = dirLights[offset + i];
				dirPos = dirLight.sceneDirection;
				
				_ambientLightR += dirLight._ambientR;
				_ambientLightG += dirLight._ambientG;
				_ambientLightB += dirLight._ambientB;
				
				if (_tangentSpace) {
					var x:Float = -dirPos.x;
					var y:Float = -dirPos.y;
					var z:Float = -dirPos.z;
					_vertexConstantData[l++] = _inverseSceneMatrix[0]*x + _inverseSceneMatrix[4]*y + _inverseSceneMatrix[8]*z;
					_vertexConstantData[l++] = _inverseSceneMatrix[1]*x + _inverseSceneMatrix[5]*y + _inverseSceneMatrix[9]*z;
					_vertexConstantData[l++] = _inverseSceneMatrix[2]*x + _inverseSceneMatrix[6]*y + _inverseSceneMatrix[10]*z;
					_vertexConstantData[l++] = 1;
				} else {
					_fragmentConstantData[k++] = -dirPos.x;
					_fragmentConstantData[k++] = -dirPos.y;
					_fragmentConstantData[k++] = -dirPos.z;
					_fragmentConstantData[k++] = 1;
				}
				
				_fragmentConstantData[k++] = dirLight._diffuseR;
				_fragmentConstantData[k++] = dirLight._diffuseG;
				_fragmentConstantData[k++] = dirLight._diffuseB;
				_fragmentConstantData[k++] = 1;
				
				_fragmentConstantData[k++] = dirLight._specularR;
				_fragmentConstantData[k++] = dirLight._specularG;
				_fragmentConstantData[k++] = dirLight._specularB;
				_fragmentConstantData[k++] = 1;
				
				if (++total == _numDirectionalLights) {
					// break loop
					caster = numLightTypes;
					break;
				}
			}
			caster++;
		}
		
		// more directional supported than currently picked, need to clamp all to 0
		if (_numDirectionalLights > total) {
			i = k + (_numDirectionalLights - total)*12;
			while (k < i)
				_fragmentConstantData[k++] = 0;
		}
		
		total = 0;
		
		var pointLights:Vector<PointLight> = _lightPicker.pointLights;
		offset = _pointLightsOffset;
		len = _lightPicker.pointLights.length;
		if (offset > len) {
			caster = 1;
			offset -= len;
		} else
			caster = 0;
		while (caster < numLightTypes) {
			if (caster != 0)
				pointLights = _lightPicker.castingPointLights;
			len = pointLights.length;
			for (i in 0...len) {
				pointLight = pointLights[offset + i];
				dirPos = pointLight.scenePosition;
				
				_ambientLightR += pointLight._ambientR;
				_ambientLightG += pointLight._ambientG;
				_ambientLightB += pointLight._ambientB;
				
				if (_tangentSpace) {
					var x:Float = dirPos.x;
					var y:Float = dirPos.y;
					var z:Float = dirPos.z;
					_vertexConstantData[l++] = _inverseSceneMatrix[0]*x + _inverseSceneMatrix[4]*y + _inverseSceneMatrix[8]*z + _inverseSceneMatrix[12];
					_vertexConstantData[l++] = _inverseSceneMatrix[1]*x + _inverseSceneMatrix[5]*y + _inverseSceneMatrix[9]*z + _inverseSceneMatrix[13];
					_vertexConstantData[l++] = _inverseSceneMatrix[2]*x + _inverseSceneMatrix[6]*y + _inverseSceneMatrix[10]*z + _inverseSceneMatrix[14];
				} else {
					_vertexConstantData[l++] = dirPos.x;
					_vertexConstantData[l++] = dirPos.y;
					_vertexConstantData[l++] = dirPos.z;
				}
				_vertexConstantData[l++] = 1;
				
				_fragmentConstantData[k++] = pointLight._diffuseR;
				_fragmentConstantData[k++] = pointLight._diffuseG;
				_fragmentConstantData[k++] = pointLight._diffuseB;
				var radius:Float = pointLight._radius;
				_fragmentConstantData[k++] = radius*radius;
				
				_fragmentConstantData[k++] = pointLight._specularR;
				_fragmentConstantData[k++] = pointLight._specularG;
				_fragmentConstantData[k++] = pointLight._specularB;
				_fragmentConstantData[k++] = pointLight._fallOffFactor;
				
				if (++total == _numPointLights) {
					// break loop
					caster = numLightTypes;
					break;
				}
			}
			caster++;
		}
		
		// more directional supported than currently picked, need to clamp all to 0
		if (_numPointLights > total) {
			i = k + (total - _numPointLights)*12;
			while (k < i) {
				_fragmentConstantData[k] = 0;
				k++;
			}
		}
	}

	/**
	 * @inheritDoc
	 */
	override private function updateProbes(stage3DProxy:Stage3DProxy):Void
	{
		var context:Context3D = stage3DProxy._context3D;
		var probe:LightProbe;
		var lightProbes:Vector<LightProbe> = _lightPicker.lightProbes;
		var weights:Vector<Float> = _lightPicker.lightProbeWeights;
		var len:Int = lightProbes.length - _lightProbesOffset;
		var addDiff:Bool = usesProbesForDiffuse();
		var addSpec:Bool = (_methodSetup._specularMethod != null) && usesProbesForSpecular();
		
		if (!(addDiff || addSpec))
			return;
		
		if (len > _numLightProbes)
			len = _numLightProbes;
		
		for (i in 0...len) {
			probe = lightProbes[_lightProbesOffset + i];
			
			if (addDiff)
				context.setTextureAt(_lightProbeDiffuseIndices[i], probe.diffuseMap.getTextureForStage3D(stage3DProxy));
			if (addSpec)
				context.setTextureAt(_lightProbeSpecularIndices[i], probe.specularMap.getTextureForStage3D(stage3DProxy));
		}
		
		for (i in 0...len)
			_fragmentConstantData[_probeWeightsIndex + i] = weights[_lightProbesOffset + i];
	}
}