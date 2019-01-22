package away3d.materials;

import away3d.animators.IAnimationSet;
import away3d.cameras.Camera3D;
import away3d.core.base.IMaterialOwner;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.core.traverse.EntityCollector;
import away3d.library.assets.Asset3DType;
import away3d.library.assets.IAsset;
import away3d.library.assets.NamedAssetBase;
import away3d.materials.lightpickers.LightPickerBase;
import away3d.materials.passes.DepthMapPass;
import away3d.materials.passes.DistanceMapPass;
import away3d.materials.passes.MaterialPassBase;
import away3d.textures.Anisotropy;

import openfl.display.BlendMode;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DCompareMode;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.geom.Matrix3D;
import openfl.Vector;

/**
 * MaterialBase forms an abstract base class for any material.
 * A material consists of several passes, each of which constitutes at least one render call. Several passes could
 * be used for special effects (render lighting for many lights in several passes, render an outline in a separate
 * pass) or to provide additional render-to-texture passes (rendering diffuse light to texture for texture-space
 * subsurface scattering, or rendering a depth map for specialized self-shadowing).
 *
 * Away3D provides default materials trough SinglePassMaterialBase and MultiPassMaterialBase, which use modular
 * methods to build the shader code. MaterialBase can be extended to build specific and high-performant custom
 * shaders, or entire new material frameworks.
 */
class MaterialBase extends NamedAssetBase implements IAsset
{
	public var assetType(get, never):String;
	public var lightPicker(get, set):LightPickerBase;
	public var mipmap(get, set):Bool;
	public var smooth(get, set):Bool;
	public var depthCompareMode(get, set):Context3DCompareMode;
	public var repeat(get, set):Bool;
	public var anisotropy(get, set):Anisotropy;
	public var bothSides(get, set):Bool;
	public var blendMode(get, set):BlendMode;
	public var alphaPremultiplied(get, set):Bool;
	public var requiresBlending(get, never):Bool;
	public var uniqueId(get, never):Int;
	@:allow(away3d) private var numPasses(get, never):Int;
	@:allow(away3d) private var owners(get, never):Vector<IMaterialOwner>;
	
	/**
	 * A counter used to assign unique ids per material, which is used to sort per material while rendering.
	 * This reduces state changes.
	 */
	private static var MATERIAL_ID_COUNT:Int = 0;

	/**
	 * An object to contain any extra data.
	 */
	public var extra:Dynamic;

	/**
	 * A value that can be used by materials that only work with a given type of renderer. The renderer can test the
	 * classification to choose which render path to use. For example, a deferred material could set this value so
	 * that the deferred renderer knows not to take the forward rendering path.
	 *
	 * @private
	 */
	@:allow(away3d) private var _classification:String;

	/**
	 * An id for this material used to sort the renderables by material, which reduces render state changes across
	 * materials using the same Program3D.
	 *
	 * @private
	 */
	@:allow(away3d) private var _uniqueId:Int;

	/**
	 * An id for this material used to sort the renderables by shader program, which reduces Program3D state changes.
	 *
	 * @private
	 */
	@:allow(away3d) private var _renderOrderId:Int;

	/**
	 * The same as _renderOrderId, but applied to the depth shader passes.
	 *
	 * @private
	 */
	@:allow(away3d) private var _depthPassId:Int;

	private var _bothSides:Bool;
	private var _animationSet:IAnimationSet;

	/**
	 * A list of material owners, renderables or custom Entities.
	 */
	private var _owners:Vector<IMaterialOwner>;
	
	private var _alphaPremultiplied:Bool;
	
	private var _blendMode:BlendMode = BlendMode.NORMAL;
	
	private var _numPasses:Int = 0;
	private var _passes:Vector<MaterialPassBase>;
	
	private var _mipmap:Bool = true;
	private var _smooth:Bool = true;
	private var _repeat:Bool;
	
	private var _anisotropy:Anisotropy = Anisotropy.ANISOTROPIC2X;
	
	private var _depthPass:DepthMapPass;
	private var _distancePass:DistanceMapPass;
	
	private var _lightPicker:LightPickerBase;
	private var _distanceBasedDepthRender:Bool;
	private var _depthCompareMode:Context3DCompareMode = Context3DCompareMode.LESS_EQUAL;
	
