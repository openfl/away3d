package away3d.materials.methods;

import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterData;
import away3d.materials.passes.MaterialPassBase;
import away3d.materials.passes.SingleObjectDepthPass;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;

import openfl.geom.Matrix3D;
import openfl.display3D.textures.Texture;
import openfl.Vector;

/**
 * SubsurfaceScatteringDiffuseMethod provides a depth map-based diffuse shading method that mimics the scattering of
 * light inside translucent surfaces. It allows light to shine through an object and to soften the diffuse shading.
 * It can be used for candle wax, ice, skin, ...
 */
class SubsurfaceScatteringDiffuseMethod extends CompositeDiffuseMethod
{
	public var scattering(get, set):Float;
	public var translucency(get, set):Float;
	public var scatterColor(get, set):Int;
	
	private var _depthPass:SingleObjectDepthPass;
	private var _lightProjVarying:ShaderRegisterElement;
	private var _propReg:ShaderRegisterElement;
	private var _scattering:Float;
	private var _translucency:Float = 1;
	private var _lightColorReg:ShaderRegisterElement;
	private var _scatterColor:Int = 0xffffff;
	private var _colorReg:ShaderRegisterElement;
	private var _decReg:ShaderRegisterElement;
	private var _scatterR:Float = 1.0;
	private var _scatterG:Float = 1.0;
	private var _scatterB:Float = 1.0;
	private var _targetReg:ShaderRegisterElement;
	
	/**
	 * Creates a new SubsurfaceScatteringDiffuseMethod object.
	 * @param depthMapSize The size of the depth map used.
	 * @param depthMapOffset The amount by which the rendered object will be inflated, to prevent depth map rounding errors.
	 */
	public function new(depthMapSize:Int = 512, depthMapOffset:Float = 15)
	{
		super(scatterLight);
		_passes = new Vector<MaterialPassBase>();
		_depthPass = new SingleObjectDepthPass(depthMapSize, depthMapOffset);
		_passes.push(_depthPass);
		_scattering = 0.2;
		_translucency = 1;
	}

	/**
	 * @inheritDoc
	 */
	override private function initConstants(vo:MethodVO):Void
	{
		super.initConstants(vo);
		var data:Vector<Float> = vo.vertexData;
		var index:Int = vo.secondaryVertexConstantsIndex;
		data[index] = .5;
		data[index + 1] = -.5;
		data[index + 2] = 0;
		data[index + 3] = 1;
		
		data = vo.fragmentData;
		index = vo.secondaryFragmentConstantsIndex;
		data[index + 3] = 1.0;
		data[index + 4] = 1.0;
		data[index + 5] = 1/255;
		data[index + 6] = 1/65025;
		data[index + 7] = 1/16581375;
		data[index + 10] = .5;
		data[index + 11] = -.1;
	}
	
	override private function cleanCompilationData():Void
	{
		super.cleanCompilationData();
		
		_lightProjVarying = null;
		_propReg = null;
		_lightColorReg = null;
		_colorReg = null;
		_decReg = null;
		_targetReg = null;
	}
	
	/**
	 * The amount by which the light scatters. It can be used to set the translucent surface's thickness. Use low
	 * values for skin.
	 */
	private function get_scattering():Float
	{
		return _scattering;
	}
	
	private function set_scattering(value:Float):Float
	{
		_scattering = value;
		return value;
	}
	
	/**
	 * The translucency of the object.
	 */
	private function get_translucency():Float
	{
		return _translucency;
	}
	
	private function set_translucency(value:Float):Float
	{
		_translucency = value;
		return value;
	}
	
	/**
	 * The colour of the "insides" of the object, ie: the colour the light becomes after leaving the object.
	 */
	private function get_scatterColor():Int
	{
		return _scatterColor;
	}
	
