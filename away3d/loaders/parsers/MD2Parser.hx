package away3d.loaders.parsers;

import away3d.*;
import away3d.animators.*;
import away3d.animators.nodes.*;
import away3d.core.base.*;
import away3d.entities.*;
import away3d.loaders.misc.*;
import away3d.loaders.parsers.utils.*;
import away3d.materials.*;
import away3d.materials.utils.*;
import away3d.textures.*;

import openfl.net.URLRequest;
import openfl.utils.ByteArray;
import openfl.utils.Endian;
import openfl.Vector;

/**
 * MD2Parser provides a parser for the MD2 data type.
 */
class MD2Parser extends ParserBase
{
	public static var FPS:Int = 6;
	
	private var _clipNodes:Map<String, VertexClipNode> = new Map<String, VertexClipNode>();
	private var _byteData:ByteArray;
	private var _startedParsing:Bool;
	private var _parsedHeader:Bool;
	private var _parsedUV:Bool;
	private var _parsedFaces:Bool;
	private var _parsedFrames:Bool;
	
	private var _ident:Int;
	private var _version:Int;
	private var _skinWidth:Int;
	private var _skinHeight:Int;
	//private var _frameSize : Int;
	private var _numSkins:Int;
	private var _numVertices:Int;
	private var _numST:Int;
	private var _numTris:Int;
	//private var _numGlCmds : Int;
	private var _numFrames:Int;
	private var _offsetSkins:Int;
	private var _offsetST:Int;
	private var _offsetTris:Int;
	private var _offsetFrames:Int;
	//private var _offsetGlCmds : Int;
	private var _offsetEnd:Int;
	
	private var _uvIndices:Vector<Float>;
	private var _indices:Vector<UInt>;
	private var _vertIndices:Vector<Float>;
	private var _indexMap:Map<Int, Map<Int, Int>> = new Map<Int, Map<Int, Int>>();
	
	// the current subgeom being built
	private var _animationSet:VertexAnimationSet = new VertexAnimationSet();
	private var _firstSubGeom:CompactSubGeometry;
	private var _uvs:Vector<Float>;
	private var _finalUV:Vector<Float>;
	
	private var _materialNames:Vector<String>;
	private var _textureType:String;
	private var _ignoreTexturePath:Bool;
	private var _mesh:Mesh;
	private var _geometry:Geometry;
	
	private var materialFinal:Bool = false;
	private var geoCreated:Bool = false;
	
	/**
	 * Creates a new MD2Parser object.
	 * @param textureType The extension of the texture (e.g. jpg/png/...)
	 * @param ignoreTexturePath If true, the path of the texture is ignored
	 */
	public function new(textureType:String = "jpg", ignoreTexturePath:Bool = true)
	{
		super(ParserDataFormat.BINARY);
		_textureType = textureType;
		_ignoreTexturePath = ignoreTexturePath;
	}
	
	/**
	 * Indicates whether or not a given file extension is supported by the parser.
	 * @param extension The file extension of a potential file to be parsed.
	 * @return Whether or not the given file type is supported.
	 */
	public static function supportsType(extension:String):Bool
	{
		extension = extension.toLowerCase();
		return extension == "md2";
	}
	
	/**
	 * Tests whether a data block can be parsed by the parser.
	 * @param data The data block to potentially be parsed.
	 * @return Whether or not the given data is supported.
	 */
	public static function supportsData(data:Dynamic):Bool
	{
		return (ParserUtil.toString(data, 4) == 'IDP2');
	}
	
