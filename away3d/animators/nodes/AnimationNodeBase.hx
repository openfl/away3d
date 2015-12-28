/**
 * Provides an abstract base class for nodes in an animation blend tree.
 */
package away3d.animators.nodes;

import away3d.animators.states.IAnimationState;
import away3d.library.assets.Asset3DType;
import away3d.library.assets.NamedAssetBase;
import away3d.library.assets.IAsset;

class AnimationNodeBase extends NamedAssetBase implements IAsset {
    public var stateClass(get, never):Class<IAnimationState>;
    public var assetType(get, never):String;

    private var _stateClass:Class<IAnimationState>;

    private function get_stateClass():Class<IAnimationState> {
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
    private function get_assetType():String {
        return Asset3DType.ANIMATION_NODE;
    }
}

