package away3d.materials.passes; 

import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.IAnimationSet;
import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.AGALProgram3DCache;
import away3d.core.managers.Stage3DProxy;
import away3d.debug.Debug;
import away3d.errors.AbstractMethodError;
import away3d.materials.MaterialBase;
import away3d.materials.lightpickers.LightPickerBase;
import away3d.textures.Anisotropy;

import openfl.display.BlendMode;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.Context3DTriangleFace;
import openfl.display3D.Program3D;
import openfl.display3D.textures.TextureBase;
import openfl.errors.ArgumentError;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;
import openfl.Vector;

/**
 * MaterialPassBase provides an abstract base class for material shader passes. A material pass constitutes at least
 * a render call per required renderable.
 */
class MaterialPassBase extends EventDispatcher
{
	public var material(get, set):MaterialBase;
	public var writeDepth(get, set):Bool;
	public var mipmap(get, set):Bool;
	public var smooth(get, set):Bool;
	public var repeat(get, set):Bool;
	public var anisotropy(get, set):Anisotropy;
	public var bothSides(get, set):Bool;
	public var depthCompareMode(get, set):Context3DCompareMode;
	public var animationSet(get, set):IAnimationSet;
	public var renderToTexture(get, never):Bool;
	public var numUsedStreams(get, never):Int;
	public var numUsedVertexConstants(get, never):Int;
	public var numUsedVaryings(get, never):Int;
	public var numUsedFragmentConstants(get, never):Int;
	public var needFragmentAnimation(get, never):Bool;
	public var needUVAnimation(get, never):Bool;
	@:allow(away3d) private var lightPicker(get, set):LightPickerBase;
	public var alphaPremultiplied(get, set):Bool;
	
	private var _material:MaterialBase;
	private var _animationSet:IAnimationSet;
	
	@:allow(away3d) private var _program3Ds:Vector<Program3D> = new Vector<Program3D>(8);
	@:allow(away3d) private var _program3Dids:Vector<Int> = Vector.ofArray([-1, -1, -1, -1, -1, -1, -1, -1]);
	private var _context3Ds:Vector<Context3D> = new Vector<Context3D>(8);
	
	// agal props. these NEED to be set by subclasses!
	// todo: can we perhaps figure these out manually by checking read operations in the bytecode, so other sources can be safely updated?
	private var _numUsedStreams:Int = 0;
	private var _numUsedTextures:Int = 0;
	private var _numUsedVertexConstants:Int = 0;
	private var _numUsedFragmentConstants:Int = 0;
	private var _numUsedVaryings:Int = 0;
	
	private var _smooth:Bool = true;
	private var _repeat:Bool = false;
	private var _mipmap:Bool = true;
	private var _anisotropy:Anisotropy = Anisotropy.ANISOTROPIC2X;
	private var _depthCompareMode:Context3DCompareMode = Context3DCompareMode.LESS_EQUAL;
	
	private var _blendFactorSource:Context3DBlendFactor = Context3DBlendFactor.ONE;
	private var _blendFactorDest:Context3DBlendFactor = Context3DBlendFactor.ZERO;
	
	private var _enableBlending:Bool;
	
	private var _bothSides:Bool;
	
	private var _lightPicker:LightPickerBase;
	private var _animatableAttributes:Vector<String> = Vector.ofArray(["va0"]);
	private var _animationTargetRegisters:Vector<String> = Vector.ofArray(["vt0"]);
	private var _shadedTarget:String = "ft0";
	
	// keep track of previously rendered usage for faster cleanup of old vertex buffer streams and textures
	private static var _previousUsedStreams:Vector<Int> = Vector.ofArray([ 0, 0, 0, 0, 0, 0, 0, 0 ]);
	private static var _previousUsedTexs:Vector<Int> = Vector.ofArray([ 0, 0, 0, 0, 0, 0, 0, 0 ]);
	private var _defaultCulling:Context3DTriangleFace = Context3DTriangleFace.BACK;
	
	private var _renderToTexture:Bool;
	
	// render state mementos for render-to-texture passes
	private var _oldTarget:TextureBase;
	private var _oldSurface:Int;
	private var _oldDepthStencil:Bool;
	private var _oldRect:Rectangle;
	
	private var _alphaPremultiplied:Bool;
	private var _needFragmentAnimation:Bool;
	private var _needUVAnimation:Bool;
	private var _UVTarget:String;
	private var _UVSource:String;
	
