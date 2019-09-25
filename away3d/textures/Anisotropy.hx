package away3d.textures;

@:enum abstract Anisotropy(Null<Int>)
{
	public var NONE = 0;
	public var ANISOTROPIC2X = 1;
	public var ANISOTROPIC4X = 2;
	public var ANISOTROPIC8X = 3;
	public var ANISOTROPIC16X = 4;
	
	@:from private static function fromString (value:String):Anisotropy
	{
		return switch (value) {
			case "none": NONE;
			case "anisotropic2x": ANISOTROPIC2X;
			case "anisotropic4x": ANISOTROPIC4X;
			case "anisotropic8x": ANISOTROPIC8X;
			case "anisotropic16x": ANISOTROPIC16X;
			default: null;
			
		}
		
	}
	
	@:to private function toString ():String
	{
		return switch (cast this : Anisotropy) {
			case Anisotropy.NONE: "bool";
			case Anisotropy.ANISOTROPIC2X: "anisotropic2x";
			case Anisotropy.ANISOTROPIC4X: "anisotropic4x";
			case Anisotropy.ANISOTROPIC8X: "anisotropic8x";
			case Anisotropy.ANISOTROPIC16X: "anisotropic16x";
			default: null;
		}
		
	}
}