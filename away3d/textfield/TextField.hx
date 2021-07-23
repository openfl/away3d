package away3d.textfield;

import away3d.core.base.CompactSubGeometry;
import away3d.core.base.Geometry;
import away3d.entities.Mesh;
import away3d.materials.methods.ColorTransformMethod;
import away3d.materials.SinglePassMaterialBase;
import away3d.materials.TextureMaterial;
import openfl.display.DisplayObjectContainer;
import openfl.geom.ColorTransform;
import openfl.geom.Rectangle;
import openfl.text.TextFieldAutoSize;
import openfl.Vector;


class TextField extends Mesh {
	
	private var vertexData:Vector<Float> = new Vector<Float>();
	private var indexData:Vector<UInt> = new Vector<UInt>();
	private var mText:String = "";
	private var mBitmapFont:BitmapFont;
	private var mFontSize:Float;
	private var mColor:UInt;
	private var mHAlign:String;
	private var mVAlign:String;
	private var mBold:Bool;
	private var mItalic:Bool;
	private var mUnderline:Bool;
	private var mAutoScale:Bool;
	private var mAutoSize:TextFieldAutoSize;
	private var mKerning:Bool;
	private var mLetterSpacing:Float = 0;
	private var mBorder:DisplayObjectContainer;
	public var mWidth:Float;
	public var mHeight:Float;
	
	public var disposeMaterial:Bool = true;
	
	private var _boundsRect:Rectangle = new Rectangle();
	
	private var _textHeight:Float;
	private var _textWidth:Float;
	
	private var _subGeometry:CompactSubGeometry;
	private var colorTransformMethod:ColorTransformMethod;
	private var textureMaterial:TextureMaterial;
	
	public function new(width:Float, height:Float, text:String, bitmapFont:BitmapFont, fontSize:Float = 12, color:UInt = 0x0, bold:Bool = false, _hAlign:String="left") {
		super(new Geometry(), bitmapFont.fontMaterial);
		
		mText = text;
		mBitmapFont = bitmapFont;
		
		mWidth = width;
		mHeight = height;
		mFontSize = fontSize;
		mColor = color;
		mHAlign = _hAlign;
		mVAlign = VAlign.TOP;
		mBorder = null;
		mKerning = true;
		mBold = bold;
		mAutoSize = TextFieldAutoSize.NONE;
		_subGeometry = new CompactSubGeometry();
		_subGeometry.autoDeriveVertexNormals = true;
		_subGeometry.autoDeriveVertexTangents = true;
		geometry.addSubGeometry(_subGeometry);
		
		textureMaterial = bitmapFont.fontMaterial;
		var rgb:Vector<UInt> = HexToRGB(color);
		if (textureMaterial.colorTransform == null) {
			textureMaterial.colorTransform = new ColorTransform();
		}
		textureMaterial.colorTransform.redMultiplier = rgb[0] / 255;
		textureMaterial.colorTransform.greenMultiplier = rgb[1] / 255;
		textureMaterial.colorTransform.blueMultiplier = rgb[2] / 255;
		textureMaterial.colorTransform.alphaMultiplier = textureMaterial.alpha;
		
		material = textureMaterial;
		
		material.alphaPremultiplied = true;
		var castMat:SinglePassMaterialBase = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(material, SinglePassMaterialBase) ? cast material : null;
		if (castMat != null) {
			castMat.alphaBlending = true;
		}
		
		updateText();
	}
	
	public function HexToRGB(hex:UInt):Vector<UInt>
	{
		var rgb = new Vector<UInt>();
		var r:UInt = hex >> 16 & 0xFF;
		var g:UInt = hex >> 8 & 0xFF;
		var b:UInt = hex & 0xFF;
		rgb.push(r);
		rgb.push(g);
		rgb.push(b);
		return rgb;
	}

	override public function dispose():Void {
		if(disposeMaterial)material.dispose();
		super.dispose();
	}

	private function updateText():Void {
		
		mBitmapFont.fillBatched(vertexData, indexData, mWidth, mHeight, mText, mFontSize, mHAlign, mVAlign, mAutoScale, mKerning, mLetterSpacing);
		
		_subGeometry.updateData(vertexData);
		_subGeometry.updateIndexData(indexData);
	}


