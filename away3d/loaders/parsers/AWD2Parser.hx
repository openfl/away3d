package away3d.loaders.parsers;

import away3d.*;
import away3d.animators.*;
import away3d.animators.data.*;
import away3d.animators.nodes.*;
import away3d.cameras.*;
import away3d.cameras.lenses.*;
import away3d.containers.*;
import away3d.core.base.*;
import away3d.entities.*;
import away3d.library.assets.*;
import away3d.lights.*;
import away3d.lights.shadowmaps.*;
import away3d.loaders.misc.*;
import away3d.loaders.parsers.utils.*;
import away3d.materials.*;
import away3d.materials.lightpickers.*;
import away3d.materials.methods.*;
import away3d.materials.utils.*;
import away3d.primitives.*;
import away3d.textures.*;
import away3d.tools.utils.*;

import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.Sprite;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;
import openfl.utils.CompressionAlgorithm;
import openfl.utils.Endian;
import openfl.Lib;
import openfl.Vector;

using Reflect;

/**
 * AWDParser provides a parser for the AWD data type.
 */
class AWD2Parser extends ParserBase
{	
	//set to "true" to have some traces in the Console
	private var _debug:Bool = false;
	private var _byteData:ByteArray;
	private var _cur_block_id:UInt;
	private var _blocks:Vector<AWDBlock>;
	private var _newBlockBytes:ByteArray;
	
	private var _version:Array<Int>;
	private var _compression:UInt;
	
	private var _accuracyOnBlocks:Bool;
	
	private var _accuracyMatrix:Bool;
	private var _accuracyGeo:Bool;
	private var _accuracyProps:Bool;
	
	private var _matrixNrType:UInt;
	private var _geoNrType:UInt;
	private var _propsNrType:UInt;
	
	private var _streaming:Bool;
	
	private var _texture_users:Map<String, Array<Int>>;
	
	private var _body:ByteArray;
	
	private var _defaultTexture:BitmapTexture;
	private var _defaultCubeTexture:BitmapCubeTexture;
	private var _defaultBitmapMaterial:TextureMaterial;
	private var _cubeTextures:Array<BitmapData>;
	
	public static inline var COMPRESSIONMODE_LZMA:String = "lzma";
	
	public static inline var UNCOMPRESSED:UInt = 0;
	public static inline var DEFLATE:UInt = 1;
	public static inline var LZMA:UInt = 2;
	
	public static inline var INT8:UInt = 1;
	public static inline var INT16:UInt = 2;
	public static inline var INT32:UInt = 3;
	public static inline var UINT8:UInt = 4;
	public static inline var UINT16:UInt = 5;
	public static inline var UINT32:UInt = 6;
	public static inline var FLOAT32:UInt = 7;
	public static inline var FLOAT64:UInt = 8;
	
	public static inline var BOOL:UInt = 21;
	public static inline var COLOR:UInt = 22;
	public static inline var BADDR:UInt = 23;
	
	public static inline var AWDSTRING:UInt = 31;
	public static inline var AWDBYTEARRAY:UInt = 32;
	
	public static inline var VECTOR2x1:UInt = 41;
	public static inline var VECTOR3x1:UInt = 42;
	public static inline var VECTOR4x1:UInt = 43;
	public static inline var MTX3x2:UInt = 44;
	public static inline var MTX3x3:UInt = 45;
	public static inline var MTX4x3:UInt = 46;
	public static inline var MTX4x4:UInt = 47;
	
	private var blendModeDic:Vector<BlendMode>;
	private var _depthSizeDic:Vector<UInt>;
	
	/**
	 * Creates a new AWDParser object.
	 * @param uri The url or id of the data or file to be parsed.
	 * @param extra The holder for extra contextual data that the parser might need.
	 */
	public function new()
	{
		super(ParserDataFormat.BINARY);
		
		blendModeDic = new Vector<BlendMode>(); // used to translate ints to blendMode-strings
		blendModeDic.push(BlendMode.NORMAL);
		blendModeDic.push(BlendMode.ADD);
		blendModeDic.push(BlendMode.ALPHA);
		blendModeDic.push(BlendMode.DARKEN);
		blendModeDic.push(BlendMode.DIFFERENCE);
		blendModeDic.push(BlendMode.ERASE);
		blendModeDic.push(BlendMode.HARDLIGHT);
		blendModeDic.push(BlendMode.INVERT);
		blendModeDic.push(BlendMode.LAYER);
		blendModeDic.push(BlendMode.LIGHTEN);
		blendModeDic.push(BlendMode.MULTIPLY);
		blendModeDic.push(BlendMode.OVERLAY);
		blendModeDic.push(BlendMode.SCREEN);
		//blendModeDic.push(BlendMode.SHADER);
		
		_depthSizeDic = new Vector<UInt>(); // used to translate ints to depthSize-values
		_depthSizeDic.push(256);
		_depthSizeDic.push(512);
		_depthSizeDic.push(2048);
		_depthSizeDic.push(1024);
	}
	
	/**
	 * Indicates whether or not a given file extension is supported by the parser.
	 * @param extension The file extension of a potential file to be parsed.
	 * @return Whether or not the given file type is supported.
	 */
	public static function supportsType(extension:String):Bool
	{
		extension = extension.toLowerCase();
		return extension == "awd";
	}
	
	/**
	 * Tests whether a data block can be parsed by the parser.
	 * @param data The data block to potentially be parsed.
	 * @return Whether or not the given data is supported.
	 */
	public static function supportsData(data:Dynamic):Bool
	{
		return (ParserUtil.toString(data, 3) == 'AWD');
	}
	/**
	 * @inheritDoc
	 */
	override private function resolveDependency(resourceDependency:ResourceDependency):Void
	{
		// this function will be called when Dependency has finished loading.
		// the Assets waiting for this Bitmap, can be Texture or CubeTexture.
		// if the Bitmap is awaited by a CubeTexture, we need to check if its the last Bitmap of the CubeTexture, 
		// so we know if we have to finalize the Asset (CubeTexture) or not.
		if (resourceDependency.assets.length == 1) {
			var isCubeTextureArray:Array<String> = resourceDependency.id.split("#");
			var ressourceID:String = isCubeTextureArray[0];
			var asset:TextureProxyBase;
			var thisBitmapTexture:Texture2DBase;
			var block:AWDBlock;
			if (isCubeTextureArray.length == 1) {
				asset = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(resourceDependency.assets[0], Texture2DBase) ? cast resourceDependency.assets[0] : null;
				if (asset != null) {
					var mat:TextureMaterial;
					//var users:Array;
					block = _blocks[Std.parseInt(resourceDependency.id)];
					block.data = asset; // Store finished asset
					// Reset name of texture to the one defined in the AWD file,
					// as opposed to whatever the image parser came up with.
					asset.resetAssetPath(block.name, null, true);
					block.name = asset.name;
					// Finalize texture asset to dispatch texture event, which was
					// previously suppressed while the dependency was loaded.
					finalizeAsset(asset);
					if (_debug) {
						trace("Successfully loadet Bitmap for texture");
						trace("Parsed CubeTexture: Name = " + block.name);
					}
				}
			}
			if (isCubeTextureArray.length > 1) {
				thisBitmapTexture = cast(resourceDependency.assets[0], BitmapTexture);
				_cubeTextures[Std.parseInt(isCubeTextureArray[1])] = cast(thisBitmapTexture, BitmapTexture).bitmapData;
				_texture_users[ressourceID].push(1);
				
				if (_debug)
					trace("Successfully loadet Bitmap " + _texture_users[ressourceID].length + " / 6 for Cubetexture");
				if (_texture_users[ressourceID].length == _cubeTextures.length) {
					asset = new BitmapCubeTexture(_cubeTextures[0], _cubeTextures[1], _cubeTextures[2], _cubeTextures[3], _cubeTextures[4], _cubeTextures[5]);
					block = _blocks[Std.parseInt(ressourceID)];
					block.data = asset; // Store finished asset
					// Reset name of texture to the one defined in the AWD file,
					// as opposed to whatever the image parser came up with.
					asset.resetAssetPath(block.name, null, true);
					block.name = asset.name;
					// Finalize texture asset to dispatch texture event, which was
					// previously suppressed while the dependency was loaded.
					finalizeAsset(asset);
					if (_debug)
						trace("Parsed CubeTexture: Name = " + block.name);
				}
			}
		}
	}
	
	/**
	 * @inheritDoc
	 */
	override private function resolveDependencyFailure(resourceDependency:ResourceDependency):Void
	{
		//not used - if a dependcy fails, the awaiting Texture or CubeTexture will never be finalized, and the default-bitmaps will be used.
		// this means, that if one Bitmap of a CubeTexture fails, the CubeTexture will have the DefaultTexture applied for all six Bitmaps.
	}
	