	/**
	 * Creates a new MaterialBase object.
	 */
	public function new()
	{
		_owners = new Vector<IMaterialOwner>();
		_passes = new Vector<MaterialPassBase>();
		_depthPass = new DepthMapPass();
		_distancePass = new DistanceMapPass();
		_depthPass.addEventListener(Event.CHANGE, onDepthPassChange);
		_distancePass.addEventListener(Event.CHANGE, onDistancePassChange);
		
		// Default to considering pre-multiplied textures while blending
		alphaPremultiplied = true;
		
		_uniqueId = MATERIAL_ID_COUNT++;
		super();
	}

	/**
	 * @inheritDoc
	 */
	private function get_assetType():String
	{
		return Asset3DType.MATERIAL;
	}

	/**
	 * The light picker used by the material to provide lights to the material if it supports lighting.
	 *
	 * @see away3d.materials.lightpickers.LightPickerBase
	 * @see away3d.materials.lightpickers.StaticLightPicker
	 */
	private function get_lightPicker():LightPickerBase
	{
		return _lightPicker;
	}
	
	private function set_lightPicker(value:LightPickerBase):LightPickerBase
	{
		if (value != _lightPicker) {
			_lightPicker = value;
			var len:Int = _passes.length;
			for (i in 0...len)
				_passes[i].lightPicker = _lightPicker;
		}
		return value;
	}
	
	/**
	 * Indicates whether or not any used textures should use mipmapping. Defaults to true.
	 */
	private function get_mipmap():Bool
	{
		return _mipmap;
	}
	
	private function set_mipmap(value:Bool):Bool
	{
		_mipmap = value;
		for (i in 0..._numPasses)
			_passes[i].mipmap = value;
		
		return value;
	}
	
	/**
	 * Indicates whether or not any used textures should use smoothing.
	 */
	private function get_smooth():Bool
	{
		return _smooth;
	}
	
	private function set_smooth(value:Bool):Bool
	{
		_smooth = value;
		for (i in 0..._numPasses)
			_passes[i].smooth = value;
		return value;
	}

	/**
	 * The depth compare mode used to render the renderables using this material.
	 *
	 * @see openfl.display3D.Context3DCompareMode
	 */
	private function get_depthCompareMode():Context3DCompareMode
	{
		return _depthCompareMode;
	}
	
	private function set_depthCompareMode(value:Context3DCompareMode):Context3DCompareMode
	{
		_depthCompareMode = value;
		return value;
	}
	
	/**
	 * Indicates whether or not any used textures should be tiled. If set to false, texture samples are clamped to
	 * the texture's borders when the uv coordinates are outside the [0, 1] interval.
	 */
	private function get_repeat():Bool
	{
		return _repeat;
	}
	
	private function set_repeat(value:Bool):Bool
	{
		_repeat = value;
		for (i in 0..._numPasses)
			_passes[i].repeat = value;
		return value;
	}
	
	/**
	 * Indicates the number of Anisotropic filtering samples to take for mipmapping
	 */
	private function get_anisotropy():Anisotropy
	{
		return _anisotropy;
	}
	
	private function set_anisotropy(value:Anisotropy):Anisotropy
	{
		_anisotropy = value;
		for (i in 0..._numPasses)
			_passes[i].anisotropy = _anisotropy;
		return value;
	}

	/**
	 * Cleans up resources owned by the material, including passes. Textures are not owned by the material since they
	 * could be used by other materials and will not be disposed.
	 */
	public function dispose():Void
	{
		for (i in 0..._numPasses)
			_passes[i].dispose();
		
		_depthPass.dispose();
		_distancePass.dispose();
		_depthPass.removeEventListener(Event.CHANGE, onDepthPassChange);
		_distancePass.removeEventListener(Event.CHANGE, onDistancePassChange);
	}
	
	/**
	 * Defines whether or not the material should cull triangles facing away from the camera.
	 */
	private function get_bothSides():Bool
	{
		return _bothSides;
	}
	
	private function set_bothSides(value:Bool):Bool
	{
		_bothSides = value;
		
		for (i in 0..._numPasses)
			_passes[i].bothSides = value;
		
		_depthPass.bothSides = value;
		_distancePass.bothSides = value;
		return value;
	}
	