	private function set_scatterColor(scatterColor:Int):Int
	{
		_scatterColor = scatterColor;
		_scatterR = ((scatterColor >> 16) & 0xff)/0xff;
		_scatterG = ((scatterColor >> 8) & 0xff)/0xff;
		_scatterB = (scatterColor & 0xff)/0xff;
		return scatterColor;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		var code:String = super.getVertexCode(vo, regCache);
		var lightProjection:ShaderRegisterElement;
		var toTexRegister:ShaderRegisterElement;
		var temp:ShaderRegisterElement = regCache.getFreeVertexVectorTemp();
		
		toTexRegister = regCache.getFreeVertexConstant();
		vo.secondaryVertexConstantsIndex = toTexRegister.index*4;
		
		_lightProjVarying = regCache.getFreeVarying();
		lightProjection = regCache.getFreeVertexConstant();
		regCache.getFreeVertexConstant();
		regCache.getFreeVertexConstant();
		regCache.getFreeVertexConstant();
		
		code += "m44 " + temp + ", vt0, " + lightProjection + "\n" +
			"div " + temp + ".xyz, " + temp + ".xyz, " + temp + ".w\n" +
			"mul " + temp + ".xy, " + temp + ".xy, " + toTexRegister + ".xy\n" +
			"add " + temp + ".xy, " + temp + ".xy, " + toTexRegister + ".xx\n" +
			"mov " + _lightProjVarying + ".xyz, " + temp + ".xyz\n" +
			"mov " + _lightProjVarying + ".w, va0.w\n";
		
		return code;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		_colorReg = regCache.getFreeFragmentConstant();
		_decReg = regCache.getFreeFragmentConstant();
		_propReg = regCache.getFreeFragmentConstant();
		vo.secondaryFragmentConstantsIndex = _colorReg.index*4;
		
		return super.getFragmentPreLightingCode(vo, regCache);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getFragmentCodePerLight(vo:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String
	{
		_isFirstLight = true;
		_lightColorReg = lightColReg;
		return super.getFragmentCodePerLight(vo, lightDirReg, lightColReg, regCache);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var code:String = super.getFragmentPostLightingCode(vo, regCache, targetReg);
		var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		
		code += "mul " + temp + ".xyz, " + _lightColorReg + ".xyz, " + _targetReg + ".w\n" +
			"mul " + temp + ".xyz, " + temp + ".xyz, " + _colorReg + ".xyz\n" +
			"add " + targetReg + ".xyz, " + targetReg + ".xyz, " + temp + ".xyz\n";
		
		if (_targetReg != _sharedRegisters.viewDirFragment)
			regCache.removeFragmentTempUsage(targetReg);
		
		return code;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		super.activate(vo, stage3DProxy);
		
		var index:Int = vo.secondaryFragmentConstantsIndex;
		var data:Vector<Float> = vo.fragmentData;
		data[index] = _scatterR;
		data[index + 1] = _scatterG;
		data[index + 2] = _scatterB;
		data[index + 8] = _scattering;
		data[index + 9] = _translucency;
	}

	/**
	 * @inheritDoc
	 */
	override private function setRenderState(vo:MethodVO, renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		var depthMap:Texture = _depthPass.getDepthMap(renderable, stage3DProxy);
		var projection:Matrix3D = _depthPass.getProjection(renderable);
		
		stage3DProxy._context3D.setTextureAt(vo.secondaryTexturesIndex, depthMap);
		projection.copyRawDataTo(vo.vertexData, vo.secondaryVertexConstantsIndex + 4, true);
	}
	
	/**
	 * Generates the code for this method
	 */
	private function scatterLight(vo:MethodVO, targetReg:ShaderRegisterElement, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
	{
		// only scatter first light
		if (!_isFirstLight)
			return "";
		_isFirstLight = false;
		
		var code:String = "";
		var depthReg:ShaderRegisterElement = regCache.getFreeTextureReg();
		
		if (sharedRegisters.viewDirFragment == null)
			_targetReg = sharedRegisters.viewDirFragment;
		else {
			_targetReg = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(_targetReg, 1);
		}
		
		vo.secondaryTexturesIndex = depthReg.index;
		
		var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		code += "tex " + temp + ", " + _lightProjVarying + ", " + depthReg + " <2d,nearest,clamp>\n" +
			// reencode RGBA
			"dp4 " + targetReg + ".z, " + temp + ", " + _decReg + "\n";
		// currentDistanceToLight - closestDistanceToLight
		code += "sub " + targetReg + ".z, " + _lightProjVarying + ".z, " + targetReg + ".z\n" +
			
			"sub " + targetReg + ".z, " + _propReg + ".x, " + targetReg + ".z\n" +
			"mul " + targetReg + ".z, " + _propReg + ".y, " + targetReg + ".z\n" +
			"sat " + targetReg + ".z, " + targetReg + ".z\n" +
			
			// targetReg.x contains dot(lightDir, normal)
			// modulate according to incident light angle (scatter = scatter*(-.5*dot(light, normal) + .5)
			"neg " + targetReg + ".y, " + targetReg + ".x\n" +
			"mul " + targetReg + ".y, " + targetReg + ".y, " + _propReg + ".z\n" +
			"add " + targetReg + ".y, " + targetReg + ".y, " + _propReg + ".z\n" +
			"mul " + _targetReg + ".w, " + targetReg + ".z, " + targetReg + ".y\n" +
			
			// blend diffuse: d' = (1-s)*d + s*1
			"sub " + targetReg + ".y, " + _colorReg + ".w, " + _targetReg + ".w\n" +
			"mul " + targetReg + ".w, " + targetReg + ".w, " + targetReg + ".y\n";
		
		return code;
	}
}