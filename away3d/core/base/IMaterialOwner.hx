package away3d.core.base;

import away3d.animators.IAnimator;
import away3d.materials.MaterialBase;

/**
 * IMaterialOwner provides an interface for objects that can use materials.
 */
interface IMaterialOwner
{
	/**
	 * The material with which to render the object.
	 */
	var material(get, set):MaterialBase;
	
	/**
	 * The animation used by the material to assemble the vertex code.
	 */
	var animator(get, never):IAnimator; // in most cases, this will in fact be null
}