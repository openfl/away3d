/**
 * Provides an interface for assigning paricle-based animation data sets to mesh-based entity objects
 * and controlling the various available states of animation through an interative playhead that can be
 * automatically updated or manually triggered.
 *
 * Requires that the containing geometry of the parent mesh is particle geometry
 *
 * @see away3d.core.base.ParticleGeometry
 */
package away3d.animators;


import haxe.ds.ObjectMap;
import away3d.core.base.ISubGeometry;
import away3d.materials.passes.MaterialPassBase;
import flash.display3D.Context3DProgramType;
import away3d.animators.data.AnimationSubGeometry;
import away3d.core.managers.Stage3DProxy;
import away3d.core.base.IRenderable;
import away3d.cameras.Camera3D;
import away3d.animators.data.AnimationRegisterCache;
import away3d.core.base.SubMesh;
import flash.errors.Error;
import away3d.animators.data.ParticlePropertiesMode;
import away3d.animators.nodes.ParticleNodeBase;
import flash.Vector;
import away3d.animators.states.ParticleStateBase;
import flash.utils.Dictionary;

class ParticleAnimator extends AnimatorBase implements IAnimator {

    public var _particleAnimationSet:ParticleAnimationSet;
    private var _animationParticleStates:Vector<ParticleStateBase>;
    private var _animatorParticleStates:Vector<ParticleStateBase>;
    private var _timeParticleStates:Vector<ParticleStateBase>;
    private var _totalLenOfOneVertex:Int;
    private var _animatorSubGeometries:ObjectMap<ISubGeometry, AnimationSubGeometry>;
/**
	 * Creates a new <code>ParticleAnimator</code> object.
	 *
	 * @param particleAnimationSet The animation data set containing the particle animations used by the animator.
	 */

    public function new(particleAnimationSet:ParticleAnimationSet) {
        _animationParticleStates = new Vector<ParticleStateBase>();
        _animatorParticleStates = new Vector<ParticleStateBase>();
        _timeParticleStates = new Vector<ParticleStateBase>();
        _totalLenOfOneVertex = 0;
        _animatorSubGeometries = new ObjectMap<ISubGeometry, AnimationSubGeometry>();
        super(particleAnimationSet);
        _particleAnimationSet = particleAnimationSet;
        var state:ParticleStateBase;
        var node:ParticleNodeBase;
        for (i in 0..._particleAnimationSet.particleNodes.length) {
            node = _particleAnimationSet.particleNodes[i];
            state = cast(getAnimationState(node), ParticleStateBase) ;
            if (node.mode == ParticlePropertiesMode.LOCAL_DYNAMIC) {
                _animatorParticleStates.push(state);
                node.dataOffset = _totalLenOfOneVertex;
                _totalLenOfOneVertex += node.dataLength;
            }

            else _animationParticleStates.push(state);
            if (state.needUpdateTime) _timeParticleStates.push(state);
        }

    }

/**
	 * @inheritDoc
	 */

    public function clone():IAnimator {
        return new ParticleAnimator(_particleAnimationSet);
    }

/**
	 * @inheritDoc
	 */

    public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:Int, vertexStreamOffset:Int, camera:Camera3D):Void {
        var animationRegisterCache:AnimationRegisterCache = _particleAnimationSet._animationRegisterCache;
        var subMesh:SubMesh = cast(renderable, SubMesh) ;
        var state:ParticleStateBase;
        if (subMesh == null) throw (new Error("Must be subMesh"));
        if (subMesh.animationSubGeometry == null) _particleAnimationSet.generateAnimationSubGeometries(subMesh.parentMesh);
        var animationSubGeometry:AnimationSubGeometry = subMesh.animationSubGeometry;
        for (state in _animationParticleStates)state.setRenderState(stage3DProxy, renderable, animationSubGeometry, animationRegisterCache, camera);
//process animator subgeometries
        if (subMesh.animatorSubGeometry == null && _animatorParticleStates.length > 0) generateAnimatorSubGeometry(subMesh);
        var animatorSubGeometry:AnimationSubGeometry = subMesh.animatorSubGeometry;
        for (state in _animatorParticleStates)state.setRenderState(stage3DProxy, renderable, animatorSubGeometry, animationRegisterCache, camera);
        stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, animationRegisterCache.vertexConstantOffset, animationRegisterCache.vertexConstantData, animationRegisterCache.numVertexConstant);
        if (animationRegisterCache.numFragmentConstant > 0) stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, animationRegisterCache.fragmentConstantOffset, animationRegisterCache.fragmentConstantData, animationRegisterCache.numFragmentConstant);
    }

/**
	 * @inheritDoc
	 */

    public function testGPUCompatibility(pass:MaterialPassBase):Void {
    }

/**
	 * @inheritDoc
	 */

    override public function start():Void {
        super.start();
        for (state in _timeParticleStates)state.offset(_absoluteTime);
    }

/**
	 * @inheritDoc
	 */

    override private function updateDeltaTime(dt:Int):Void {
        _absoluteTime += dt;
        for (state in _timeParticleStates)state.update(_absoluteTime);
    }

/**
	 * @inheritDoc
	 */

    public function resetTime(offset:Int = 0):Void {
        for (state in _timeParticleStates)state.offset(_absoluteTime + offset);
        update(time);
    }

    override public function dispose():Void {
        var subGeometry:AnimationSubGeometry;
        for (subGeometry in _animatorSubGeometries)subGeometry.dispose();
    }

    private function generateAnimatorSubGeometry(subMesh:SubMesh):Void {
        var subGeometry:ISubGeometry = subMesh.subGeometry;
        _animatorSubGeometries.set(subGeometry, new AnimationSubGeometry());
        var animatorSubGeometry:AnimationSubGeometry = subMesh.animatorSubGeometry = _animatorSubGeometries.get(subGeometry) ;
//create the vertexData vector that will be used for local state data
        animatorSubGeometry.createVertexData(subGeometry.numVertices, _totalLenOfOneVertex);
//pass the particles data to the animator subGeometry
        animatorSubGeometry.animationParticles = subMesh.animationSubGeometry.animationParticles;
    }

}

