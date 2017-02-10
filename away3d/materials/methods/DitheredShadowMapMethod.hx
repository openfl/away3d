package away3d.materials.methods;

import away3d.core.managers.Stage3DProxy;
import away3d.lights.DirectionalLight;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.textures.BitmapTexture;

import openfl.display.BitmapData;
import openfl.utils.ByteArray;
import openfl.Vector;

/**
 * DitheredShadowMapMethod provides a soft shadowing technique by randomly distributing sample points differently for each fragment.
 */
class DitheredShadowMapMethod extends SimpleShadowMapMethodBase
{
	public var numSamples(get, set):Int;
	public var range(get, set):Float;
	
	private static var _grainTexture:BitmapTexture;
	private static var _grainUsages:Int;
	private static var _grainBitmapData:BitmapData;
	private var _depthMapSize:Int;
	private var _range:Float = 1;
	private var _numSamples:Int;
	
	/**
	 * Creates a new DitheredShadowMapMethod object.
	 * @param castingLight The light casting the shadows
	 * @param numSamples The amount of samples to take for dithering. Minimum 1, maximum 24.
	 */
	public function new(castingLight:DirectionalLight, numSamples:Int = 4)
	{
		super(castingLight);
		
		_depthMapSize = _castingLight.shadowMapper.depthMapSize;
		
		this.numSamples = numSamples;
		
		++_grainUsages;
		
		if (_grainTexture == null)
			initGrainTexture();
	}

	/**
	 * The amount of samples to take for dithering. Minimum 1, maximum 24. The actual maximum may depend on the
	 * complexity of the shader.
	 */
	private function get_numSamples():Int
	{
		return _numSamples;
	}
	
	private function set_numSamples(value:Int):Int
	{
		_numSamples = value;
		if (_numSamples < 1)
			_numSamples = 1;
		else if (_numSamples > 24)
			_numSamples = 24;
		invalidateShaderProgram();
		return value;
	}

	/**
	 * @inheritDoc
	 */
	override private function initVO(vo:MethodVO):Void
	{
		super.initVO(vo);
		vo.needsProjection = true;
	}

	/**
	 * @inheritDoc
	 */
	override private function initConstants(vo:MethodVO):Void
	{
		super.initConstants(vo);
		
		var fragmentData:Vector<Float> = vo.fragmentData;
		var index:Int = vo.fragmentConstantsIndex;
		fragmentData[index + 8] = 1/_numSamples;
	}

	/**
	 * The range in the shadow map in which to distribute the samples.
	 */
	private function get_range():Float
	{
		return _range*2;
	}
	
	private function set_range(value:Float):Float
	{
		_range = value/2;
		return value;
	}

	/**
	 * Creates a texture containing the dithering noise texture.
	 */
	private function initGrainTexture():Void
	{
		_grainBitmapData = new BitmapData(64, 64, false);
		var vec:Vector<UInt> = new Vector<UInt>();
		var len:Int = 4096;
		var step:Float = 1/(_depthMapSize*_range);
		var r:Float, g:Float;
		
		for (i in 0...len) {
			r = 2*(Math.random() - .5);
			g = 2*(Math.random() - .5);
			if (r < 0)
				r -= step;
			else
				r += step;
			if (g < 0)
				g -= step;
			else
				g += step;
			if (r > 1)
				r = 1;
			else if (r < -1)
				r = -1;
			if (g > 1)
				g = 1;
			else if (g < -1)
				g = -1;
			vec[i] = (Std.int((r * .5 + .5) * 0xff) << 16) | (Std.int((g * .5 + .5) * 0xff) << 8);
		}
		
		_grainBitmapData.setVector(_grainBitmapData.rect, vec);
		_grainTexture = new BitmapTexture(_grainBitmapData);
	}

	/**
	 * @inheritDoc
	 */
	override public function dispose():Void
	{
		if (--_grainUsages == 0) {
			_grainTexture.dispose();
			_grainBitmapData.dispose();
			_grainTexture = null;
		}
	}