	/**
	 * Resolve a dependency name
	 *
	 * @param resourceDependency The dependency to be resolved.
	 */
	override private function resolveDependencyName(resourceDependency:ResourceDependency, asset:IAsset):String
	{
		var oldName:String = asset.name;
		if (asset != null) {
			var block:AWDBlock = _blocks[Std.parseInt(resourceDependency.id)];
			// Reset name of texture to the one defined in the AWD file,
			// as opposed to whatever the image parser came up with.
			asset.resetAssetPath(block.name, null, true);
		}
		var newName:String = asset.name;
		asset.name = oldName;
		return newName;
	}
	
	
	/**
	 * @inheritDoc
	 */
	private override function startParsing(frameLimit:Float):Void
	{
		super.startParsing(frameLimit);
		
		_texture_users = new Map<String, Array<Int>> ();
		
		_byteData = getByteData();
		
		_blocks = new Vector<AWDBlock>();
		_blocks[0] = new AWDBlock();
		_blocks[0].data = null; // Zero address means null in AWD
		
		_version = []; // will contain 2 int (major-version, minor-version) for awd-version-check
		
		//parse header
		_byteData.endian = Endian.LITTLE_ENDIAN;
		
		// Parse header and decompress body if needed
		parseHeader();
		switch (_compression) {
			case DEFLATE:
				_body = new ByteArray();
				_byteData.readBytes(_body, 0, _byteData.bytesAvailable);
				_body.uncompress();
			case LZMA:
				_body = new ByteArray();
				_byteData.readBytes(_body, 0, _byteData.bytesAvailable);
				_body.uncompress(COMPRESSIONMODE_LZMA);
			case UNCOMPRESSED:
				_body = _byteData;
		}
		
		_body.endian = Endian.LITTLE_ENDIAN;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function proceedParsing():Bool
	{
		while (_body.bytesAvailable > 0 && !parsingPaused && hasTime())
			parseNextBlock();
		
		// Return complete status
		if (_body.bytesAvailable == 0)
			return ParserBase.PARSING_DONE;
		else
			return ParserBase.MORE_TO_PARSE;
	}
	
	private function parseHeader():Void
	{
		var flags:UInt;
		var body_len:Float;
		_byteData.position = 3; // Skip magic string and parse version
		_version[0] = _byteData.readUnsignedByte();
		_version[1] = _byteData.readUnsignedByte();
		
		flags = _byteData.readUnsignedShort(); // Parse bit flags
		_streaming = BitFlags.test(flags, BitFlags.FLAG1);
		if ((_version[0] == 2) && (_version[1] == 1)) {
			_accuracyMatrix = BitFlags.test(flags, BitFlags.FLAG2);
			_accuracyGeo = BitFlags.test(flags, BitFlags.FLAG3);
			_accuracyProps = BitFlags.test(flags, BitFlags.FLAG4);
		}
		// if we set _accuracyOnBlocks, the precision-values are read from each block-header.
		
		// set storagePrecision types
		_geoNrType = FLOAT32;
		if (_accuracyGeo)
			_geoNrType = FLOAT64;
		_matrixNrType = FLOAT32;
		if (_accuracyMatrix)
			_matrixNrType = FLOAT64;
		_propsNrType = FLOAT32;
		if (_accuracyProps)
			_propsNrType = FLOAT64;
		
		_compression = _byteData.readUnsignedByte(); // compression	
		
		if (_debug) {
			trace("Import AWDFile of version = " + _version[0] + " - " + _version[1]);
			trace("Global Settings = Compression = " + _compression + " | Streaming = " + _streaming + " | Matrix-Precision = " + _accuracyMatrix + " | Geometry-Precision = " + _accuracyGeo + " | Properties-Precision = " + _accuracyProps);
		}
		
		// Check file integrity
		body_len = _byteData.readUnsignedInt();
		if (!_streaming && body_len != _byteData.bytesAvailable)
			dieWithError('AWD2 body length does not match header integrity field');
	}
	
	private function parseNextBlock():Void
	{
		var block:AWDBlock = null;
		var assetData:IAsset = null;
		var isParsed:Bool = false;
		var ns:UInt, type:UInt, flags:UInt, len:UInt;
		_cur_block_id = _body.readUnsignedInt();
		ns = _body.readUnsignedByte();
		type = _body.readUnsignedByte();
		flags = _body.readUnsignedByte();
		len = _body.readUnsignedInt();
		var blockCompression:Bool = BitFlags.test(flags, BitFlags.FLAG4);
		var blockCompressionLZMA:Bool = BitFlags.test(flags, BitFlags.FLAG5);
		if (_accuracyOnBlocks) {
			_accuracyMatrix = BitFlags.test(flags, BitFlags.FLAG1);
			_accuracyGeo = BitFlags.test(flags, BitFlags.FLAG2);
			_accuracyProps = BitFlags.test(flags, BitFlags.FLAG3);
			_geoNrType = FLOAT32;
			if (_accuracyGeo)
				_geoNrType = FLOAT64;
			_matrixNrType = FLOAT32;
			if (_accuracyMatrix)
				_matrixNrType = FLOAT64;
			_propsNrType = FLOAT32;
			if (_accuracyProps)
				_propsNrType = FLOAT64;
		}
		
		var blockEndAll:UInt = _body.position + len;
		if (Std.int(len) > Std.int(_body.bytesAvailable)) {
			dieWithError('AWD2 block length is bigger than the bytes that are available!');
			_body.position += _body.bytesAvailable;
			return;
		}
		_newBlockBytes = new ByteArray();
		_body.readBytes(_newBlockBytes, 0, len);
		if (blockCompression) {
			if (blockCompressionLZMA)
				_newBlockBytes.uncompress(CompressionAlgorithm.LZMA);
			else
				_newBlockBytes.uncompress();
		}
		_newBlockBytes.endian = Endian.LITTLE_ENDIAN;
		_newBlockBytes.position = 0;
		block = new AWDBlock();
		block.len = _newBlockBytes.position + len;
		block.id = _cur_block_id;
		
		var blockEndBlock:UInt = _newBlockBytes.position + len;
		if (blockCompression) {
			blockEndBlock = _newBlockBytes.position + _newBlockBytes.length;
			block.len = blockEndBlock;
		}
		
		if (_debug)
			trace("AWDBlock:  ID = " + _cur_block_id + " | TypeID = " + type + " | Compression = " + blockCompression + " | Matrix-Precision = " + _accuracyMatrix + " | Geometry-Precision = " + _accuracyGeo + " | Properties-Precision = " + _accuracyProps);
		
		_blocks[_cur_block_id] = block;
		if ((_version[0] == 2) && (_version[1] == 1)) {
			switch (type) {
				case 11:
					parsePrimitves(_cur_block_id);
					isParsed = true;
				case 31:
					parseSkyBoxInstance(_cur_block_id);
					isParsed = true;
				case 41:
					parseLight(_cur_block_id);
					isParsed = true;
				case 42:
					parseCamera(_cur_block_id);
					isParsed = true;
				case 43:
					parseTextureProjector(_cur_block_id);
					isParsed = true;
				case 51:
					parseLightPicker(_cur_block_id);
					isParsed = true;
				case 81:
					parseMaterial_v1(_cur_block_id);
					isParsed = true;
				case 83:
					parseCubeTexture(_cur_block_id);
					isParsed = true;
				case 91:
					parseSharedMethodBlock(_cur_block_id);
					isParsed = true;
				case 92:
					parseShadowMethodBlock(_cur_block_id);
					isParsed = true;
				case 111:
					parseMeshPoseAnimation(_cur_block_id, true);
					isParsed = true;
				case 112:
					parseMeshPoseAnimation(_cur_block_id);
					isParsed = true;
				case 113:
					parseVertexAnimationSet(_cur_block_id);
					isParsed = true;
				case 122:
					parseAnimatorSet(_cur_block_id);
					isParsed = true;
				case 253:
					parseCommand(_cur_block_id);
					isParsed = true;
			}
		}
		if (isParsed == false) {
			switch (type) {
				case 1:
					parseTriangleGeometrieBlock(_cur_block_id);
				case 22:
					parseContainer(_cur_block_id);
				case 23:
					parseMeshInstance(_cur_block_id);
				case 81:
					parseMaterial(_cur_block_id);
				case 82:
					parseTexture(_cur_block_id);
				case 101:
					parseSkeleton(_cur_block_id);
				case 102:
					parseSkeletonPose(_cur_block_id);
				case 103:
					parseSkeletonAnimation(_cur_block_id);
				case 121:
					parseUVAnimation(_cur_block_id);
				case 254:
					parseNameSpace(_cur_block_id);
				case 255:
					parseMetaData(_cur_block_id);
				default:
					if (_debug)
						trace("AWDBlock:   Unknown BlockType  (BlockID = " + _cur_block_id + ") - Skip " + len + " bytes");
					_newBlockBytes.position += len;
			}
		}
		var msgCnt:Int = 0;
		if (_newBlockBytes.position == blockEndBlock) {
			if (_debug) {
				if (block.errorMessages != null) {
					while (msgCnt < block.errorMessages.length) {
						trace("        (!) Error: " + block.errorMessages[msgCnt] + " (!)");
						msgCnt++;
					}
				}
			}
			if (_debug)
				trace("\n");
		} else {
			if (_debug) {
				trace("  (!)(!)(!) Error while reading AWDBlock ID " + _cur_block_id + " = skip to next block");
				if (block.errorMessages != null) {
					while (msgCnt < block.errorMessages.length) {
						trace("        (!) Error: " + block.errorMessages[msgCnt] + " (!)");
						msgCnt++;
					}
				}
			}
		}
		
		_body.position = blockEndAll;
		_newBlockBytes = null;
	
	}
	
	//Block ID = 1
	private function parseTriangleGeometrieBlock(blockID:UInt):Void
	{
		
		var geom:Geometry = new Geometry();
		
		// Read name and sub count
		var name:String = parseVarStr();
		var num_subs:Int = _newBlockBytes.readUnsignedShort();
		
		// Read optional properties
		var props:AWDProperties = parseProperties({"1":_geoNrType, "2":_geoNrType});
		var geoScaleU:Float = props.get(1, 1);
		var geoScaleV:Float = props.get(2, 1);
		var sub_geoms:Vector<ISubGeometry> = new Vector<ISubGeometry>();
		// Loop through sub meshes
		var subs_parsed:Int = 0;
		while (subs_parsed < num_subs) {
			var i:UInt;
			var sm_len:UInt, sm_end:UInt;
			var w_indices:Vector<Float> = null;
			var weights:Vector<Float> = null;
			
			sm_len = _newBlockBytes.readUnsignedInt();
			sm_end = _newBlockBytes.position + sm_len;
			
			// Ignore for now
			var subProps:AWDProperties = parseProperties({ "1":_geoNrType, "2":_geoNrType });
			
			var verts:Vector<Float> = null;
			var indices:Vector<UInt> = null;
			var uvs:Vector<Float> = null;
			var normals:Vector<Float> = null;
			
			// Loop through data streams
			while (_newBlockBytes.position < sm_end) {
				var idx:UInt = 0;
				var str_ftype:UInt, str_type:UInt, str_len:UInt, str_end:UInt;
				
				// Type, field type, length
				str_type = _newBlockBytes.readUnsignedByte();
				str_ftype = _newBlockBytes.readUnsignedByte();
				str_len = _newBlockBytes.readUnsignedInt();
				str_end = _newBlockBytes.position + str_len;
				
				var x:Float, y:Float, z:Float;
				
				if (str_type == 1) {
					verts = new Vector<Float>();
					while (_newBlockBytes.position < str_end) {
						// TODO: Respect stream field type
						x = readNumber(_accuracyGeo);
						y = readNumber(_accuracyGeo);
						z = readNumber(_accuracyGeo);
						
						verts[idx++] = x;
						verts[idx++] = y;
						verts[idx++] = z;
					}
				} else if (str_type == 2) {
					indices = new Vector<UInt>();
					while (_newBlockBytes.position < str_end) {
						// TODO: Respect stream field type
						indices[idx++] = _newBlockBytes.readUnsignedShort();
					}
				} else if (str_type == 3) {
					uvs = new Vector<Float>();
					while (_newBlockBytes.position < str_end)
						uvs[idx++] = readNumber(_accuracyGeo);
				} else if (str_type == 4) {
					normals = new Vector<Float>();
					while (_newBlockBytes.position < str_end)
						normals[idx++] = readNumber(_accuracyGeo);
				} else if (str_type == 6) {
					w_indices = new Vector<Float>();
					while (_newBlockBytes.position < str_end)
						w_indices[idx++] = _newBlockBytes.readUnsignedShort()*3; // TODO: Respect stream field type
				} else if (str_type == 7) {
					weights = new Vector<Float>();
					while (_newBlockBytes.position < str_end)
						weights[idx++] = readNumber(_accuracyGeo);
				} else
					_newBlockBytes.position = str_end;
			}
			parseUserAttributes(); // Ignore sub-mesh attributes for now
			
			sub_geoms = GeomUtil.fromVectors(verts, indices, uvs, normals, null, weights, w_indices);
			
			var scaleU:Float = subProps.get(1, 1);
			var scaleV:Float = subProps.get(2, 1);
			var setSubUVs:Bool = false; //this should remain false atm, because in AwayBuilder the uv is only scaled by the geometry
			if ((geoScaleU != scaleU) || (geoScaleV != scaleV)) {
				trace("set sub uvs");
				setSubUVs = true;
				scaleU = geoScaleU/scaleU;
				scaleV = geoScaleV/scaleV;
			}
			for (i in 0...sub_geoms.length) {
				if (setSubUVs)
					sub_geoms[i].scaleUV(scaleU, scaleV);
				geom.addSubGeometry(sub_geoms[i]);
					// TODO: Somehow map in-sub to out-sub indices to enable look-up
					// when creating meshes (and their material assignments.)
			}
			subs_parsed++;
		}
		if ((geoScaleU != 1) || (geoScaleV != 1))
			geom.scaleUV(geoScaleU, geoScaleV);
		parseUserAttributes();
		finalizeAsset(geom, name);
		_blocks[blockID].data = geom;
		
		if (_debug)
			trace("Parsed a TriangleGeometry: Name = " + name + "| SubGeometries = " + sub_geoms.length);
	
	}
	
	//Block ID = 11
	private function parsePrimitves(blockID:Int):Void
	{
		var name:String;
		var geom:Geometry;
		var primType:Int;
		var subs_parsed:Int;
		var props:AWDProperties;
		var bsm:Matrix3D;
		
		// Read name and sub count
		name = parseVarStr();
		primType = _newBlockBytes.readUnsignedByte();
		props = parseProperties({ "101": _geoNrType, "102": _geoNrType, "103": _geoNrType, "110": _geoNrType, "111": _geoNrType, "301": UINT16, "302": UINT16, "303": UINT16, "701": BOOL, "702": BOOL, "703": BOOL, "704": BOOL});
		
		var primitveTypes:Array<String> = ["Unsupported Type-ID", "PlaneGeometry", "CubeGeometry", "SphereGeometry", "CylinderGeometry", "ConeGeometry", "CapsuleGeometry", "TorusGeometry"];
		switch (primType) {
			// to do, not all properties are set on all primitives
			case 1:
				geom = new PlaneGeometry(props.get(101, 100), props.get(102, 100), props.get(301, 1), props.get(302, 1), props.get(701, true), props.get(702, false));
			case 2:
				geom = new CubeGeometry(props.get(101, 100), props.get(102, 100), props.get(103, 100), props.get(301, 1), props.get(302, 1), props.get(303, 1), props.get(701, true));
			case 3:
				geom = new SphereGeometry(props.get(101, 50), props.get(301, 16), props.get(302, 12), props.get(701, true));
			case 4:
				geom = new CylinderGeometry(props.get(101, 50), props.get(102, 50), props.get(103, 100), props.get(301, 16), props.get(302, 1), true, true, true); // bool701, bool702, bool703, bool704);
				if (!props.get(701, true))
					cast(geom, CylinderGeometry).topClosed = false;
				if (!props.get(702, true))
					cast(geom, CylinderGeometry).bottomClosed = false;
				if (!props.get(703, true))
					cast(geom, CylinderGeometry).yUp = false;
			case 5:
				geom = new ConeGeometry(props.get(101, 50), props.get(102, 100), props.get(301, 16), props.get(302, 1), props.get(701, true), props.get(702, true));
			case 6:
				geom = new CapsuleGeometry(props.get(101, 50), props.get(102, 100), props.get(301, 16), props.get(302, 15), props.get(701, true));
			case 7:
				geom = new TorusGeometry(props.get(101, 50), props.get(102, 50), props.get(301, 16), props.get(302, 8), props.get(701, true));

			default:
				geom = new Geometry();
				trace("ERROR: UNSUPPORTED PRIMITIVE_TYPE");
		}
		if ((props.get(110, 1) != 1) || (props.get(111, 1) != 1)) {
			geom.subGeometries;
			geom.scaleUV(props.get(110, 1), props.get(111, 1));
		}
		parseUserAttributes();
		geom.name = name;
		finalizeAsset(geom, name);
		_blocks[blockID].data = geom;
		if (_debug) {
			if ((primType < 0) || (primType > 7))
				primType = 0;
			trace("Parsed a Primivite: Name = " + name + "| type = " + primitveTypes[primType]);
		}
	}
	
	// Block ID = 22
	private function parseContainer(blockID:Int):Void
	{
		var name:String;
		var par_id:Int;
		var mtx:Matrix3D;
		var ctr:ObjectContainer3D;
		var parent:ObjectContainer3D;
		
		par_id = _newBlockBytes.readUnsignedInt();
		mtx = parseMatrix3D();
		name = parseVarStr();
		var parentName:String = "Root (TopLevel)";
		ctr = new ObjectContainer3D();
		ctr.transform = mtx;
		var assetVO:AssetVO = getAssetByID(par_id, [Asset3DType.CONTAINER, Asset3DType.LIGHT, Asset3DType.MESH, Asset3DType.ENTITY, Asset3DType.SEGMENT_SET]);
		if (assetVO.enable) {
			cast(assetVO.data, ObjectContainer3D).addChild(ctr);
			parentName = cast(assetVO.data, ObjectContainer3D).name;
		} else if (par_id > 0)
			_blocks[blockID].addError("Could not find a parent for this ObjectContainer3D");
		
		// in AWD version 2.1 we read the Container properties
		if ((_version[0] == 2) && (_version[1] == 1)) {
			var props:Dynamic = parseProperties({"1" : _matrixNrType, "2": _matrixNrType, "3": _matrixNrType, "4": UINT8});
			ctr.pivotPoint = new Vector3D(props.get(1, 0), props.get(2, 0), props.get(3, 0));
		}
		// in other versions we do not read the Container properties
		else
			parseProperties(null);
		// the extraProperties should only be set for AWD2.1-Files, but is read for both versions
		ctr.extra = parseUserAttributes();
		finalizeAsset(ctr, name);
		_blocks[blockID].data = ctr;
		if (_debug)
			trace("Parsed a Container: Name = '" + name + "' | Parent-Name = " + parentName);
	}
	
	// Block ID = 23
	private function parseMeshInstance(blockID:Int):Void
	{
		var num_materials:Int;
		var materials_parsed:Int;
		var parent:ObjectContainer3D;
		
		var par_id:Int = _newBlockBytes.readUnsignedInt();
		var mtx:Matrix3D = parseMatrix3D();
		var name:String = parseVarStr();
		var parentName:String = "Root (TopLevel)";
		var data_id:Int = _newBlockBytes.readUnsignedInt();
		var geom:Geometry;
		var geometryAssetVO:AssetVO = getAssetByID(data_id, [Asset3DType.GEOMETRY]);
		if (geometryAssetVO.enable)
			geom = cast(geometryAssetVO.data, Geometry);
		else {
			_blocks[blockID].addError("Could not find a Geometry for this Mesh. A empty Geometry is created!");
			geom = new Geometry();
		}
		
		_blocks[blockID].geoID = data_id;
		var materials:Vector<MaterialBase> = new Vector<MaterialBase>();
		num_materials = _newBlockBytes.readUnsignedShort();
		var materialNames:Array<String> = new Array<String>();
		materials_parsed = 0;
		var materialAssetVO:AssetVO;
		while (materials_parsed < num_materials) {
			var mat_id:Int;
			mat_id = _newBlockBytes.readUnsignedInt();
			materialAssetVO = getAssetByID(mat_id, [Asset3DType.MATERIAL]);
			if (!materialAssetVO.enable && (mat_id > 0))
				_blocks[blockID].addError("Could not find Material Nr " + materials_parsed + " (ID = " + mat_id + " ) for this Mesh");
			materials.push(cast(materialAssetVO.data, MaterialBase));
			materialNames.push(cast(materialAssetVO.data, MaterialBase).name);
			
			materials_parsed++;
		}
		
		var mesh:Mesh = new Mesh(geom, null);
		mesh.transform = mtx;
		
		var parentAssetVO:AssetVO = getAssetByID(par_id, [Asset3DType.CONTAINER, Asset3DType.LIGHT, Asset3DType.MESH, Asset3DType.ENTITY, Asset3DType.SEGMENT_SET]);
		if (parentAssetVO.enable) {
			cast(parentAssetVO.data, ObjectContainer3D).addChild(mesh);
			parentName = cast(parentAssetVO.data, ObjectContainer3D).name;
		} else if (par_id > 0)
			_blocks[blockID].addError("Could not find a parent for this Mesh");
		
		if (materials.length >= 1 && mesh.subMeshes.length == 1)
			mesh.material = materials[0];
		else if (materials.length > 1) {
			var i:UInt;
			// Assign each sub-mesh in the mesh a material from the list. If more sub-meshes
			// than materials, repeat the last material for all remaining sub-meshes.
			for (i in 0...mesh.subMeshes.length)
				mesh.subMeshes[i].material = materials[Std.int(Math.min(materials.length - 1, i))];
		}
		if ((_version[0] == 2) && (_version[1] == 1)) {
			var props:Dynamic = parseProperties({"1" : _matrixNrType, "2": _matrixNrType, "3": _matrixNrType, "4": UINT8, "5": BOOL});
			mesh.pivotPoint = new Vector3D(props.get(1, 0), props.get(2, 0), props.get(3, 0));
			mesh.castsShadows = props.get(5, true);
		} else
			parseProperties(null);
		mesh.extra = parseUserAttributes();
		finalizeAsset(mesh, name);
		_blocks[blockID].data = mesh;
		if (_debug)
			trace("Parsed a Mesh: Name = '" + name + "' | Parent-Name = " + parentName + "| Geometry-Name = " + geom.name + " | SubMeshes = " + mesh.subMeshes.length + " | Mat-Names = " + materialNames.toString());
	
	}
	
	//Block ID 31
	private function parseSkyBoxInstance(blockID:UInt):Void
	{
		var name:String = parseVarStr();
		var cubeTexAddr:UInt = _newBlockBytes.readUnsignedInt();
		
		var cubeTexAssetVO:AssetVO = getAssetByID(cubeTexAddr, [Asset3DType.TEXTURE], "CubeTexture");
		if (!cubeTexAssetVO.enable && (cubeTexAddr != 0))
			_blocks[blockID].addError("Could not find the Cubetexture (ID = " + cubeTexAddr + " ) for this SkyBox");
		var asset:SkyBox = new SkyBox(cast(cubeTexAssetVO.data, BitmapCubeTexture));
		
		parseProperties(null);
		asset.extra = parseUserAttributes();
		finalizeAsset(asset, name);
		_blocks[blockID].data = asset;
		if (_debug)
			trace("Parsed a SkyBox: Name = '" + name + "' | CubeTexture-Name = " + cast(cubeTexAssetVO.data, BitmapCubeTexture).name);
	
	}
	
	//Block ID = 41
	private function parseLight(blockID:UInt):Void
	{
		var light:LightBase = null;
		var newShadowMapper:ShadowMapperBase = null;
		var par_id:UInt = _newBlockBytes.readUnsignedInt();
		var mtx:Matrix3D = parseMatrix3D();
		var name:String = parseVarStr();
		var lightType:UInt = _newBlockBytes.readUnsignedByte();
		var props:AWDProperties = parseProperties({"1" : _propsNrType, "2": _propsNrType, "3": COLOR, "4": _propsNrType, "5": _propsNrType, "6": BOOL, "7": COLOR, "8": _propsNrType, "9": UINT8, "10": UINT8, "11": _propsNrType, "12": UINT16, "21": _matrixNrType, "22": _matrixNrType, "23": _matrixNrType});
		var shadowMapperType:UInt = props.get(9, 0);
		var parentName:String = "Root (TopLevel)";
		var lightTypes:Array<String> = ["Unsupported LightType", "PointLight", "DirectionalLight"];
		var shadowMapperTypes:Array<String> = ["No ShadowMapper", "DirectionalShadowMapper", "NearDirectionalShadowMapper", "CascadeShadowMapper", "CubeMapShadowMapper"];
		if (lightType == 1) {
			light = new PointLight();
			cast(light, PointLight).radius = props.get(1, 90000);
			cast(light, PointLight).fallOff = props.get(2, 100000);
			if (shadowMapperType > 0) {
				if (shadowMapperType == 4)
					newShadowMapper = new CubeMapShadowMapper();
			}
			light.transform = mtx;
		}
		if (lightType == 2) {
			light = new DirectionalLight(props.get(21, 0), props.get(22, -1), props.get(23, 1));
			if (shadowMapperType > 0) {
				if (shadowMapperType == 1)
					newShadowMapper = new DirectionalShadowMapper();
				if (shadowMapperType == 2)
					newShadowMapper = new NearDirectionalShadowMapper(props.get(11, 0.5));
				if (shadowMapperType == 3)
					newShadowMapper = new CascadeShadowMapper(props.get(12, 3));
			}
		}
		if ((lightType != 2) && (lightType != 1)){
			_blocks[blockID].addError("Unsuported lighttype = "+lightType);
			return;
			
		}
		light.color = props.get(3, 0xffffff);
		light.specular = props.get(4, 1.0);
		light.diffuse = props.get(5, 1.0);
		light.ambientColor = props.get(7, 0xffffff);
		light.ambient = props.get(8, 0.0);
		// if a shadowMapper has been created, adjust the depthMapSize if needed, assign to light and set castShadows to true
		if (newShadowMapper != null) {
			if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(newShadowMapper, CubeMapShadowMapper)) {
				if (props.get(10, 1) != 1)
					newShadowMapper.depthMapSize = _depthSizeDic[props.get(10, 1)];
			} else {
				if (props.get(10, 2) != 2)
					newShadowMapper.depthMapSize = _depthSizeDic[props.get(10, 2)];
			}
			
			light.shadowMapper = newShadowMapper;
			light.castsShadows = true;
		}
		if (par_id != 0) {
			var parentAssetVO:AssetVO = getAssetByID(par_id, [Asset3DType.CONTAINER, Asset3DType.LIGHT, Asset3DType.MESH, Asset3DType.ENTITY, Asset3DType.SEGMENT_SET]);
			if (parentAssetVO.enable) {
				cast(parentAssetVO.data, ObjectContainer3D).addChild(light);
				parentName = cast(parentAssetVO.data, ObjectContainer3D).name;
			} else
				_blocks[blockID].addError("Could not find a parent for this Light");
		}
		
		parseUserAttributes();
		
		finalizeAsset(light, name);
		
		_blocks[blockID].data = light;
		if (_debug)
			trace("Parsed a Light: Name = '" + name + "' | Type = " + lightTypes[lightType] + " | Parent-Name = " + parentName + " | ShadowMapper-Type = " + shadowMapperTypes[shadowMapperType]);
	
	}
	