	private var _agalVersion:Int = 1;
	private var _writeDepth:Bool = true;
	
	public var animationRegisterCache:AnimationRegisterCache;
	
	/**
	 * Creates a new MaterialPassBase object.
	 *
	 * @param renderToTexture Indicates whether this pass is a render-to-texture pass.
	 */
	public function new(renderToTexture:Bool = false)
	{
		super();
		_renderToTexture = renderToTexture;
		_numUsedStreams = 1;
		_numUsedVertexConstants = 5;
	}
	
	/**
	 * The material to which this pass belongs.
	 */
	private function get_material():MaterialBase
	{
		return _material;
	}
	
	private function set_material(value:MaterialBase):MaterialBase
	{
		_material = value;
		return _material;
	}
	
	/**
	 * Indicate whether this pass should write to the depth buffer or not. Ignored when blending is enabled.
	 */
	private function get_writeDepth():Bool
	{
		return _writeDepth;
	}
	
	private function set_writeDepth(value:Bool):Bool
	{
		_writeDepth = value;
		return _writeDepth;
	}
	
	/**
	 * Defines whether any used textures should use mipmapping.
	 */
	private function get_mipmap():Bool
	{
		return _mipmap;
	}
	
	private function set_mipmap(value:Bool):Bool
	{
		if (_mipmap == value)
			return _mipmap;
		_mipmap = value;
		invalidateShaderProgram();
		return _mipmap;
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
		if (_anisotropy == value)
			return value;
		_anisotropy = value;
		invalidateShaderProgram();
		return value;
	}
	
	/**
	 * Defines whether smoothing should be applied to any used textures.
	 */
	private function get_smooth():Bool
	{
		return _smooth;
	}
	
	private function set_smooth(value:Bool):Bool
	{
		if (_smooth == value)
			return _smooth;
		_smooth = value;
		invalidateShaderProgram();
		return _smooth;
	}
	
	/**
	 * Defines whether textures should be tiled.
	 */
	private function get_repeat():Bool
	{
		return _repeat;
	}
	
	private function set_repeat(value:Bool):Bool
	{
		if (_repeat == value)
			return _repeat;
		_repeat = value;
		invalidateShaderProgram();
		return _repeat;
	}
	
	/**
	 * Defines whether or not the material should perform backface culling.
	 */
	private function get_bothSides():Bool
	{
		return _bothSides;
	}
	
	private function set_bothSides(value:Bool):Bool
	{
		_bothSides = value;
		return _bothSides;
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
	 * Returns the animation data set adding animations to the material.
	 */
	private function get_animationSet():IAnimationSet
	{
		return _animationSet;
	}
	
	private function set_animationSet(value:IAnimationSet):IAnimationSet
	{
		if (_animationSet == value)
			return _animationSet;
		
		_animationSet = value;
		
		invalidateShaderProgram();
		return _animationSet;
	}
	
	/**
	 * Specifies whether this pass renders to texture
	 */
	private function get_renderToTexture():Bool
	{
		return _renderToTexture;
	}
	
	/**
	 * Cleans up any resources used by the current object.
	 * @param deep Indicates whether other resources should be cleaned up, that could potentially be shared across different instances.
	 */
	public function dispose():Void
	{
		if (_lightPicker != null)
			_lightPicker.removeEventListener(Event.CHANGE, onLightsChange);
		
		for (i in 0...8) {
			if (_program3Ds[i] != null) {
				AGALProgram3DCache.getInstanceFromIndex(i).freeProgram3D(_program3Dids[i]);
				_program3Ds[i] = null;
			}
		}
	}
	
	/**
	 * The amount of used vertex streams in the vertex code. Used by the animation code generation to know from which index on streams are available.
	 */
	private function get_numUsedStreams():UInt
	{
		return _numUsedStreams;
	}
	
	/**
	 * The amount of used vertex constants in the vertex code. Used by the animation code generation to know from which index on registers are available.
	 */
	private function get_numUsedVertexConstants():UInt
	{
		return _numUsedVertexConstants;
	}
	
	private function get_numUsedVaryings():UInt
	{
		return _numUsedVaryings;
	}

	/**
	 * The amount of used fragment constants in the fragment code. Used by the animation code generation to know from which index on registers are available.
	 */
	private function get_numUsedFragmentConstants():UInt
	{
		return _numUsedFragmentConstants;
	}
	
	private function get_needFragmentAnimation():Bool
	{
		return _needFragmentAnimation;
	}

	/**
	 * Indicates whether the pass requires any UV animatin code.
	 */
	private function get_needUVAnimation():Bool
	{
		return _needUVAnimation;
	}
	
	/**
	 * Sets up the animation state. This needs to be called before render()
	 *
	 * @private
	 */
	@:allow(away3d) private function updateAnimationState(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		renderable.animator.setRenderState(stage3DProxy, renderable, _numUsedVertexConstants, _numUsedStreams, camera);
	}
	
	/**
	 * Renders an object to the current render target.
	 *
	 * @private
	 */
	@:allow(away3d) private function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):Void
	{
		throw new AbstractMethodError();
	}

