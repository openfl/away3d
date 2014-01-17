/**
 * IMaterialOwner provides an interface for objects that can use materials.
 */
package away3d.core.base;

import away3d.animators.IAnimator;
import away3d.materials.MaterialBase;

interface IMaterialOwner {
    var material(get_material, set_material):MaterialBase;
    var animator(get_animator, never):IAnimator;

/**
	 * The material with which to render the object.
	 */
    function get_material():MaterialBase;
    function set_material(value:MaterialBase):MaterialBase;
/**
	 * The animation used by the material to assemble the vertex code.
	 */
    function get_animator():IAnimator;
// in most cases, this will in fact be null
}