	//Block ID = 43
	private function parseCamera(blockID:UInt):Void
	{
		
		var par_id:UInt = _newBlockBytes.readUnsignedInt();
		var mtx:Matrix3D = parseMatrix3D();
		var name:String = parseVarStr();
		var parentName:String = "Root (TopLevel)";
		var lens:LensBase;
		_newBlockBytes.readUnsignedByte(); //set as active camera
		_newBlockBytes.readShort(); //lengthof lenses - not used yet
		var lenstype:UInt = _newBlockBytes.readShort();
		var props:AWDProperties = parseProperties({"101": _propsNrType, "102": _propsNrType, "103": _propsNrType, "104": _propsNrType});
		switch (lenstype) {
			case 5001:
				lens = new PerspectiveLens(props.get(101, 60));
			case 5002:
				lens = new OrthographicLens(props.get(101, 500));
			case 5003:
				lens = new OrthographicOffCenterLens(props.get(101, -400), props.get(102, 400), props.get(103, -300), props.get(104, 300));
			default:
				trace("unsupportedLenstype");
				return;
		}
		var camera:Camera3D = new Camera3D(lens);
		camera.transform = mtx;
		var parentAssetVO:AssetVO = getAssetByID(par_id, [Asset3DType.CONTAINER, Asset3DType.LIGHT, Asset3DType.MESH, Asset3DType.ENTITY, Asset3DType.SEGMENT_SET]);
		if (parentAssetVO.enable) {
			cast(parentAssetVO.data, ObjectContainer3D).addChild(camera);
			parentName = cast(parentAssetVO.data, ObjectContainer3D).name;
		} else if (par_id > 0)
			_blocks[blockID].addError("Could not find a parent for this Camera");
		camera.name = name;
		props = parseProperties({"1": _matrixNrType, "2": _matrixNrType, "3": _matrixNrType, "4": UINT8, "101":_propsNrType, "102":_propsNrType});
		camera.pivotPoint = new Vector3D(props.get(1, 0), props.get(2, 0), props.get(3, 0));
		camera.lens.near = props.get(101, 20);
		camera.lens.far = props.get(102, 3000);
		camera.extra = parseUserAttributes();
		finalizeAsset(camera, name);
		
		_blocks[blockID].data = camera;
		if (_debug)
			trace("Parsed a Camera: Name = '" + name + "' | Lenstype = " + lens + " | Parent-Name = " + parentName);
	
	}
	
	//Block ID = 43
	private function parseTextureProjector(blockID:UInt):Void
	{

		var par_id:UInt = _newBlockBytes.readUnsignedInt();
		var mtx:Matrix3D = parseMatrix3D();
		var name:String = parseVarStr();
		var parentName:String = "Root (TopLevel)";
		var tex_id:UInt = _newBlockBytes.readUnsignedInt();
		var geometryAssetVO:AssetVO = getAssetByID(tex_id, [Asset3DType.TEXTURE]);
		if (!geometryAssetVO.enable && (tex_id != 0))
			_blocks[blockID].addError("Could not find the Texture (ID = " + tex_id + " ( for this TextureProjector!");
		var textureProjector:TextureProjector = new TextureProjector(geometryAssetVO.data);
		textureProjector.name = name;
		textureProjector.aspectRatio = _newBlockBytes.readFloat();
		textureProjector.fieldOfView = _newBlockBytes.readFloat();
		textureProjector.transform = mtx;
		var props:AWDProperties = parseProperties({"1": _matrixNrType, "2": _matrixNrType, "3": _matrixNrType, "4": UINT8});
		textureProjector.pivotPoint = new Vector3D(props.get(1, 0), props.get(2, 0), props.get(3, 0));
		textureProjector.extra = parseUserAttributes();
		finalizeAsset(textureProjector, name);
		
		_blocks[blockID].data = textureProjector;
		if (_debug)
			trace("Parsed a TextureProjector: Name = '" + name + "' | Texture-Name = " + cast(geometryAssetVO.data, Texture2DBase).name + " | Parent-Name = " + parentName);
	
	}
	
