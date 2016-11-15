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


/** A BitmapChar contains the information about one char of a bitmap font.  
 *  <em>You don't have to use this class directly in most cases. 
 *  The TextField class contains methods that handle bitmap fonts for you.</em>	
 */ 
class BitmapChar
{
	private var mCharID:Int;
	private var mXOffset:Float;
	private var mYOffset:Float;
	private var mXAdvance:Float;
	private var mKernings:Map<Int, Float>;

	private var mX:Float;
	private var mY:Float;
	private var mWidth:Float;
	private var mHeight:Float;

	/** Creates a char with a texture and its properties. */
	public function new(id:Int, x:Float, y:Float, width:Float, height:Float, xOffset:Float, yOffset:Float, xAdvance:Float)
	{
		mCharID = id;
		mXOffset = xOffset;
		mYOffset = yOffset;
		mXAdvance = xAdvance;
		mKernings = null;
		mX = x;
		mY = y;
		mWidth = width;
		mHeight = height;
	}
	
	/** Adds kerning information relative to a specific other character ID. */
	public function addKerning(charID:Int, amount:Float):Void
	{
		if (mKernings == null)
			mKernings = new Map<Int, Float>();
		
		mKernings[charID] = amount;
	}
	
	/** Retrieve kerning information relative to the given character ID. */
	public function getKerning(charID:Int):Float
	{
		if (mKernings == null || mKernings.get(charID) == null) return 0.0;
		else return mKernings[charID];
	}

	
	/** The unicode ID of the char. */
	public var charID(get, null):Int;
	private function get_charID():Int { return mCharID; }
	
	/** The number of points to move the char in x direction on character arrangement. */
	public var xOffset(get, null):Float;
	private function get_xOffset():Float { return mXOffset; }
	
	/** The number of points to move the char in y direction on character arrangement. */
	public var yOffset(get, null):Float;
	private function get_yOffset():Float { return mYOffset; }
	
	/** The number of points the cursor has to be moved to the right for the next char. */
	public var xAdvance(get, null):Float;
	private function get_xAdvance():Float { return mXAdvance; }
	
	/** The width of the character in points. */
	public var width(get, null):Float;
	private function get_width():Float { return mWidth; }
	
	/** The height of the character in points. */
	public var height(get, null):Float;
	private function get_height():Float { return mHeight; }
	
	public var x(get, null):Float;
	private function get_x():Float { return mX; }
	
	public var y(get, null):Float;
	private function get_y():Float { return mY; }
}