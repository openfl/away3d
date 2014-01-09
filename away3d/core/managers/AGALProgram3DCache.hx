package away3d.core.managers;

	//import away3d.arcane;
	import away3d.debug.Debug;
	import away3d.events.Stage3DEvent;
	import away3d.materials.passes.MaterialPassBase;
	
	//import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;
	import flash.utils.ByteArray;

	import flash.errors.Error;

	import haxe.ds.StringMap;

	import flash.display3D.shaders.glsl.GLSLProgram;
	import flash.display3D.shaders.glsl.GLSLFragmentShader;
	import flash.display3D.shaders.glsl.GLSLVertexShader;
	import flash.display3D.shaders.ShaderUtils;
	
	import aglsl.AGLSLCompiler;
	import openfl.gl.GLShader;
	
	//use namespace arcane;
	
	class AGALProgram3DCache
	{
		private static var _instances:Array<AGALProgram3DCache>;
		
		var _stage3DProxy:Stage3DProxy;
		
		public var _program3Ds:StringMap<Program3D>;
		var _ids:StringMap<Dynamic>;
		var _usages:Array<Dynamic>;
		var _keys:Array<Dynamic>;
		
		private static var _currentId:Int;
		
		public function new(stage3DProxy:Stage3DProxy, singleton:AGALProgram3DCacheSingletonEnforcer)
		{
			if (singleton==null)
				throw new Error("This class is a multiton and cannot be instantiated manually. Use Stage3DManager.getInstance instead.");
			_stage3DProxy = stage3DProxy;
			
			_program3Ds = new StringMap<Program3D>();
			_ids = new StringMap<Dynamic>();
			_usages = [];
			_keys = [];
		}
		
		public static function getInstance(stage3DProxy:Stage3DProxy):AGALProgram3DCache
		{
			var index:Int = stage3DProxy._stage3DIndex;
			
			if (_instances==null) _instances = new Array<AGALProgram3DCache>();
			
			if (_instances[index]==null) {
				_instances[index] = new AGALProgram3DCache(stage3DProxy, new AGALProgram3DCacheSingletonEnforcer());
				stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed, false, 0, true);
				stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DDisposed, false, 0, true);
				stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContext3DDisposed, false, 0, true);
			}
			
			return _instances[index];
		}
		
		public static function getInstanceFromIndex(index:Int):AGALProgram3DCache
		{
			if (_instances[index]==null)
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
			var key:String;
			for (key in _program3Ds.keys())
				destroyProgram(key);
			
			_keys = null;
			_program3Ds = null;
			_usages = null;
		}
		
		public function setProgram3D(pass:MaterialPassBase, vertexCode:String, fragmentCode:String):Void
		{
			var stageIndex:Int = _stage3DProxy._stage3DIndex;
			var program:Program3D;
			var key:String = getKey(vertexCode, fragmentCode);
			
			if (_program3Ds.get(key) == null) {
				_keys[_currentId] = key;
				_usages[_currentId] = 0;
				_ids.set(key, _currentId);
				++_currentId;
				
				program = _stage3DProxy._context3D.createProgram();
                var vertCompiler:AGLSLCompiler = new AGLSLCompiler();
                var fragCompiler:AGLSLCompiler = new AGLSLCompiler();

                var vertexShaderSource:String = vertCompiler.compile( Context3DProgramType.VERTEX, vertexCode );
                var fragmentShaderSource:String = fragCompiler.compile( Context3DProgramType.FRAGMENT, fragmentCode );


                trace( '===GLSL-COMPILED========================================================');
                trace( 'vertString' );
                trace( vertexShaderSource );
                trace( 'fragString' );
                trace( fragmentShaderSource );

                trace( '===AGAL=========================================================');
                trace( 'vertexCode' );
                trace( vertexCode );
                trace( 'fragmentCode' );
                trace( fragmentCode );
                
				var vertexShader = ShaderUtils.createShader(Context3DProgramType.VERTEX, vertexShaderSource);
		        var fragmentShader = ShaderUtils.createShader(Context3DProgramType.FRAGMENT, fragmentShaderSource);

				program.upload(vertexShader, fragmentShader);

				_program3Ds.set(key, program);
			}
			
			var oldId:Int = pass._program3Dids[stageIndex];
			var newId:Int = _ids.get(key);
			
			if (oldId != newId) {
				if (oldId >= 0)
					freeProgram3D(oldId);
				_usages[newId]++;
			}
			
			pass._program3Dids[stageIndex] = newId;
			pass._program3Ds[stageIndex] = _program3Ds.get(key);
		}
		
		public function freeProgram3D(programId:Int):Void
		{
			_usages[programId]--;
			if (_usages[programId] == 0)
				destroyProgram(_keys[programId]);
		}
		
		private function destroyProgram(key:String):Void
		{
			_program3Ds.get(key).dispose();
			_program3Ds.set(key, null);
			//delete _program3Ds[key];
			_program3Ds.remove(key);
			_ids.set(key, -1);
		}
		
		private function getKey(vertexCode:String, fragmentCode:String):String
		{
			return vertexCode + "---" + fragmentCode;
		}
	}

class AGALProgram3DCacheSingletonEnforcer
{
	public function new() {}
}