	//Block ID = 51
	private function parseLightPicker(blockID:UInt):Void
	{
		var name:String = parseVarStr();
		var numLights:UInt = _newBlockBytes.readUnsignedShort();
		var lightsArray:Array<LightBase> = new Array();
		var k:Int = 0;
		var lightID:Int = 0;
		var lightAssetVO:AssetVO;
		var lightsArrayNames:Array<String> = new Array();
		for (k in 0...numLights) {
			lightID = _newBlockBytes.readUnsignedInt();
			lightAssetVO = getAssetByID(lightID, [Asset3DType.LIGHT]);
			if (lightAssetVO.enable) {
				lightsArray.push(cast(lightAssetVO.data, LightBase));
				lightsArrayNames.push(cast(lightAssetVO.data, LightBase).name);
			} else
				_blocks[blockID].addError("Could not find a Light Nr " + k + " (ID = " + lightID + " ) for this LightPicker");
		}
		if (lightsArray.length == 0) {
			_blocks[blockID].addError("Could not create this LightPicker, cause no Light was found.");
			parseUserAttributes();
			return; //return without any more parsing for this block
		}
		var lightPick:LightPickerBase = new StaticLightPicker(lightsArray);
		lightPick.name = name;
		parseUserAttributes();
		finalizeAsset(lightPick, name);
		
		_blocks[blockID].data = lightPick;
		if (_debug)
			trace("Parsed a StaticLightPicker: Name = '" + name + "' | Texture-Name = " + lightsArrayNames.toString());
	}
	
	//Block ID = 81
	private function parseMaterial(blockID:UInt):Void
	{
		// TODO: not used
		////blockLength = block.len; 
		var name:String;
		var type:UInt;
		var props:AWDProperties = null;
		var mat:MaterialBase = null;
		var attributes:Dynamic;
		var finalize:Bool;
		var num_methods:UInt;
		var methods_parsed:UInt;
		var assetVO:AssetVO;
		
		name = parseVarStr();
		type = _newBlockBytes.readUnsignedByte();
		num_methods = _newBlockBytes.readUnsignedByte();
		
		// Read material numerical properties
		// (1=color, 2=bitmap url, 10=alpha, 11=alpha_blending, 12=alpha_threshold, 13=repeat)
		props = parseProperties({ "1": INT32, "2": BADDR, "10": _propsNrType, "11": BOOL, "12": _propsNrType, "13": BOOL});
		
		methods_parsed = 0;
		while (methods_parsed < num_methods) {
			var method_type:UInt;
			
			method_type = _newBlockBytes.readUnsignedShort();
			parseProperties(null);
			parseUserAttributes();
			methods_parsed += 1;
		}
		var debugString:String = "";
		attributes = parseUserAttributes();
		if (type == 1) { // Color material
			debugString += "Parsed a ColorMaterial(SinglePass): Name = '" + name + "' | ";
			var color:UInt;
			color = props.get(1, 0xcccccc);
			if (materialMode < 2)
				mat = new ColorMaterial(color, props.get(10, 1.0));
			else
				mat = new ColorMultiPassMaterial(color);
			
		} else if (type == 2) {
			var tex_addr:UInt = props.get(2, 0);
			assetVO = getAssetByID(tex_addr, [Asset3DType.TEXTURE]);
			if (!assetVO.enable && (tex_addr > 0))
				_blocks[blockID].addError("Could not find the DiffsueTexture (ID = " + tex_addr + " ) for this Material");
			
			if (materialMode < 2) {
				mat = new TextureMaterial(assetVO.data);
				cast(mat, TextureMaterial).alphaBlending = props.get(11, false);
				cast(mat, TextureMaterial).alpha = props.get(10, 1.0);
				debugString += "Parsed a TextureMaterial(SinglePass): Name = '" + name + "' | Texture-Name = " + mat.name;
			} else {
				mat = new TextureMultiPassMaterial(assetVO.data);
				debugString += "Parsed a TextureMaterial(MultipAss): Name = '" + name + "' | Texture-Name = " + mat.name;
			}
		}
		
		mat.extra = attributes;
		if (materialMode < 2)
			cast(mat, SinglePassMaterialBase).alphaThreshold = props.get(12, 0.0);
		else
			cast(mat, MultiPassMaterialBase).alphaThreshold = props.get(12, 0.0);
		mat.repeat = props.get(13, false);
		
		finalizeAsset(mat, name);
		
		_blocks[blockID].data = mat;
		if (_debug)
			trace(debugString);
	}
	
	// Block ID = 81 AWD2.1
	private function parseMaterial_v1(blockID:UInt):Void
	{
		var mat:MaterialBase = null;
		var normalTexture:Texture2DBase = null;
		var specTexture:Texture2DBase = null;
		var assetVO:AssetVO;
		var name:String = parseVarStr();
		var type:Int = _newBlockBytes.readUnsignedByte();
		var num_methods:Int = _newBlockBytes.readUnsignedByte();
		var props:AWDProperties = parseProperties({"1": UINT32, "2": BADDR, "3": BADDR, "4": UINT8, "5": BOOL, "6": BOOL, "7": BOOL, "8": BOOL, "9": UINT8, "10": _propsNrType, "11": BOOL, "12": _propsNrType, "13": BOOL, "15": _propsNrType, "16": UINT32, "17": BADDR, "18": _propsNrType, "19": _propsNrType, "20": UINT32, "21": BADDR, "22": BADDR});
		
		var spezialType:Int = props.get(4, 0);
		var debugString:String = "";
		if (spezialType >= 2) { //this is no supported material
			_blocks[blockID].addError("Material-spezialType '" + spezialType + "' is not supported, can only be 0:singlePass, 1:MultiPass !");
			return;
		}
		if (materialMode == 1)
			spezialType = 0;
		else if (materialMode == 2)
			spezialType = 1;
		if (spezialType < 2) { //this is SinglePass or MultiPass
			if (type == 1) { // Color material
				var color:UInt = props.get(1, 0xcccccc);
				if (spezialType == 1) { //	MultiPassMaterial
					mat = new ColorMultiPassMaterial(color);
					debugString += "Parsed a ColorMaterial(MultiPass): Name = '" + name + "' | ";
				} else { //	SinglePassMaterial
					mat = new ColorMaterial(color, props.get(10, 1.0));
					cast(mat, ColorMaterial).alphaBlending = props.get(11, false);
					debugString += "Parsed a ColorMaterial(SinglePass): Name = '" + name + "' | ";
				}
			} else if (type == 2) { // texture material
				
				var tex_addr:UInt = props.get(2, 0);
				assetVO = getAssetByID(tex_addr, [Asset3DType.TEXTURE]);
				if (!assetVO.enable && (tex_addr > 0))
					_blocks[blockID].addError("Could not find the DiffsueTexture (ID = " + tex_addr + " ) for this TextureMaterial");
				var texture:Texture2DBase = assetVO.data;
				
				var ambientTexture:Texture2DBase = null;
				var ambientTex_addr:UInt = props.get(17, 0);
				assetVO = getAssetByID(ambientTex_addr, [Asset3DType.TEXTURE]);
				if (!assetVO.enable && (ambientTex_addr != 0))
					_blocks[blockID].addError("Could not find the AmbientTexture (ID = " + ambientTex_addr + " ) for this TextureMaterial");
				if (assetVO.enable)
					ambientTexture = assetVO.data;
				if (spezialType == 1) { // MultiPassMaterial
					mat = new TextureMultiPassMaterial(texture);
					debugString += "Parsed a TextureMaterial(MultiPass): Name = '" + name + "' | Texture-Name = " + texture.name;
					if (ambientTexture != null) {
						cast(mat, TextureMultiPassMaterial).ambientTexture = ambientTexture;
						debugString += " | AmbientTexture-Name = " + ambientTexture.name;
					}
				} else { //	SinglePassMaterial
					mat = new TextureMaterial(texture);
					debugString += "Parsed a TextureMaterial(SinglePass): Name = '" + name + "' | Texture-Name = " + texture.name;
					if (ambientTexture != null) {
						cast(mat, TextureMaterial).ambientTexture = ambientTexture;
						debugString += " | AmbientTexture-Name = " + ambientTexture.name;
					}
					cast(mat, TextureMaterial).alpha = props.get(10, 1.0);
					cast(mat, TextureMaterial).alphaBlending = props.get(11, false);
				}
				
			}
			var normalTex_addr:UInt = props.get(3, 0);
			assetVO = getAssetByID(normalTex_addr, [Asset3DType.TEXTURE]);
			if (!assetVO.enable && (normalTex_addr != 0))
				_blocks[blockID].addError("Could not find the NormalTexture (ID = " + normalTex_addr + " ) for this TextureMaterial");
			if (assetVO.enable) {
				normalTexture = assetVO.data;
				debugString += " | NormalTexture-Name = " + normalTexture.name;
			}
			
			var specTex_addr:UInt = props.get(21, 0);
			assetVO = getAssetByID(specTex_addr, [Asset3DType.TEXTURE]);
			if (!assetVO.enable && (specTex_addr != 0))
				_blocks[blockID].addError("Could not find the SpecularTexture (ID = " + specTex_addr + " ) for this TextureMaterial");
			if (assetVO.enable) {
				specTexture = assetVO.data;
				debugString += " | SpecularTexture-Name = " + specTexture.name;
			}
			var lightPickerAddr:UInt = props.get(22, 0);
			assetVO = getAssetByID(lightPickerAddr, [Asset3DType.LIGHT_PICKER]);
			if (!assetVO.enable && (lightPickerAddr != 0))
				_blocks[blockID].addError("Could not find the LightPicker (ID = " + lightPickerAddr + " ) for this TextureMaterial");
			else {
				cast(mat, MaterialBase).lightPicker = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(assetVO.data, LightPickerBase) ? cast assetVO.data : null;
				//debugString+=" | Lightpicker-Name = "+LightPickerBase(returnedArray[1]).name;
			}
			
			cast(mat, MaterialBase).smooth = props.get(5, true);
			cast(mat, MaterialBase).mipmap = props.get(6, true);
			cast(mat, MaterialBase).bothSides = props.get(7, false);
			cast(mat, MaterialBase).alphaPremultiplied = props.get(8, false);
			cast(mat, MaterialBase).blendMode = blendModeDic[props.get(9, 0)];
			cast(mat, MaterialBase).repeat = props.get(13, false);
			
			if (spezialType == 0) { // this is a SinglePassMaterial
				if (normalTexture != null)
					cast(mat, SinglePassMaterialBase).normalMap = normalTexture;
				if (specTexture != null)
					cast(mat, SinglePassMaterialBase).specularMap = specTexture;
				cast(mat, SinglePassMaterialBase).alphaThreshold = props.get(12, 0.0);
				cast(mat, SinglePassMaterialBase).ambient = props.get(15, 1.0);
				cast(mat, SinglePassMaterialBase).ambientColor = props.get(16, 0xffffff);
				cast(mat, SinglePassMaterialBase).specular = props.get(18, 1.0);
				cast(mat, SinglePassMaterialBase).gloss = props.get(19, 50);
				cast(mat, SinglePassMaterialBase).specularColor = props.get(20, 0xffffff);
			}

			else { // this is MultiPassMaterial
				if (normalTexture != null)
					cast(mat, MultiPassMaterialBase).normalMap = normalTexture;
				if (specTexture != null)
					cast(mat, MultiPassMaterialBase).specularMap = specTexture;
				cast(mat, MultiPassMaterialBase).alphaThreshold = props.get(12, 0.0);
				cast(mat, MultiPassMaterialBase).ambient = props.get(15, 1.0);
				cast(mat, MultiPassMaterialBase).ambientColor = props.get(16, 0xffffff);
				cast(mat, MultiPassMaterialBase).specular = props.get(18, 1.0);
				cast(mat, MultiPassMaterialBase).gloss = props.get(19, 50);
				cast(mat, MultiPassMaterialBase).specularColor = props.get(20, 0xffffff);
			}
			
			var methods_parsed:Int = 0;
			var targetID:Int;
			while (methods_parsed < num_methods) {
				var method_type:UInt;
				method_type = _newBlockBytes.readUnsignedShort();
				props = parseProperties({ "1" : BADDR, "2": BADDR, "3": BADDR, "101": _propsNrType, "102": _propsNrType, "103": _propsNrType, "201": UINT32, "202": UINT32, "301": UINT16, "302": UINT16, "401": UINT8, "402": UINT8, "601": COLOR, "602": COLOR, "701": BOOL, "702": BOOL, "801": MTX4x4});
				switch (method_type) {
					case 999: //wrapper-Methods that will load a previous parsed EffektMethod returned
						targetID = props.get(1, 0);
						assetVO = getAssetByID(targetID, [Asset3DType.EFFECTS_METHOD]);
						if (!assetVO.enable)
							_blocks[blockID].addError("Could not find the EffectMethod (ID = " + targetID + " ) for this Material");
						else {
							if (spezialType == 0)
								cast(mat, SinglePassMaterialBase).addMethod(assetVO.data);
							if (spezialType == 1)
								cast(mat, MultiPassMaterialBase).addMethod(assetVO.data);
							debugString += " | EffectMethod-Name = " + cast(assetVO.data, EffectMethodBase).name;
						}
					case 998: //wrapper-Methods that will load a previous parsed ShadowMapMethod
						targetID = props.get(1, 0);
						assetVO = getAssetByID(targetID, [Asset3DType.SHADOW_MAP_METHOD]);
						if (!assetVO.enable)
							_blocks[blockID].addError("Could not find the ShadowMethod (ID = " + targetID + " ) for this Material");
						else {
							if (spezialType == 0)
								cast(mat, SinglePassMaterialBase).shadowMethod = assetVO.data;
							if (spezialType == 1)
								cast(mat, MultiPassMaterialBase).shadowMethod = assetVO.data;
							debugString += " | ShadowMethod-Name = " + cast(assetVO.data, ShadowMapMethodBase).name;
						}
					case 1: //EnvMapAmbientMethod
						targetID = props.get(1, 0);
						assetVO = getAssetByID(targetID, [Asset3DType.TEXTURE], "CubeTexture");
						if (!assetVO.enable)
							_blocks[blockID].addError("Could not find the EnvMap (ID = " + targetID + " ) for this EnvMapAmbientMethodMaterial");
						if (spezialType == 0)
							cast(mat, SinglePassMaterialBase).ambientMethod = new EnvMapAmbientMethod(assetVO.data);
						if (spezialType == 1)
							cast(mat, MultiPassMaterialBase).ambientMethod = new EnvMapAmbientMethod(assetVO.data);
						debugString += " | EnvMapAmbientMethod | EnvMap-Name =" + cast(assetVO.data, CubeTextureBase).name;
					case 51: //DepthDiffuseMethod
						if (spezialType == 0)
							cast(mat, SinglePassMaterialBase).diffuseMethod = new DepthDiffuseMethod();
						if (spezialType == 1)
							cast(mat, MultiPassMaterialBase).diffuseMethod = new DepthDiffuseMethod();
						debugString += " | DepthDiffuseMethod";
					case 52: //GradientDiffuseMethod
						targetID = props.get(1, 0);
						assetVO = getAssetByID(targetID, [Asset3DType.TEXTURE]);
						if (!assetVO.enable)
							_blocks[blockID].addError("Could not find the GradientDiffuseTexture (ID = " + targetID + " ) for this GradientDiffuseMethod");
						if (spezialType == 0)
							cast(mat, SinglePassMaterialBase).diffuseMethod = new GradientDiffuseMethod(assetVO.data);
						if (spezialType == 1)
							cast(mat, MultiPassMaterialBase).diffuseMethod = new GradientDiffuseMethod(assetVO.data);
						debugString += " | GradientDiffuseMethod | GradientDiffuseTexture-Name =" + cast(assetVO.data, Texture2DBase).name;
					case 53: //WrapDiffuseMethod
						if (spezialType == 0)
							cast(mat, SinglePassMaterialBase).diffuseMethod = new WrapDiffuseMethod(props.get(101, 5));
						if (spezialType == 1)
							cast(mat, MultiPassMaterialBase).diffuseMethod = new WrapDiffuseMethod(props.get(101, 5));
						debugString += " | WrapDiffuseMethod";
					case 54: //LightMapDiffuseMethod
						targetID = props.get(1, 0);
						assetVO = getAssetByID(targetID, [Asset3DType.TEXTURE]);
						if (!assetVO.enable)
							_blocks[blockID].addError("Could not find the LightMap (ID = " + targetID + " ) for this LightMapDiffuseMethod");
						if (spezialType == 0)
							cast(mat, SinglePassMaterialBase).diffuseMethod = new LightMapDiffuseMethod(assetVO.data, blendModeDic[props.get(401, 10)], false, cast(mat, SinglePassMaterialBase).diffuseMethod);
						if (spezialType == 1)
							cast(mat, MultiPassMaterialBase).diffuseMethod = new LightMapDiffuseMethod(assetVO.data, blendModeDic[props.get(401, 10)], false, cast(mat, MultiPassMaterialBase).diffuseMethod);
						debugString += " | LightMapDiffuseMethod | LightMapTexture-Name =" + cast(assetVO.data, Texture2DBase).name;
					case 55: //CelDiffuseMethod
						if (spezialType == 0) {
							cast(mat, SinglePassMaterialBase).diffuseMethod = new CelDiffuseMethod(props.get(401, 3), cast(mat, SinglePassMaterialBase).diffuseMethod);
							cast(cast(mat, SinglePassMaterialBase).diffuseMethod, CelDiffuseMethod).smoothness = props.get(101, 0.1);
						}
						if (spezialType == 1) {
							cast(mat, MultiPassMaterialBase).diffuseMethod = new CelDiffuseMethod(props.get(401, 3), cast(mat, MultiPassMaterialBase).diffuseMethod);
							cast(cast(mat, MultiPassMaterialBase).diffuseMethod, CelDiffuseMethod).smoothness = props.get(101, 0.1);
						}
						debugString += " | CelDiffuseMethod";
					case 56: //SubSurfaceScatteringMethod
						if (spezialType == 0) {
							cast(mat, SinglePassMaterialBase).diffuseMethod = new SubsurfaceScatteringDiffuseMethod(); //depthMapSize and depthMapOffset ?
							cast(cast(mat, SinglePassMaterialBase).diffuseMethod, SubsurfaceScatteringDiffuseMethod).scattering = props.get(101, 0.2);
							cast(cast(mat, SinglePassMaterialBase).diffuseMethod, SubsurfaceScatteringDiffuseMethod).translucency = props.get(102, 1);
							cast(cast(mat, SinglePassMaterialBase).diffuseMethod, SubsurfaceScatteringDiffuseMethod).scatterColor = props.get(601, 0xffffff);
						}
						if (spezialType == 1) {
							cast(mat, MultiPassMaterialBase).diffuseMethod = new SubsurfaceScatteringDiffuseMethod(); //depthMapSize and depthMapOffset ?
							cast(cast(mat, MultiPassMaterialBase).diffuseMethod, SubsurfaceScatteringDiffuseMethod).scattering = props.get(101, 0.2);
							cast(cast(mat, MultiPassMaterialBase).diffuseMethod, SubsurfaceScatteringDiffuseMethod).translucency = props.get(102, 1);
							cast(cast(mat, MultiPassMaterialBase).diffuseMethod, SubsurfaceScatteringDiffuseMethod).scatterColor = props.get(601, 0xffffff);
						}
						debugString += " | SubSurfaceScatteringMethod";
					case 101: //AnisotropicSpecularMethod
						if (spezialType == 0)
							cast(mat, SinglePassMaterialBase).specularMethod = new AnisotropicSpecularMethod();
						if (spezialType == 1)
							cast(mat, MultiPassMaterialBase).specularMethod = new AnisotropicSpecularMethod();
						debugString += " | AnisotropicSpecularMethod";
					case 102: //PhongSpecularMethod
						if (spezialType == 0)
							cast(mat, SinglePassMaterialBase).specularMethod = new PhongSpecularMethod();
						if (spezialType == 1)
							cast(mat, MultiPassMaterialBase).specularMethod = new PhongSpecularMethod();
						debugString += " | PhongSpecularMethod";
					case 103: //CellSpecularMethod
						if (spezialType == 0) {
							cast(mat, SinglePassMaterialBase).specularMethod = new CelSpecularMethod(props.get(101, 0.5), cast(mat, SinglePassMaterialBase).specularMethod);
							cast(cast(mat, SinglePassMaterialBase).specularMethod, CelSpecularMethod).smoothness = props.get(102, 0.1);
						}
						if (spezialType == 1) {
							cast(mat, MultiPassMaterialBase).specularMethod = new CelSpecularMethod(props.get(101, 0.5), cast(mat, MultiPassMaterialBase).specularMethod);
							cast(cast(mat, MultiPassMaterialBase).specularMethod, CelSpecularMethod).smoothness = props.get(102, 0.1);
						}
						debugString += " | CellSpecularMethod";
					case 104: //FresnelSpecularMethod
						if (spezialType == 0) {
							cast(mat, SinglePassMaterialBase).specularMethod = new FresnelSpecularMethod(props.get(701, true), cast(mat, SinglePassMaterialBase).specularMethod);
							cast(cast(mat, SinglePassMaterialBase).specularMethod, FresnelSpecularMethod).fresnelPower = props.get(101, 5);
							cast(cast(mat, SinglePassMaterialBase).specularMethod, FresnelSpecularMethod).normalReflectance = props.get(102, 0.1);
						}
						if (spezialType == 1) {
							cast(mat, MultiPassMaterialBase).specularMethod = new FresnelSpecularMethod(props.get(701, true), cast(mat, MultiPassMaterialBase).specularMethod);
							cast(cast(mat, MultiPassMaterialBase).specularMethod, FresnelSpecularMethod).fresnelPower = props.get(101, 5);
							cast(cast(mat, MultiPassMaterialBase).specularMethod, FresnelSpecularMethod).normalReflectance = props.get(102, 0.1);
						}
						debugString += " | FresnelSpecularMethod";
					//case 151://HeightMapNormalMethod - thios is not implemented for now, but might appear later
					case 152: //SimpleWaterNormalMethod
						targetID = props.get(1, 0);
						assetVO = getAssetByID(targetID, [Asset3DType.TEXTURE]);
						if (!assetVO.enable)
							_blocks[blockID].addError("Could not find the SecoundNormalMap (ID = " + targetID + " ) for this SimpleWaterNormalMethod");
						if (spezialType == 0) {
							if (cast(mat, SinglePassMaterialBase).normalMap == null)
								_blocks[blockID].addError("Could not find a normal Map on this Material to use with this SimpleWaterNormalMethod");
							cast(mat, SinglePassMaterialBase).normalMap = assetVO.data;
							cast(mat, SinglePassMaterialBase).normalMethod = new SimpleWaterNormalMethod(cast(mat, SinglePassMaterialBase).normalMap, assetVO.data);
						}
						if (spezialType == 1) {
							if (cast(mat, MultiPassMaterialBase).normalMap == null)
								_blocks[blockID].addError("Could not find a normal Map on this Material to use with this SimpleWaterNormalMethod");
							cast(mat, MultiPassMaterialBase).normalMap = assetVO.data;
							cast(mat, MultiPassMaterialBase).normalMethod = new SimpleWaterNormalMethod(cast(mat, MultiPassMaterialBase).normalMap, assetVO.data);
						}
						debugString += " | SimpleWaterNormalMethod | Second-NormalTexture-Name = " + cast(assetVO.data, Texture2DBase).name;
				}
				parseUserAttributes();
				methods_parsed += 1;
			}
		}
		cast(mat, MaterialBase).extra = parseUserAttributes();
		finalizeAsset(mat, name);
		_blocks[blockID].data = mat;
		if (_debug)
			trace(debugString);
	}
	
