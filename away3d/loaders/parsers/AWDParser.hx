package away3d.loaders.parsers;

import away3d.library.assets.IAsset;
import away3d.events.Asset3DEvent;
import away3d.events.ParserEvent;
import away3d.loaders.misc.ResourceDependency;

import openfl.Vector;

/**
 * The AWDParser class is a wrapper for both AWD1Parser and AWD2Parser, and will
 * find the right concrete parser for an AWD file.
 */
class AWDParser extends ParserBase
{
	private var _parser:ParserBase;
	
	public function new()
	{
		super(ParserDataFormat.BINARY);
	}
	
	/**
	 * Indicates whether or not a given file extension is supported by the parser.
	 * @param extension The file extension of a potential file to be parsed.
	 * @return Whether or not the given file type is supported.
	 */
	public static function supportsType(suffix:String):Bool
	{
		return (suffix.toLowerCase() == 'awd');
	}
	
	/**
	 * Tests whether a data block can be parsed by the parser.
	 * @param data The data block to potentially be parsed.
	 * @return Whether or not the given data is supported.
	 */
	public static function supportsData(data:Dynamic):Bool
	{
		return (AWD1Parser.supportsData(data) || AWD2Parser.supportsData(data));
	}
	
	/**
	 * @inheritDoc
	 */
	public override function get_dependencies():Vector<ResourceDependency>
	{
		return _parser != null? _parser.dependencies : super.dependencies;
	}
	
	/**
	 * @inheritDoc
	 */
	public override function get_parsingComplete():Bool
	{
		return _parser != null? _parser.parsingComplete : false;
	}
	
	/**
	 * @inheritDoc
	 */
	public override function get_parsingPaused():Bool
	{
		return _parser != null? _parser.parsingPaused : false;
	}
	
	/**
	 * @private
	 * Delegate to the concrete parser.
	 */
	override private function resolveDependency(resourceDependency:ResourceDependency):Void
	{
		if (_parser != null)
			_parser.resolveDependency(resourceDependency);
	}
	
	/**
	 * @private
	 * Delegate to the concrete parser.
	 */
	override private function resolveDependencyFailure(resourceDependency:ResourceDependency):Void
	{
		if (_parser != null)
			_parser.resolveDependencyFailure(resourceDependency);
	}
	
	/**
	 * @private
	 * Delagate to the concrete parser.
	 */
	override private function resolveDependencyName(resourceDependency:ResourceDependency, asset:IAsset):String
	{
		if (_parser != null)
			return _parser.resolveDependencyName(resourceDependency, asset);
		return asset.name;
	}
	
	override private function resumeParsingAfterDependencies():Void
	{
		if (_parser != null)
			_parser.resumeParsingAfterDependencies();
	}
	
	/**
	 * Find the right conrete parser (AWD1Parser or AWD2Parser) and delegate actual
	 * parsing to it.
	 */
	private override function proceedParsing():Bool
	{
		if (_parser == null) {
			// Inspect data to find correct parser. AWD2 parser
			// file inspection is the most reliable
			if (AWD2Parser.supportsData(_data))
				_parser = new AWD2Parser();
			else
				_parser = new AWD1Parser();
			_parser.materialMode = materialMode;
			// Listen for events that need to be bubbled
			_parser.addEventListener(ParserEvent.PARSE_COMPLETE, onParseComplete);
			_parser.addEventListener(ParserEvent.READY_FOR_DEPENDENCIES, onReadyForDependencies);
			_parser.addEventListener(ParserEvent.PARSE_ERROR, onParseError);
			_parser.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.TEXTURE_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.CONTAINER_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.GEOMETRY_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.MATERIAL_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.MESH_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.ENTITY_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.SKELETON_COMPLETE, onAssetComplete);
			_parser.addEventListener(Asset3DEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
			
			_parser.parseAsync(_data);
		}
		
		// Return MORE_TO_PARSE while delegate parser is working. Once the delegate
		// finishes parsing, this dummy parser instance will be stopped as well as
		// a result of the delegate's PARSE_COMPLETE event (onParseComplete).
		return ParserBase.MORE_TO_PARSE;
	}
	
	/**
	 * @private
	 * Just bubble events from concrete parser.
	 */
	@:allow(away3d) private function onParseError(ev:ParserEvent):Void
	{
		dispatchEvent(ev.clone());
	}
	
	/**
	 * @private
	 * Just bubble events from concrete parser.
	 */
	@:allow(away3d) private function onReadyForDependencies(ev:ParserEvent):Void
	{
		dispatchEvent(ev.clone());
	}
	
	/**
	 * @private
	 * Just bubble events from concrete parser.
	 */
	@:allow(away3d) private function onAssetComplete(ev:Asset3DEvent):Void
	{
		dispatchEvent(ev.clone());
	}
	
	/**
	 * @private
	 * Just bubble events from concrete parser.
	 */
	@:allow(away3d) private function onParseComplete(ev:ParserEvent):Void
	{
		_parser.removeEventListener(ParserEvent.READY_FOR_DEPENDENCIES, onReadyForDependencies);
		_parser.removeEventListener(ParserEvent.PARSE_COMPLETE, onParseComplete);
		_parser.removeEventListener(ParserEvent.PARSE_ERROR, onParseError);
		_parser.removeEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.TEXTURE_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.CONTAINER_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.GEOMETRY_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.MATERIAL_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.MESH_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.ENTITY_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.SKELETON_COMPLETE, onAssetComplete);
		_parser.removeEventListener(Asset3DEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
		
		finishParsing();
	}
}