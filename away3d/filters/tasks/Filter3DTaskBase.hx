/**
 */
package away3d.filters.tasks;

import away3d.cameras.Camera3D;
import away3d.core.managers.Stage3DProxy;
import away3d.debug.Debug;
import away3d.errors.AbstractMethodError;

import openfl.display3D.textures.Texture;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.Context3D;
import openfl.display3D.Program3D;
import openfl.utils.AGALMiniAssembler;

class Filter3DTaskBase
{
	public var textureScale(get, set):Int;
	public var target(get, set):Texture;
	public var textureWidth(get, set):Int;
	public var textureHeight(get, set):Int;
	public var requireDepthRender(get, never):Bool;
	
	private var _mainInputTexture:Texture;
	private var _mainInputTextureContext:Context3D;
	private var _scaledTextureWidth:Int = -1;
	private var _scaledTextureHeight:Int = -1;
	private var _textureWidth:Int = -1;
	private var _textureHeight:Int = -1;
	private var _textureDimensionsInvalid:Bool = true;
	private var _program3DInvalid:Bool = true;
	private var _program3D:Program3D;
	private var _program3DContext:Context3D;
	private var _target:Texture;
	private var _requireDepthRender:Bool;
	private var _textureScale:Int = 0;
	
	public function new(requireDepthRender:Bool = false)
	{
		_requireDepthRender = requireDepthRender;
	}
	
	/**
	 * The texture scale for the input of this texture. This will define the output of the previous entry in the chain
	 */
	private function get_textureScale():Int
	{
		return _textureScale;
	}
	
	private function set_textureScale(value:Int):Int
	{
		if (_textureScale == value)
			return value;
		_textureScale = value;
		_scaledTextureWidth = _textureWidth >> _textureScale;
		_scaledTextureHeight = _textureHeight >> _textureScale;
		_textureDimensionsInvalid = true;
		return value;
	}
	
	private function get_target():Texture
	{
		return _target;
	}
	
	private function set_target(value:Texture):Texture
	{
		_target = value;
		return value;
	}
	
	private function get_textureWidth():Int
	{
		return _textureWidth;
	}
	
	private function set_textureWidth(value:Int):Int
	{
		if (_textureWidth == value)
			return value;
		_textureWidth = value;
		_scaledTextureWidth = _textureWidth >> _textureScale;
		if(_scaledTextureWidth < 1) _scaledTextureWidth = 1;
		_textureDimensionsInvalid = true;
		return value;
	}
	
	private function get_textureHeight():Int
	{
		return _textureHeight;
	}
	
	private function set_textureHeight(value:Int):Int
	{
		if (_textureHeight == value)
			return value;
		_textureHeight = value;
		_scaledTextureHeight = _textureHeight >> _textureScale;
		if(_scaledTextureHeight < 1) _scaledTextureHeight = 1;
		_textureDimensionsInvalid = true;
		return value;
	}
	
	public function getMainInputTexture(stage:Stage3DProxy):Texture
	{
		if(stage.context3D!=_mainInputTextureContext){
			_textureDimensionsInvalid = true;
		}

		if (_textureDimensionsInvalid)
			updateTextures(stage);
		
		return _mainInputTexture;
	}
	
	public function dispose():Void
	{
		if (_mainInputTexture != null)
			_mainInputTexture.dispose();
		if (_program3D != null)
			_program3D.dispose();
		_program3DContext = null;
	}
	
	private function invalidateProgram3D():Void
	{
		_program3DInvalid = true;
	}
	
	private function updateProgram3D(stage:Stage3DProxy):Void
	{
		if (_program3D != null)
			_program3D.dispose();
		_program3DContext = stage.context3D;
		_program3D = _program3DContext.createProgram();
		_program3D.upload(new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, getVertexCode()),
			new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, getFragmentCode()));
		_program3DInvalid = false;
	}
	
	private function getVertexCode():String
	{
		return "mov op, va0\n" +
			"mov v0, va1\n";
	}
	
	private function getFragmentCode():String
	{
		throw new AbstractMethodError();
		return null;
	}
	
	private function updateTextures(stage:Stage3DProxy):Void
	{
		if (_mainInputTexture != null)
			_mainInputTexture.dispose();
		_mainInputTextureContext = stage.context3D;
		_mainInputTexture = _mainInputTextureContext.createTexture(_scaledTextureWidth, _scaledTextureHeight, Context3DTextureFormat.BGRA, true);
		
		_textureDimensionsInvalid = false;
	}
	
	public function getProgram3D(stage3DProxy:Stage3DProxy):Program3D
	{
		if(_program3DContext != stage3DProxy.context3D) {
			_program3DInvalid = true;
		}

		if (_program3DInvalid)
			updateProgram3D(stage3DProxy);
		return _program3D;
	}
	
	public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D, depthTexture:Texture):Void
	{
	}
	
	public function deactivate(stage3DProxy:Stage3DProxy):Void
	{
	}
	
	private function get_requireDepthRender():Bool
	{
		return _requireDepthRender;
	}
}