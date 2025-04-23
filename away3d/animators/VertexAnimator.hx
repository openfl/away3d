package away3d.animators;

import away3d.animators.states.*;
import away3d.animators.transitions.*;
import away3d.animators.data.*;
import away3d.cameras.Camera3D;
import away3d.core.base.*;
import away3d.core.managers.*;
import away3d.materials.passes.*;

import openfl.display3D.*;
import openfl.errors.Error;
import openfl.Vector;

/**
 * Provides an interface for assigning vertex-based animation data sets to mesh-based entity objects
 * and controlling the various available states of animation through an interative playhead that can be
 * automatically updated or manually triggered.
 */
class VertexAnimator extends AnimatorBase implements IAnimator
{
	private var _vertexAnimationSet:VertexAnimationSet;
	private var _poses:Vector<Geometry> = new Vector<Geometry>();
	private var _weights:Vector<Float> = Vector.ofArray([1, 0, 0, 0.0]);
	private var _numPoses:Int;
	private var _blendMode:VertexAnimationMode;
	private var _activeVertexState:IVertexAnimationState;
	
	/**
	 * Creates a new <code>VertexAnimator</code> object.
	 *
	 * @param vertexAnimationSet The animation data set containing the vertex animations used by the animator.
	 */
	public function new(vertexAnimationSet:VertexAnimationSet)
	{
		super(vertexAnimationSet);
		
		_vertexAnimationSet = vertexAnimationSet;
		_numPoses = vertexAnimationSet.numPoses;
		_blendMode = vertexAnimationSet.blendMode;
	}
	
	/**
	 * @inheritDoc
	 */
	public function clone():IAnimator
	{
		return new VertexAnimator(_vertexAnimationSet);
	}
	
	/**
	 * Plays a sequence with a given name. If the sequence is not found, it may not be loaded yet, and it will retry every frame.
	 * @param sequenceName The name of the clip to be played.
	 */
	public function play(name:String, transition:IAnimationTransition = null, ?offset:Int = null):Void
	{
		if (_activeAnimationName != name) {
			_activeAnimationName = name;
			
			//TODO: implement transitions in vertex animator
			
			if (!_animationSet.hasAnimation(name))
				throw new Error("Animation root node " + name + " not found!");
			
			_activeNode = _animationSet.getAnimation(name);
			
			_activeState = getAnimationState(_activeNode);
			
			if (updatePosition) {
				//update straight away to reset position deltas
				_activeState.update(_absoluteTime);
				_activeState.positionDelta;
			}
			
			_activeVertexState = cast(_activeState, IVertexAnimationState);
		}
		
		start();
		
		//apply a time offset if specified
		if (!Math.isNaN(offset))
			reset(name, offset);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateDeltaTime(dt:Int):Void
	{
		super.updateDeltaTime(dt);
		
		_poses[0] = _activeVertexState.currentGeometry;
		_poses[1] = _activeVertexState.nextGeometry;
		_weights[0] = 1 - (_weights[1] = _activeVertexState.blendWeight);
	}
	
	/**
	 * @inheritDoc
	 */
	public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:Int, vertexStreamOffset:Int, camera:Camera3D):Void
	{
		// todo: add code for when running on cpu
		
		// if no poses defined, set temp data
		if (_poses.length == 0) {
			setNullPose(stage3DProxy, renderable, vertexConstantOffset, vertexStreamOffset);
			return;
		}
		
		// this type of animation can only be SubMesh
		var subMesh:SubMesh = cast(renderable, SubMesh);
		var subGeom:ISubGeometry;
		var i:Int;
		var len:Int = _numPoses;
		
		stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _weights, 1);
		
		if (_blendMode == ABSOLUTE) {
			i = 1;
			subGeom = _poses[0].subGeometries[subMesh._index];
			// set the base sub-geometry so the material can simply pick up on this data
			if (subGeom != null)
				subMesh.subGeometry = subGeom;
		} else
			i = 0;
		
		while (i < len) {
			subGeom = _poses[i].subGeometries[subMesh._index];
			if (subGeom == null)
				subGeom = subMesh.subGeometry;
			
			subGeom.activateVertexBuffer(vertexStreamOffset++, stage3DProxy);
			
			if (_vertexAnimationSet.useNormals)
				subGeom.activateVertexNormalBuffer(vertexStreamOffset++, stage3DProxy);
			
			++i;
		}
	}
	
	private function setNullPose(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:Int, vertexStreamOffset:Int):Void
	{
		stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _weights, 1);
		
		if (_blendMode == ABSOLUTE) {
			var len:Int = _numPoses;
			for (i in 0...len) {
				renderable.activateVertexBuffer(vertexStreamOffset++, stage3DProxy);
				
				if (_vertexAnimationSet.useNormals)
					renderable.activateVertexNormalBuffer(vertexStreamOffset++, stage3DProxy);
			}
		}
		// todo: set temp data for additive?
	}
	
	/**
	 * Verifies if the animation will be used on cpu. Needs to be true for all passes for a material to be able to use it on gpu.
	 * Needs to be called if gpu code is potentially required.
	 */
	public function testGPUCompatibility(pass:MaterialPassBase):Void
	{
	}
}