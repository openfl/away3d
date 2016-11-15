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

import away3d.materials.TextureMaterial;
import openfl.geom.Rectangle;
import openfl.Vector;

/** The BitmapFont class parses bitmap font files and arranges the glyphs
 *  in the form of a text.
 *
 *  The class parses the Xml format as it is used in the 
 *  <a href="http://www.angelcode.com/products/bmfont/">AngelCode Bitmap Font Generator</a> or
 *  the <a href="http://glyphdesigner.71squared.com/">Glyph Designer</a>. 
 *  This is what the file format looks like:
 *
 *  <pre> 
 *  &lt;font&gt;
 *	&lt;info face="BranchingMouse" size="40" /&gt;
 *	&lt;common lineHeight="40" /&gt;
 *	&lt;pages&gt;  &lt;!-- currently, only one page is supported --&gt;
 *	  &lt;page id="0" file="texture.png" /&gt;
 *	&lt;/pages&gt;
 *	&lt;chars&gt;
 *	  &lt;char id="32" x="60" y="29" width="1" height="1" xoffset="0" yoffset="27" xadvance="8" /&gt;
 *	  &lt;char id="33" x="155" y="144" width="9" height="21" xoffset="0" yoffset="6" xadvance="9" /&gt;
 *	&lt;/chars&gt;
 *	&lt;kernings&gt; &lt;!-- Kerning is optional --&gt;
 *	  &lt;kerning first="83" second="83" amount="-4"/&gt;
 *	&lt;/kernings&gt;
 *  &lt;/font&gt;
 *  </pre>
 *  
 *  Pass an instance of this class to the method <code>registerBitmapFont</code> of the
 *  TextField class. Then, set the <code>fontName</code> property of the text field to the 
 *  <code>name</code> value of the bitmap font. This will make the text field use the bitmap
 *  font.  
 */

class BitmapFont
{
	/** Use this constant for the <code>fontSize</code> property of the TextField class to 
	 *  render the bitmap font in exactly the size it was created. */ 
	public static var NATIVE_SIZE:Int = -1;
	
	/** The font name of the embedded minimal bitmap font. Use this e.g. for debug output. */
	public static var MINI:String = "mini";
	
	private static var CHAR_SPACE:Int		   = 32;
	private static var CHAR_TAB:Int			 =  9;
	private static var CHAR_NEWLINE:Int		 = 10;
	private static var CHAR_CARRIAGE_RETURN:Int = 13;
	
	private var mFontMaterial:TextureMaterial;
	private var mChars:Map<Int, BitmapChar>;
	private var mName:String;
	private var mSize:Float;
	private var mLineHeight:Float;
	private var mBaseline:Float;
	private var mOffsetX:Float;
	private var mOffsetY:Float;

	/** Helper objects. */
	private static var sLines = new Vector<Vector<CharLocation>>();
	
	/** Creates a bitmap font by parsing an Xml file and uses the specified texture. 
	 *  If you don't pass any data, the "mini" font will be created. */
	public function new(texture:TextureMaterial=null, fontXml:Xml=null)
	{
		// if no texture is passed in, we create the minimal, embedded font
		if (texture == null && fontXml == null)
		{
			texture = MiniBitmapFont.texture;
			fontXml = MiniBitmapFont.xml;
		}
		
		mName = "unknown";
		mLineHeight = mSize = mBaseline = 14;
		mOffsetX = mOffsetY = 0.0;
		mFontMaterial = texture;
		mChars = new Map<Int, BitmapChar>();

		parseFontXml(fontXml);
	}
	
	/** Disposes the texture of the bitmap font! */
	public function dispose():Void
	{
		if (mFontMaterial != null)
			mFontMaterial.dispose();
	}
	