	/**
	 * @inheritDoc
	 */
	override private function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		super.activate(vo, stage3DProxy);
		var data:Vector<Float> = vo.fragmentData;
		var index:Int = vo.fragmentConstantsIndex;
		data[index + 9] = (stage3DProxy.width - 1)/63;
		data[index + 10] = (stage3DProxy.height - 1)/63;
		data[index + 11] = 2*_range/_depthMapSize;
		stage3DProxy._context3D.setTextureAt(vo.texturesIndex + 1, _grainTexture.getTextureForStage3D(stage3DProxy));
	}

	/**
	 * @inheritDoc
	 */
	override private function getPlanarFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var depthMapRegister:ShaderRegisterElement = regCache.getFreeTextureReg();
		var decReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		var customDataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();

		vo.fragmentConstantsIndex = decReg.index*4;
		vo.texturesIndex = depthMapRegister.index;

		return getSampleCode(regCache, customDataReg, depthMapRegister, decReg, targetReg);
	}

	/**
	 * Get the actual shader code for shadow mapping
	 * @param regCache The register cache managing the registers.
	 * @param depthMapRegister The texture register containing the depth map.
	 * @param decReg The register containing the depth map decoding data.
	 * @param targetReg The target register to add the shadow coverage.
	 */
	private function getSampleCode(regCache:ShaderRegisterCache, customDataReg:ShaderRegisterElement, depthMapRegister:ShaderRegisterElement, decReg:ShaderRegisterElement, targetReg:ShaderRegisterElement):String
	{
		var code:String = "";
		var grainRegister:ShaderRegisterElement = regCache.getFreeTextureReg();
		var uvReg:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		var numSamples:Int = _numSamples;
		regCache.addFragmentTempUsages(uvReg, 1);
		
		var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		
		var projectionReg:ShaderRegisterElement = _sharedRegisters.projectionFragment;
		
		code += "div " + uvReg + ", " + projectionReg + ", " + projectionReg + ".w\n" +
			"mul " + uvReg + ".xy, " + uvReg + ".xy, " + customDataReg + ".yz\n";
		
		while (numSamples > 0) {
			if (numSamples == _numSamples)
				code += "tex " + uvReg + ", " + uvReg + ", " + grainRegister + " <2d,nearest,repeat,mipnone>\n";
			else
				code += "tex " + uvReg + ", " + uvReg + ".zwxy, " + grainRegister + " <2d,nearest,repeat,mipnone>\n";
			
			// keep grain in uvReg.zw
			code += "sub " + uvReg + ".zw, " + uvReg + ".xy, fc0.xx\n" + // uv-.5
				"mul " + uvReg + ".zw, " + uvReg + ".zw, " + customDataReg + ".w\n"; // (tex unpack scale and tex scale in one)
			
			// first sample
			
			if (numSamples == _numSamples) {
				// first sample
				code += "add " + uvReg + ".xy, " + uvReg + ".zw, " + _depthMapCoordReg + ".xy\n" +
					"tex " + temp + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp,mipnone>\n" +
					"dp4 " + temp + ".z, " + temp + ", " + decReg + "\n" +
					"slt " + targetReg + ".w, " + _depthMapCoordReg + ".z, " + temp + ".z\n"; // 0 if in shadow
			} else
				code += addSample(uvReg, depthMapRegister, decReg, targetReg, regCache);
			
			if (numSamples > 4) {
				code += "add " + uvReg + ".xy, " + uvReg + ".xy, " + uvReg + ".zw\n" +
					addSample(uvReg, depthMapRegister, decReg, targetReg, regCache);
			}
			
			if (numSamples > 1) {
				code += "sub " + uvReg + ".xy, " + _depthMapCoordReg + ".xy, " + uvReg + ".zw\n" +
					addSample(uvReg, depthMapRegister, decReg, targetReg, regCache);
			}
			
			if (numSamples > 5) {
				code += "sub " + uvReg + ".xy, " + uvReg + ".xy, " + uvReg + ".zw\n" +
					addSample(uvReg, depthMapRegister, decReg, targetReg, regCache);
			}
			
			if (numSamples > 2) {
				code += "neg " + uvReg + ".w, " + uvReg + ".w\n"; // will be rotated 90 degrees when being accessed as wz
				
				code += "add " + uvReg + ".xy, " + uvReg + ".wz, " + _depthMapCoordReg + ".xy\n" +
					addSample(uvReg, depthMapRegister, decReg, targetReg, regCache);
			}
			
			if (numSamples > 6) {
				code += "add " + uvReg + ".xy, " + uvReg + ".xy, " + uvReg + ".wz\n" +
					addSample(uvReg, depthMapRegister, decReg, targetReg, regCache);
			}
			
			if (numSamples > 3) {
				code += "sub " + uvReg + ".xy, " + _depthMapCoordReg + ".xy, " + uvReg + ".wz\n" +
					addSample(uvReg, depthMapRegister, decReg, targetReg, regCache);
			}
			
			if (numSamples > 7) {
				code += "sub " + uvReg + ".xy, " + uvReg + ".xy, " + uvReg + ".wz\n" +
					addSample(uvReg, depthMapRegister, decReg, targetReg, regCache);
			}
			
			numSamples -= 8;
		}
		
		regCache.removeFragmentTempUsage(uvReg);
		code += "mul " + targetReg + ".w, " + targetReg + ".w, " + customDataReg + ".x\n"; // average
		return code;
	}

	/**
	 * Adds the code for another tap to the shader code.
	 * @param uvReg The uv register for the tap.
	 * @param depthMapRegister The texture register containing the depth map.
	 * @param decReg The register containing the depth map decoding data.
	 * @param targetReg The target register to add the tap comparison result.
	 * @param regCache The register cache managing the registers.
	 * @return
	 */
	private function addSample(uvReg:ShaderRegisterElement, depthMapRegister:ShaderRegisterElement, decReg:ShaderRegisterElement, targetReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String
	{
		var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		return "tex " + temp + ", " + uvReg + ", " + depthMapRegister + " <2d,nearest,clamp,mipnone>\n" +
			"dp4 " + temp + ".z, " + temp + ", " + decReg + "\n" +
			"slt " + temp + ".z, " + _depthMapCoordReg + ".z, " + temp + ".z\n" + // 0 if in shadow
			"add " + targetReg + ".w, " + targetReg + ".w, " + temp + ".z\n";
	}

	/**
	 * @inheritDoc
	 */
	override private function activateForCascade(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		var data:Vector<Float> = vo.fragmentData;
		var index:Int = vo.secondaryFragmentConstantsIndex;
		data[index] = 1/_numSamples;
		data[index + 1] = (stage3DProxy.width - 1)/63;
		data[index + 2] = (stage3DProxy.height - 1)/63;
		data[index + 3] = 2*_range/_depthMapSize;
		stage3DProxy._context3D.setTextureAt(vo.texturesIndex + 1, _grainTexture.getTextureForStage3D(stage3DProxy));
	}

	/**
	 * @inheritDoc
	 */
	override private function getCascadeFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, decodeRegister:ShaderRegisterElement, depthTexture:ShaderRegisterElement, depthProjection:ShaderRegisterElement, targetRegister:ShaderRegisterElement):String
	{
		_depthMapCoordReg = depthProjection;
		
		var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		vo.secondaryFragmentConstantsIndex = dataReg.index*4;
		
		return getSampleCode(regCache, dataReg, depthTexture, decodeRegister, targetRegister);
	}
}