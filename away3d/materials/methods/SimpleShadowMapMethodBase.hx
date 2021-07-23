package away3d.materials.methods;

import away3d.*;
import away3d.cameras.*;
import away3d.core.base.*;
import away3d.core.managers.*;
import away3d.errors.*;
import away3d.lights.*;
import away3d.lights.shadowmaps.*;
import away3d.materials.compilation.*;

import openfl.errors.Error;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * SimpleShadowMapMethodBase provides an abstract method for simple (non-wrapping) shadow map methods.
 */
class SimpleShadowMapMethodBase extends ShadowMapMethodBase
{
	@:allow(away3d) private var depthMapCoordReg(get, set):ShaderRegisterElement;
	
	private var _depthMapCoordReg:ShaderRegisterElement;
	private var _usePoint:Bool;
	
	/**
	 * Creates a new SimpleShadowMapMethodBase object.
	 * @param castingLight The light used to cast shadows.
	 */
	public function new(castingLight:LightBase)
	{
		_usePoint = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(castingLight, PointLight);
		_depthMapCoordReg = null;
		super(castingLight);
	}

	/**
	 * @inheritDoc
	 */
	override private function initVO(vo:MethodVO):Void
	{
		vo.needsView = true;
		vo.needsGlobalVertexPos = true;
		vo.needsGlobalFragmentPos = _usePoint;
		vo.needsNormals = vo.numLights > 0;
	}

	/**
	 * @inheritDoc
	 */
	override private function initConstants(vo:MethodVO):Void
	{
		var fragmentData:Vector<Float> = vo.fragmentData;
		var vertexData:Vector<Float> = vo.vertexData;
		var index:Int = vo.fragmentConstantsIndex;
		fragmentData[index] = 1.0;
		fragmentData[index + 1] = 1/255.0;
		fragmentData[index + 2] = 1/65025.0;
		fragmentData[index + 3] = 1/16581375.0;
		
		fragmentData[index + 6] = 0;
		fragmentData[index + 7] = 1;
		
		if (_usePoint) {
			fragmentData[index + 8] = 0;
			fragmentData[index + 9] = 0;
			fragmentData[index + 10] = 0;
			fragmentData[index + 11] = 1;
		}
		
		index = vo.vertexConstantsIndex;
		if (index != -1) {
			vertexData[index] = .5;
			vertexData[index + 1] = -.5;
			vertexData[index + 2] = 0.0;
			vertexData[index + 3] = 1.0;
		}
	}
	
	/**
	 * Wrappers that override the vertex shader need to set this explicitly
	 */
	private function get_depthMapCoordReg():ShaderRegisterElement
	{
		return _depthMapCoordReg;
	}
	
	private function set_depthMapCoordReg(value:ShaderRegisterElement):ShaderRegisterElement
	{
		_depthMapCoordReg = value;
		return value;
	}

	/**
	 * @inheritDoc
	 */
	override private function cleanCompilationData():Void
	{
		super.cleanCompilationData();
		
		_depthMapCoordReg = null;
	}