	private function parseFontXml(fontXml:Xml):Void
	{
		var frameX:Float = 0;
		var frameY:Float = 0;
		var scale:Float = 1;
		
		for (font in fontXml.elementsNamed("font")) {
			
			if (font.nodeType == Xml.Element ) {
				for (info in font.elementsNamed("info")) {
					if (info.nodeType == Xml.Element ) {
						mName = info.get("face");
						mSize = Std.parseFloat(info.get("size")) / scale;
					}
				}
				for (common in font.elementsNamed("common")) {
					if (common.nodeType == Xml.Element ) {
						mLineHeight = Std.parseFloat(common.get("lineHeight")) / scale;
						mBaseline = Std.parseFloat(common.get("base")) / scale;
					}
				}
				for (chars in font.elementsNamed("chars")) {
					if (chars.nodeType == Xml.Element ) {
						for (char in chars.elementsNamed("char")) {
							if (char.nodeType == Xml.Element ) {
								
								var id:Int = Std.parseInt(char.get("id"));
								
								var xOffset:Float  = Std.parseFloat(char.get("xoffset"))  / scale;
								var yOffset:Float  = Std.parseFloat(char.get("yoffset"))  / scale;
								var xAdvance:Float = Std.parseFloat(char.get("xadvance")) / scale;
								
								var region:Rectangle = new Rectangle();
								region.x = Std.parseFloat(char.get("x")) / scale + frameX;
								region.y = Std.parseFloat(char.get("y")) / scale + frameY;
								region.width  = Std.parseFloat(char.get("width"))  / scale;
								region.height = Std.parseFloat(char.get("height")) / scale;
								
								var bitmapChar:BitmapChar = new BitmapChar(id, region.x, region.y, region.width, region.height, xOffset, yOffset, xAdvance);
								addChar(id, bitmapChar);
							}
						}
					}
				}
				for (kernings in font.elementsNamed("kernings")) {
					if (kernings.nodeType == Xml.Element ) {
						for (kerning in kernings.elementsNamed("kerning")) {
							if (kerning.nodeType == Xml.Element ) {
								
								var first:Int  = Std.parseInt(kerning.get("first"));
								var second:Int = Std.parseInt(kerning.get("second"));
								var amount:Float = Std.parseFloat(kerning.get("amount")) / scale;
								if (mChars.exists(second)) {
									getChar(second).addKerning(first, amount);
								}
							}
						}
					}
				}
			}
		}
	}
	
	/** Returns a single bitmap char with a certain character ID. */
	public function getChar(charID:Int):BitmapChar
	{
		return mChars[charID];   
	}
	
	/** Adds a bitmap char with a certain character ID. */
	public function addChar(charID:Int, bitmapChar:BitmapChar):Void
	{
		mChars[charID] = bitmapChar;
	}
	
	/** Returns a vector containing all the character IDs that are contained in this font. */
	public function getCharIDs(result:Vector<Int>=null):Vector<Int>
	{
		if (result == null) result = new Vector<Int>();
		
		var keys = mChars.keys();
		for (k in keys) {
			var key:Int = k;
			result[result.length] = key;
		}
		
		return result;
	}

	/** Checks whether a provided string can be displayed with the font. */
	public function hasChars(text:String):Bool
	{
		if (text == null) return true;

		var charID:Int;
		var numChars:Int = text.length;

		for (i in 0...numChars)
		{
			charID = text.charCodeAt(i);

			if (charID != CHAR_SPACE && charID != CHAR_TAB && charID != CHAR_NEWLINE &&
				charID != CHAR_CARRIAGE_RETURN && getChar(charID) == null)
			{
				return false;
			}
		}

		return true;
	}

