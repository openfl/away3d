// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package away3d.textfield;

import openfl.errors.Error;

/** A class that provides constant values for vertical alignment of objects. */
class VAlign
{
	/** @private */
	@:allow(away3d) private function new() { throw new Error(); }
	
	/** Top alignment. */
	public static var TOP:String = "top";
	
	/** Centered alignment. */
	public static var CENTER:String = "center";
	
	/** Bottom alignment. */
	public static var BOTTOM:String = "bottom";
	
	/** Indicates whether the given alignment string is valid. */
	public static function isValid(vAlign:String):Bool
	{
		return vAlign == VAlign.TOP || vAlign == VAlign.CENTER || vAlign == VAlign.BOTTOM;
	}
}