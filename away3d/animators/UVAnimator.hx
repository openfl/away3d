package away3d.animators;

import away3d.animators.data.*;
import away3d.animators.states.*;
import away3d.animators.transitions.*;
import away3d.cameras.Camera3D;
import away3d.core.base.*;
import away3d.core.managers.*;
import away3d.core.math.MathConsts;
import away3d.materials.*;
import away3d.materials.passes.*;

import openfl.display3D.Context3DProgramType;
import openfl.errors.Error;
import openfl.geom.Matrix;
import openfl.Vector;

/**
 * Provides an interface for assigning uv-based animation data sets to mesh-based entity objects
 * and controlling the various available states of animation through an interative playhead that can be
 * automatically updated or manually triggered.
 */
class UVAnimator extends AnimatorBase implements IAnimator
{
	public var autoRotation(get, set):Bool;
	public var rotationIncrease(get, set):Float;
	public var autoTranslate(get, set):Bool;
	public var translateIncrease(get, never):Vector<Float>;
	
	private var _uvAnimationSet:UVAnimationSet;
	private var _deltaFrame:UVAnimationFrame = new UVAnimationFrame();
	private var _activeUVState:IUVAnimationState;
	
	private var _uvTransform:Matrix;
	private var _matrix2d:Vector<Float>;
	private var _translate:Vector<Float>;
	
	private var _autoRotation:Bool;
	private var _rotationIncrease:Float = 1;
	private var _autoTranslate:Bool;
	private var _translateIncrease:Vector<Float>;

	/**
	 * Creates a new <code>UVAnimator</code> object.
	 *
	 * @param uvAnimationSet The animation data set containing the uv animations used by the animator.
	 */
	public function new(uvAnimationSet:UVAnimationSet)
	{
		super(uvAnimationSet);
		
		_uvTransform = new Matrix();
		_matrix2d = Vector.ofArray([1, 0, 0, 0, 1, 0, 0, 0.0]);
		_translate = Vector.ofArray([0, 0, 0.5, 0.5]);
		_uvAnimationSet = uvAnimationSet;
	}
	
	/**
	 * Defines if a rotation is performed automatically each update. The rotationIncrease value is added each iteration.
	 */
	private function set_autoRotation(b:Bool):Bool
	{
		return _autoRotation = b;
	}
	
	private function get_autoRotation():Bool
	{
		return _autoRotation;
	}
	
	/**
	 * if autoRotation = true, the rotation is increased by the rotationIncrease value. Default is 1;
	 */
	private function set_rotationIncrease(value:Float):Float
	{
		return _rotationIncrease = value;
	}
	
	private function get_rotationIncrease():Float
	{
		return _rotationIncrease;
	}
	
	/**
	 * Defines if the animation is translated automatically each update. Ideal to scroll maps. Use setTranslateIncrease to define the offsets.
	 */
	private function set_autoTranslate(b:Bool):Bool
	{
		_autoTranslate = b;
		if (b && _translateIncrease == null)
			_translateIncrease = Vector.ofArray([0, 0.0]);
		return b;
	}
	
	private function get_autoTranslate():Bool
	{
		return _autoTranslate;
	}
	
	/**
	 * if autoTranslate = true, animation is translated automatically each update with the u and v values.
	 * Note if value are integers, no visible update will be performed. Values are expected to be in 0-1 range.
	 */
	public function setTranslateIncrease(u:Float, v:Float):Void
	{
		if (_translateIncrease == null)
			_translateIncrease = Vector.ofArray([0, 0.0]);
		_translateIncrease[0] = u;
		_translateIncrease[1] = v;
	}
	
	private function get_translateIncrease():Vector<Float>
	{
		return _translateIncrease;
	}
	
	/**
	 * @inheritDoc
	 */
	public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:Int, vertexStreamOffset:Int, camera:Camera3D):Void
	{
		var material:TextureMaterial = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(renderable.material, TextureMaterial) ? cast renderable.material : null;
		var subMesh:SubMesh = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(renderable, SubMesh) ? cast renderable : null;
		
		if (material == null || subMesh == null)
			return;
		
		if (autoTranslate) {
			_deltaFrame.offsetU += _translateIncrease[0];
			_deltaFrame.offsetV += _translateIncrease[1];
		}
		
		_translate[0] = _deltaFrame.offsetU;
		_translate[1] = _deltaFrame.offsetV;
		
		stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _translate);
		
		_uvTransform.identity();
		
		if (_autoRotation)
			_deltaFrame.rotation += _rotationIncrease;
		
		if (_deltaFrame.rotation != 0)
			_uvTransform.rotate(_deltaFrame.rotation*MathConsts.DEGREES_TO_RADIANS);
		
		if (_deltaFrame.scaleU != 1 || _deltaFrame.scaleV != 1)
			_uvTransform.scale(_deltaFrame.scaleU, _deltaFrame.scaleV);
		
		_matrix2d[0] = _uvTransform.a;
		_matrix2d[1] = _uvTransform.b;
		_matrix2d[3] = _uvTransform.tx;
		_matrix2d[4] = _uvTransform.c;
		_matrix2d[5] = _uvTransform.d;
		_matrix2d[7] = _uvTransform.ty;
		
		stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset + 4, _matrix2d);
		
	}
	
	/**
	 * @inheritDoc
	 */
	public function play(name:String, transition:IAnimationTransition = null, ?offset:Float = null):Void
	{
		if (_activeAnimationName == name)
			return;
		
		_activeAnimationName = name;
		
		if (!_animationSet.hasAnimation(name))
			throw new Error("Animation root node " + name + " not found!");
		
		_activeNode = _animationSet.getAnimation(name);
		_activeState = getAnimationState(_activeNode);
		_activeUVState = cast(_activeState, IUVAnimationState);
		
		start();
	}
	
	/**
	 * Applies the calculated time delta to the active animation state node.
	 */
	override private function updateDeltaTime(dt:Int):Void
	{
		_absoluteTime += dt;
		_activeUVState.update(_absoluteTime);
		
		var currentUVFrame:UVAnimationFrame = _activeUVState.currentUVFrame;
		var nextUVFrame:UVAnimationFrame = _activeUVState.nextUVFrame;
		var blendWeight:Float = _activeUVState.blendWeight;
		
		if (currentUVFrame != null && nextUVFrame != null) {
			_deltaFrame.offsetU = currentUVFrame.offsetU + blendWeight*(nextUVFrame.offsetU - currentUVFrame.offsetU);
			_deltaFrame.offsetV = currentUVFrame.offsetV + blendWeight*(nextUVFrame.offsetV - currentUVFrame.offsetV);
			_deltaFrame.scaleU = currentUVFrame.scaleU + blendWeight*(nextUVFrame.scaleU - currentUVFrame.scaleU);
			_deltaFrame.scaleV = currentUVFrame.scaleV + blendWeight*(nextUVFrame.scaleV - currentUVFrame.scaleV);
			_deltaFrame.rotation = currentUVFrame.rotation + blendWeight*(nextUVFrame.rotation - currentUVFrame.rotation);
		}
	}
	
	/**
	 * Verifies if the animation will be used on cpu. Needs to be true for all passes for a material to be able to use it on gpu.
	 * Needs to be called if gpu code is potentially required.
	 */
	public function testGPUCompatibility(pass:MaterialPassBase):Void
	{
	}
	
	/**
	 * @inheritDoc
	 */
	public function clone():IAnimator
	{
		return new UVAnimator(_uvAnimationSet);
	}
}