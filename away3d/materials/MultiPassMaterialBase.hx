package away3d.materials;

import away3d.cameras.Camera3D;
import away3d.core.managers.Stage3DProxy;
import away3d.materials.lightpickers.LightPickerBase;
import away3d.materials.lightpickers.StaticLightPicker;
import away3d.materials.methods.BasicAmbientMethod;
import away3d.materials.methods.BasicDiffuseMethod;
import away3d.materials.methods.BasicNormalMethod;
import away3d.materials.methods.BasicSpecularMethod;
import away3d.materials.methods.EffectMethodBase;
import away3d.materials.methods.ShadowMapMethodBase;
import away3d.materials.passes.CompiledPass;
import away3d.materials.passes.LightingPass;
import away3d.materials.passes.ShadowCasterPass;
import away3d.materials.passes.SuperShaderPass;
import away3d.textures.Texture2DBase;

import openfl.display.BlendMode;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DCompareMode;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.Vector;

/**
 * MultiPassMaterialBase forms an abstract base class for the default multi-pass materials provided by Away3D,
 * using material methods to define their appearance.
 */
class MultiPassMaterialBase extends MaterialBase
{
	public var enableLightFallOff(get, set):Bool;
	public var alphaThreshold(get, set):Float;
	public var specularLightSources(get, set):Int;
	public var diffuseLightSources(get, set):Int;
	public var ambientMethod(get, set):BasicAmbientMethod;
	public var shadowMethod(get, set):ShadowMapMethodBase;
	public var diffuseMethod(get, set):BasicDiffuseMethod;
	public var specularMethod(get, set):BasicSpecularMethod;
	public var normalMethod(get, set):BasicNormalMethod;
	public var numMethods(get, never):Int;
	public var normalMap(get, set):Texture2DBase;
	public var specularMap(get, set):Texture2DBase;
	public var gloss(get, set):Float;
	public var ambient(get, set):Float;
	public var specular(get, set):Float;
	public var ambientColor(get, set):Int;
	public var specularColor(get, set):Int;
	public var numLights(get, never):Int;
	public var numNonCasters(get, never):Int;
	
	private var _casterLightPass:ShadowCasterPass;
	private var _nonCasterLightPasses:Vector<LightingPass>;
	private var _effectsPass:SuperShaderPass;
	
	private var _alphaThreshold:Float = 0;
	private var _specularLightSources:Int = 0x01;
	private var _diffuseLightSources:Int = 0x03;
	
	private var _ambientMethod:BasicAmbientMethod = new BasicAmbientMethod();
	private var _shadowMethod:ShadowMapMethodBase;
	private var _diffuseMethod:BasicDiffuseMethod = new BasicDiffuseMethod();
	private var _normalMethod:BasicNormalMethod = new BasicNormalMethod();
	private var _specularMethod:BasicSpecularMethod = new BasicSpecularMethod();
	
	private var _screenPassesInvalid:Bool = true;
	private var _enableLightFallOff:Bool = true;
	
	/**
	 * Creates a new MultiPassMaterialBase object.
	 */
	public function new()
	{
		super();
	}
	
	/**
	 * Whether or not to use fallOff and radius properties for lights. This can be used to improve performance and
	 * compatibility for constrained mode.
	 */
	private function get_enableLightFallOff():Bool
	{
		return _enableLightFallOff;
	}
	
	private function set_enableLightFallOff(value:Bool):Bool
	{
		if (_enableLightFallOff != value)
			invalidateScreenPasses();
		_enableLightFallOff = value;
		return value;
	}
	
	/**
	 * The minimum alpha value for which pixels should be drawn. This is used for transparency that is either
	 * invisible or entirely opaque, often used with textures for foliage, etc.
	 * Recommended values are 0 to disable alpha, or 0.5 to create smooth edges. Default value is 0 (disabled).
	 */
	private function get_alphaThreshold():Float
	{
		return _alphaThreshold;
	}
	
	private function set_alphaThreshold(value:Float):Float
	{
		_alphaThreshold = value;
		_diffuseMethod.alphaThreshold = value;
		_depthPass.alphaThreshold = value;
		_distancePass.alphaThreshold = value;
		return value;
	}

