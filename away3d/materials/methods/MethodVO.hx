package away3d.materials.methods;

import away3d.textures.Anisotropy;

import openfl.Vector;

/**
 * MethodVO contains data for a given method for the use within a single material.
 * This allows methods to be shared across materials while their non-public state differs.
 */
class MethodVO
{
	public var vertexData:Vector<Float>;
	public var fragmentData:Vector<Float>;
	
	// public register indices
	public var texturesIndex:Int;
	public var secondaryTexturesIndex:Int; // sometimes needed for composites
	public var vertexConstantsIndex:Int;
	public var secondaryVertexConstantsIndex:Int; // sometimes needed for composites
	public var fragmentConstantsIndex:Int;
	public var secondaryFragmentConstantsIndex:Int; // sometimes needed for composites
	
	public var useMipmapping:Bool;
	public var useSmoothTextures:Bool;
	public var repeatTextures:Bool;
	
	public var anisotropy:Anisotropy;
	
	// internal stuff for the material to know before assembling code
	public var needsProjection:Bool;
	public var needsView:Bool;
	public var needsNormals:Bool;
	public var needsTangents:Bool;
	public var needsUV:Bool;
	public var needsSecondaryUV:Bool;
	public var needsGlobalVertexPos:Bool;
	public var needsGlobalFragmentPos:Bool;
	
	public var numLights:Int;
	public var useLightFallOff:Bool = true;

	/**
	 * Creates a new MethodVO object.
	 */
	public function new()
	{
	
	}

	/**
	 * Resets the values of the value object to their "unused" state.
	 */
	public function reset():Void
	{
		texturesIndex = -1;
		vertexConstantsIndex = -1;
		fragmentConstantsIndex = -1;
		
		useMipmapping = true;
		anisotropy = Anisotropy.ANISOTROPIC2X;
		useSmoothTextures = true;
		repeatTextures = false;
		
		needsProjection = false;
		needsView = false;
		needsNormals = false;
		needsTangents = false;
		needsUV = false;
		needsSecondaryUV = false;
		needsGlobalVertexPos = false;
		needsGlobalFragmentPos = false;
		
		numLights = 0;
		useLightFallOff = true;
	}
}