	/** Indicates whether the text is bold. @default false */
	public var bold(get, set):Bool;
	private function get_bold():Bool {
		return mBold;
	}

	private function set_bold(value:Bool):Bool {
		if (mBold != value) {
			mBold = value;
			updateText();
		}
		return value;
	}

	/** Indicates whether the text is italicized. @default false */
	public var italic(get, set):Bool;
	private function get_italic():Bool {
		return mItalic;
	}

	private function set_italic(value:Bool):Bool {
		if (mItalic != value) {
			mItalic = value;
			updateText();
		}
		return value;
	}

	/** Indicates whether the text is underlined. @default false */
	public var underline(get, set):Bool;
	private function get_underline():Bool {
		return mUnderline;
	}

	private function set_underline(value:Bool):Bool {
		if (mUnderline != value) {
			mUnderline = value;
			updateText();
		}
		return value;
	}

	/** Indicates whether kerning is enabled. @default true */
	public var kerning(get, set):Bool;
	private function get_kerning():Bool {
		return mKerning;
	}

	private function set_kerning(value:Bool):Bool {
		if (mKerning != value) {
			mKerning = value;
			updateText();
		}
		return value;
	}


	/** A number representing the amount of space that is uniformly distributed between all characters.
	 * The value specifies the number of pixels that are added to the advance after each character.
	 * The default value is null, which means that 0 pixels of letter spacing is used.
	 * You can use decimal values such as 1.75. @default 0 */
	public var letterSpacing(get, set):Float;
	private function get_letterSpacing():Float {
		return mLetterSpacing;
	}

	private function set_letterSpacing(value:Float):Float {
		if (mLetterSpacing != value) {
			mLetterSpacing = value;
			updateText();
		}
		return value;
	}

	/** Indicates whether the font size is scaled down so that the complete text fits
	 *  into the text field. @default false */
	public var autoScale(get, set):Bool;
	private function get_autoScale():Bool {
		return mAutoScale;
	}

	private function set_autoScale(value:Bool):Bool {
		if (mAutoScale != value) {
			mAutoScale = value;
			updateText();
		}
		return value;
	}

	/** Specifies the type of auto-sizing the TextField will do.
	 *  Note that any auto-sizing will make auto-scaling useless. Furthermore, it has
	 *  implications on alignment: horizontally auto-sized text will always be left-,
	 *  vertically auto-sized text will always be top-aligned. @default "none" */
	public var autoSize(get, set):TextFieldAutoSize;
	private function get_autoSize():TextFieldAutoSize {
		return mAutoSize;
	}

	private function set_autoSize(value:TextFieldAutoSize):TextFieldAutoSize {
		if (mAutoSize != value) {
			mAutoSize = value;
			updateText();
		}
		return value;
	}
	
	public var textHeight(get, null):Float;
	private function get_textHeight():Float 
	{
		_textHeight = Math.abs(bounds.min.z - bounds.max.z);
		return _textHeight;
	}
	
	public var textWidth(get, null):Float;
	private function get_textWidth():Float 
	{
		_textWidth = Math.abs(bounds.min.x - bounds.max.x);
		return _textWidth;
	}
	
	public var boundsRect(get, null):Rectangle;
	private function get_boundsRect():Rectangle 
	{
		var minX:Float = bounds.min.x;
		var maxX:Float = bounds.max.x;
		
		var minY:Float = bounds.min.y;
		var maxY:Float = bounds.max.y;
		
		var minZ:Float = bounds.min.z;
		var maxZ:Float = bounds.max.z;
		
		_boundsRect.setTo(minX, minZ, maxX - minX, maxZ - minZ);
		return _boundsRect;
	}
	
	public var alpha(get, set):Float;
	private function get_alpha():Float 
	{
		return textureMaterial.colorTransform.alphaMultiplier;
	}
	
	private function set_alpha(value:Float):Float 
	{
		return textureMaterial.colorTransform.alphaMultiplier = value;
	}	
}