	/** Draws text into a Geometry. */
	public function fillBatched(data:Vector<Float>, indices:Vector<UInt>, width:Float, height:Float, text:String,
								  fontSize:Float=-1,
								  hAlign:String="center", vAlign:String="center",
								  autoScale:Bool=true, 
								  kerning:Bool = true,
								  letterSpacing:Float=0):Void
	{
		var charLocations:Vector<CharLocation> = arrangeChars(width, height, text, fontSize, 
															   hAlign, vAlign, autoScale, kerning, letterSpacing);
		data.length = 0;
		indices.length = 0;
		
		var k:Int = 0;
		var indicesCount:Int = 0;
		var numChars:Int = charLocations.length;
		
		for (i in 0...numChars)
		{
			indices[indicesCount++] = i*4;
			indices[indicesCount++] = i*4+1;
			indices[indicesCount++] = i*4+2;

			indices[indicesCount++] = i*4;
			indices[indicesCount++] = i*4+2;
			indices[indicesCount++] = i*4+3;

			var charLocation:CharLocation = charLocations[i];

			var x:Float = charLocation.x;
			var y:Float = charLocation.y;
			var scale:Float = charLocation.scale;
			var char:BitmapChar = charLocation.char;
			var width:Float = char.width*scale;
			var height:Float = char.height*scale;

			var u1:Float = char.x/mFontMaterial.texture.width;
			var u2:Float = (char.x+char.width)/mFontMaterial.texture.width;
			var v1:Float = char.y/mFontMaterial.texture.height;
			var v2:Float = (char.y+char.height)/mFontMaterial.texture.height;

			//1
			data[k++] = x;
			data[k++] = 0;
			data[k++] = y+height;
			//n
			data[k++] = 0;
			data[k++] = 0;
			data[k++] = 0;
			//t
			data[k++] = 0;
			data[k++] = 0;
			data[k++] = 0;
			//uv
			data[k++] = u1;
			data[k++] = v2;
			//seconduv
			data[k++] = 0;
			data[k++] = 0;

			//2
			data[k++] = x;
			data[k++] = 0;
			data[k++] = y;
			//n
			data[k++] = 0;
			data[k++] = 0;
			data[k++] = 0;
			//t
			data[k++] = 0;
			data[k++] = 0;
			data[k++] = 0;
			//uv
			data[k++] = u1;
			data[k++] = v1;
			//seconduv
			data[k++] = 0;
			data[k++] = 0;

			//3
			data[k++] = x+width;
			data[k++] = 0;
			data[k++] = y;
			//n
			data[k++] = 0;
			data[k++] = 0;
			data[k++] = 0;
			//t
			data[k++] = 0;
			data[k++] = 0;
			data[k++] = 0;
			//uv
			data[k++] = u2;
			data[k++] = v1;
			//seconduv
			data[k++] = 0;
			data[k++] = 0;

			//4
			data[k++] = x+width;
			data[k++] = 0;
			data[k++] = y+height;
			//n
			data[k++] = 0;
			data[k++] = 0;
			data[k++] = 0;
			//t
			data[k++] = 0;
			data[k++] = 0;
			data[k++] = 0;
			//uv
			data[k++] = u2;
			data[k++] = v2;
			//seconduv
			data[k++] = 0;
			data[k++] = 0;
		}
		
		CharLocation.rechargePool();
	}
	
	public function getMaterialClone():TextureMaterial 
	{
		return new TextureMaterial(mFontMaterial.texture, mFontMaterial.smooth, mFontMaterial.repeat, mFontMaterial.mipmap);
	}
	