	/**
	 * @inheritDoc
	 */
	override private function set_depthCompareMode(value:Context3DCompareMode):Context3DCompareMode
	{
		super.depthCompareMode = value;
		invalidateScreenPasses();
		return value;
	}

	/**
	 * @inheritDoc
	 */
	override private function set_blendMode(value:BlendMode):BlendMode
	{
		super.blendMode = value;
		invalidateScreenPasses();
		return value;
	}

	/**
	 * @inheritDoc
	 */
	override private function activateForDepth(stage3DProxy:Stage3DProxy, camera:Camera3D, distanceBased:Bool = false):Void
	{
		if (distanceBased)
			_distancePass.alphaMask = _diffuseMethod.texture;
		else
			_depthPass.alphaMask = _diffuseMethod.texture;
		
		super.activateForDepth(stage3DProxy, camera, distanceBased);
	}

	/**
	 * Define which light source types to use for specular reflections. This allows choosing between regular lights
	 * and/or light probes for specular reflections.
	 *
	 * @see away3d.materials.LightSources
	 */
	private function get_specularLightSources():Int
	{
		return _specularLightSources;
	}
	
	private function set_specularLightSources(value:Int):Int
	{
		_specularLightSources = value;
		return value;
	}

	/**
	 * Define which light source types to use for diffuse reflections. This allows choosing between regular lights
	 * and/or light probes for diffuse reflections.
	 *
	 * @see away3d.materials.LightSources
	 */
	private function get_diffuseLightSources():Int
	{
		return _diffuseLightSources;
	}
	
	private function set_diffuseLightSources(value:Int):Int
	{
		_diffuseLightSources = value;
		return value;
	}

