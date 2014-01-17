/**
 * SuperShaderPass is a shader pass that uses shader methods to compile a complete program. It includes all methods
 * associated with a material.
 *
 * @see away3d.materials.methods.ShadingMethodBase
 */
package away3d.materials.passes;


import flash.Vector;
import away3d.cameras.Camera3D;
import away3d.core.managers.Stage3DProxy;
import away3d.lights.DirectionalLight;
import away3d.lights.LightProbe;
import away3d.lights.PointLight;
import away3d.materials.LightSources;
import away3d.materials.MaterialBase;
import away3d.materials.compilation.ShaderCompiler;
import away3d.materials.compilation.SuperShaderCompiler;
import away3d.materials.methods.ColorTransformMethod;
import away3d.materials.methods.EffectMethodBase;
import away3d.materials.methods.MethodVOSet;
import flash.display3D.Context3D;
import flash.geom.ColorTransform;
import flash.geom.Vector3D;

class SuperShaderPass extends CompiledPass {
    public var includeCasters(get_includeCasters, set_includeCasters):Bool;
    public var colorTransform(get_colorTransform, set_colorTransform):ColorTransform;
    public var colorTransformMethod(get_colorTransformMethod, set_colorTransformMethod):ColorTransformMethod;
    public var numMethods(get_numMethods, never):Int;
    public var ignoreLights(get_ignoreLights, set_ignoreLights):Bool;

    private var _includeCasters:Bool;
    private var _ignoreLights:Bool;
/**
	 * Creates a new SuperShaderPass objects.
	 *
	 * @param material The material to which this material belongs.
	 */

    public function new(material:MaterialBase) {
        _includeCasters = true;
        super(material);
        _needFragmentAnimation = true;
    }

/**
	 * @inheritDoc
	 */

    override private function createCompiler(profile:String):ShaderCompiler {
        return new SuperShaderCompiler(profile);
    }

/**
	 * Indicates whether lights that cast shadows should be included in the pass.
	 */

    public function get_includeCasters():Bool {
        return _includeCasters;
    }

    public function set_includeCasters(value:Bool):Bool {
        if (_includeCasters == value) return value;
        _includeCasters = value;
        invalidateShaderProgram();
        return value;
    }

/**
	 * The ColorTransform object to transform the colour of the material with. Defaults to null.
	 */

    public function get_colorTransform():ColorTransform {
        return (_methodSetup.colorTransformMethod != null) ? _methodSetup._colorTransformMethod.colorTransform : null;
    }

    public function set_colorTransform(value:ColorTransform):ColorTransform {
        if (value != null) {
            if (colorTransformMethod == null)
                colorTransformMethod = new ColorTransformMethod();
            _methodSetup._colorTransformMethod.colorTransform = value;
        }

        else if (value == null) {
            if (_methodSetup._colorTransformMethod != null) colorTransformMethod = null;
            colorTransformMethod = _methodSetup._colorTransformMethod = null;
        }
        return value;
    }

/**
	 * The ColorTransformMethod object to transform the colour of the material with. Defaults to null.
	 */

    public function get_colorTransformMethod():ColorTransformMethod {
        return _methodSetup.colorTransformMethod;
    }

    public function set_colorTransformMethod(value:ColorTransformMethod):ColorTransformMethod {
        _methodSetup.colorTransformMethod = value;
        return value;
    }

/**
	 * Appends an "effect" shading method to the shader. Effect methods are those that do not influence the lighting
	 * but modulate the shaded colour, used for fog, outlines, etc. The method will be applied to the result of the
	 * methods added prior.
	 */

    public function addMethod(method:EffectMethodBase):Void {
        _methodSetup.addMethod(method);
    }

/**
	 * The number of "effect" methods added to the material.
	 */

    public function get_numMethods():Int {
        return _methodSetup.numMethods;
    }

/**
	 * Queries whether a given effect method was added to the material.
	 *
	 * @param method The method to be queried.
	 * @return true if the method was added to the material, false otherwise.
	 */

    public function hasMethod(method:EffectMethodBase):Bool {
        return _methodSetup.hasMethod(method);
    }

/**
	 * Returns the method added at the given index.
	 * @param index The index of the method to retrieve.
	 * @return The method at the given index.
	 */

    public function getMethodAt(index:Int):EffectMethodBase {
        return _methodSetup.getMethodAt(index);
    }

/**
	 * Adds an effect method at the specified index amongst the methods already added to the material. Effect
	 * methods are those that do not influence the lighting but modulate the shaded colour, used for fog, outlines,
	 * etc. The method will be applied to the result of the methods with a lower index.
	 */