	/**
	 * The blend mode to use when drawing this renderable. The following blend modes are supported:
	 * <ul>
	 * <li>BlendMode.NORMAL: No blending, unless the material inherently needs it</li>
	 * <li>BlendMode.LAYER: Force blending. This will draw the object the same as NORMAL, but without writing depth writes.</li>
	 * <li>BlendMode.MULTIPLY</li>
	 * <li>BlendMode.ADD</li>
	 * <li>BlendMode.ALPHA</li>
	 * </ul>
	 */
	private function get_blendMode():BlendMode
	{
		return _blendMode;
	}
	
	private function set_blendMode(value:BlendMode):BlendMode
	{
		_blendMode = value;
		return value;
	}
	
	/**
	 * Indicates whether visible textures (or other pixels) used by this material have
	 * already been premultiplied. Toggle this if you are seeing black halos around your
	 * blended alpha edges.
	 */
	private function get_alphaPremultiplied():Bool
	{
		return _alphaPremultiplied;
	}
	
	private function set_alphaPremultiplied(value:Bool):Bool
	{
		_alphaPremultiplied = value;
		
		for (i in 0..._numPasses)
			_passes[i].alphaPremultiplied = value;
		return value;
	}
	
	/**
	 * Indicates whether or not the material requires alpha blending during rendering.
	 */
	private function get_requiresBlending():Bool
	{
		return _blendMode != BlendMode.NORMAL;
	}

	/**
	 * An id for this material used to sort the renderables by material, which reduces render state changes across
	 * materials using the same Program3D.
	 */
	private function get_uniqueId():Int
	{
		return _uniqueId;
	}
	
	/**
	 * The amount of passes used by the material.
	 *
	 * @private
	 */
	private function get_numPasses():Int
	{
		return _numPasses;
	}

	/**
	 * Indicates that the depth pass uses transparency testing to discard pixels.
	 *
	 * @private
	 */
	@:allow(away3d) private function hasDepthAlphaThreshold():Bool
	{
		return _depthPass.alphaThreshold > 0;
	}

	/**
	 * Sets the render state for the depth pass that is independent of the rendered object. Used when rendering
	 * depth or distances (fe: shadow maps, depth pre-pass).
	 *
	 * @param stage3DProxy The Stage3DProxy used for rendering.
	 * @param camera The camera from which the scene is viewed.
	 * @param distanceBased Whether or not the depth pass or distance pass should be activated. The distance pass
	 * is required for shadow cube maps.
	 *
	 * @private
	 */
	@:allow(away3d) private function activateForDepth(stage3DProxy:Stage3DProxy, camera:Camera3D, distanceBased:Bool = false):Void
	{
		_distanceBasedDepthRender = distanceBased;

		if (distanceBased)
			_distancePass.activate(stage3DProxy, camera);
		else
			_depthPass.activate(stage3DProxy, camera);
	}

	/**
	 * Clears the render state for the depth pass.
	 *
	 * @param stage3DProxy The Stage3DProxy used for rendering.
	 *
	 * @private
	 */
	@:allow(away3d) private function deactivateForDepth(stage3DProxy:Stage3DProxy):Void
	{
		if (_distanceBasedDepthRender)
			_distancePass.deactivate(stage3DProxy);
		else
			_depthPass.deactivate(stage3DProxy);
	}

	/**
	 * Renders a renderable using the depth pass.
	 *
	 * @param renderable The IRenderable instance that needs to be rendered.
	 * @param stage3DProxy The Stage3DProxy used for rendering.
	 * @param camera The camera from which the scene is viewed.
	 * @param viewProjection The view-projection matrix used to project to the screen. This is not the same as
	 * camera.viewProjection as it includes the scaling factors when rendering to textures.
	 *
	 * @private
	 */
	@:allow(away3d) private function renderDepth(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):Void
	{
		if (_distanceBasedDepthRender) {
			if (renderable.animator != null)
				_distancePass.updateAnimationState(renderable, stage3DProxy, camera);
			_distancePass.render(renderable, stage3DProxy, camera, viewProjection);
		} else {
			if (renderable.animator != null)
				_depthPass.updateAnimationState(renderable, stage3DProxy, camera);
			_depthPass.render(renderable, stage3DProxy, camera, viewProjection);
		}
	}

	/**
	 * Indicates whether or not the pass with the given index renders to texture or not.
	 * @param index The index of the pass.
	 * @return True if the pass renders to texture, false otherwise.
	 *
	 * @private
	 */
	@:allow(away3d) private function passRendersToTexture(index:Int):Bool
	{
		return _passes[index].renderToTexture;
	}
	
