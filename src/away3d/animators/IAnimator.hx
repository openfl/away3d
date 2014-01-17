/**
 * Provides an interface for animator classes that control animation output from a data set subtype of <code>AnimationSetBase</code>.
 *
 * @see away3d.animators.IAnimationSet
 */
package away3d.animators;
import away3d.animators.states.AnimationStateBase;
import away3d.animators.nodes.AnimationNodeBase;
import away3d.entities.Mesh;
import away3d.core.managers.Stage3DProxy;
import away3d.core.base.IRenderable;
import away3d.cameras.Camera3D;
import away3d.materials.passes.MaterialPassBase;

interface IAnimator {
    var animationSet(get_animationSet, never):IAnimationSet;

/**
	 * Returns the animation data set in use by the animator.
	 */
    function get_animationSet():IAnimationSet;
/**
	 * Sets the GPU render state required by the animation that is dependent of the rendered object.
	 *
	 * @param stage3DProxy The Stage3DProxy object which is currently being used for rendering.
	 * @param renderable The object currently being rendered.
	 * @param vertexConstantOffset The first available vertex register to write data to if running on the gpu.
	 * @param vertexStreamOffset The first available vertex stream to write vertex data to if running on the gpu.
	 */
    function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:Int, vertexStreamOffset:Int, camera:Camera3D):Void;
    function testGPUCompatibility(pass:MaterialPassBase):Void;
/**
	 * Used by the mesh object to which the animator is applied, registers the owner for internal use.
	 *
	 * @private
	 */
    function addOwner(mesh:Mesh):Void;
    function removeOwner(mesh:Mesh):Void;
    function getAnimationState(node:AnimationNodeBase):AnimationStateBase;
    function getAnimationStateByName(name:String):AnimationStateBase;
/**
	 * Returns a shallow clone (re-using the same IAnimationSet) of this IAnimator.
	 */
    function clone():IAnimator;
    function dispose():Void;
}

