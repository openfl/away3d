package away3d.core.managers;

import away3d.debug.Debug;
import away3d.events.Stage3DEvent;
import away3d.materials.passes.MaterialPassBase;

import openfl.display3D.Context3DProgramType;
import openfl.display3D.Program3D;
import openfl.errors.Error;
import openfl.utils.AGALMiniAssembler;
import openfl.utils.ByteArray;
import openfl.Vector;

class AGALProgram3DCache
{
	private static var _instances:Vector<AGALProgram3DCache>;
	
	private var _stage3DProxy:Stage3DProxy;
	
	private var _program3Ds:Map<String, Program3D>;
	private var _ids:Map<String, Int>;
	private var _usages:Array<Int>;
	private var _keys:Array<String>;
	
	private static var _currentId:Int = 0;
	
	private function new(stage3DProxy:Stage3DProxy)
	{
		_stage3DProxy = stage3DProxy;
		
		_program3Ds = new Map<String, Program3D>();
		_ids = new Map<String, Int>();
		_usages = [];
		_keys = [];
	}
	
	public static function getInstance(stage3DProxy:Stage3DProxy):AGALProgram3DCache
	{
		var index:Int = stage3DProxy.stage3DIndex;
		
		if (_instances == null)
			_instances = new Vector<AGALProgram3DCache>(8, true);
		
		if (_instances[index] == null) {
			_instances[index] = new AGALProgram3DCache(stage3DProxy);
			stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed, false, 0, true);
			stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DDisposed, false, 0, true);
			stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContext3DDisposed, false, 0, true);
		}
		
		return _instances[index];
	}
	
	public static function getInstanceFromIndex(index:Int):AGALProgram3DCache
	{
		if (_instances[index] == null)
			throw new Error("Instance not created yet!");
		return _instances[index];
	}
	
	private static function onContext3DDisposed(event:Stage3DEvent):Void
	{
		var stage3DProxy:Stage3DProxy = cast(event.target, Stage3DProxy);
		var index:Int = stage3DProxy._stage3DIndex;
		_instances[index].dispose();
		_instances[index] = null;
		stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed);
		stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DDisposed);
		stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContext3DDisposed);
	}
	
	public function dispose():Void
	{
		var keys:Iterator<String> = _program3Ds.keys();
		for (key in keys)
			destroyProgram(key);
		
		_keys = null;
		_program3Ds = null;
		_usages = null;
	}
	
	public function setProgram3D(pass:MaterialPassBase, vertexCode:String, fragmentCode:String, agalVersion:Int=1):Void
	{
		var stageIndex:Int = _stage3DProxy._stage3DIndex;
		var program:Program3D;
		var key:String = getKey(vertexCode, fragmentCode);
		
		if (!_program3Ds.exists(key)) {
			_keys[_currentId] = key;
			_usages[_currentId] = 0;
			_ids[key] = _currentId;
			++_currentId;
			program = _stage3DProxy._context3D.createProgram();
			
			var vertexByteCode:ByteArray = new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, vertexCode, agalVersion);
			var fragmentByteCode:ByteArray = new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, fragmentCode, agalVersion);
			
			program.upload(vertexByteCode, fragmentByteCode);
			
			_program3Ds[key] = program;
		}
		
		var oldId:Int = pass._program3Dids[stageIndex];
		var newId:Int = _ids[key];
		
		if (oldId != newId) {
			if (oldId >= 0)
				freeProgram3D(oldId);
			_usages[newId]++;
		}
		
		pass._program3Dids[stageIndex] = newId;
		pass._program3Ds[stageIndex] = _program3Ds[key];
	}
	
	public function freeProgram3D(programId:Int):Void
	{
		_usages[programId]--;
		if (_usages[programId] == 0)
			destroyProgram(_keys[programId]);
	}
	
	private function destroyProgram(key:String):Void
	{
		_program3Ds[key].dispose();
		_program3Ds.remove(key);
		_ids[key] = -1;
	}
	
	private inline function getKey(vertexCode:String, fragmentCode:String):String
	{
		return vertexCode + "---" + fragmentCode;
	}
}