	/**
	 * Sets the render state for a pass that is independent of the rendered object. This needs to be called before
	 * calling renderPass. Before activating a pass, the previously used pass needs to be deactivated.
	 * @param index The index of the pass to activate.
	 * @param stage3DProxy The Stage3DProxy object which is currently used for rendering.
	 * @param camera The camera from which the scene is viewed.
	 * @private
	 */
	@:allow(away3d) private function activatePass(index:Int, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		_passes[index].activate(stage3DProxy, camera);
	}


	/**
	 * Clears the render state for a pass. This needs to be called before activating another pass.
	 * @param index The index of the pass to deactivate.
	 * @param stage3DProxy The Stage3DProxy used for rendering
	 *
	 * @private
	 */
	@:allow(away3d) private function deactivatePass(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_passes[index].deactivate(stage3DProxy);
	}

	/**
	 * Renders the current pass. Before calling renderPass, activatePass needs to be called with the same index.
	 * @param index The index of the pass used to render the renderable.
	 * @param renderable The IRenderable object to draw.
	 * @param stage3DProxy The Stage3DProxy object used for rendering.
	 * @param entityCollector The EntityCollector object that contains the visible scene data.
	 * @param viewProjection The view-projection matrix used to project to the screen. This is not the same as
	 * camera.viewProjection as it includes the scaling factors when rendering to textures.
	 */
	@:allow(away3d) private function renderPass(index:Int, renderable:IRenderable, stage3DProxy:Stage3DProxy, entityCollector:EntityCollector, viewProjection:Matrix3D):Void
	{
		if (_lightPicker != null)
			_lightPicker.collectLights(renderable, entityCollector);
		
		var pass:MaterialPassBase = _passes[index];
		
		if (renderable.animator != null)
			pass.updateAnimationState(renderable, stage3DProxy, entityCollector.camera);
		
		pass.render(renderable, stage3DProxy, entityCollector.camera, viewProjection);
	}
	
	//
	// MATERIAL MANAGEMENT
	//
	/**
	 * Mark an IMaterialOwner as owner of this material.
	 * Assures we're not using the same material across renderables with different animations, since the
	 * Program3Ds depend on animation. This method needs to be called when a material is assigned.
	 *
	 * @param owner The IMaterialOwner that had this material assigned
	 *
	 * @private
	 */
	@:allow(away3d) private function addOwner(owner:IMaterialOwner):Void
	{
		_owners.push(owner);
		
		if (owner.animator != null) {
			if (_animationSet != null && owner.animator.animationSet != _animationSet)
				throw new Error("A Material instance cannot be shared across renderables with different animator libraries")
			else {
				if (_animationSet != owner.animator.animationSet) {
					_animationSet = owner.animator.animationSet;
					for (i in 0..._numPasses)
						_passes[i].animationSet = _animationSet;
					_depthPass.animationSet = _animationSet;
					_distancePass.animationSet = _animationSet;
					invalidatePasses(null);
				}
			}
		}
	}
	
	/**
	 * Removes an IMaterialOwner as owner.
	 * @param owner
	 * @private
	 */
	@:allow(away3d) private function removeOwner(owner:IMaterialOwner):Void
	{
		_owners.splice(_owners.indexOf(owner), 1);
		if (_owners.length == 0) {
			_animationSet = null;
			for (i in 0..._numPasses)
				_passes[i].animationSet = _animationSet;
			_depthPass.animationSet = _animationSet;
			_distancePass.animationSet = _animationSet;
			invalidatePasses(null);
		}
	}
	
	/**
	 * A list of the IMaterialOwners that use this material
	 *
	 * @private
	 */
	@:allow(away3d) private function get_owners():Vector<IMaterialOwner>
	{
		return _owners;
	}
	
	/**
	 * Performs any processing that needs to occur before any of its passes are used.
	 *
	 * @private
	 */
	@:allow(away3d) private function updateMaterial(context:Context3D):Void
	{
	
	}
	
	/**
	 * Deactivates the last pass of the material.
	 *
	 * @private
	 */
	@:allow(away3d) private function deactivate(stage3DProxy:Stage3DProxy):Void
	{
		_passes[_numPasses - 1].deactivate(stage3DProxy);
	}
	