    public function addMethodAt(method:EffectMethodBase, index:Int):Void {
        _methodSetup.addMethodAt(method, index);
    }

/**
	 * Removes an effect method from the material.
	 * @param method The method to be removed.
	 */

    public function removeMethod(method:EffectMethodBase):Void {
        _methodSetup.removeMethod(method);
    }

/**
	 * @inheritDoc
	 */

    override private function updateLights():Void {
//			super.updateLights();
        if (_lightPicker != null && !_ignoreLights) {
            _numPointLights = _lightPicker.numPointLights;
            _numDirectionalLights = _lightPicker.numDirectionalLights;
            _numLightProbes = _lightPicker.numLightProbes;
            if (_includeCasters) {
                _numPointLights += _lightPicker.numCastingPointLights;
                _numDirectionalLights += _lightPicker.numCastingDirectionalLights;
            }
        }

        else {
            _numPointLights = 0;
            _numDirectionalLights = 0;
            _numLightProbes = 0;
        }

        invalidateShaderProgram();
    }

/**
	 * @inheritDoc
	 */

    override public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):Void {
        super.activate(stage3DProxy, camera);
        if (_methodSetup._colorTransformMethod != null) _methodSetup._colorTransformMethod.activate(_methodSetup._colorTransformMethodVO, stage3DProxy);
        var methods:Array<MethodVOSet> = _methodSetup._methods;
        var len:Int = methods.length;
        var i:Int = 0;
        while (i < len) {
            var set:MethodVOSet = methods[i];
            set.method.activate(set.data, stage3DProxy);
            ++i;
        }
        if (_cameraPositionIndex >= 0) {
            var pos:Vector3D = camera.scenePosition;
            _vertexConstantData[_cameraPositionIndex] = pos.x;
            _vertexConstantData[_cameraPositionIndex + 1] = pos.y;
            _vertexConstantData[_cameraPositionIndex + 2] = pos.z;
        }
    }

/**
	 * @inheritDoc
	 */

    override public function deactivate(stage3DProxy:Stage3DProxy):Void {
        super.deactivate(stage3DProxy);
        if (_methodSetup._colorTransformMethod != null) _methodSetup._colorTransformMethod.deactivate(_methodSetup._colorTransformMethodVO, stage3DProxy);
        var set:MethodVOSet;
        var methods:Array<MethodVOSet> = _methodSetup._methods;
        var len:Int = methods.length;
        var i:Int = 0;
        while (i < len) {
            set = methods[i];
            set.method.deactivate(set.data, stage3DProxy);
            ++i;
        }
    }

/**
	 * @inheritDoc
	 */

    override private function addPassesFromMethods():Void {
        super.addPassesFromMethods();
        if (_methodSetup._colorTransformMethod != null) addPasses(_methodSetup._colorTransformMethod.passes);
        var methods:Array<MethodVOSet> = _methodSetup._methods;
        var i:Int = 0;
        while (i < methods.length) {
            addPasses(methods[i].method.passes);
            ++i;
        }
    }

/**
	 * Indicates whether any light probes are used to contribute to the specular shading.
	 */

    private function usesProbesForSpecular():Bool {
        return _numLightProbes > 0 && (_specularLightSources & LightSources.PROBES) != 0;
    }

/**
	 * Indicates whether any light probes are used to contribute to the diffuse shading.
	 */

    private function usesProbesForDiffuse():Bool {
        return _numLightProbes > 0 && (_diffuseLightSources & LightSources.PROBES) != 0;
    }

/**
	 * @inheritDoc
	 */

    override private function updateMethodConstants():Void {
        super.updateMethodConstants();
        if (_methodSetup._colorTransformMethod != null) _methodSetup._colorTransformMethod.initConstants(_methodSetup._colorTransformMethodVO);
        var methods:Array<MethodVOSet> = _methodSetup._methods;
        var len:Int = methods.length;
        var i:Int = 0;
        while (i < len) {
            methods[i].method.initConstants(methods[i].data);
            ++i;
        }
    }