	/**
	 * Returns the vertex AGAL code for the material.
	 */
	@:allow(away3d) private function getVertexCode():String
	{
		throw new AbstractMethodError();
		return null;
	}

	/**
	 * Returns the fragment AGAL code for the material.
	 */
	@:allow(away3d) private function getFragmentCode(fragmentAnimatorCode:String):String
	{
		throw new AbstractMethodError();
		return null;
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
	public function setBlendMode(value:BlendMode):Void
	{
		switch (value) {
			case BlendMode.NORMAL:
				_blendFactorSource = Context3DBlendFactor.ONE;
				_blendFactorDest = Context3DBlendFactor.ZERO;
				_enableBlending = false;
			case BlendMode.LAYER:
				_blendFactorSource = Context3DBlendFactor.SOURCE_ALPHA;
				_blendFactorDest = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
				_enableBlending = true;
			case BlendMode.MULTIPLY:
				_blendFactorSource = Context3DBlendFactor.ZERO;
				_blendFactorDest = Context3DBlendFactor.SOURCE_COLOR;
				_enableBlending = true;
			case BlendMode.ADD:
				_blendFactorSource = Context3DBlendFactor.SOURCE_ALPHA;
				_blendFactorDest = Context3DBlendFactor.ONE;
				_enableBlending = true;
			case BlendMode.ALPHA:
				_blendFactorSource = Context3DBlendFactor.ZERO;
				_blendFactorDest = Context3DBlendFactor.SOURCE_ALPHA;
				_enableBlending = true;
			case BlendMode.SCREEN:
				_blendFactorSource = Context3DBlendFactor.ONE;
				_blendFactorDest = Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR;
				_enableBlending = true;
			default:
				throw new ArgumentError("Unsupported blend mode!");
		}
	}

	/**
	 * Sets the render state for the pass that is independent of the rendered object. This needs to be called before
	 * calling renderPass. Before activating a pass, the previously used pass needs to be deactivated.
	 * @param stage3DProxy The Stage3DProxy object which is currently used for rendering.
	 * @param camera The camera from which the scene is viewed.
	 * @private
	 */
	@:allow(away3d) private function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		var contextIndex:Int = stage3DProxy._stage3DIndex;
		var context:Context3D = stage3DProxy._context3D;
		
		context.setDepthTest(_writeDepth && !_enableBlending, _depthCompareMode);
		if (_enableBlending)
			context.setBlendFactors(_blendFactorSource, _blendFactorDest);
		
		if (_context3Ds[contextIndex] != context || _program3Ds[contextIndex] == null) {
			_context3Ds[contextIndex] = context;
			updateProgram(stage3DProxy);
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		var prevUsed:Int = _previousUsedStreams[contextIndex];
		for (i in _numUsedStreams...prevUsed)
			context.setVertexBufferAt(i, null);
		
		prevUsed = _previousUsedTexs[contextIndex];
		for (i in _numUsedTextures...prevUsed)
			context.setTextureAt(i, null);
		
		if (_animationSet != null && !_animationSet.usesCPU)
			_animationSet.activate(stage3DProxy, this);
		
		context.setProgram(_program3Ds[contextIndex]);
		
		context.setCulling(_bothSides? Context3DTriangleFace.NONE : _defaultCulling);
		
		if (_renderToTexture) {
			_oldTarget = stage3DProxy.renderTarget;
			_oldSurface = stage3DProxy.renderSurfaceSelector;
			_oldDepthStencil = stage3DProxy.enableDepthAndStencil;
			_oldRect = stage3DProxy.scissorRect;
		}
	}

	/**
	 * Clears the render state for the pass. This needs to be called before activating another pass.
	 * @param stage3DProxy The Stage3DProxy used for rendering
	 *
	 * @private
	 */
	@:allow(away3d) private function deactivate(stage3DProxy:Stage3DProxy):Void
	{
		var index:UInt = stage3DProxy._stage3DIndex;
		_previousUsedStreams[index] = _numUsedStreams;
		_previousUsedTexs[index] = _numUsedTextures;
		
		if (_animationSet != null && !_animationSet.usesCPU)
			_animationSet.deactivate(stage3DProxy, this);
		
		if (_renderToTexture) {
			// kindly restore state
			stage3DProxy.setRenderTarget(_oldTarget, _oldDepthStencil, _oldSurface);
			stage3DProxy.scissorRect = _oldRect;
		}

		if(_enableBlending) {
			stage3DProxy._context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		}

		stage3DProxy._context3D.setDepthTest(true, Context3DCompareMode.LESS_EQUAL);
	}
	
	/**
	 * Marks the shader program as invalid, so it will be recompiled before the next render.
	 *
	 * @param updateMaterial Indicates whether the invalidation should be performed on the entire material. Should always pass "true" unless it's called from the material itself.
	 */
	@:allow(away3d) private function invalidateShaderProgram(updateMaterial:Bool = true):Void
	{
		for (i in 0...8)
			_program3Ds[i] = null;
		
		if (_material != null && updateMaterial)
			_material.invalidatePasses(this);
	}
	
	/**
	 * Compiles the shader program.
	 * @param polyOffsetReg An optional register that contains an amount by which to inflate the model (used in single object depth map rendering).
	 */
	@:allow(away3d) private function updateProgram(stage3DProxy:Stage3DProxy):Void
	{
		var animatorCode:String = "";
		var UVAnimatorCode:String = "";
		var fragmentAnimatorCode:String = "";
		var vertexCode:String = getVertexCode();
		
		if (_animationSet != null && !_animationSet.usesCPU) {
			animatorCode = _animationSet.getAGALVertexCode(this, _animatableAttributes, _animationTargetRegisters, stage3DProxy.profile);
			if (_needFragmentAnimation)
				fragmentAnimatorCode = _animationSet.getAGALFragmentCode(this, _shadedTarget, stage3DProxy.profile);
			if (_needUVAnimation)
				UVAnimatorCode = _animationSet.getAGALUVCode(this, _UVSource, _UVTarget);
			_animationSet.doneAGALCode(this);
		} else {
			var len:UInt = _animatableAttributes.length;
			
			// simply write attributes to targets, do not animate them
			// projection will pick up on targets[0] to do the projection
			for (i in 0...len)
				animatorCode += "mov " + _animationTargetRegisters[i] + ", " + _animatableAttributes[i] + "\n";
			if (_needUVAnimation)
				UVAnimatorCode = "mov " + _UVTarget + "," + _UVSource + "\n";
		}
		
		vertexCode = animatorCode + UVAnimatorCode + vertexCode;
		
		var fragmentCode:String = getFragmentCode(fragmentAnimatorCode);
		if (Debug.active) {
			trace("Compiling AGAL Code:");
			trace("--------------------");
			trace(vertexCode);
			trace("--------------------");
			trace(fragmentCode);
		}
		AGALProgram3DCache.getInstance(stage3DProxy).setProgram3D(this, vertexCode, fragmentCode, _agalVersion);
	}

	/**
	 * The light picker used by the material to provide lights to the material if it supports lighting.
	 *
	 * @see away3d.materials.lightpickers.LightPickerBase
	 * @see away3d.materials.lightpickers.StaticLightPicker
	 */
	@:allow(away3d) private function get_lightPicker():LightPickerBase
	{
		return _lightPicker;
	}
	
	@:allow(away3d) private function set_lightPicker(value:LightPickerBase):LightPickerBase
	{
		if (_lightPicker != null)
			_lightPicker.removeEventListener(Event.CHANGE, onLightsChange);
		_lightPicker = value;
		if (_lightPicker != null)
			_lightPicker.addEventListener(Event.CHANGE, onLightsChange);
		updateLights();
		return _lightPicker;
	}

	/**
	 * Called when the light picker's configuration changes.
	 */
	private function onLightsChange(event:Event):Void
	{
		updateLights();
	}

	/**
	 * Implemented by subclasses if the pass uses lights to update the shader.
	 */
	private function updateLights():Void
	{
	
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
		invalidateShaderProgram(false);
		return _alphaPremultiplied;
	}
}