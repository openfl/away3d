package away3d.materials.methods;

import away3d.core.base.data.VertexDefinition.AttributeDefinition;
import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.materials.methods.EffectMethodBase;
import away3d.materials.methods.MethodVO;
import openfl.Vector;

class SegmentMethod extends EffectMethodBase
{
	/**
	 * Half of the line segment's width.
	 */
	public static var HALF_WIDTH(default, null):AttributeDefinition = new AttributeDefinition("halfWidth", 1);
	
	/**
	 * For each vertex, the position of the opposite end of the line segment.
	 */
	public static var OPPOSITE(default, null):AttributeDefinition = new AttributeDefinition("opposite", 3);
	
	public function new()
	{
		super([OPPOSITE, HALF_WIDTH]);
	}
	
	private override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		var index:Int = vo.vertexConstantsIndex;
		var data:Vector<Float> = vo.vertexData;
		
		var width:Float = stage3DProxy.width;
		var height:Float = stage3DProxy.height;
		if (stage3DProxy.scissorRect != null) {
			width = stage3DProxy.scissorRect.width;
			height = stage3DProxy.scissorRect.height;
		}
		if (width < 1) width = 1;
		if (height < 1) height = 1;
		
		//One pixel in screen coordinates. This can be either `2 / height` or
		//`2 / width`, with the only difference being the order of operations in
		//the "Find the line's direction" section.
		data[index] = 2 / height; //onePixel
		
		data[index + 1] = width / height; //aspectRatio
		data[index + 2] = height / width; //invAspectRatio
	}
	
	private override function getClipSpaceVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		var halfWidth:String = sharedRegisters.custom[HALF_WIDTH.name] + ".x";
		
		var constants:ShaderRegisterElement = regCache.getFreeVertexConstant();
		vo.vertexConstantsIndex = constants.index * 4;
		var onePixel:String = constants + ".x";
		var aspectRatio:String = constants + ".y";
		var invAspectRatio:String = constants + ".z";
		
		var code:String = "";
		
		var vertexPosition:ShaderRegisterElement = regCache.getFreeVertexVectorTemp();
		regCache.addVertexTempUsages(vertexPosition, 1);
		code += 'div $vertexPosition.xyz, ${ sharedRegisters.clipSpacePosition }.xyz, ${ sharedRegisters.clipSpacePosition }.w\n';
		
		var oppositePosition:ShaderRegisterElement = regCache.getFreeVertexVectorTemp();
		regCache.addVertexTempUsages(oppositePosition, 1);
		if (sharedRegisters.sceneTransform != null) {
			code += 'm44 $oppositePosition, ${ sharedRegisters.custom[OPPOSITE.name] }, ${ sharedRegisters.sceneTransform }\n'
				+ 'm44 $oppositePosition, $oppositePosition, vc0\n';
		} else {
			code += 'm44 $oppositePosition, ${ sharedRegisters.custom[OPPOSITE.name] }, vc0\n';
		}
		
		//Convert from clip space to (relative) screen space.
		//Normally, converting from clip space requires dividing a point by its
		//own w, but we only need the relative angle between them. Multiplying
		//each point by the other's w gets that and saves the division.
		code += 'mul $vertexPosition.xyz, ${ sharedRegisters.clipSpacePosition }.xyz, $oppositePosition.w\n'
			+ 'mul $oppositePosition.xyz, $oppositePosition.xyz, ${ sharedRegisters.clipSpacePosition }.w\n';
		
		//Find the line's direction in screen coordinates.
		var direction:ShaderRegisterElement = regCache.getFreeVertexVectorTemp();
		regCache.addVertexTempUsages(direction, 1);
		code += 'sub $direction.xy, $oppositePosition.xy, $vertexPosition.xy\n'
			+ 'mul $direction.x, $direction.x, $aspectRatio\n'
			+ 'nrm $direction.xy, $direction.xy\n'
			+ 'mul $direction.y, $direction.y, $invAspectRatio\n';
		
		//Rotate `direction` to be perpendicular to the line.
		code += 'mov $direction.z, $direction.x\n'
			+ 'mov $direction.x, $direction.y\n'
			+ 'neg $direction.y, $direction.z\n';
		
		//Prepare to move the vertex by `halfWidth * onePixel` in clip space.
		//This vertex's mirror will move the same distance in the opposite
		//direction, so the line will be drawn at its full width.
		var distance:String = '$direction.z';
		code += 'mul $distance, $halfWidth, $onePixel\n'
			+ 'mul $distance, $distance, ${ sharedRegisters.clipSpacePosition }.w\n'
			+ 'mul $direction.xy, $direction.xy, $distance\n';
		
		//Move the vertex.
		code += 'add ${ sharedRegisters.clipSpacePosition }.xy, ${ sharedRegisters.clipSpacePosition }.xy, $direction.xy\n';
		
		regCache.removeVertexTempUsage(vertexPosition);
		regCache.removeVertexTempUsage(oppositePosition);
		regCache.removeVertexTempUsage(direction);
		
		return code;
	}
	
	private override function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		return "";
	}
}