/**
	 * @inheritDoc
	 */

    override private function updateLightConstants():Void {
// first dirs, then points
        var dirLight:DirectionalLight;
        var pointLight:PointLight;
        var i:Int = 0;
        var k:Int = 0;
        var len:Int;
        var dirPos:Vector3D;
        var total:Int = 0;
        var numLightTypes:Int = (_includeCasters) ? 2 : 1;
        k = _lightFragmentConstantIndex;
        var __cast:Int = 0;
        while (__cast < numLightTypes) {
            var dirLights:Vector<DirectionalLight> = (__cast > 0) ? _lightPicker.castingDirectionalLights : _lightPicker.directionalLights;
            len = dirLights.length;
            total += len;
            i = 0;
            while (i < len) {
                dirLight = dirLights[i];
                dirPos = dirLight.sceneDirection;
                _ambientLightR += dirLight._ambientR;
                _ambientLightG += dirLight._ambientG;
                _ambientLightB += dirLight._ambientB;
                _fragmentConstantData[k++] = -dirPos.x;
                _fragmentConstantData[k++] = -dirPos.y;
                _fragmentConstantData[k++] = -dirPos.z;
                _fragmentConstantData[k++] = 1;
                _fragmentConstantData[k++] = dirLight._diffuseR;
                _fragmentConstantData[k++] = dirLight._diffuseG;
                _fragmentConstantData[k++] = dirLight._diffuseB;
                _fragmentConstantData[k++] = 1;
                _fragmentConstantData[k++] = dirLight._specularR;
                _fragmentConstantData[k++] = dirLight._specularG;
                _fragmentConstantData[k++] = dirLight._specularB;
                _fragmentConstantData[k++] = 1;
                ++i;
            }
            ++__cast;
        }
// more directional supported than currently picked, need to clamp all to 0
        if (_numDirectionalLights > total) {
            i = k + (_numDirectionalLights - total) * 12;
            while (k < i)_fragmentConstantData[k++] = 0;
        }
        total = 0;
        __cast = 0;
        while (__cast < numLightTypes) {
            var pointLights:Vector<PointLight> = (__cast > 0) ? _lightPicker.castingPointLights : _lightPicker.pointLights;
            len = pointLights.length;
            i = 0;
            while (i < len) {
                pointLight = pointLights[i];
                dirPos = pointLight.scenePosition;
                _ambientLightR += pointLight._ambientR;
                _ambientLightG += pointLight._ambientG;
                _ambientLightB += pointLight._ambientB;
                _fragmentConstantData[k++] = dirPos.x;
                _fragmentConstantData[k++] = dirPos.y;
                _fragmentConstantData[k++] = dirPos.z;
                _fragmentConstantData[k++] = 1;
                _fragmentConstantData[k++] = pointLight._diffuseR;
                _fragmentConstantData[k++] = pointLight._diffuseG;
                _fragmentConstantData[k++] = pointLight._diffuseB;
                _fragmentConstantData[k++] = pointLight._radius * pointLight._radius;
                _fragmentConstantData[k++] = pointLight._specularR;
                _fragmentConstantData[k++] = pointLight._specularG;
                _fragmentConstantData[k++] = pointLight._specularB;
                _fragmentConstantData[k++] = pointLight._fallOffFactor;
                ++i;
            }
            ++__cast;
        }
// more directional supported than currently picked, need to clamp all to 0
        if (_numPointLights > total) {
            i = k + (total - _numPointLights) * 12;
            while (k < i) {
                _fragmentConstantData[k] = 0;
                ++k;
            }
        }
    }

/**
	 * @inheritDoc
	 */

    override private function updateProbes(stage3DProxy:Stage3DProxy):Void {
        var probe:LightProbe;
        var lightProbes:Vector<LightProbe> = _lightPicker.lightProbes;
        var weights:Vector<Float> = _lightPicker.lightProbeWeights;
        var len:Int = lightProbes.length;
        var addDiff:Bool = usesProbesForDiffuse();
        var addSpec:Bool = cast((_methodSetup._specularMethod != null && usesProbesForSpecular()), Bool);
        var context:Context3D = stage3DProxy._context3D;
        if (!(addDiff || addSpec)) return;
        var i:Int = 0;
        while (i < len) {
            probe = lightProbes[i];
            if (addDiff) context.setTextureAt(_lightProbeDiffuseIndices[i], probe.diffuseMap.getTextureForStage3D(stage3DProxy));
            if (addSpec) context.setTextureAt(_lightProbeSpecularIndices[i], probe.specularMap.getTextureForStage3D(stage3DProxy));
            ++i;
        }
        _fragmentConstantData[_probeWeightsIndex] = weights[0];
        _fragmentConstantData[_probeWeightsIndex + 1] = weights[1];
        _fragmentConstantData[_probeWeightsIndex + 2] = weights[2];
        _fragmentConstantData[_probeWeightsIndex + 3] = weights[3];
    }

/**
	 * Indicates whether lights should be ignored in this pass. This is used when only effect methods are rendered in
	 * a multipass material.
	 */

    private function set_ignoreLights(ignoreLights:Bool):Bool {
        _ignoreLights = ignoreLights;
        return ignoreLights;
    }

    private function get_ignoreLights():Bool {
        return _ignoreLights;
    }

}