	/**
	 * @inheritDoc
	 */
	override private function resolveDependency(resourceDependency:ResourceDependency):Void
	{
		if (resourceDependency.assets.length != 1)
			return;
		
		var asset:Texture2DBase = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(resourceDependency.assets[0], Texture2DBase) ? cast resourceDependency.assets[0] : null;
		if (asset != null) {
			var material:MaterialBase;
			if (materialMode < 2)
				material = new TextureMaterial(asset);
			else
				material = new TextureMultiPassMaterial(asset);
			
			material.name = _mesh.material.name;
			_mesh.material = material;
			finalizeAsset(material);
			finalizeAsset(_mesh.geometry);
			finalizeAsset(_mesh);
		}
		materialFinal = true;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function resolveDependencyFailure(resourceDependency:ResourceDependency):Void
	{
		// apply system default
		if (materialMode < 2)
			_mesh.material = DefaultMaterialManager.getDefaultMaterial();
		else
			_mesh.material = new TextureMultiPassMaterial(DefaultMaterialManager.getDefaultTexture());
		
		finalizeAsset(_mesh.geometry);
		finalizeAsset(_mesh);
		materialFinal = true;
	
	}
	
	/**
	 * @inheritDoc
	 */
	override private function proceedParsing():Bool
	{
		if (!_startedParsing) {
			_byteData = getByteData();
			_startedParsing = true;
			
			// Reset bytearray read position (which may have been 
			// moved forward by the supportsData() function.)
			_byteData.position = 0;
		}
		
		while (hasTime()) {
			if (!_parsedHeader) {
				_byteData.endian = Endian.LITTLE_ENDIAN;
				
				// TODO: Create a mesh only when encountered (if it makes sense
				// for this file format) and return it using finalizeAsset()
				_geometry = new Geometry();
				_mesh = new Mesh(_geometry, null);
				if (materialMode < 2)
					_mesh.material = DefaultMaterialManager.getDefaultMaterial();
				else
					_mesh.material = new TextureMultiPassMaterial(DefaultMaterialManager.getDefaultTexture());
				
				//_geometry.animation = new VertexAnimation(2, VertexAnimationMode.ABSOLUTE);
				//_animator = new VertexAnimator(VertexAnimationState(_mesh.animationState));
				
				// Parse header and decompress body
				parseHeader();
				parseMaterialNames();
			}
			
			else if (!_parsedUV)
				parseUV();
			
			else if (!_parsedFaces)
				parseFaces();
			
			else if (!_parsedFrames)
				parseFrames();
			else if ((geoCreated) && (materialFinal))
				return ParserBase.PARSING_DONE;
			
			else if (!geoCreated) {
				geoCreated = true;
				createDefaultSubGeometry();
				// Force name to be chosen by finalizeAsset()
				_mesh.name = "";
				if (materialFinal) {
					finalizeAsset(_mesh.geometry);
					finalizeAsset(_mesh);
				}
				
				pauseAndRetrieveDependencies();
			}
		}
		
		return ParserBase.MORE_TO_PARSE;
	}
	
	/**
	 * Reads in all that MD2 Header data that is declared as private variables.
	 * I know its a lot, and it looks ugly, but only way to do it in Flash
	 */
	private function parseHeader():Void
	{
		_ident = _byteData.readInt();
		_version = _byteData.readInt();
		_skinWidth = _byteData.readInt();
		_skinHeight = _byteData.readInt();
		//skip _frameSize
		_byteData.readInt();
		_numSkins = _byteData.readInt();
		_numVertices = _byteData.readInt();
		_numST = _byteData.readInt();
		_numTris = _byteData.readInt();
		//skip _numGlCmds
		_byteData.readInt();
		_numFrames = _byteData.readInt();
		_offsetSkins = _byteData.readInt();
		_offsetST = _byteData.readInt();
		_offsetTris = _byteData.readInt();
		_offsetFrames = _byteData.readInt();
		//skip _offsetGlCmds
		_byteData.readInt();
		_offsetEnd = _byteData.readInt();
		
		_parsedHeader = true;
	}
	
	/**
	 * Parses the file names for the materials.
	 */
	private function parseMaterialNames():Void
	{
		var url:String;
		var name:String;
		var extIndex:Int;
		var slashIndex:Int = 0;
		_materialNames = new Vector<String>();
		_byteData.position = _offsetSkins;
		
		var regExp:EReg = ~/[^a-zA-Z0-9\\_\/.]/g;
		for (i in 0..._numSkins) {
			name = _byteData.readUTFBytes(64);
			name = regExp.replace(name, "");
			extIndex = name.lastIndexOf(".");
			if (_ignoreTexturePath)
				slashIndex = name.lastIndexOf("/");
			if (name.toLowerCase().indexOf(".jpg") == -1 && name.toLowerCase().indexOf(".png") == -1) {
				name = name.substring(slashIndex + 1, extIndex);
				url = name + "." + _textureType;
			} else
				url = name;
			
			_materialNames[i] = name;
			// only support 1 skin TODO: really?
			if (dependencies.length == 0)
				addDependency(name, new URLRequest(url));
		}
		
		if (_materialNames.length > 0)
			_mesh.material.name = _materialNames[0];
		else
			materialFinal = true;
	
	}
	
	/**
	 * Parses the uv data for the mesh.
	 */
	private function parseUV():Void
	{
		var j:Int = 0;
		
		_uvs = new Vector<Float>(_numST*2);
		_byteData.position = _offsetST;
		for (i in 0..._numST) {
			_uvs[j++] = _byteData.readShort()/_skinWidth;
			_uvs[j++] = _byteData.readShort()/_skinHeight;
		}
		
		_parsedUV = true;
	}
	
	/**
	 * Parses unique indices for the faces.
	 */
	private function parseFaces():Void
	{
		var a:Int, b:Int, c:Int, ta:Int, tb:Int, tc:Int;
		
		_vertIndices = new Vector<Float>();
		_uvIndices = new Vector<Float>();
		_indices = new Vector<UInt>();
		
		_byteData.position = _offsetTris;
		
		for (i in 0..._numTris) {
			//collect vertex indices
			a = _byteData.readUnsignedShort();
			b = _byteData.readUnsignedShort();
			c = _byteData.readUnsignedShort();
			
			//collect uv indices
			ta = _byteData.readUnsignedShort();
			tb = _byteData.readUnsignedShort();
			tc = _byteData.readUnsignedShort();
			
			addIndex(a, ta);
			addIndex(b, tb);
			addIndex(c, tc);
		}
		
		var len:Int = _uvIndices.length;
		_finalUV = new Vector<Float>(len*2, true);
		
		for (i in 0...len) {
			var t:Int = Std.int(_uvIndices[i]);
			t = t << 1;
			var t2:Int = i << 1;
			_finalUV[t2] = _uvs[t];
			_finalUV[t2 + 1] = _uvs[t + 1];
		}
		
		_parsedFaces = true;
	}
	
	/**
	 * Adds a face index to the list if it doesn't exist yet, based on vertexIndex and uvIndex, and adds the
	 * corresponding vertex and uv data in the correct location.
	 * @param vertexIndex The original index in the vertex list.
	 * @param uvIndex The original index in the uv list.
	 */
	private function addIndex(vertexIndex:Int, uvIndex:Int):Void
	{
		var index:Int = findIndex(vertexIndex, uvIndex);
		
		if (index == -1) {
			if (!_indexMap.exists(vertexIndex)) _indexMap[vertexIndex] = new Map<Int, Int>();
			_indices.push(_indexMap[vertexIndex][uvIndex] = _vertIndices.length);
			_vertIndices.push(vertexIndex);
			_uvIndices.push(uvIndex);
		} else
			_indices.push(index);
	}
	
	/**
	 * Finds the final index corresponding to the original MD2's vertex and uv indices. Returns -1 if it wasn't added yet.
	 * @param vertexIndex The original index in the vertex list.
	 * @param uvIndex The original index in the uv list.
	 * @return The index of the final mesh corresponding to the original vertex and uv index. -1 if it doesn't exist yet.
	 */
	private function findIndex(vertexIndex:Int, uvIndex:Int):Int
	{
		if (_indexMap.exists(vertexIndex) && _indexMap[vertexIndex].exists(uvIndex))
			return _indexMap[vertexIndex][uvIndex];
		
		return -1;
	}
	
	/**
	 * Parses all the frame geometries.
	 */
	private function parseFrames():Void
	{
		var sx:Float, sy:Float, sz:Float;
		var tx:Float, ty:Float, tz:Float;
		var geometry:Geometry;
		var subGeom:CompactSubGeometry;
		var vertLen:UInt = _vertIndices.length;
		var fvertices:Vector<Float>;
		var tvertices:Vector<Float>;
		var k:Int;
		//var ch : uint;
		var name:String = "";
		var prevClip:VertexClipNode = null;
		
		_byteData.position = _offsetFrames;
		
		for (i in 0..._numFrames) {
			subGeom = new CompactSubGeometry();
			if (_firstSubGeom == null)
				_firstSubGeom = subGeom;
			geometry = new Geometry();
			geometry.addSubGeometry(subGeom);
			tvertices = new Vector<Float>();
			fvertices = new Vector<Float>(vertLen*3, true);
			
			sx = _byteData.readFloat();
			sy = _byteData.readFloat();
			sz = _byteData.readFloat();
			
			tx = _byteData.readFloat();
			ty = _byteData.readFloat();
			tz = _byteData.readFloat();
			
			name = readFrameName();
			
			// Note, the extra data.position++ in the for loop is there
			// to skip over a byte that holds the "vertex normal index"
			for (j in 0..._numVertices) {
				tvertices.push(sx * _byteData.readUnsignedByte() + tx);
				tvertices.push(sy * _byteData.readUnsignedByte() + ty);
				tvertices.push(sz * _byteData.readUnsignedByte() + tz);
				_byteData.position = _byteData.position + 1;
			}
			
			k = 0;
			for (j in 0...vertLen) {
				fvertices[k++] = tvertices[Std.int(_vertIndices[j]) * 3];
				fvertices[k++] = tvertices[Std.int(_vertIndices[j]) * 3 + 2];
				fvertices[k++] = tvertices[Std.int(_vertIndices[j]) * 3 + 1];
			}
			
			subGeom.fromVectors(fvertices, _finalUV, null, null);
			subGeom.updateIndexData(_indices);
			subGeom.vertexNormalData;
			subGeom.vertexTangentData;
			subGeom.autoDeriveVertexNormals = false;
			subGeom.autoDeriveVertexTangents = false;
			
			var clip:VertexClipNode = _clipNodes[name];
			
			if (clip == null) {
				// If another sequence was parsed before this one, starting
				// a new state means the previous one is complete and can
				// hence be finalized.
				if (prevClip != null) {
					finalizeAsset(prevClip);
					_animationSet.addAnimation(prevClip);
				}
				
				clip = new VertexClipNode();
				clip.name = name;
				clip.stitchFinalFrame = true;
				
				_clipNodes[name] = clip;
				
				prevClip = clip;
			}
			clip.addFrame(geometry, Std.int(1000 / FPS));
		}
		
		// Finalize the last state
		if (prevClip != null) {
			finalizeAsset(prevClip);
			_animationSet.addAnimation(prevClip);
		}
		
		// Force finalizeAsset() to decide name
		finalizeAsset(_animationSet);
		
		_parsedFrames = true;
	}
	
	private function readFrameName():String
	{
		var name:String = "";
		var k:Int = 0;
		for (j in 0...16) {
			var ch:Int = _byteData.readUnsignedByte();
			
			if (ch > 0x39 && ch <= 0x7A && k == 0)
				name += String.fromCharCode(ch);
			
			if (ch >= 0x30 && ch <= 0x39)
				k++;
		}
		return name;
	}
	
	private function createDefaultSubGeometry():Void
	{
		var sub:CompactSubGeometry = new CompactSubGeometry();
		sub.updateData(_firstSubGeom.vertexData);
		sub.updateIndexData(_indices);
		_geometry.addSubGeometry(sub);
	}
}