	//Block ID = 82
	private function parseTexture(blockID:UInt):Void
	{
		var asset:Texture2DBase = null;
		
		_blocks[blockID].name = parseVarStr();
		var type:Int = _newBlockBytes.readUnsignedByte();
		var data_len:Int;
		_texture_users[Std.string(_cur_block_id)] = [];
		
		// External
		if (type == 0) {
			data_len = _newBlockBytes.readUnsignedInt();
			var url:String;
			url = _newBlockBytes.readUTFBytes(data_len);
			addDependency(Std.string(_cur_block_id), new URLRequest(url), false, null, true);
		}
		else {
			data_len = _newBlockBytes.readUnsignedInt();
			var data:ByteArray;
			data = new ByteArray();
			data.endian = BIG_ENDIAN;
			_newBlockBytes.readBytes(data, 0, data_len);
			addDependency(Std.string(_cur_block_id), null, false, data, true);
		}
		// Ignore for now
		parseProperties(null);
		_blocks[blockID].extras = parseUserAttributes();
		pauseAndRetrieveDependencies();
		_blocks[blockID].data = asset;
		if (_debug) {
			var textureStylesNames:Array<String> = ["external", "embed"];
			trace("Start parsing a " + textureStylesNames[type] + " Bitmap for Texture");
		}
	}
	
	//Block ID = 83
	private function parseCubeTexture(blockID:UInt):Void
	{
		//blockLength = block.len;
		var data_len:UInt;
		var asset:CubeTextureBase = null;
		_cubeTextures = new Array();
		_texture_users[Std.string(_cur_block_id)] = [];
		var type:Int = _newBlockBytes.readUnsignedByte();
		_blocks[blockID].name = parseVarStr();
		
		for (i in 0...6) {
			_texture_users[Std.string(_cur_block_id)] = [];
			_cubeTextures.push(null);
			// External
			if (type == 0) {
				data_len = _newBlockBytes.readUnsignedInt();
				var url:String;
				url = _newBlockBytes.readUTFBytes(data_len);
				addDependency(Std.string(_cur_block_id) + "#" + i, new URLRequest(url), false, null, true);
			} else {
				data_len = _newBlockBytes.readUnsignedInt();
				var data:ByteArray;
				data = new ByteArray();
				data.endian = BIG_ENDIAN;
				_newBlockBytes.readBytes(data, 0, data_len);
				addDependency(Std.string(_cur_block_id) + "#" + i, null, false, data, true);
			}
		}
		
		// Ignore for now
		parseProperties(null);
		_blocks[blockID].extras = parseUserAttributes();
		pauseAndRetrieveDependencies();
		_blocks[blockID].data = asset;
		if (_debug) {
			var textureStylesNames:Array<String> = ["external", "embed"];
			trace("Start parsing 6 " + textureStylesNames[type] + " Bitmaps for CubeTexture");
		}
	}
	
	//Block ID = 91
	private function parseSharedMethodBlock(blockID:UInt):Void
	{
		var asset:EffectMethodBase;
		_blocks[blockID].name = parseVarStr();
		asset = parseSharedMethodList(blockID);
		parseUserAttributes();
		_blocks[blockID].data = asset;
		finalizeAsset(asset, _blocks[blockID].name);
		_blocks[blockID].data = asset;
		if (_debug)
			trace("Parsed a EffectMethod: Name = " + asset.name + " Type = " + asset);
	}
	