	/**
	 * @inheritDoc
	 */
	override private function set_lightPicker(value:LightPickerBase):LightPickerBase
	{
		if (_lightPicker != null)
			_lightPicker.removeEventListener(Event.CHANGE, onLightsChange);
		super.lightPicker = value;
		if (_lightPicker != null)
			_lightPicker.addEventListener(Event.CHANGE, onLightsChange);
		invalidateScreenPasses();
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function get_requiresBlending():Bool
	{
		return false;
	}
	
	/**
	 * The method that provides the ambient lighting contribution. Defaults to BasicAmbientMethod.
	 */
	private function get_ambientMethod():BasicAmbientMethod
	{
		return _ambientMethod;
	}
	
	private function set_ambientMethod(value:BasicAmbientMethod):BasicAmbientMethod
	{
		value.copyFrom(_ambientMethod);
		_ambientMethod = value;
		invalidateScreenPasses();
		return value;
	}
	
	/**
	 * The method used to render shadows cast on this surface, or null if no shadows are to be rendered. Defaults to null.
	 */
	private function get_shadowMethod():ShadowMapMethodBase
	{
		return _shadowMethod;
	}
	
	private function set_shadowMethod(value:ShadowMapMethodBase):ShadowMapMethodBase
	{
		if (value != null && _shadowMethod != null)
			value.copyFrom(_shadowMethod);
		_shadowMethod = value;
		invalidateScreenPasses();
		return value;
	}
	
	/**
	 * The method that provides the diffuse lighting contribution. Defaults to BasicDiffuseMethod.
	 */
	private function get_diffuseMethod():BasicDiffuseMethod
	{
		return _diffuseMethod;
	}
	
	private function set_diffuseMethod(value:BasicDiffuseMethod):BasicDiffuseMethod
	{
		value.copyFrom(_diffuseMethod);
		_diffuseMethod = value;
		invalidateScreenPasses();
		return value;
	}

	/**
	 * The method that provides the specular lighting contribution. Defaults to BasicSpecularMethod.
	 */
	private function get_specularMethod():BasicSpecularMethod
	{
		return _specularMethod;
	}

	private function set_specularMethod(value:BasicSpecularMethod):BasicSpecularMethod
	{
		if (value != null && _specularMethod != null) 
			value.copyFrom(_specularMethod);
		_specularMethod = value;
		invalidateScreenPasses();
		return value;
	}
	
	/**
	 * The method used to generate the per-pixel normals. Defaults to BasicNormalMethod.
	 */
	private function get_normalMethod():BasicNormalMethod
	{
		return _normalMethod;
	}
	
	private function set_normalMethod(value:BasicNormalMethod):BasicNormalMethod
	{
		value.copyFrom(_normalMethod);
		_normalMethod = value;
		invalidateScreenPasses();
		return value;
	}
	
	/**
	 * Appends an "effect" shading method to the shader. Effect methods are those that do not influence the lighting
	 * but modulate the shaded colour, used for fog, outlines, etc. The method will be applied to the result of the
	 * methods added prior.
	 */
	public function addMethod(method:EffectMethodBase):Void
	{
		if (_effectsPass == null)
			_effectsPass = new SuperShaderPass(this);
		_effectsPass.addMethod(method);
		invalidateScreenPasses();
	}

	/**
	 * The number of "effect" methods added to the material.
	 */
	private function get_numMethods():Int
	{
		return (_effectsPass != null)? _effectsPass.numMethods : 0;
	}

	/**
	 * Queries whether a given effect method was added to the material.
	 *
	 * @param method The method to be queried.
	 * @return true if the method was added to the material, false otherwise.
	 */
	public function hasMethod(method:EffectMethodBase):Bool
	{
		return (_effectsPass != null)? _effectsPass.hasMethod(method) : false;
	}

	/**
	 * Returns the method added at the given index.
	 * @param index The index of the method to retrieve.
	 * @return The method at the given index.
	 */
	public function getMethodAt(index:Int):EffectMethodBase
	{
		return _effectsPass.getMethodAt(index);
	}
	
	/**
	 * Adds an effect method at the specified index amongst the methods already added to the material. Effect
	 * methods are those that do not influence the lighting but modulate the shaded colour, used for fog, outlines,
	 * etc. The method will be applied to the result of the methods with a lower index.
	 */
	public function addMethodAt(method:EffectMethodBase, index:Int):Void
	{
		if (_effectsPass == null)
			_effectsPass = new SuperShaderPass(this);
		_effectsPass.addMethodAt(method, index);
		invalidateScreenPasses();
	}

	/**
	 * Removes an effect method from the material.
	 * @param method The method to be removed.
	 */
	public function removeMethod(method:EffectMethodBase):Void
	{
		if (_effectsPass == null)
			return;
		_effectsPass.removeMethod(method);
		
		// reconsider
		if (_effectsPass.numMethods == 0)
			invalidateScreenPasses();
	}
	
	/**
	 * @inheritDoc
	 */
	override private function set_mipmap(value:Bool):Bool
	{
		if (_mipmap == value)
			return value;
		super.mipmap = value;
		return value;
	}
	
	/**
	 * The normal map to modulate the direction of the surface for each texel. The default normal method expects
	 * tangent-space normal maps, but others could expect object-space maps.
	 */
	private function get_normalMap():Texture2DBase
	{
		return _normalMethod.normalMap;
	}
	
	private function set_normalMap(value:Texture2DBase):Texture2DBase
	{
		_normalMethod.normalMap = value;
		return value;
	}
	
	/**
	 * A specular map that defines the strength of specular reflections for each texel in the red channel,
	 * and the gloss factor in the green channel. You can use SpecularBitmapTexture if you want to easily set
	 * specular and gloss maps from grayscale images, but correctly authored images are preferred.
	 */
	private function get_specularMap():Texture2DBase
	{
		return _specularMethod.texture;
	}
	
	private function set_specularMap(value:Texture2DBase):Texture2DBase
	{
		if (_specularMethod != null)
			_specularMethod.texture = value;
		else
			throw new Error("No specular method was set to assign the specularGlossMap to");
		return value;
	}
	
	/**
	 * The glossiness of the material (sharpness of the specular highlight).
	 */
	private function get_gloss():Float
	{
		return (_specularMethod != null)? _specularMethod.gloss : 0;
	}
	
	private function set_gloss(value:Float):Float
	{
		if (_specularMethod != null)
			_specularMethod.gloss = value;
		return value;
	}
	
	/**
	 * The strength of the ambient reflection.
	 */
	private function get_ambient():Float
	{
		return _ambientMethod.ambient;
	}
	
	private function set_ambient(value:Float):Float
	{
		_ambientMethod.ambient = value;
		return value;
	}
	
	/**
	 * The overall strength of the specular reflection.
	 */
	private function get_specular():Float
	{
		return (_specularMethod != null)? _specularMethod.specular : 0;
	}
	
	private function set_specular(value:Float):Float
	{
		if (_specularMethod != null)
			_specularMethod.specular = value;
		return value;
	}
	
	/**
	 * The colour of the ambient reflection.
	 */
	private function get_ambientColor():Int
	{
		return _ambientMethod.ambientColor;
	}
	
	private function set_ambientColor(value:Int):Int
	{
		_ambientMethod.ambientColor = value;
		return value;
	}
	
	/**
	 * The colour of the specular reflection.
	 */
	private function get_specularColor():Int
	{
		return _specularMethod.specularColor;
	}
	
	private function set_specularColor(value:Int):Int
	{
		_specularMethod.specularColor = value;
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function updateMaterial(context:Context3D):Void
	{
		var passesInvalid:Bool = false;
		
		if (_screenPassesInvalid) {
			updateScreenPasses();
			passesInvalid = true;
		}
		
		if (passesInvalid || isAnyScreenPassInvalid()) {
			clearPasses();
			
			addChildPassesFor(_casterLightPass);
			if (_nonCasterLightPasses != null) {
				for (i in 0..._nonCasterLightPasses.length)
					addChildPassesFor(_nonCasterLightPasses[i]);
			}
			addChildPassesFor(_effectsPass);
			
			addScreenPass(_casterLightPass);
			if (_nonCasterLightPasses != null) {
				for (i in 0..._nonCasterLightPasses.length)
					addScreenPass(_nonCasterLightPasses[i]);
			}
			addScreenPass(_effectsPass);
		}
	}

	/**
	 * Adds a compiled pass that renders to the screen.
	 * @param pass The pass to be added.
	 */
	private function addScreenPass(pass:CompiledPass):Void
	{
		if (pass != null) {
			addPass(pass);
			pass._passesDirty = false;
		}
	}

	/**
	 * Tests if any pass that renders to the screen is invalid. This would trigger a new setup of the multiple passes.
	 * @return
	 */
	private function isAnyScreenPassInvalid():Bool
	{
		if ((_casterLightPass != null && _casterLightPass._passesDirty) || (_effectsPass != null && _effectsPass._passesDirty)) {
			return true;
		}
		
		if (_nonCasterLightPasses != null) {
			for (i in 0..._nonCasterLightPasses.length) {
				if (_nonCasterLightPasses[i]._passesDirty)
					return true;
			}
		}
		
		return false;
	}

	/**
	 * Adds any additional passes on which the given pass is dependent.
	 * @param pass The pass that my need additional passes.
	 */
	private function addChildPassesFor(pass:CompiledPass):Void
	{
		if (pass == null)
			return;
		
		if (pass._passes != null) {
			var len:Int = pass._passes.length;
			for (i in 0...len)
				addPass(pass._passes[i]);
		}
	}

	/**
	 * @inheritDoc
	 */
	override private function activatePass(index:Int, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		if (index == 0)
			stage3DProxy._context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		super.activatePass(index, stage3DProxy, camera);
	}

	/**
	 * @inheritDoc
	 */
	override private function deactivate(stage3DProxy:Stage3DProxy):Void
	{
		super.deactivate(stage3DProxy);
		stage3DProxy._context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
	}

	/**
	 * Updates screen passes when they were found to be invalid.
	 */
	private function updateScreenPasses():Void
	{
		initPasses();
		setBlendAndCompareModes();
		
		_screenPassesInvalid = false;
	}

	/**
	 * Initializes all the passes and their dependent passes.
	 */
	private function initPasses():Void
	{
		// let the effects pass handle everything if there are no lights,
		// or when there are effect methods applied after shading.
		if (numLights == 0 || numMethods > 0)
			initEffectsPass();
		else if (_effectsPass != null && numMethods == 0)
			removeEffectsPass();

		// only use a caster light pass if shadows need to be rendered
		if (_shadowMethod != null)
			initCasterLightPass();
		else
			removeCasterLightPass();

		// only use non caster light passes if there are lights that don't cast
		if (numNonCasters > 0)
			initNonCasterLightPasses();
		else
			removeNonCasterLightPasses();
	}

	/**
	 * Sets up the various blending modes for all screen passes, based on whether or not there are previous passes.
	 */
	private function setBlendAndCompareModes():Void
	{
		var forceSeparateMVP:Bool = ((_casterLightPass != null || _effectsPass != null));

		// caster light pass is always first if it exists, hence it uses normal blending
		if (_casterLightPass != null) {
			_casterLightPass.setBlendMode(BlendMode.NORMAL);
			_casterLightPass.depthCompareMode = depthCompareMode;
			_casterLightPass.forceSeparateMVP = forceSeparateMVP;
		}

		if (_nonCasterLightPasses != null) {
			var firstAdditiveIndex:Int = 0;

			// if there's no caster light pass, the first non caster light pass will be the first
			// and should use normal blending
			if (_casterLightPass == null) {
				_nonCasterLightPasses[0].forceSeparateMVP = forceSeparateMVP;
				_nonCasterLightPasses[0].setBlendMode(BlendMode.NORMAL);
				_nonCasterLightPasses[0].depthCompareMode = depthCompareMode;
				firstAdditiveIndex = 1;
			}

			// all lighting passes following the first light pass should use additive blending
			for (i in 0..._nonCasterLightPasses.length) {
				_nonCasterLightPasses[i].forceSeparateMVP = forceSeparateMVP;
				_nonCasterLightPasses[i].setBlendMode(BlendMode.ADD);
				_nonCasterLightPasses[i].depthCompareMode = Context3DCompareMode.LESS_EQUAL;
			}
		}

		if (_casterLightPass != null || _nonCasterLightPasses != null) {
			// there are light passes, so this should be blended in
			if (_effectsPass != null) {
				_effectsPass.ignoreLights = true;
				_effectsPass.depthCompareMode = Context3DCompareMode.LESS_EQUAL;
				_effectsPass.setBlendMode(BlendMode.SCREEN);
				_effectsPass.forceSeparateMVP = forceSeparateMVP;
			}
		} else if (_effectsPass != null) {
			// effects pass is the only pass, so it should just blend normally
			_effectsPass.ignoreLights = false;
			_effectsPass.depthCompareMode = depthCompareMode;
			_effectsPass.setBlendMode(BlendMode.NORMAL);
			_effectsPass.forceSeparateMVP = false;
		}
	}

	private function initCasterLightPass():Void
	{
		if (_casterLightPass == null)
			_casterLightPass = new ShadowCasterPass(this);
		_casterLightPass.diffuseMethod = null;
		_casterLightPass.ambientMethod = null;
		_casterLightPass.normalMethod = null;
		_casterLightPass.specularMethod = null;
		_casterLightPass.shadowMethod = null;
		_casterLightPass.enableLightFallOff = _enableLightFallOff;
		_casterLightPass.lightPicker = new StaticLightPicker([_shadowMethod.castingLight]);
		_casterLightPass.shadowMethod = _shadowMethod;
		_casterLightPass.diffuseMethod = _diffuseMethod;
		_casterLightPass.ambientMethod = _ambientMethod;
		_casterLightPass.normalMethod = _normalMethod;
		_casterLightPass.specularMethod = _specularMethod;
		_casterLightPass.diffuseLightSources = _diffuseLightSources;
		_casterLightPass.specularLightSources = _specularLightSources;
	}
	
	private function removeCasterLightPass():Void
	{
		if (_casterLightPass == null)
			return;
		_casterLightPass.dispose();
		removePass(_casterLightPass);
		_casterLightPass = null;
	}
	
	private function initNonCasterLightPasses():Void
	{
		removeNonCasterLightPasses();
		var pass:LightingPass;
		var numDirLights:Int = _lightPicker.numDirectionalLights;
		var numPointLights:Int = _lightPicker.numPointLights;
		var numLightProbes:Int = _lightPicker.numLightProbes;
		var dirLightOffset:Int = 0;
		var pointLightOffset:Int = 0;
		var probeOffset:Int = 0;
		
		if (_casterLightPass == null) {
			numDirLights += _lightPicker.numCastingDirectionalLights;
			numPointLights += _lightPicker.numCastingPointLights;
		}
		
		_nonCasterLightPasses = new Vector<LightingPass>();
		while (dirLightOffset < numDirLights || pointLightOffset < numPointLights || probeOffset < numLightProbes) {
			pass = new LightingPass(this);
			pass.enableLightFallOff = _enableLightFallOff;
			pass.includeCasters = _shadowMethod == null;
			pass.directionalLightsOffset = dirLightOffset;
			pass.pointLightsOffset = pointLightOffset;
			pass.lightProbesOffset = probeOffset;
			pass.diffuseMethod = null;
			pass.ambientMethod = null;
			pass.normalMethod = null;
			pass.specularMethod = null;
			pass.lightPicker = _lightPicker;
			pass.diffuseMethod = _diffuseMethod;
			pass.ambientMethod = _ambientMethod;
			pass.normalMethod = _normalMethod;
			pass.specularMethod = _specularMethod;
			pass.diffuseLightSources = _diffuseLightSources;
			pass.specularLightSources = _specularLightSources;
			_nonCasterLightPasses.push(pass);
			
			dirLightOffset += pass.numDirectionalLights;
			pointLightOffset += pass.numPointLights;
			probeOffset += pass.numLightProbes;
		}
	}
	
	private function removeNonCasterLightPasses():Void
	{
		if (_nonCasterLightPasses == null)
			return;
		for (i in 0..._nonCasterLightPasses.length) {
			removePass(_nonCasterLightPasses[i]);
			_nonCasterLightPasses[i].dispose();
		}
		_nonCasterLightPasses = null;
	}
	
	private function removeEffectsPass():Void
	{
		if (_effectsPass.diffuseMethod != _diffuseMethod)
			_effectsPass.diffuseMethod.dispose();
		removePass(_effectsPass);
		_effectsPass.dispose();
		_effectsPass = null;
	}
	
	private function initEffectsPass():SuperShaderPass
	{
		if (_effectsPass == null)
			_effectsPass = new SuperShaderPass(this);
		_effectsPass.enableLightFallOff = _enableLightFallOff;
		if (numLights == 0) {
			_effectsPass.diffuseMethod = null;
			_effectsPass.diffuseMethod = _diffuseMethod;
		} else {
			_effectsPass.diffuseMethod = null;
			_effectsPass.diffuseMethod = new BasicDiffuseMethod();
			_effectsPass.diffuseMethod.diffuseColor = 0x000000;
			_effectsPass.diffuseMethod.diffuseAlpha = 0;
		}
		_effectsPass.preserveAlpha = false;
		_effectsPass.normalMethod = null;
		_effectsPass.normalMethod = _normalMethod;
		
		return _effectsPass;
	}

	/**
	 * The maximum total number of lights provided by the light picker.
	 */
	private function get_numLights():Int
	{
		return (_lightPicker != null)? _lightPicker.numLightProbes + _lightPicker.numDirectionalLights + _lightPicker.numPointLights +
			_lightPicker.numCastingDirectionalLights + _lightPicker.numCastingPointLights : 0;
	}

	/**
	 * The amount of lights that don't cast shadows.
	 */
	private function get_numNonCasters():Int
	{
		return (_lightPicker != null)? _lightPicker.numLightProbes + _lightPicker.numDirectionalLights + _lightPicker.numPointLights : 0;
	}

	/**
	 * Flags that the screen passes have become invalid.
	 */
	private function invalidateScreenPasses():Void
	{
		_screenPassesInvalid = true;
	}

	/**
	 * Called when the light picker's configuration changed.
	 */
	private function onLightsChange(event:Event):Void
	{
		invalidateScreenPasses();
	}
}