/**
 * ...
 */
package away3d.animators.data;

import away3d.utils.ArrayUtils;
import away3d.animators.nodes.AnimationNodeBase;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import openfl.geom.Matrix3D;
import openfl.Vector;
import haxe.ds.ObjectMap;

class AnimationRegisterCache extends ShaderRegisterCache {
    public var numVertexConstant(get, never):Int;
    public var numFragmentConstant(get, never):Int;

    //vertex
    public var positionAttribute:ShaderRegisterElement;
    public var uvAttribute:ShaderRegisterElement;
    public var positionTarget:ShaderRegisterElement;
    public var scaleAndRotateTarget:ShaderRegisterElement;
    public var velocityTarget:ShaderRegisterElement;
    public var vertexTime:ShaderRegisterElement;
    public var vertexLife:ShaderRegisterElement;
    public var vertexZeroConst:ShaderRegisterElement;
    public var vertexOneConst:ShaderRegisterElement;
    public var vertexTwoConst:ShaderRegisterElement;
    public var uvTarget:ShaderRegisterElement;
    public var colorAddTarget:ShaderRegisterElement;
    public var colorMulTarget:ShaderRegisterElement;
    
    //vary
    public var colorAddVary:ShaderRegisterElement;
    public var colorMulVary:ShaderRegisterElement;
    
    //fragment
    public var uvVar:ShaderRegisterElement;

    //these are targets only need to rotate ( normal and tangent )
    public var rotationRegisters:Array<ShaderRegisterElement>;
    public var needFragmentAnimation:Bool;
    public var needUVAnimation:Bool;
    public var sourceRegisters:Array<String>;
    public var targetRegisters:Array<String>;
    private var indexDictionary:ObjectMap<AnimationNodeBase, Array<Int>>;

    //set true if has an node which will change UV
    public var hasUVNode:Bool;

    //set if the other nodes need to access the velocity
    public var needVelocity:Bool;

    //set if has a billboard node.
    public var hasBillboard:Bool;

    //set if has an node which will apply color multiple operation
    public var hasColorMulNode:Bool;

    //set if has an node which will apply color add operation
    public var hasColorAddNode:Bool;

    public function new(profile:String) {
        super(profile);
        indexDictionary = new ObjectMap<AnimationNodeBase, Array<Int>>();
        vertexConstantData = new Vector<Float>();
        fragmentConstantData = new Vector<Float>();
    }

    override public function reset():Void {
        super.reset();
        rotationRegisters = new Array<ShaderRegisterElement>();
        positionAttribute = getRegisterFromString(sourceRegisters[0]);
        scaleAndRotateTarget = getRegisterFromString(targetRegisters[0]);
        addVertexTempUsages(scaleAndRotateTarget, 1);
        var i:Int = 1;
        while (i < targetRegisters.length) {
            rotationRegisters.push(getRegisterFromString(targetRegisters[i]));
            addVertexTempUsages(rotationRegisters[i - 1], 1);
            i++;
        }
        scaleAndRotateTarget = new ShaderRegisterElement(scaleAndRotateTarget.regName, scaleAndRotateTarget.index);
        
        //only use xyz, w is used as vertexLife
        //allot const register
        vertexZeroConst = getFreeVertexConstant();
        vertexZeroConst = new ShaderRegisterElement(vertexZeroConst.regName, vertexZeroConst.index, 0);
        vertexOneConst = new ShaderRegisterElement(vertexZeroConst.regName, vertexZeroConst.index, 1);
        vertexTwoConst = new ShaderRegisterElement(vertexZeroConst.regName, vertexZeroConst.index, 2);

        //allot temp register
        positionTarget = getFreeVertexVectorTemp();
        addVertexTempUsages(positionTarget, 1);
        positionTarget = new ShaderRegisterElement(positionTarget.regName, positionTarget.index);
        if (needVelocity) {
            velocityTarget = getFreeVertexVectorTemp();
            addVertexTempUsages(velocityTarget, 1);
            velocityTarget = new ShaderRegisterElement(velocityTarget.regName, velocityTarget.index);
            vertexTime = new ShaderRegisterElement(velocityTarget.regName, velocityTarget.index, 3);
            vertexLife = new ShaderRegisterElement(positionTarget.regName, positionTarget.index, 3);
        }

        else {
            var tempTime:ShaderRegisterElement = getFreeVertexVectorTemp();
            addVertexTempUsages(tempTime, 1);
            vertexTime = new ShaderRegisterElement(tempTime.regName, tempTime.index, 0);
            vertexLife = new ShaderRegisterElement(tempTime.regName, tempTime.index, 1);
        }

    }

    public function setUVSourceAndTarget(UVAttribute:String, UVVaring:String):Void {
        uvVar = getRegisterFromString(UVVaring);
        uvAttribute = getRegisterFromString(UVAttribute);
        
        //uv action is processed after normal actions,so use offsetTarget as uvTarget
        uvTarget = new ShaderRegisterElement(positionTarget.regName, positionTarget.index);
    }

    public function setRegisterIndex(node:AnimationNodeBase, parameterIndex:Int, registerIndex:Int):Void {
        
        //8 should be enough for any node.
        var aNode = indexDictionary.exists(node) ? indexDictionary.get( node ) : ArrayUtils.Prefill( new Array<Int>(), 8, 0 );
        aNode[parameterIndex] = registerIndex;
        indexDictionary.set( node, aNode );
    }

