package away3d.loaders.parsers;

import away3d.animators.data.*;
import away3d.animators.nodes.*;
import away3d.core.math.*;

import openfl.errors.Error;
import openfl.geom.Vector3D;
import openfl.Vector;

// todo: create animation system, parse skeleton

/**
 * MD5AnimParser provides a parser for the md5anim data type, providing an animation sequence for the md5 format.
 *
 * todo: optimize
 */
class MD5AnimParser extends ParserBase
{
	private var _textData:String;
	private var _startedParsing:Bool;
	private static inline var VERSION_TOKEN:String = "MD5Version";
	private static inline var COMMAND_LINE_TOKEN:String = "commandline";
	private static inline var NUM_FRAMES_TOKEN:String = "numFrames";
	private static inline var NUM_JOINTS_TOKEN:String = "numJoints";
	private static inline var FRAME_RATE_TOKEN:String = "frameRate";
	private static inline var NUM_ANIMATED_COMPONENTS_TOKEN:String = "numAnimatedComponents";
	
	private static inline var HIERARCHY_TOKEN:String = "hierarchy";
	private static inline var BOUNDS_TOKEN:String = "bounds";
	private static inline var BASE_FRAME_TOKEN:String = "baseframe";
	private static inline var FRAME_TOKEN:String = "frame";
	
	private static inline var COMMENT_TOKEN:String = "//";
	
	private var _parseIndex:Int = 0;
	private var _reachedEOF:Bool;
	private var _line:Int = 0;
	private var _charLineIndex:Int = 0;
	private var _version:Int = 0;
	private var _frameRate:Int = 0;
	private var _numFrames:Int = 0;
	private var _numJoints:Int = 0;
	private var _numAnimatedComponents:Int = 0;
	
	private var _hierarchy:Vector<HierarchyData>;
	private var _bounds:Vector<BoundsData>;
	private var _frameData:Vector<FrameData>;
	private var _baseFrameData:Vector<BaseFrameData>;
	
	private var _rotationQuat:Quaternion;
	private var _clip:SkeletonClipNode;
	
	/**
	 * Creates a new MD5AnimParser object.
	 * @param uri The url or id of the data or file to be parsed.
	 * @param extra The holder for extra contextual data that the parser might need.
	 */
	public function new(additionalRotationAxis:Vector3D = null, additionalRotationRadians:Float = 0)
	{
		super(ParserDataFormat.PLAIN_TEXT);
		_rotationQuat = new Quaternion();
		var t1:Quaternion = new Quaternion();
		var t2:Quaternion = new Quaternion();
		
		t1.fromAxisAngle(Vector3D.X_AXIS, -Math.PI*.5);
		t2.fromAxisAngle(Vector3D.Y_AXIS, -Math.PI*.5);
		
		_rotationQuat.multiply(t2, t1);
		
		if (additionalRotationAxis != null) {
			_rotationQuat.multiply(t2, t1);
			t1.fromAxisAngle(additionalRotationAxis, additionalRotationRadians);
			_rotationQuat.multiply(t1, _rotationQuat);
		}
	}
	
	/**
	 * Indicates whether or not a given file extension is supported by the parser.
	 * @param extension The file extension of a potential file to be parsed.
	 * @return Whether or not the given file type is supported.
	 */
	public static function supportsType(extension:String):Bool
	{
		extension = extension.toLowerCase();
		return extension == "md5anim";
	}
	
