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

/** A class that provides constant values for horizontal alignment of objects. */
class HAlign
{
	/** @private */
	@:allow(away3d) private function new() { throw new Error(); }
	
	/** Left alignment. */
	public static var LEFT:String   = "left";
	
	/** Centered alignement. */
	public static var CENTER:String = "center";
	
	/** Right alignment. */
	public static var RIGHT:String  = "right";
	
	/** Indicates whether the given alignment string is valid. */
	public static function isValid(hAlign:String):Bool
	{
		return hAlign == HAlign.LEFT || hAlign == HAlign.CENTER || hAlign == HAlign.RIGHT;
	}
}