	/**
	 * @inheritDoc
	 */
	override private function getVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		return _usePoint? getPointVertexCode(vo, regCache) : getPlanarVertexCode(vo, regCache);
	}

	/**
	 * Gets the vertex code for shadow mapping with a point light.
	 *
	 * @param vo The MethodVO object linking this method with the pass currently being compiled.
	 * @param regCache The register cache used during the compilation.
	 */
	private function getPointVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		vo.vertexConstantsIndex = -1;
		return "";
	}

	/**
	 * Gets the vertex code for shadow mapping with a planar shadow map (fe: directional lights).
	 *
	 * @param vo The MethodVO object linking this method with the pass currently being compiled.
	 * @param regCache The register cache used during the compilation.
	 */
	private function getPlanarVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		var code:String = "";
		var temp:ShaderRegisterElement = regCache.getFreeVertexVectorTemp();
		var dataReg:ShaderRegisterElement = regCache.getFreeVertexConstant();
		var depthMapProj:ShaderRegisterElement = regCache.getFreeVertexConstant();
		regCache.getFreeVertexConstant();
		regCache.getFreeVertexConstant();
		regCache.getFreeVertexConstant();
		_depthMapCoordReg = regCache.getFreeVarying();
		vo.vertexConstantsIndex = dataReg.index*4;
		
		// todo: can epsilon be applied here instead of fragment shader?
		
		code += "m44 " + temp + ", " + _sharedRegisters.globalPositionVertex + ", " + depthMapProj + "\n" +
			"div " + temp + ", " + temp + ", " + temp + ".w\n" +
			"mul " + temp + ".xy, " + temp + ".xy, " + dataReg + ".xy\n" +
			"add " + _depthMapCoordReg + ", " + temp + ", " + dataReg + ".xxwz\n";
		
		return code;
	}

	/**
	 * @inheritDoc
	 */
	override private function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var code:String = _usePoint? getPointFragmentCode(vo, regCache, targetReg) : getPlanarFragmentCode(vo, regCache, targetReg);
		code += "add " + targetReg + ".w, " + targetReg + ".w, fc" + (vo.fragmentConstantsIndex/4 + 1) + ".y\n" +
			"sat " + targetReg + ".w, " + targetReg + ".w\n";
		return code;
	}

	/**
	 * Gets the fragment code for shadow mapping with a planar shadow map.
	 * @param vo The MethodVO object linking this method with the pass currently being compiled.
	 * @param regCache The register cache used during the compilation.
	 * @param targetReg The register to contain the shadow coverage
	 * @return
	 */
	private function getPlanarFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		throw new AbstractMethodError();
		return "";
	}

	/**
	 * Gets the fragment code for shadow mapping with a point light.
	 * @param vo The MethodVO object linking this method with the pass currently being compiled.
	 * @param regCache The register cache used during the compilation.
	 * @param targetReg The register to contain the shadow coverage
	 * @return
	 */
	private function getPointFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		throw new AbstractMethodError();
		return "";
	}

	/**
	 * @inheritDoc
	 */
	override private function setRenderState(vo:MethodVO, renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		if (!_usePoint)
			cast(_shadowMapper, DirectionalShadowMapper).depthProjection.copyRawDataTo(vo.vertexData, vo.vertexConstantsIndex + 4, true);
	}

	/**
	 * Gets the fragment code for combining this method with a cascaded shadow map method.
	 * @param vo The MethodVO object linking this method with the pass currently being compiled.
	 * @param regCache The register cache used during the compilation.
	 * @param decodeRegister The register containing the data to decode the shadow map depth value.
	 * @param depthTexture The texture containing the shadow map.
	 * @param depthProjection The projection of the fragment relative to the light.
	 * @param targetRegister The register to contain the shadow coverage
	 * @return
	 */
	@:allow(away3d) private function getCascadeFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, decodeRegister:ShaderRegisterElement, depthTexture:ShaderRegisterElement, depthProjection:ShaderRegisterElement, targetRegister:ShaderRegisterElement):String
	{
		throw new Error("This shadow method is incompatible with cascade shadows");
		return null;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		var fragmentData:Vector<Float> = vo.fragmentData;
		var index:Int = vo.fragmentConstantsIndex;
		
		if (_usePoint)
			fragmentData[index + 4] = -Math.pow(1/(cast(_castingLight, PointLight).fallOff*_epsilon), 2);
		else
			vo.vertexData[vo.vertexConstantsIndex + 3] = -1/(cast(_shadowMapper, DirectionalShadowMapper).depth*_epsilon);
		
		fragmentData[index + 5] = 1 - _alpha;
		if (_usePoint) {
			var pos:Vector3D = _castingLight.scenePosition;
			fragmentData[index + 8] = pos.x;
			fragmentData[index + 9] = pos.y;
			fragmentData[index + 10] = pos.z;
			// used to decompress distance
			var f:Float = cast(_castingLight, PointLight)._fallOff;
			fragmentData[index + 11] = 1/(2*f*f);
		}
		stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _castingLight.shadowMapper.depthMap.getTextureForStage3D(stage3DProxy));
	}

	/**
	 * Sets the method state for cascade shadow mapping.
	 */
	@:allow(away3d) private function activateForCascade(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		throw new Error("This shadow method is incompatible with cascade shadows");
	}
}