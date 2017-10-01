package away3d.animators.nodes;

import away3d.animators.AnimatorBase;
import away3d.animators.states.IAnimationState;
import away3d.library.assets.*;

/**
 * Provides an abstract base class for nodes in an animation blend tree.
 */
class AnimationNodeBase extends NamedAssetBase implements IAsset
{
	public var stateConstructor(get, never):IAnimator -> AnimationNodeBase -> IAnimationState;
	public var assetType(get, never):String;
	
	private var _stateConstructor:IAnimator -> AnimationNodeBase -> IAnimationState;
	
	private function get_stateConstructor():IAnimator -> AnimationNodeBase -> IAnimationState
	{
		return _stateConstructor;
	}
	
	/**
	 * Creates a new <code>AnimationNodeBase</code> object.
	 */
	public function new()
	{
		super();
	}
	
	/**
	 * @inheritDoc
	 */
	public function dispose():Void
	{
	}
	
	/**
	 * @inheritDoc
	 */
	private function get_assetType():String
	{
		return Asset3DType.ANIMATION_NODE;
	}
}