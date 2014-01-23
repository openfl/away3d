/**
 * Provides an abstract base class for nodes in an animation blend tree.
 */
package away3d.animators.nodes;

import away3d.animators.states.IAnimationState;
import away3d.library.assets.AssetType;
import away3d.library.assets.NamedAssetBase;
import away3d.library.assets.IAsset;

class AnimationNodeBase extends NamedAssetBase implements IAsset {
    public var stateClass(get_stateClass, never):Class<IAnimationState>;
    public var assetType(get_assetType, never):String;

    private var _stateClass:Class<IAnimationState>;

    public function get_stateClass():Class<IAnimationState> {
        return _stateClass;
    }

/**
	 * Creates a new <code>AnimationNodeBase</code> object.
	 */

    public function new() {
        super();
    }

/**
	 * @inheritDoc
	 */

    public function dispose():Void {
    }

/**
	 * @inheritDoc
	 */

    public function get_assetType():String {
        return AssetType.ANIMATION_NODE;
    }

}

