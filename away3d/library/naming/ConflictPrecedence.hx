package away3d.library.naming;

/**
 * Enumaration class for precedence when resolving naming conflicts in the library.
 *
 * @see away3d.library.Asset3DLibrary.conflictPrecedence
 * @see away3d.library.Asset3DLibrary.conflictStrategy
 * @see away3d.library.naming.ConflictStrategy
 */
class ConflictPrecedence
{
	/**
	 * Signals that in a conflict, the previous owner of the conflicting name
	 * should be favored (and keep it's name) and that the newly renamed asset
	 * is reverted to a non-conflicting name.
	 */
	public static inline var FAVOR_OLD:String = "favorOld";
	
	/**
	 * Signales that in a conflict, the newly renamed asset is favored (and keeps
	 * it's newly defined name) and that the previous owner of that name gets
	 * renamed to a non-conflicting name.
	 */
	public static inline var FAVOR_NEW:String = "favorNew";
}