	// this functions reads and creates a EffectMethod
	private function parseSharedMethodList(blockID:UInt):EffectMethodBase
	{
		
		var methodType:UInt = _newBlockBytes.readUnsignedShort();
		var effectMethodReturn:EffectMethodBase = null;
		var props:AWDProperties = parseProperties({"1": BADDR, "2": BADDR, "3": BADDR, "101": _propsNrType, "102": _propsNrType, "103": _propsNrType, "104": _propsNrType, "105": _propsNrType, "106": _propsNrType, "107": _propsNrType, "201": UINT32, "202": UINT32, "301": UINT16, "302": UINT16, "401": UINT8, "402": UINT8, "601": COLOR, "602": COLOR, "701": BOOL, "702": BOOL});
		var targetID:UInt;
		var assetVO:AssetVO;
		switch (methodType) {
			// Effect Methods
			case 401: //ColorMatrix
				effectMethodReturn = new ColorMatrixMethod(props.get(101, [0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]));
			case 402: //ColorTransform
				effectMethodReturn = new ColorTransformMethod();
				var offCol:UInt = props.get(601, 0x00000000);
				var newColorTransform:ColorTransform = new ColorTransform(props.get(102, 1), props.get(103, 1), props.get(104, 1), props.get(101, 1), ((offCol >> 16) & 0xFF), ((offCol >> 8) & 0xFF), (offCol & 0xFF), ((offCol >> 24) & 0xFF));
				cast(effectMethodReturn, ColorTransformMethod).colorTransform = newColorTransform;
			case 403: //EnvMap
				targetID = props.get(1, 0);
				assetVO = getAssetByID(targetID, [Asset3DType.TEXTURE], "CubeTexture");
				if (!assetVO.enable)
					_blocks[blockID].addError("Could not find the EnvMap (ID = " + targetID + " ) for this EnvMapMethod");
				effectMethodReturn = new EnvMapMethod(assetVO.data, props.get(101, 1));
				targetID = props.get(2, 0);
				if (targetID > 0) {
					assetVO = getAssetByID(targetID, [Asset3DType.TEXTURE]);
					if (!assetVO.enable)
						_blocks[blockID].addError("Could not find the Mask-texture (ID = " + targetID + " ) for this EnvMapMethod");
					cast(effectMethodReturn, EnvMapMethod).mask = assetVO.data;
				}
			case 404: //LightMapMethod
				targetID = props.get(1, 0);
				assetVO = getAssetByID(targetID, [Asset3DType.TEXTURE]);
				if (!assetVO.enable)
					_blocks[blockID].addError("Could not find the LightMap (ID = " + targetID + " ) for this LightMapMethod");
				effectMethodReturn = new LightMapMethod(assetVO.data, blendModeDic[props.get(401, 10)]); //usesecondaryUV not set
			case 405: //ProjectiveTextureMethod
				targetID = props.get(1, 0);
				assetVO = getAssetByID(targetID, [Asset3DType.TEXTURE_PROJECTOR]);
				if (!assetVO.enable)
					_blocks[blockID].addError("Could not find the TextureProjector (ID = " + targetID + " ) for this ProjectiveTextureMethod");
				effectMethodReturn = new ProjectiveTextureMethod(assetVO.data, blendModeDic[props.get(401, 10)]);
			case 406: //RimLightMethod
				effectMethodReturn = new RimLightMethod(props.get(601, 0xffffff), props.get(101, 0.4), props.get(101, 2));
			case 407: //AlphaMaskMethod
				targetID = props.get(1, 0);
				assetVO = getAssetByID(targetID, [Asset3DType.TEXTURE]);
				if (!assetVO.enable)
					_blocks[blockID].addError("Could not find the Alpha-texture (ID = " + targetID + " ) for this AlphaMaskMethod");
				effectMethodReturn = new AlphaMaskMethod(assetVO.data, props.get(701, false));
			case 408: //RefractionEnvMapMethod
				targetID = props.get(1, 0);
				assetVO = getAssetByID(targetID, [Asset3DType.TEXTURE], "CubeTexture");
				if (!assetVO.enable)
					_blocks[blockID].addError("Could not find the EnvMap (ID = " + targetID + " ) for this RefractionEnvMapMethod");
				effectMethodReturn = new RefractionEnvMapMethod(assetVO.data, props.get(101, 0.1), props.get(102, 0.01), props.get(103, 0.01), props.get(104, 0.01));
				cast(effectMethodReturn, RefractionEnvMapMethod).alpha = props.get(104, 1);
			case 409: //OutlineMethod
				effectMethodReturn = new OutlineMethod(props.get(601, 0x00000000), props.get(101, 1), props.get(701, true), props.get(702, false));
			case 410: //FresnelEnvMapMethod
				targetID = props.get(1, 0);
				assetVO = getAssetByID(targetID, [Asset3DType.TEXTURE], "CubeTexture");
				if (!assetVO.enable)
					_blocks[blockID].addError("Could not find the EnvMap (ID = " + targetID + " ) for this FresnelEnvMapMethod");
				effectMethodReturn = new FresnelEnvMapMethod(assetVO.data, props.get(101, 1));
			case 411: //FogMethod
				effectMethodReturn = new FogMethod(props.get(101, 0), props.get(102, 1000), props.get(601, 0x808080));
		}
		parseUserAttributes();
		return effectMethodReturn;
	}
	
	//Block ID = 92
	private function parseShadowMethodBlock(blockID:UInt):Void
	{
		var type:UInt;
		var data_len:UInt;
		var asset:ShadowMapMethodBase;
		var shadowLightID:UInt;
		_blocks[blockID].name = parseVarStr();
		shadowLightID = _newBlockBytes.readUnsignedInt();
		var assetVO:AssetVO = getAssetByID(shadowLightID, [Asset3DType.LIGHT]);
		if (!assetVO.enable) {
			_blocks[blockID].addError("Could not find the TargetLight (ID = " + shadowLightID + " ) for this ShadowMethod - ShadowMethod not created");
			return;
		}
		asset = parseShadowMethodList(cast(assetVO.data, LightBase), blockID);
		if (asset == null)
			return;
		parseUserAttributes(); // Ignore for now
		finalizeAsset(asset, _blocks[blockID].name);
		_blocks[blockID].data = asset;
		if (_debug)
			trace("Parsed a ShadowMapMethodMethod: Name = " + asset.name + " | Type = " + asset + " | Light-Name = " + cast(assetVO.data, LightBase));
	}
	
	// this functions reads and creates a ShadowMethodMethod
	private function parseShadowMethodList(light:LightBase, blockID:UInt):ShadowMapMethodBase
	{
		
		var methodType:UInt = _newBlockBytes.readUnsignedShort();
		var shadowMethod:ShadowMapMethodBase = null;
		var props:AWDProperties = parseProperties({"1": BADDR, "2": BADDR, "3": BADDR, "101": _propsNrType, "102": _propsNrType, "103": _propsNrType, "201": UINT32, "202": UINT32, "301": UINT16, "302": UINT16, "401": UINT8, "402": UINT8, "601": COLOR, "602": COLOR, "701": BOOL, "702": BOOL, "801": MTX4x4});
		var targetID:UInt;
		var assetVO:AssetVO;
		switch (methodType) {
			case 1001: //CascadeShadowMapMethod
				targetID = props.get(1, 0);
				assetVO = getAssetByID(targetID, [Asset3DType.SHADOW_MAP_METHOD]);
				if (!assetVO.enable) {
					_blocks[blockID].addError("Could not find the ShadowBaseMethod (ID = " + targetID + " ) for this CascadeShadowMapMethod - ShadowMethod not created");
					return shadowMethod;
				}
				shadowMethod = new CascadeShadowMapMethod(assetVO.data);
			case 1002: //NearShadowMapMethod
				targetID = props.get(1, 0);
				assetVO = getAssetByID(targetID, [Asset3DType.SHADOW_MAP_METHOD]);
				if (!assetVO.enable) {
					_blocks[blockID].addError("Could not find the ShadowBaseMethod (ID = " + targetID + " ) for this NearShadowMapMethod - ShadowMethod not created");
					return shadowMethod;
				}
				shadowMethod = new NearShadowMapMethod(assetVO.data);
			case 1101: //FilteredShadowMapMethod
				shadowMethod = new FilteredShadowMapMethod(cast(light, DirectionalLight));
				cast(shadowMethod, FilteredShadowMapMethod).alpha = props.get(101, 1);
				cast(shadowMethod, FilteredShadowMapMethod).epsilon = props.get(102, 0.002);
			case 1102: //DitheredShadowMapMethod
				shadowMethod = new DitheredShadowMapMethod(cast(light, DirectionalLight), props.get(201, 5));
				cast(shadowMethod, DitheredShadowMapMethod).alpha = props.get(101, 1);
				cast(shadowMethod, DitheredShadowMapMethod).epsilon = props.get(102, 0.002);
				cast(shadowMethod, DitheredShadowMapMethod).range = props.get(103, 1);
			case 1103: //SoftShadowMapMethod
				shadowMethod = new SoftShadowMapMethod(cast(light, DirectionalLight), props.get(201, 5));
				cast(shadowMethod, SoftShadowMapMethod).alpha = props.get(101, 1);
				cast(shadowMethod, SoftShadowMapMethod).epsilon = props.get(102, 0.002);
				cast(shadowMethod, SoftShadowMapMethod).range = props.get(103, 1);
			case 1104: //HardShadowMapMethod
				shadowMethod = new HardShadowMapMethod(light);
				cast(shadowMethod, HardShadowMapMethod).alpha = props.get(101, 1);
				cast(shadowMethod, HardShadowMapMethod).epsilon = props.get(102, 0.002);

		}
		parseUserAttributes();
		return shadowMethod;
	}
	
	//Block ID 101
	private function parseSkeleton(blockID:UInt):Void
	{
		var name:String = parseVarStr();
		var num_joints:Int = _newBlockBytes.readUnsignedShort();
		var skeleton:Skeleton = new Skeleton();
		parseProperties(null); // Discard properties for now
		
		var joints_parsed:Int = 0;
		while (joints_parsed < num_joints) {
			var joint:SkeletonJoint;
			var ibp:Matrix3D;
			// Ignore joint id
			_newBlockBytes.readUnsignedShort();
			joint = new SkeletonJoint();
			joint.parentIndex = _newBlockBytes.readUnsignedShort() - 1; // 0=null in AWD
			joint.name = parseVarStr();
			
			ibp = parseMatrix3D();
			joint.inverseBindPose = ibp.rawData;
			// Ignore joint props/attributes for now
			parseProperties(null);
			parseUserAttributes();
			skeleton.joints.push(joint);
			joints_parsed++;
		}
		
		// Discard attributes for now
		parseUserAttributes();
		finalizeAsset(skeleton, name);
		_blocks[blockID].data = skeleton;
		if (_debug)
			trace("Parsed a Skeleton: Name = " + skeleton.name + " | Number of Joints = " + joints_parsed);
	}
	
	//Block ID = 102
	private function parseSkeletonPose(blockID:UInt):Void
	{
		var name:String = parseVarStr();
		var num_joints:UInt = _newBlockBytes.readUnsignedShort();
		parseProperties(null); // Ignore properties for now
		
		var pose:SkeletonPose = new SkeletonPose();
		
		var joints_parsed:UInt = 0;
		while (joints_parsed < num_joints) {
			var joint_pose:JointPose;
			var has_transform:UInt;
			joint_pose = new JointPose();
			has_transform = _newBlockBytes.readUnsignedByte();
			if (has_transform == 1) {
				var mtx_data:Vector<Float> = parseMatrix43RawData();
				
				var mtx:Matrix3D = new Matrix3D(mtx_data);
				joint_pose.orientation.fromMatrix(mtx);
				joint_pose.translation.copyFrom(mtx.position);
				
				pose.jointPoses[joints_parsed] = joint_pose;
			}
			joints_parsed++;
		}
		// Skip attributes for now
		parseUserAttributes();
		finalizeAsset(pose, name);
		_blocks[blockID].data = pose;
		if (_debug)
			trace("Parsed a SkeletonPose: Name = " + pose.name + " | Number of Joints = " + joints_parsed);
	}
	
	//blockID 103
	private function parseSkeletonAnimation(blockID:UInt):Void
	{
		var frame_dur:UInt;
		var pose_addr:UInt;
		var name:String = parseVarStr();
		var clip:SkeletonClipNode = new SkeletonClipNode();
		var num_frames:UInt = _newBlockBytes.readUnsignedShort();
		parseProperties(null); // Ignore properties for now
		
		var frames_parsed:UInt = 0;
		var assetVO:AssetVO;
		while (frames_parsed < num_frames) {
			pose_addr = _newBlockBytes.readUnsignedInt();
			frame_dur = _newBlockBytes.readUnsignedShort();
			assetVO = getAssetByID(pose_addr, [Asset3DType.SKELETON_POSE]);
			if (!assetVO.enable)
				_blocks[blockID].addError("Could not find the SkeletonPose Frame # " + frames_parsed + " (ID = " + pose_addr + " ) for this SkeletonClipNode");
			else
				clip.addFrame(cast(_blocks[pose_addr].data, SkeletonPose), frame_dur);
			frames_parsed++;
		}
		if (clip.frames.length == 0) {
			_blocks[blockID].addError("Could not this SkeletonClipNode, because no Frames where set.");
			return;
		}
		// Ignore attributes for now
		parseUserAttributes();
		finalizeAsset(clip, name);
		_blocks[blockID].data = clip;
		if (_debug)
			trace("Parsed a SkeletonClipNode: Name = " + clip.name + " | Number of Frames = " + clip.frames.length);
	}
	
