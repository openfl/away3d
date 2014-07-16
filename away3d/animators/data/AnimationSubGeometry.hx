/**
 * ...
 */
package away3d.animators.data;

import away3d.utils.ArrayUtils;
import openfl.display3D.Context3DVertexBufferFormat;
import away3d.core.managers.Stage3DProxy;
import away3d.core.math.MathConsts;
import openfl.display3D.Context3D;
import openfl.display3D.VertexBuffer3D;

class AnimationSubGeometry {
    public var vertexData(get_vertexData, never):Array<Float>;
    public var numVertices(get_numVertices, never):Int;
    public var totalLenOfOneVertex(get_totalLenOfOneVertex, never):Int;

    private var _vertexData:Array<Float>;
    private var _vertexBuffer:Array<VertexBuffer3D>;
    private var _bufferContext:Array<Context3D>;
    private var _bufferDirty:Array<Bool>;
    private var _numVertices:Int;
    private var _totalLenOfOneVertex:Int;
    public var numProcessedVertices:Int;
    public var previousTime:Float;
    public var animationParticles:Array<ParticleAnimationData>;

    public function new() {
        _vertexBuffer = ArrayUtils.Prefill( new Array<VertexBuffer3D>(), 8 );
        _bufferContext = ArrayUtils.Prefill( new Array<Context3D>(), 8 );
        _bufferDirty = ArrayUtils.Prefill( new Array<Bool>(), 8 );
        numProcessedVertices = 0;
        previousTime = Math.NEGATIVE_INFINITY;
        animationParticles = new Array<ParticleAnimationData>();
        var i:Int = 0;
        while (i < 8) {
            _bufferDirty[i] = true;
            i++;
        }
    }

    public function createVertexData(numVertices:Int, totalLenOfOneVertex:Int):Void {
        _numVertices = numVertices;
        _totalLenOfOneVertex = totalLenOfOneVertex;
        _vertexData = ArrayUtils.Prefill( new Array<Float>(), numVertices * totalLenOfOneVertex, 0 );
    }

    public function activateVertexBuffer(index:Int, bufferOffset:Int, stage3DProxy:Stage3DProxy, format:Context3DVertexBufferFormat):Void {
        var contextIndex:Int = stage3DProxy.stage3DIndex;
        var context:Context3D = stage3DProxy.context3D;
        var buffer:VertexBuffer3D = _vertexBuffer[contextIndex];
        if (buffer == null || _bufferContext[contextIndex] != context) {
            buffer = _vertexBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _totalLenOfOneVertex);
            _bufferContext[contextIndex] = context;
            _bufferDirty[contextIndex] = true;
        }
        if (_bufferDirty[contextIndex]) {
            buffer.uploadFromVector(_vertexData, 0, _numVertices);
            _bufferDirty[contextIndex] = false;
        }
        context.setVertexBufferAt(index, buffer, bufferOffset, format);
    }

    public function dispose():Void {
        while (_vertexBuffer.length > 0) {
            var vertexBuffer:VertexBuffer3D = _vertexBuffer.pop();
            if (vertexBuffer != null) vertexBuffer.dispose();
        }

    }

    public function invalidateBuffer():Void {
        var i:Int = 0;
        while (i < 8) {
            _bufferDirty[i] = true;
            i++;
        }
    }

    public function get_vertexData():Array<Float> {
        return _vertexData;
    }

    public function get_numVertices():Int {
        return _numVertices;
    }

    public function get_totalLenOfOneVertex():Int {
        return _totalLenOfOneVertex;
    }
}