	/**
	 * Tests whether a data block can be parsed by the parser.
	 * @param data The data block to potentially be parsed.
	 * @return Whether or not the given data is supported.
	 */
	public static function supportsData(data:Dynamic):Bool
	{
		return false;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function proceedParsing():Bool
	{
		var token:String;
		
		if (!_startedParsing) {
			_textData = getTextData();
			_startedParsing = true;
		}
		
		while (hasTime()) {
			token = getNextToken();
			switch (token) {
				case COMMENT_TOKEN:
					ignoreLine();
				case "":
					// can occur at the end of a file
				case VERSION_TOKEN:
					_version = getNextInt();
					if (_version != 10)
						throw new Error("Unknown version number encountered!");
				case COMMAND_LINE_TOKEN:
					parseCMD();
				case NUM_FRAMES_TOKEN:
					_numFrames = getNextInt();
					_bounds = new Vector<BoundsData>();
					_frameData = new Vector<FrameData>();
				case NUM_JOINTS_TOKEN:
					_numJoints = getNextInt();
					_hierarchy = new Vector<HierarchyData>(_numJoints, true);
					_baseFrameData = new Vector<BaseFrameData>(_numJoints, true);
				case FRAME_RATE_TOKEN:
					_frameRate = getNextInt();
				case NUM_ANIMATED_COMPONENTS_TOKEN:
					_numAnimatedComponents = getNextInt();
				case HIERARCHY_TOKEN:
					parseHierarchy();
				case BOUNDS_TOKEN:
					parseBounds();
				case BASE_FRAME_TOKEN:
					parseBaseFrame();
				case FRAME_TOKEN:
					parseFrame();
				default:
					if (!_reachedEOF)
						sendUnknownKeywordError();
			}
			
			if (_reachedEOF) {
				_clip = new SkeletonClipNode();
				translateClip();
				finalizeAsset(_clip);
				return ParserBase.PARSING_DONE;
			}
		}
		return ParserBase.MORE_TO_PARSE;
	}
	
	/**
	 * Converts all key frame data to an SkinnedAnimationSequence.
	 */
	private function translateClip():Void
	{
		for (i in 0..._numFrames)
			_clip.addFrame(translatePose(_frameData[i]), Std.int(1000/_frameRate));
	}
	
	/**
	 * Converts a single key frame data to a SkeletonPose.
	 * @param frameData The actual frame data.
	 * @return A SkeletonPose containing the frame data's pose.
	 */
	private function translatePose(frameData:FrameData):SkeletonPose
	{
		var hierarchy:HierarchyData;
		var pose:JointPose;
		var base:BaseFrameData;
		var flags:Int;
		var j:Int;
		var translate:Vector3D = new Vector3D();
		var orientation:Quaternion = new Quaternion();
		var components:Vector<Float> = frameData.components;
		var skelPose:SkeletonPose = new SkeletonPose();
		var jointPoses:Vector<JointPose> = skelPose.jointPoses;
		
		for (i in 0..._numJoints) {
			j = 0;
			pose = new JointPose();
			hierarchy = _hierarchy[i];
			base = _baseFrameData[i];
			flags = hierarchy.flags;
			translate.x = base.position.x;
			translate.y = base.position.y;
			translate.z = base.position.z;
			orientation.x = base.orientation.x;
			orientation.y = base.orientation.y;
			orientation.z = base.orientation.z;
			
			if ((flags & 1) != 0)
				translate.x = components[hierarchy.startIndex + (j++)];
			if ((flags & 2) != 0)
				translate.y = components[hierarchy.startIndex + (j++)];
			if ((flags & 4) != 0)
				translate.z = components[hierarchy.startIndex + (j++)];
			if ((flags & 8) != 0)
				orientation.x = components[hierarchy.startIndex + (j++)];
			if ((flags & 16) != 0)
				orientation.y = components[hierarchy.startIndex + (j++)];
			if ((flags & 32) != 0)
				orientation.z = components[hierarchy.startIndex + (j++)];
			
			var w:Float = 1 - orientation.x*orientation.x - orientation.y*orientation.y - orientation.z*orientation.z;
			orientation.w = w < 0? 0 : -Math.sqrt(w);
			
			if (hierarchy.parentIndex < 0) {
				pose.orientation.multiply(_rotationQuat, orientation);
				pose.translation = _rotationQuat.rotatePoint(translate);
			} else {
				pose.orientation.copyFrom(orientation);
				pose.translation.x = translate.x;
				pose.translation.y = translate.y;
				pose.translation.z = translate.z;
			}
			pose.orientation.y = -pose.orientation.y;
			pose.orientation.z = -pose.orientation.z;
			pose.translation.x = -pose.translation.x;
			
			jointPoses[i] = pose;
		}
		
		return skelPose;
	}
	
	/**
	 * Parses the skeleton's hierarchy data.
	 */
	private function parseHierarchy():Void
	{
		var ch:String;
		var data:HierarchyData;
		var token:String = getNextToken();
		var i:Int = 0;
		
		if (token != "{")
			sendUnknownKeywordError();
		
		do {
			if (_reachedEOF)
				sendEOFError();
			data = new HierarchyData();
			data.name = parseLiteralString();
			data.parentIndex = getNextInt();
			data.flags = getNextInt();
			data.startIndex = getNextInt();
			_hierarchy[i++] = data;
			
			ch = getNextChar();
			
			if (ch == "/") {
				putBack();
				ch = getNextToken();
				if (ch == COMMENT_TOKEN)
					ignoreLine();
				ch = getNextChar();
			}
			
			if (ch != "}")
				putBack();
			
		} while (ch != "}");
	}
	
	/**
	 * Parses frame bounds.
	 */
	private function parseBounds():Void
	{
		var ch:String;
		var data:BoundsData;
		var token:String = getNextToken();
		var i:Int = 0;
		
		if (token != "{")
			sendUnknownKeywordError();
		
		do {
			if (_reachedEOF)
				sendEOFError();
			data = new BoundsData();
			data.min = parseVector3D();
			data.max = parseVector3D();
			_bounds[i++] = data;
			
			ch = getNextChar();
			
			if (ch == "/") {
				putBack();
				ch = getNextToken();
				if (ch == COMMENT_TOKEN)
					ignoreLine();
				ch = getNextChar();
			}
			
			if (ch != "}")
				putBack();
			
		} while (ch != "}");
	}
	
	/**
	 * Parses the base frame.
	 */
	private function parseBaseFrame():Void
	{
		var ch:String;
		var data:BaseFrameData;
		var token:String = getNextToken();
		var i:Int = 0;
		
		if (token != "{")
			sendUnknownKeywordError();
		
		do {
			if (_reachedEOF)
				sendEOFError();
			data = new BaseFrameData();
			data.position = parseVector3D();
			data.orientation = parseQuaternion();
			_baseFrameData[i++] = data;
			
			ch = getNextChar();
			
			if (ch == "/") {
				putBack();
				ch = getNextToken();
				if (ch == COMMENT_TOKEN)
					ignoreLine();
				ch = getNextChar();
			}
			
			if (ch != "}")
				putBack();
			
		} while (ch != "}");
	}
	
	/**
	 * Parses a single frame.
	 */
	private function parseFrame():Void
	{
		var ch:String;
		var data:FrameData;
		var token:String;
		var frameIndex:Int;
		
		frameIndex = getNextInt();
		
		token = getNextToken();
		if (token != "{")
			sendUnknownKeywordError();
		
		do {
			if (_reachedEOF)
				sendEOFError();
			data = new FrameData();
			data.components = new Vector<Float>(_numAnimatedComponents, true);
			
			for (i in 0..._numAnimatedComponents)
				data.components[i] = getNextNumber();
			
			_frameData[frameIndex] = data;
			
			ch = getNextChar();
			
			if (ch == "/") {
				putBack();
				ch = getNextToken();
				if (ch == COMMENT_TOKEN)
					ignoreLine();
				ch = getNextChar();
			}
			
			if (ch != "}")
				putBack();
			
		} while (ch != "}");
	}
	
	/**
	 * Puts back the last read character into the data stream.
	 */
	private function putBack():Void
	{
		_parseIndex--;
		_charLineIndex--;
		_reachedEOF = _parseIndex >= _textData.length;
	}
	
	/**
	 * Gets the next token in the data stream.
	 */
	private function getNextToken():String
	{
		var ch:String;
		var token:String = "";
		
		while (!_reachedEOF) {
			ch = getNextChar();
			if (ch == " " || ch == "\r" || ch == "\n" || ch == "\t") {
				if (token != COMMENT_TOKEN)
					skipWhiteSpace();
				if (token != "")
					return token;
			} else
				token += ch;
			
			if (token == COMMENT_TOKEN)
				return token;
		}
		
		return token;
	}
	
	/**
	 * Skips all whitespace in the data stream.
	 */
	private function skipWhiteSpace():Void
	{
		var ch:String;
		
		do {
			ch = getNextChar();
		} while (ch == "\n" || ch == " " || ch == "\r" || ch == "\t");
		
		putBack();
	}
	
	/**
	 * Skips to the next line.
	 */
	private function ignoreLine():Void
	{
		var ch:String = null;
		while (!_reachedEOF && ch != "\n")
			ch = getNextChar();
	}
	
	/**
	 * Retrieves the next single character in the data stream.
	 */
	private function getNextChar():String
	{
		var ch:String = _textData.charAt(_parseIndex++);
		
		if (ch == "\n") {
			++_line;
			_charLineIndex = 0;
		} else if (ch != "\r")
			++_charLineIndex;
		
		if (_parseIndex == _textData.length)
			_reachedEOF = true;
		
		return ch;
	}
	
	/**
	 * Retrieves the next integer in the data stream.
	 */
	private function getNextInt():Int
	{
		var i:Int = Std.parseInt(getNextToken());
		if (Math.isNaN(i))
			sendParseError("int type");
		return i;
	}
	
	/**
	 * Retrieves the next floating point number in the data stream.
	 */
	private function getNextNumber():Float
	{
		var f:Float = Std.parseFloat(getNextToken());
		if (Math.isNaN(f))
			sendParseError("float type");
		return f;
	}
	
	/**
	 * Retrieves the next 3d vector in the data stream.
	 */
	private function parseVector3D():Vector3D
	{
		var vec:Vector3D = new Vector3D();
		var ch:String = getNextToken();
		
		if (ch != "(")
			sendParseError("(");
		vec.x = getNextNumber();
		vec.y = getNextNumber();
		vec.z = getNextNumber();
		
		if (getNextToken() != ")")
			sendParseError(")");
		
		return vec;
	}
	
	/**
	 * Retrieves the next quaternion in the data stream.
	 */
	private function parseQuaternion():Quaternion
	{
		var quat:Quaternion = new Quaternion();
		var ch:String = getNextToken();
		
		if (ch != "(")
			sendParseError("(");
		quat.x = getNextNumber();
		quat.y = getNextNumber();
		quat.z = getNextNumber();
		
		// quat supposed to be unit length
		var t:Float = 1 - (quat.x*quat.x) - (quat.y*quat.y) - (quat.z*quat.z);
		quat.w = t < 0? 0 : -Math.sqrt(t);
		
		if (getNextToken() != ")")
			sendParseError(")");
		
		return quat;
	}
	
	/**
	 * Parses the command line data.
	 */
	private function parseCMD():Void
	{
		// just ignore the command line property
		parseLiteralString();
	}
	
	/**
	 * Retrieves the next literal string in the data stream. A literal string is a sequence of characters bounded
	 * by double quotes.
	 */
	private function parseLiteralString():String
	{
		skipWhiteSpace();
		
		var ch:String = getNextChar();
		var str:String = "";
		
		if (ch != "\"")
			sendParseError("\"");
		
		do {
			if (_reachedEOF)
				sendEOFError();
			ch = getNextChar();
			if (ch != "\"")
				str += ch;
		} while (ch != "\"");
		
		return str;
	}
	
	/**
	 * Throws an end-of-file error when a premature end of file was encountered.
	 */
	private function sendEOFError():Void
	{
		throw new Error("Unexpected end of file");
	}
	
	/**
	 * Throws an error when an unexpected token was encountered.
	 * @param expected The token type that was actually expected.
	 */
	private function sendParseError(expected:String):Void
	{
		throw new Error("Unexpected token at line " + (_line + 1) + ", character " + _charLineIndex + ". " + expected + " expected, but " + _textData.charAt(_parseIndex - 1) + " encountered");
	}
	
	/**
	 * Throws an error when an unknown keyword was encountered.
	 */
	private function sendUnknownKeywordError():Void
	{
		throw new Error("Unknown keyword at line " + (_line + 1) + ", character " + _charLineIndex + ". ");
	}
}

// value objects

class HierarchyData
{
	public var name:String;
	public var parentIndex:Int;
	public var flags:Int;
	public var startIndex:Int;
	
	public function new()
	{
	}
}

class BoundsData
{
	public var min:Vector3D;
	public var max:Vector3D;
	
	public function new()
	{
	}
}

class BaseFrameData
{
	public var position:Vector3D;
	public var orientation:Quaternion;
	
	public function new()
	{
	}
}

class FrameData
{
	public var index:Int;
	public var components:Vector<Float>;
	
	public function new()
	{
	}
}