	//Block ID = 111 /  Block ID = 112
	private function parseMeshPoseAnimation(blockID:UInt, poseOnly:Bool = false):Void
	{
		var num_frames:UInt = 1;
		var num_submeshes:UInt;
		var frames_parsed:UInt;
		var subMeshParsed:UInt;
		var frame_dur:Int;
		var x:Float;
		var y:Float;
		var z:Float;
		var str_len:UInt;
		var str_end:UInt;
		var geometry:Geometry;
		var subGeom:CompactSubGeometry;
		var idx:Int = 0;
		var clip:VertexClipNode = new VertexClipNode();
		var indices:Vector<UInt>;
		var verts:Vector<Float>;
		var num_Streams:Int = 0;
		var streamsParsed:Int = 0;
		var streamtypes:Vector<Int> = new Vector<Int>();
		var props:AWDProperties;
		var thisGeo:Geometry;
		var name:String = parseVarStr();
		var geoAdress:Int = _newBlockBytes.readUnsignedInt();
		var assetVO:AssetVO = getAssetByID(geoAdress, [Asset3DType.GEOMETRY]);
		if (!assetVO.enable) {
			_blocks[blockID].addError("Could not find the target-Geometry-Object " + geoAdress + " ) for this VertexClipNode");
			return;
		}
		var uvs:Vector<Vector<Float>> = getUVForVertexAnimation(geoAdress);
		if (!poseOnly)
			num_frames = _newBlockBytes.readUnsignedShort();
		
		num_submeshes = _newBlockBytes.readUnsignedShort();
		num_Streams = _newBlockBytes.readUnsignedShort();
		streamsParsed = 0;
		while (streamsParsed < num_Streams) {
			streamtypes.push(_newBlockBytes.readUnsignedShort());
			streamsParsed++;
		}
		props = parseProperties({"1": BOOL, "2": BOOL});
		
		clip.looping = props.get(1, true);
		clip.stitchFinalFrame = props.get(2, false);
		
		frames_parsed = 0;
		while (frames_parsed < num_frames) {
			frame_dur = _newBlockBytes.readUnsignedShort();
			geometry = new Geometry();
			subMeshParsed = 0;
			while (subMeshParsed < num_submeshes) {
				streamsParsed = 0;
				str_len = _newBlockBytes.readUnsignedInt();
				str_end = _newBlockBytes.position + str_len;
				while (streamsParsed < num_Streams) {
					if (streamtypes[streamsParsed] == 1) {
						indices = assetVO.data.subGeometries[subMeshParsed].indexData;
						verts = new Vector<Float>();
						idx = 0;
						while (_newBlockBytes.position < str_end) {
							x = readNumber(_accuracyGeo);
							y = readNumber(_accuracyGeo);
							z = readNumber(_accuracyGeo);
							verts[idx++] = x;
							verts[idx++] = y;
							verts[idx++] = z;
						}
						subGeom = new CompactSubGeometry();
						subGeom.fromVectors(verts, uvs[subMeshParsed], null, null);
						subGeom.updateIndexData(indices);
						subGeom.vertexNormalData;
						subGeom.vertexTangentData;
						subGeom.autoDeriveVertexNormals = false;
						subGeom.autoDeriveVertexTangents = false;
						subMeshParsed++;
						geometry.addSubGeometry(subGeom);
					} else
						_newBlockBytes.position = str_end;
					streamsParsed++;
				}
			}
			clip.addFrame(geometry, frame_dur);
			frames_parsed++;
		}
		parseUserAttributes();
		finalizeAsset(clip, name);
		
		_blocks[blockID].data = clip;
		if (_debug)
			trace("Parsed a VertexClipNode: Name = " + clip.name + " | Target-Geometry-Name = " + cast(assetVO.data, Geometry).name + " | Number of Frames = " + clip.frames.length);
	}
	