    public function getRegisterIndex(node:AnimationNodeBase, parameterIndex:Int):Int {
        return indexDictionary.get( node )[parameterIndex];
    }

    public function getInitCode():String {
        var len:Int = sourceRegisters.length;
        var code:String = "";
        var i:Int = 0;
        while (i < len) {
            code += "mov " + targetRegisters[i] + "," + sourceRegisters[i] + "\n";
            i++;
        }
        code += "mov " + positionTarget + ".xyz," + vertexZeroConst.toString() + "\n";
        if (needVelocity) code += "mov " + velocityTarget + ".xyz," + vertexZeroConst.toString() + "\n";
        return code;
    }

    public function getCombinationCode():String {
        return "add " + scaleAndRotateTarget + ".xyz," + scaleAndRotateTarget + ".xyz," + positionTarget + ".xyz\n";
    }

    public function initColorRegisters():String {
        var code:String = "";
        if (hasColorMulNode) {
            colorMulTarget = getFreeVertexVectorTemp();
            addVertexTempUsages(colorMulTarget, 1);
            colorMulVary = getFreeVarying();
            code += "mov " + colorMulTarget + "," + vertexOneConst + "\n";
        }
        if (hasColorAddNode) {
            colorAddTarget = getFreeVertexVectorTemp();
            addVertexTempUsages(colorAddTarget, 1);
            colorAddVary = getFreeVarying();
            code += "mov " + colorAddTarget + "," + vertexZeroConst + "\n";
        }
        return code;
    }

    public function getColorPassCode():String {
        var code:String = "";
        if (needFragmentAnimation && (hasColorAddNode || hasColorMulNode)) {
            if (hasColorMulNode) code += "mov " + colorMulVary + "," + colorMulTarget + "\n";
            if (hasColorAddNode) code += "mov " + colorAddVary + "," + colorAddTarget + "\n";
        }
        return code;
    }

    public function getColorCombinationCode(shadedTarget:String):String {
        var code:String = "";
        if (needFragmentAnimation && (hasColorAddNode || hasColorMulNode)) {
            var colorTarget:ShaderRegisterElement = getRegisterFromString(shadedTarget);
            addFragmentTempUsages(colorTarget, 1);
            if (hasColorMulNode) 
                code += "mul " + colorTarget + "," + colorTarget + "," + colorMulVary + "\n";
            if (hasColorAddNode) 
                code += "add " + colorTarget + "," + colorTarget + "," + colorAddVary + "\n";
        }
        return code;
    }

    private function getRegisterFromString(code:String):ShaderRegisterElement {
        var er = ~/([a-z]+)([\d]+)/;
        er.match(code);
        return new ShaderRegisterElement(er.matched(1), Std.parseInt(er.matched(2)));
    }

    public var vertexConstantData:Vector<Float>;
    public var fragmentConstantData:Vector<Float>;
    private var _numVertexConstant:Int;
    private var _numFragmentConstant:Int;

    private function get_numVertexConstant():Int {
        return _numVertexConstant;
    }

    private function get_numFragmentConstant():Int {
        return _numFragmentConstant;
    }

    public function setDataLength():Void {
        _numVertexConstant = _numUsedVertexConstants - _vertexConstantOffset;
        _numFragmentConstant = _numUsedFragmentConstants - _fragmentConstantOffset;
        ArrayUtils.reSize( vertexConstantData,  _numVertexConstant * 4);
        ArrayUtils.reSize( fragmentConstantData,  _numFragmentConstant * 4);
    }

    public function setVertexConst(index:Int, x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 0):Void {
        var _index:Int = (index - _vertexConstantOffset) * 4;
        vertexConstantData[_index++] = x;
        vertexConstantData[_index++] = y;
        vertexConstantData[_index++] = z;
        vertexConstantData[_index] = w;
     }

    public function setVertexConstFromVector(index:Int, data:Array<Float>):Void {
        var _index:Int = (index - _vertexConstantOffset) * 4;
        var i:Int = 0;
        while (i < data.length) {
            vertexConstantData[_index++] = data[i];
            i++;
        }
    }

    public function setVertexConstFromMatrix(index:Int, matrix:Matrix3D):Void {
        var rawData:Vector<Float> = matrix.rawData;
        var _index:Int = (index - _vertexConstantOffset) * 4;
        vertexConstantData[_index++] = rawData[0];
        vertexConstantData[_index++] = rawData[4];
        vertexConstantData[_index++] = rawData[8];
        vertexConstantData[_index++] = rawData[12];
        vertexConstantData[_index++] = rawData[1];
        vertexConstantData[_index++] = rawData[5];
        vertexConstantData[_index++] = rawData[9];
        vertexConstantData[_index++] = rawData[13];
        vertexConstantData[_index++] = rawData[2];
        vertexConstantData[_index++] = rawData[6];
        vertexConstantData[_index++] = rawData[10];
        vertexConstantData[_index++] = rawData[14];
        vertexConstantData[_index++] = rawData[3];
        vertexConstantData[_index++] = rawData[7];
        vertexConstantData[_index++] = rawData[11];
        vertexConstantData[_index] = rawData[15];
    }

    public function setFragmentConst(index:Int, x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 0):Void {
        var _index:Int = (index - _fragmentConstantOffset) * 4;
        fragmentConstantData[_index++] = x;
        fragmentConstantData[_index++] = y;
        fragmentConstantData[_index++] = z;
        fragmentConstantData[_index] = w;
    }
}

