package away3d.materials.passes;

import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.lights.DirectionalLight;
import away3d.lights.PointLight;
import away3d.materials.MaterialBase;
import away3d.materials.compilation.LightingShaderCompiler;
import away3d.materials.compilation.ShaderCompiler;

import openfl.errors.Error;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * ShadowCasterPass is a shader pass that uses shader methods to compile a complete program. It only draws the lighting
 * contribution for a single shadow-casting light.
 *
 * @see away3d.materials.methods.ShadingMethodBase
 */
class ShadowCasterPass extends CompiledPass
{
	private var _tangentSpace:Bool;
	private var _lightVertexConstantIndex:Int;
	private var _inverseSceneMatrix:Vector<Float> = new Vector<Float>();
	
	/**
	 * Creates a new ShadowCasterPass objects.
	 *
	 * @param material The material to which this pass belongs.
	 */
	public function new(material:MaterialBase)
	{
		super(material);
	}

	/**
	 * @inheritDoc
	 */
	override private function createCompiler(profile:String):ShaderCompiler
	{
		return new LightingShaderCompiler(profile);
	}

	/**
	 * @inheritDoc
	 */
	override private function updateLights():Void
	{
		super.updateLights();
		
		var numPointLights:Int;
		var numDirectionalLights:Int;
		
		if (_lightPicker != null) {
			numPointLights = _lightPicker.numCastingPointLights > 0? 1 : 0;
			numDirectionalLights = _lightPicker.numCastingDirectionalLights > 0? 1 : 0;
		} else {
			numPointLights = 0;
			numDirectionalLights = 0;
		}
		
		_numLightProbes = 0;
		
		if (numPointLights + numDirectionalLights > 1)
			throw new Error("Must have exactly one light!");
		
		if (numPointLights != _numPointLights || numDirectionalLights != _numDirectionalLights) {
			_numPointLights = numPointLights;
			_numDirectionalLights = numDirectionalLights;
			invalidateShaderProgram();
		}
	}

	/**
	 * @inheritDoc
	 */
	override private function updateShaderProperties():Void {
		super.updateShaderProperties();
		_tangentSpace = cast(_compiler, LightingShaderCompiler).tangentSpace;
	}

	/**
	 * @inheritDoc
	 */
	override private function updateRegisterIndices():Void {
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
	 * @inheritDoc
	 */
	override private function updateLightConstants():Void
	{
		// first dirs, then points
		var dirLight:DirectionalLight;
		var pointLight:PointLight;
		var k:Int = 0, l:Int;
		var dirPos:Vector3D;
		
		var x:Float;
		var y:Float;
		var z:Float;
		l = _lightVertexConstantIndex;
		k = _lightFragmentConstantIndex;
		
		if (_numDirectionalLights > 0) {
			dirLight = _lightPicker.castingDirectionalLights[0];
			dirPos = dirLight.sceneDirection;
			
			_ambientLightR += dirLight._ambientR;
			_ambientLightG += dirLight._ambientG;
			_ambientLightB += dirLight._ambientB;
			
			if (_tangentSpace) {
				x = -dirPos.x;
				y = -dirPos.y;
				z = -dirPos.z;
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
			return;
		}
		
		if (_numPointLights > 0) {
			pointLight = _lightPicker.castingPointLights[0];
			dirPos = pointLight.scenePosition;
			
			_ambientLightR += pointLight._ambientR;
			_ambientLightG += pointLight._ambientG;
			_ambientLightB += pointLight._ambientB;
			
			if (_tangentSpace) {
				x = dirPos.x;
				y = dirPos.y;
				z = dirPos.z;
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
			_fragmentConstantData[k++] = pointLight._radius*pointLight._radius;
			
			_fragmentConstantData[k++] = pointLight._specularR;
			_fragmentConstantData[k++] = pointLight._specularG;
			_fragmentConstantData[k++] = pointLight._specularB;
			_fragmentConstantData[k++] = pointLight._fallOffFactor;
		}
	}

	/**
	 * @inheritDoc
	 */
	override private function usesProbes():Bool
	{
		return false;
	}

	/**
	 * @inheritDoc
	 */
	override private function usesLights():Bool
	{
		return true;
	}

	/**
	 * @inheritDoc
	 */
	override private function updateProbes(stage3DProxy:Stage3DProxy):Void
	{
	}
}