	//BlockID 113
	private function parseVertexAnimationSet(blockID:UInt):Void
	{
		var assetVO:AssetVO;
		var poseBlockAdress:Int = -1;
		var outputString:String = "";
		var name:String = parseVarStr();
		var num_frames:UInt = _newBlockBytes.readUnsignedShort();
		var props:AWDProperties = parseProperties({"1": UINT16});
		var frames_parsed:UInt = 0;
		var skeletonFrames:Vector<SkeletonClipNode> = new Vector<SkeletonClipNode>();
		var vertexFrames:Vector<VertexClipNode> = new Vector<VertexClipNode>();
		while (frames_parsed < num_frames) {
			poseBlockAdress = _newBlockBytes.readUnsignedInt();
			assetVO = getAssetByID(poseBlockAdress, [Asset3DType.ANIMATION_NODE]);
			if (!assetVO.enable)
				_blocks[blockID].addError("Could not find the AnimationClipNode Nr " + frames_parsed + " ( " + poseBlockAdress + " ) for this AnimationSet");
			else {
				if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(assetVO.data, VertexClipNode))
					vertexFrames.push(assetVO.data);
				if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(assetVO.data, SkeletonClipNode))
					skeletonFrames.push(assetVO.data);
			}
			frames_parsed++;
		}
		if ((vertexFrames.length == 0) && (skeletonFrames.length == 0)) {
			_blocks[blockID].addError("Could not create this AnimationSet, because it contains no animations");
			return;
		}
		parseUserAttributes();
		if (vertexFrames.length > 0) {
			var newVertexAnimationSet:VertexAnimationSet = new VertexAnimationSet();
			for (vertexFrame in vertexFrames)
				newVertexAnimationSet.addAnimation(vertexFrame);
			finalizeAsset(newVertexAnimationSet, name);
			_blocks[blockID].data = newVertexAnimationSet;
			if (_debug)
				trace("Parsed a VertexAnimationSet: Name = " + name + " | Animations = " + newVertexAnimationSet.animations.length + " | Animation-Names = " + newVertexAnimationSet.animationNames.toString());

		} else if (skeletonFrames.length > 0) {
			assetVO = getAssetByID(poseBlockAdress, [Asset3DType.ANIMATION_NODE]);
			var newSkeletonAnimationSet:SkeletonAnimationSet = new SkeletonAnimationSet(props.get(1, 4)); //props.get(1,4));
			var skeletFrame:SkeletonClipNode;
			for (skeletFrame in skeletonFrames)
				newSkeletonAnimationSet.addAnimation(skeletFrame);
			finalizeAsset(newSkeletonAnimationSet, name);
			_blocks[blockID].data = newSkeletonAnimationSet;
			if (_debug)
				trace("Parsed a SkeletonAnimationSet: Name = " + name + " | Animations = " + newSkeletonAnimationSet.animations.length + " | Animation-Names = " + newSkeletonAnimationSet.animationNames.toString());
			
		}
	}
	
	//blockID 121
	private function parseUVAnimation(blockID:UInt):Void
	{
		var name:String = parseVarStr();
		var num_frames:UInt = _newBlockBytes.readUnsignedShort();
		var props:AWDProperties = parseProperties(null);
		var clip:UVClipNode = new UVClipNode();
		var dummy:Sprite = new Sprite();
		var frames_parsed:UInt = 0;
		while (frames_parsed < num_frames) {
			// TODO: Replace this with some reliable way to decompose a 2d matrix
			var mtx:Matrix = parseMatrix2D();
			mtx.scale(100, 100);
			dummy.transform.matrix = mtx;
			var frame_dur:UInt = _newBlockBytes.readUnsignedShort();
			var frame:UVAnimationFrame = new UVAnimationFrame(dummy.x * 0.01, dummy.y * 0.01, dummy.scaleX / 100, dummy.scaleY / 100, dummy.rotation);
			clip.addFrame(frame, frame_dur);
			frames_parsed++;
		}
		// Ignore for now
		parseUserAttributes();
		finalizeAsset(clip, name);
		_blocks[blockID].data = clip;
		if (_debug)
			trace("Parsed a UVClipNode: Name = " + name + " | Number of Frames = " + frames_parsed);
	}
	
	//BlockID 122
	private function parseAnimatorSet(blockID:UInt):Void
	{
		var targetMesh:Mesh;
		var animSetBlockAdress:Int;
		var targetAnimationSet:AnimationSetBase;
		var outputString:String = "";
		var name:String = parseVarStr();
		var type:UInt = _newBlockBytes.readUnsignedShort();
		
		var props:AWDProperties = parseProperties({"1": BADDR});
		
		animSetBlockAdress = _newBlockBytes.readUnsignedInt();
		var targetMeshLength:UInt = _newBlockBytes.readUnsignedShort();
		var meshAdresses:Vector<UInt> = new Vector<UInt>();
		for (i in 0...targetMeshLength)
			meshAdresses.push(_newBlockBytes.readUnsignedInt());
		
		var activeState:UInt = _newBlockBytes.readUnsignedShort();
		var autoplay:Bool = _newBlockBytes.readUnsignedByte() != 0;
		parseUserAttributes();
		parseUserAttributes();
		
		var assetVO:AssetVO;
		var targetMeshes:Vector<Mesh> = new Vector<Mesh>();
		
		for (i in 0...meshAdresses.length) {
			assetVO = getAssetByID(meshAdresses[i], [Asset3DType.MESH]);
			if (assetVO.enable)
				targetMeshes.push(cast(assetVO.data, Mesh));
		}
		assetVO = getAssetByID(animSetBlockAdress, [Asset3DType.ANIMATION_SET]);
		if (!assetVO.enable) {
			_blocks[blockID].addError("Could not find the AnimationSet ( " + animSetBlockAdress + " ) for this Animator");
			return;
		}
		targetAnimationSet = cast(assetVO.data, AnimationSetBase);
		var thisAnimator:AnimatorBase = null;
		if (type == 1) {
			
			assetVO = getAssetByID(props.get(1, 0), [Asset3DType.SKELETON]);
			if (!assetVO.enable) {
				_blocks[blockID].addError("Could not find the Skeleton ( " + props.get(1, 0) + " ) for this Animator");
				return;
			}
			thisAnimator = new SkeletonAnimator(cast(targetAnimationSet, SkeletonAnimationSet), cast(assetVO.data, Skeleton));
			
		} else if (type == 2)
			thisAnimator = new VertexAnimator(cast(targetAnimationSet, VertexAnimationSet));
		
		finalizeAsset(thisAnimator, name);
		_blocks[blockID].data = thisAnimator;
		for (i in 0...targetMeshes.length) {
			if (type == 1)
				targetMeshes[i].animator = cast(thisAnimator, SkeletonAnimator);
			if (type == 2)
				targetMeshes[i].animator = cast(thisAnimator, VertexAnimator);
			
		}
		if (_debug)
			trace("Parsed a Animator: Name = " + name);
	}
	
	//Block ID = 253
	private function parseCommand(blockID:UInt):Void
	{
		var hasBlocks:Bool = _newBlockBytes.readUnsignedByte() != 0;
		var par_id:Int = _newBlockBytes.readUnsignedInt();
		var mtx:Matrix3D = parseMatrix3D();
		var name:String = parseVarStr();
		
		var parentObject:ObjectContainer3D = null;
		var targetObject:ObjectContainer3D = null;
		var assetVO:AssetVO = getAssetByID(par_id, [Asset3DType.CONTAINER, Asset3DType.LIGHT, Asset3DType.MESH, Asset3DType.ENTITY, Asset3DType.SEGMENT_SET]);
		if (assetVO.enable)
			parentObject = cast(assetVO.data, ObjectContainer3D);
		
		var numCommands:Int = _newBlockBytes.readShort();
		var typeCommand:Int = _newBlockBytes.readShort();
		var props:AWDProperties = parseProperties({"1": BADDR});
		switch (typeCommand) {
			case 1:
				var targetID:Int = props.get(1, 0);
				var targetAssetVO:AssetVO = getAssetByID(targetID, [Asset3DType.LIGHT, Asset3DType.TEXTURE_PROJECTOR]); //for no only light is requested!!!!
				if (!targetAssetVO.enable && (targetID != 0)) {
					_blocks[blockID].addError("Could not find the light (ID = " + targetID + " ( for this CommandBock!");
					return;
				}
				targetObject = targetAssetVO.data;
				if (parentObject != null)
					parentObject.addChild(targetObject);
				targetObject.transform = mtx;
		}
		if (targetObject != null) {
			props = parseProperties({"1": _matrixNrType, "2": _matrixNrType, "3": _matrixNrType, "4": UINT8});
			targetObject.pivotPoint = new Vector3D(props.get(1, 0), props.get(2, 0), props.get(3, 0));
			targetObject.extra = parseUserAttributes();
		}
		_blocks[blockID].data = targetObject;
		if (_debug)
			trace("Parsed a CommandBlock: Name = '" + name);
	
	}
	
	//blockID 254
	private function parseNameSpace(blockID:UInt):Void
	{
		var id:UInt = _newBlockBytes.readUnsignedByte();
		var nameSpaceString:String = parseVarStr();
		if (_debug)
			trace("Parsed a NameSpaceBlock: ID = " + id + " | String = " + nameSpaceString);
	}
	
	//blockID 255
	private function parseMetaData(blockID:UInt):Void
	{
		var props:AWDProperties = parseProperties({"1": UINT32, "2": AWDSTRING, "3": AWDSTRING, "4": AWDSTRING, "5": AWDSTRING});
		if (_debug) {
			trace("Parsed a MetaDataBlock: TimeStamp         = " + props.get(1, 0));
			trace("                        EncoderName       = " + props.get(2, "unknown"));
			trace("                        EncoderVersion    = " + props.get(3, "unknown"));
			trace("                        GeneratorName     = " + props.get(4, "unknown"));
			trace("                        GeneratorVersion  = " + props.get(5, "unknown"));
		}
	
	}
	
	// Helper - functions
	private function getUVForVertexAnimation(meshID:UInt):Vector<Vector<Float>>
	{
		if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(_blocks[meshID].data, Mesh))
			meshID = _blocks[meshID].geoID;
		if (_blocks[meshID].uvsForVertexAnimation != null)
			return _blocks[meshID].uvsForVertexAnimation;
		var geometry:Geometry = cast(_blocks[meshID].data, Geometry);
		var geoCnt:Int = 0;
		var ud:Vector<Float>;
		var uStride:UInt;
		var uOffs:UInt;
		var numPoints:UInt;
		var i:Int;
		var newUvs:Vector<Float>;
		_blocks[meshID].uvsForVertexAnimation = new Vector<Vector<Float>>();
		while (geoCnt < geometry.subGeometries.length) {
			newUvs = new Vector<Float>();
			numPoints = geometry.subGeometries[geoCnt].numVertices;
			ud = geometry.subGeometries[geoCnt].UVData;
			uStride = geometry.subGeometries[geoCnt].UVStride;
			uOffs = geometry.subGeometries[geoCnt].UVOffset;
			for (i in 0...numPoints) {
				newUvs.push(ud[uOffs + i*uStride + 0]);
				newUvs.push(ud[uOffs + i*uStride + 1]);
			}
			_blocks[meshID].uvsForVertexAnimation.push(newUvs);
			geoCnt++;
		}
		return _blocks[meshID].uvsForVertexAnimation;
	}
	
	private function parseVarStr():String
	{
		var len:UInt = _newBlockBytes.readUnsignedShort();
		return _newBlockBytes.readUTFBytes(len);
	}
	
	private function parseProperties(expected:Dynamic):AWDProperties
	{
		var list_end:UInt;
		var list_len:UInt;
		var propertyCnt:UInt = 0;
		var props:AWDProperties = new AWDProperties();
		
		list_len = _newBlockBytes.readUnsignedInt();
		list_end = _newBlockBytes.position + list_len;
		if (expected != null) {
			while (_newBlockBytes.position < list_end) {
				var len:Int;
				var key:Int;
				var type:Int;
				key = _newBlockBytes.readUnsignedShort();
				len = _newBlockBytes.readUnsignedInt();
				if ((_newBlockBytes.position + len) > list_end) {
					trace("           Error in reading property # " + propertyCnt + " = skipped to end of propertie-list");
					_newBlockBytes.position = list_end;
					return props;
				}
				if (expected.hasField(Std.string(key))) {
					type = expected.field(Std.string(key));
					props.set(key, parseAttrValue(type, len));
				} else
					_newBlockBytes.position += len;
				propertyCnt += 1;
				
			}
		} else
			_newBlockBytes.position = list_end;
		
		return props;
	}
	
	private function parseUserAttributes():Dynamic
	{
		var attributes:Dynamic = null;
		var list_len:UInt;
		var attibuteCnt:Int = 0;
		
		list_len = _newBlockBytes.readUnsignedInt();
		if (list_len > 0) {
			var list_end:UInt;
			
			attributes = {};
			
			list_end = _newBlockBytes.position + list_len;
			while (_newBlockBytes.position < list_end) {
				var ns_id:Int;
				var attr_key:String;
				var attr_type:Int;
				var attr_len:Int;
				var attr_val:Dynamic;
				
				// TODO: Properly tend to namespaces in attributes
				ns_id = _newBlockBytes.readUnsignedByte();
				attr_key = parseVarStr();
				attr_type = _newBlockBytes.readUnsignedByte();
				attr_len = _newBlockBytes.readUnsignedInt();
				
				if ((_newBlockBytes.position + attr_len) > list_end) {
					trace("           Error in reading attribute # " + attibuteCnt + " = skipped to end of attribute-list");
					_newBlockBytes.position = list_end;
					return attributes;
				}
				switch (attr_type) {
					case AWDSTRING:
						attr_val = _newBlockBytes.readUTFBytes(attr_len);
					case INT8:
						attr_val = _newBlockBytes.readByte();
					case INT16:
						attr_val = _newBlockBytes.readShort();
					case INT32:
						attr_val = _newBlockBytes.readInt();
					case BOOL, UINT8:
						attr_val = _newBlockBytes.readUnsignedByte();
					case UINT16:
						attr_val = _newBlockBytes.readUnsignedShort();
					case UINT32, BADDR:
						attr_val = _newBlockBytes.readUnsignedInt();
					case FLOAT32:
						attr_val = _newBlockBytes.readFloat();
					case FLOAT64:
						attr_val = _newBlockBytes.readDouble();
					default:
						attr_val = 'unimplemented attribute type ' + attr_type;
						_newBlockBytes.position += attr_len;
				}
				
				if (_debug)
					trace("attribute = name: " + attr_key + "  / value = " + attr_val);
				attributes.setField(attr_key, attr_val);
				attibuteCnt += 1;
			}
		}
		
		return attributes;
	}
	
	private function getDefaultMaterial():IAsset
	{
		if (_defaultBitmapMaterial == null)
			_defaultBitmapMaterial = DefaultMaterialManager.getDefaultMaterial();
		return _defaultBitmapMaterial;
	}
	
	private function getDefaultTexture():IAsset
	{
		if (_defaultTexture == null)
			_defaultTexture = DefaultMaterialManager.getDefaultTexture();
		return _defaultTexture;
	}
	
	private function getDefaultCubeTexture():IAsset
	{
		if (_defaultCubeTexture == null) {
			if (_defaultTexture == null)
				_defaultTexture = DefaultMaterialManager.getDefaultTexture();
			var defaultBitmap:BitmapData = _defaultTexture.bitmapData;
			_defaultCubeTexture = new BitmapCubeTexture(defaultBitmap, defaultBitmap, defaultBitmap, defaultBitmap, defaultBitmap, defaultBitmap);
			_defaultCubeTexture.name = "defaultTexture";
		}
		return _defaultCubeTexture;
	}
	
	private function getDefaultAsset(assetType:String, extraTypeInfo:String):IAsset
	{
		var isTexture:Bool = (assetType == Asset3DType.TEXTURE);
		var isMaterial:Bool = (assetType == Asset3DType.MATERIAL);

		if (isTexture) {
			if (extraTypeInfo == "CubeTexture")
				return getDefaultCubeTexture();
			if (extraTypeInfo == "SingleTexture")
				return getDefaultTexture();
		} else if (isMaterial)
			return getDefaultMaterial();
		return null;
	}
	
	private function getAssetByID(assetID:UInt, assetTypesToGet:Array<String>, extraTypeInfo:String = "SingleTexture"):AssetVO
	{
		var assetVO:AssetVO = { enable:false, data:null };
		var typeCnt:Int = 0;
		if (assetID > 0) {
			if (_blocks[assetID] != null) {
				if (_blocks[assetID].data != null) {
					while (typeCnt < assetTypesToGet.length) {
						if (cast(_blocks[assetID].data, IAsset).assetType == assetTypesToGet[typeCnt]) {
							//if the right Asset3DType was found
							if ((assetTypesToGet[typeCnt] == Asset3DType.TEXTURE) && (extraTypeInfo == "CubeTexture")) {
								if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(_blocks[assetID].data, BitmapCubeTexture)) {
									assetVO.enable = true;
									assetVO.data = _blocks[assetID].data;
									return assetVO;
								}
							}
							if ((assetTypesToGet[typeCnt] == Asset3DType.TEXTURE) && (extraTypeInfo == "SingleTexture")) {
								if (#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(_blocks[assetID].data, BitmapTexture)) {
									assetVO.enable = true;
									assetVO.data = _blocks[assetID].data;
									return assetVO;
								}
							} else {
								assetVO.enable = true;
								assetVO.data = _blocks[assetID].data;
								return assetVO;
								
							}
						}
						if ((assetTypesToGet[typeCnt] == Asset3DType.GEOMETRY) && (cast(_blocks[assetID].data, IAsset).assetType == Asset3DType.MESH)) {
							assetVO.enable = true;
							assetVO.data = cast(_blocks[assetID].data, Mesh).geometry;
							return assetVO;
						}
						typeCnt++;
					}
				}
			}
		}
		// if the function has not returned anything yet, the asset is not found, or the found asset is not the right type.
		assetVO.enable = false;
		assetVO.data = getDefaultAsset(assetTypesToGet[0], extraTypeInfo);
		return assetVO;
	}
	
	private function parseAttrValue(type:UInt, len:UInt):Dynamic
	{
		var elem_len:UInt = 0;
		var read_func:Dynamic = null;
		
		switch (type) {
			case BOOL, INT8:
				elem_len = 1;
				read_func = _newBlockBytes.readByte;
			case INT16:
				elem_len = 2;
				read_func = _newBlockBytes.readShort;
			case INT32:
				elem_len = 4;
				read_func = _newBlockBytes.readInt;
			case UINT8:
				elem_len = 1;
				read_func = _newBlockBytes.readUnsignedByte;
			case UINT16:
				elem_len = 2;
				read_func = _newBlockBytes.readUnsignedShort;
			case UINT32, COLOR, BADDR:
				elem_len = 4;
				read_func = _newBlockBytes.readUnsignedInt;
			case FLOAT32:
				elem_len = 4;
				read_func = _newBlockBytes.readFloat;
			case FLOAT64:
				elem_len = 8;
				read_func = _newBlockBytes.readDouble;
			case AWDSTRING:
				return _newBlockBytes.readUTFBytes(len);
			case VECTOR2x1, VECTOR3x1, VECTOR4x1, MTX3x2, MTX3x3, MTX4x3, MTX4x4:
				elem_len = 8;
				read_func = _newBlockBytes.readDouble;
		}
		
		if (elem_len < len) {
			var list:Array<Dynamic>;
			var num_read:UInt;
			var num_elems:UInt;

			list = [];
			num_read = 0;
			num_elems = Std.int(len/elem_len);
			while (num_read < num_elems) {
				list.push(read_func());
				num_read++;
			}
			
			return list;
		} else {
			var val:Dynamic;
			
			val = read_func();
			return val;
		}
	}
	
	private function parseMatrix2D():Matrix
	{
		var mtx:Matrix;
		var mtx_raw:Vector<Float> = parseMatrix32RawData();
		
		mtx = new Matrix(mtx_raw[0], mtx_raw[1], mtx_raw[2], mtx_raw[3], mtx_raw[4], mtx_raw[5]);
		return mtx;
	}
	
	private function parseMatrix3D():Matrix3D
	{
		return new Matrix3D(parseMatrix43RawData());
	}
	
	private function parseMatrix32RawData():Vector<Float>
	{
		var mtx_raw:Vector<Float> = new Vector<Float>(6, true);
		for (i in 0...6)
			mtx_raw[i] = _newBlockBytes.readFloat();
		
		return mtx_raw;
	}
	
	private function readNumber(precision:Bool = false):Float
	{
		if (precision)
			return _newBlockBytes.readDouble();
		return _newBlockBytes.readFloat();
	}
	
	private function parseMatrix43RawData():Vector<Float>
	{
		var mtx_raw:Vector<Float> = new Vector<Float>(16, true);
		
		mtx_raw[0] = readNumber(_accuracyMatrix);
		mtx_raw[1] = readNumber(_accuracyMatrix);
		mtx_raw[2] = readNumber(_accuracyMatrix);
		mtx_raw[3] = 0.0;
		mtx_raw[4] = readNumber(_accuracyMatrix);
		mtx_raw[5] = readNumber(_accuracyMatrix);
		mtx_raw[6] = readNumber(_accuracyMatrix);
		mtx_raw[7] = 0.0;
		mtx_raw[8] = readNumber(_accuracyMatrix);
		mtx_raw[9] = readNumber(_accuracyMatrix);
		mtx_raw[10] = readNumber(_accuracyMatrix);
		mtx_raw[11] = 0.0;
		mtx_raw[12] = readNumber(_accuracyMatrix);
		mtx_raw[13] = readNumber(_accuracyMatrix);
		mtx_raw[14] = readNumber(_accuracyMatrix);
		mtx_raw[15] = 1.0;
		
		//TODO: fix max exporter to remove NaN values in joint 0 inverse bind pose
		if (Math.isNaN(mtx_raw[0])) {
			mtx_raw[0] = 1;
			mtx_raw[1] = 0;
			mtx_raw[2] = 0;
			mtx_raw[4] = 0;
			mtx_raw[5] = 1;
			mtx_raw[6] = 0;
			mtx_raw[8] = 0;
			mtx_raw[9] = 0;
			mtx_raw[10] = 1;
			mtx_raw[12] = 0;
			mtx_raw[13] = 0;
			mtx_raw[14] = 0;
			
		}
		
		return mtx_raw;
	}
}

class AWDBlock
{
	public var id:Int;
	public var name:String;
	public var data:Dynamic;
	public var len:Dynamic;
	public var geoID:UInt;
	public var extras:Dynamic;
	public var bytes:ByteArray;
	public var errorMessages:Vector<String>;
	public var uvsForVertexAnimation:Vector<Vector<Float>>;
	
	public function new()
	{
	}

	public function addError(errorMsg:String):Void
	{
		if (errorMessages == null)
			errorMessages = new Vector<String>();
		errorMessages.push(errorMsg);
	}
}

class BitFlags
{
	public static inline var FLAG1:Int = 1;
	public static inline var FLAG2:Int = 2;
	public static inline var FLAG3:Int = 4;
	public static inline var FLAG4:Int = 8;
	public static inline var FLAG5:Int = 16;
	public static inline var FLAG6:Int = 32;
	public static inline var FLAG7:Int = 64;
	public static inline var FLAG8:Int = 128;
	public static inline var FLAG9:Int = 256;
	public static inline var FLAG10:Int = 512;
	public static inline var FLAG11:Int = 1024;
	public static inline var FLAG12:Int = 2048;
	public static inline var FLAG13:Int = 4096;
	public static inline var FLAG14:Int = 8192;
	public static inline var FLAG15:Int = 16384;
	public static inline var FLAG16:Int = 32768;
	
	public static function test(flags:Int, testFlag:Int):Bool
	{
		return (flags & testFlag) == testFlag;
	}
}

class AWDProperties
{
	private var data:Map<Int, Dynamic>;
	
	public function new()
	{
		data = new Map<Int, Dynamic> ();
	}
	
	public function set(key:Int, value:Dynamic):Void
	{
		data[key] = value;
	}
	
	public function get(key:Int, fallback:Dynamic):Dynamic
	{
		if (data.exists(key))
			return data[key];
		else
			return fallback;
	}
}

typedef AssetVO = {
	var data:Dynamic;
	var enable:Bool;
}