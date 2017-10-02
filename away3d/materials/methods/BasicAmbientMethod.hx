package away3d.materials.methods;

import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.textures.Texture2DBase;

import openfl.display3D.Context3DWrapMode;
import openfl.display3D.Context3DTextureFilter;
import openfl.display3D.Context3DMipFilter;
import openfl.Vector;

/**
 * BasicAmbientMethod provides the default shading method for uniform ambient lighting.
 */
class BasicAmbientMethod extends ShadingMethodBase
{
	public var ambient(get, set):Float;
	public var ambientColor(get, set):Int;
	public var texture(get, set):Texture2DBase;
	
	private var _useTexture:Bool;
	private var _texture:Texture2DBase;
	
	private var _ambientInputRegister:ShaderRegisterElement;
	
	private var _ambientColor:Int = 0xffffff;
	private var _ambientR:Float = 0;
	private var _ambientG:Float = 0;
	private var _ambientB:Float = 0;
	private var _ambient:Float = 1;
	@:allow(away3d) private var _lightAmbientR:Float = 0;
	@:allow(away3d) private var _lightAmbientG:Float = 0;
	@:allow(away3d) private var _lightAmbientB:Float = 0;
	
	/**
	 * Creates a new BasicAmbientMethod object.
	 */
	public function new()
	{
		super();
	}

	/**
	 * @inheritDoc
	 */
	@:allow(away3d) private override function initVO(vo:MethodVO):Void
	{
		vo.needsUV = _useTexture;
	}

	/**
	 * @inheritDoc
	 */
	@:allow(away3d) private override function initConstants(vo:MethodVO):Void
	{
		vo.fragmentData[vo.fragmentConstantsIndex + 3] = 1;
	}
	
	/**
	 * The strength of the ambient reflection of the surface.
	 */
	private function get_ambient():Float
	{
		return _ambient;
	}
	
	private function set_ambient(value:Float):Float
	{
		_ambient = value;
		return value;
	}
	
	/**
	 * The colour of the ambient reflection of the surface.
	 */
	private function get_ambientColor():Int
	{
		return _ambientColor;
	}
	
	private function set_ambientColor(value:Int):Int
	{
		_ambientColor = value;
		return value;
	}
	
	/**
	 * The bitmapData to use to define the diffuse reflection color per texel.
	 */
	private function get_texture():Texture2DBase
	{
		return _texture;
	}
	
	private function set_texture(value:Texture2DBase):Texture2DBase
	{
		if ((value != null) != _useTexture ||
			(value != null && _texture != null && (value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format))) {
			invalidateShaderProgram();
		}
		_useTexture = (value != null);
		_texture = value;
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override public function copyFrom(method:ShadingMethodBase):Void
	{
		var diff:BasicAmbientMethod = cast(method, BasicAmbientMethod);
		ambient = diff.ambient;
		ambientColor = diff.ambientColor;
	}

	/**
	 * @inheritDoc
	 */
	@:allow(away3d) private override function cleanCompilationData():Void
	{
		super.cleanCompilationData();
		_ambientInputRegister = null;
	}
	
	/**
	 * @inheritDoc
	 */
	@:allow(away3d) private function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var code:String = "";
		
		if (_useTexture) {
			_ambientInputRegister = regCache.getFreeTextureReg();
			vo.texturesIndex = _ambientInputRegister.index;
			code += getTex2DSampleCode(vo, targetReg, _ambientInputRegister, _texture) +
				// apparently, still needs to un-premultiply :s
				"div " + targetReg + ".xyz, " + targetReg + ".xyz, " + targetReg + ".w\n";
		} else {
			_ambientInputRegister = regCache.getFreeFragmentConstant();
			vo.fragmentConstantsIndex = _ambientInputRegister.index*4;
			code += "mov " + targetReg + ", " + _ambientInputRegister + "\n";
		}
		
		return code;
	}
	
	/**
	 * @inheritDoc
	 */
	@:allow(away3d) private override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		if (_useTexture) {
			#if (!flash || flash11_6)
			stage3DProxy.context3D.setSamplerStateAt(
					vo.texturesIndex, vo.repeatTextures ? Context3DWrapMode.REPEAT : Context3DWrapMode.CLAMP, 
					getSmoothingFilter(vo.useSmoothTextures, vo.anisotropy), 
					vo.useMipmapping ? Context3DMipFilter.MIPLINEAR : Context3DMipFilter.MIPNONE );
			#end
			stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
		}
	}
	
	/**
	 * Updates the ambient color data used by the render state.
	 */
	private function updateAmbient():Void
	{
		_ambientR = ((_ambientColor >> 16) & 0xff)/0xff*_ambient*_lightAmbientR;
		_ambientG = ((_ambientColor >> 8) & 0xff)/0xff*_ambient*_lightAmbientG;
		_ambientB = (_ambientColor & 0xff)/0xff*_ambient*_lightAmbientB;
	}

	/**
	 * @inheritDoc
	 */
	@:allow(away3d) private override function setRenderState(vo:MethodVO, renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		updateAmbient();
		
		if (!_useTexture) {
			var index:Int = vo.fragmentConstantsIndex;
			var data:Vector<Float> = vo.fragmentData;
			data[index] = _ambientR;
			data[index + 1] = _ambientG;
			data[index + 2] = _ambientB;
		}
	}
}