	/**
	 * Marks the shader programs for all passes as invalid, so they will be recompiled before the next use.
	 * @param triggerPass The pass triggering the invalidation, if any. This is passed to prevent invalidating the
	 * triggering pass, which would result in an infinite loop.
	 *
	 * @private
	 */
	@:allow(away3d) private function invalidatePasses(triggerPass:MaterialPassBase):Void
	{
		var owner:IMaterialOwner;
		
		_depthPass.invalidateShaderProgram();
		_distancePass.invalidateShaderProgram();

		// test if the depth and distance passes support animating the animation set in the vertex shader
		// if any object using this material fails to support accelerated animations for any of the passes,
		// we should do everything on cpu (otherwise we have the cost of both gpu + cpu animations)
		if (_animationSet!=null) {
			_animationSet.resetGPUCompatibility();
			for (owner in _owners) {
				if (owner.animator!=null) {
					owner.animator.testGPUCompatibility(_depthPass);
					owner.animator.testGPUCompatibility(_distancePass);
				}
			}
		}
		
		for (i in 0..._numPasses) {
			// only invalidate the pass if it wasn't the triggering pass
			if (_passes[i] != triggerPass)
				_passes[i].invalidateShaderProgram(false);

			// test if animation will be able to run on gpu BEFORE compiling materials
			// test if the pass supports animating the animation set in the vertex shader
			// if any object using this material fails to support accelerated animations for any of the passes,
			// we should do everything on cpu (otherwise we have the cost of both gpu + cpu animations)
			if (_animationSet != null) {
				for (owner in _owners) {
					if (owner.animator != null)
						owner.animator.testGPUCompatibility(_passes[i]);
				}
			}
		}
	}

	/**
	 * Removes a pass from the material.
	 * @param pass The pass to be removed.
	 */
	private function removePass(pass:MaterialPassBase):Void
	{
		_passes.splice(_passes.indexOf(pass), 1);
		--_numPasses;
	}
	
	/**
	 * Removes all passes from the material
	 */
	private function clearPasses():Void
	{
		for (i in 0..._numPasses)
			_passes[i].removeEventListener(Event.CHANGE, onPassChange);
		
		_passes.length = 0;
		_numPasses = 0;
	}
	
	/**
	 * Adds a pass to the material
	 * @param pass
	 */
	private function addPass(pass:MaterialPassBase):Void
	{
		_passes[_numPasses++] = pass;
		pass.animationSet = _animationSet;
		pass.alphaPremultiplied = _alphaPremultiplied;
		pass.mipmap = _mipmap;
		pass.smooth = _smooth;
		pass.repeat = _repeat;
		pass.anisotropy = _anisotropy;
		pass.lightPicker = _lightPicker;
		pass.bothSides = _bothSides;
		pass.addEventListener(Event.CHANGE, onPassChange);
		invalidatePasses(null);
	}

	/**
	 * Listener for when a pass's shader code changes. It recalculates the render order id.
	 */
	private function onPassChange(event:Event):Void
	{
		var mult:Float = 1;
		var ids:Vector<Int>;
		var len:Int;
		
		_renderOrderId = 0;
		
		for (i in 0..._numPasses) {
			ids = _passes[i]._program3Dids;
			len = ids.length;
			for (j in 0...len) {
				if (ids[j] != -1) {
					_renderOrderId += Std.int(mult*ids[j]);
					break;
				}
			}
			mult *= 1000;
		}
	}

	/**
	 * Listener for when the distance pass's shader code changes. It recalculates the depth pass id.
	 */
	private function onDistancePassChange(event:Event):Void
	{
		var ids:Vector<Int> = _distancePass._program3Dids;
		var len:Int = ids.length;
		
		_depthPassId = 0;
		
		for (j in 0...len) {
			if (ids[j] != -1) {
				_depthPassId += ids[j];
				break;
			}
		}
	}

	/**
	 * Listener for when the depth pass's shader code changes. It recalculates the depth pass id.
	 */
	private function onDepthPassChange(event:Event):Void
	{
		var ids:Vector<Int> = _depthPass._program3Dids;
		var len:Int = ids.length;
		
		_depthPassId = 0;
		
		for (j in 0...len) {
			if (ids[j] != -1) {
				_depthPassId += ids[j];
				break;
			}
		}
	}
}