	/** Arranges the characters of a text inside a rectangle, adhering to the given settings. 
	 *  Returns a Vector of CharLocations. */
	private function arrangeChars(width:Float, height:Float, text:String, fontSize:Float=-1,
								  hAlign:String="center", vAlign:String="center",
								  autoScale:Bool=true, kerning:Bool=true, letterSpacing:Float=0):Vector<CharLocation>
	{
		if (hAlign == null) hAlign = HAlign.CENTER;
		if (vAlign == null) vAlign = VAlign.CENTER;
		
		if (text == null || text.length == 0) return CharLocation.vectorFromPool();
		if (fontSize < 0) fontSize *= -mSize;
		
		var finished:Bool = false;
		var charLocation:CharLocation;
		var numChars:Int;
		var containerWidth:Float = 0;
		var containerHeight:Float = 0;
		var scale:Float = 1;
		
		var currentX:Float = 0;
		var currentY:Float = 0;
		
		while (!finished)
		{
			sLines = new Vector<Vector<CharLocation>>();
			
			scale = fontSize / mSize;
			containerWidth  = width / scale;
			containerHeight = height / scale;
			
			if (mLineHeight <= containerHeight)
			{
				var lastWhiteSpace:Int = -1;
				var lastCharID:Int = -1;
				currentX = 0;
				currentY = 0;
				var currentLine:Vector<CharLocation> = CharLocation.vectorFromPool();
				
				numChars = text.length;
				for (i in 0...numChars) 
				{
					var lineFull:Bool = false;
					var charID:Int = text.charCodeAt(i);
					var char:BitmapChar = getChar(charID);
					
					if (charID == CHAR_NEWLINE || charID == CHAR_CARRIAGE_RETURN)
					{
						lineFull = true;
					}
					else if (char == null)
					{
						trace("[BitmapFont] Missing character: " + charID);
					}
					else
					{
						if (charID == CHAR_SPACE || charID == CHAR_TAB)
							lastWhiteSpace = i;
						
						if (kerning)
							currentX += char.getKerning(lastCharID);
						
						charLocation = CharLocation.instanceFromPool(char);
						charLocation.x = currentX + char.xOffset;
						charLocation.y = currentY + char.yOffset;
						currentLine[currentLine.length] = charLocation; // push
						
						currentX += char.xAdvance;
						lastCharID = charID;
						
						if (charLocation.x + char.width > containerWidth)
						{
							// when autoscaling, we must not split a word in half -> restart
							if (autoScale && lastWhiteSpace == -1)
								break;

							// remove characters and add them again to next line
							var numCharsToRemove:Int = lastWhiteSpace == -1 ? 1 : i - lastWhiteSpace;
							var removeIndex:Int = currentLine.length - numCharsToRemove;
							
							currentLine.splice(removeIndex, numCharsToRemove);
							
							if (currentLine.length == 0)
								break;
							
							//i -= numCharsToRemove;
							lineFull = true;
						}
					}
					
					if (i == numChars - 1)
					{
						sLines[sLines.length] = currentLine; // push
						finished = true;
					}
					else if (lineFull)
					{
						sLines[sLines.length] = currentLine; // push
						if (lastWhiteSpace == i)
							currentLine.pop();
						
						if (currentY + 2*mLineHeight <= containerHeight)
						{
							currentLine = CharLocation.vectorFromPool();
							currentX = 0;
							currentY += mLineHeight;
							lastWhiteSpace = -1;
							lastCharID = -1;
						}
						else
						{
							break;
						}
					}
				} // for each char
			} // if (mLineHeight <= containerHeight)
			
			if (autoScale && !finished && fontSize > 3)
				fontSize -= 1;
			else
				finished = true; 
		} // while (!finished)
		
		var finalLocations:Vector<CharLocation> = CharLocation.vectorFromPool();
		var numLines:Int = sLines.length;
		var bottom:Float = currentY + mLineHeight;
		var yOffset:Int = 0;
		
		if (vAlign == VAlign.BOTTOM)	  yOffset =  Std.int (containerHeight - bottom);
		else if (vAlign == VAlign.CENTER) yOffset = Std.int ((containerHeight - bottom) / 2);
		
		for (lineID in 0...numLines)
		{
			var line:Vector<CharLocation> = sLines[lineID];
			numChars = line.length;
			
			if (numChars == 0) continue;
			
			var xOffset:Int = 0;
			var lastLocation:CharLocation = line[line.length-1];
			var right:Float = lastLocation.x - lastLocation.char.xOffset 
											  + lastLocation.char.xAdvance;
			
			if (hAlign == HAlign.RIGHT)	   xOffset = Std.int (containerWidth - right);
			else if (hAlign == HAlign.CENTER) xOffset = Std.int ((containerWidth - right) / 2);
			
			for (c in 0...numChars)
			{
				charLocation = line[c];
				charLocation.x = scale * (charLocation.x + xOffset + mOffsetX);
				charLocation.y = scale * (charLocation.y + yOffset + mOffsetY);
				charLocation.scale = scale;
				
				if (charLocation.char.width > 0 && charLocation.char.height > 0)
					finalLocations[finalLocations.length] = charLocation;
			}
		}
		
		return finalLocations;
	}
	
	/** The name of the font as it was parsed from the font file. */
	public var name(get, null):String;
	private function get_name():String { return mName; }
	
	/** The native size of the font. */
	public var size(get, null):Float;
	private function get_size():Float { return mSize; }
	
	/** The height of one line in points. */
	public var lineHeight(get, set):Float;
	private function get_lineHeight():Float { return mLineHeight; }
	private function set_lineHeight(value:Float):Float { return mLineHeight = value; }

	/** The baseline of the font. This property does not affect text rendering;
	 *  it's just an information that may be useful for exact text placement. */
	public var baseline(get, set):Float;
	private function get_baseline():Float { return mBaseline; }
	private function set_baseline(value:Float):Float { return mBaseline = value; }
	
	/** An offset that moves any generated text along the x-axis (in points).
	 *  Useful to make up for incorrect font data. @default 0. */ 
	public var offsetX(get, set):Float;
	private function get_offsetX():Float { return mOffsetX; }
	private function set_offsetX(value:Float):Float { return mOffsetX = value; }
	
	/** An offset that moves any generated text along the y-axis (in points).
	 *  Useful to make up for incorrect font data. @default 0. */
	public var offsetY(get, set):Float;
	private function get_offsetY():Float { return mOffsetY; }
	private function set_offsetY(value:Float):Float { return mOffsetY = value; }

	/** The underlying texture that contains all the chars. */
	public var fontMaterial(get, null):TextureMaterial;
	private function get_fontMaterial():TextureMaterial { return mFontMaterial; }
}