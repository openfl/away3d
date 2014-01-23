/**
 * SkinnedSubGeometry provides a SubGeometry extension that contains data needed to skin vertices. In particular,
 * it provides joint indices and weights.
 * Important! Joint indices need to be pre-multiplied by 3, since they index the matrix array (and each matrix has 3 float4 elements)
 */
package away3d.core.base;


import away3d.utils.ArrayUtils;
import flash.display3D.Context3DVertexBufferFormat;
import flash.Vector;
import away3d.core.managers.Stage3DProxy;
import flash.display3D.Context3D;
import flash.display3D.VertexBuffer3D;
import haxe.ds.IntMap;

class SkinnedSubGeometry extends CompactSubGeometry {
    public var condensedIndexLookUp(get_condensedIndexLookUp, never):Vector<UInt>;
    public var numCondensedJoints(get_numCondensedJoints, never):Int;
    public var animatedData(get_animatedData, never):Vector<Float>;
    public var jointWeightsData(get_jointWeightsData, never):Vector<Float>;
    public var jointIndexData(get_jointIndexData, never):Vector<Float>;

    private var _bufferFormat:Context3DVertexBufferFormat;
    private var _jointWeightsData:Vector<Float>;
    private var _jointIndexData:Vector<Float>;
    private var _animatedData:Vector<Float>;
// used for cpu fallback
    private var _jointWeightsBuffer:Vector<VertexBuffer3D>;
    private var _jointIndexBuffer:Vector<VertexBuffer3D>;
    private var _jointWeightsInvalid:Vector<Bool>;
    private var _jointIndicesInvalid:Vector<Bool>;
    private var _jointWeightContext:Vector<Context3D>;
    private var _jointIndexContext:Vector<Context3D>;
    private var _jointsPerVertex:Int;
    private var _condensedJointIndexData:Vector<Float>;
    private var _condensedIndexLookUp:Vector<UInt>;
// used for linking condensed indices to the real ones
    private var _numCondensedJoints:Int;
/**
	 * Creates a new SkinnedSubGeometry object.
	 * @param jointsPerVertex The amount of joints that can be assigned per vertex.
	 */

    public function new(jointsPerVertex:Int) {
        _jointWeightsBuffer = new Vector<VertexBuffer3D>(8);
        _jointIndexBuffer = new Vector<VertexBuffer3D>(8);
        _jointWeightsInvalid = new Vector<Bool>(8, true);
        ArrayUtils.Prefill(_jointWeightsInvalid,8,false);
        _jointIndicesInvalid = new Vector<Bool>(8, true);
        ArrayUtils.Prefill(_jointIndicesInvalid,8,false);
        _jointWeightContext = new Vector<Context3D>(8);
        _jointIndexContext = new Vector<Context3D>(8);
        super();
        _jointsPerVertex = jointsPerVertex;
        _bufferFormat = getVertexBufferFormat(_jointsPerVertex);
    }

    public function getVertexBufferFormat(size:Int):Context3DVertexBufferFormat {
        switch(size)
        {
            case 1:
                return Context3DVertexBufferFormat.FLOAT_1;
            case 2:
                return Context3DVertexBufferFormat.FLOAT_2;
            case 3:
                return Context3DVertexBufferFormat.FLOAT_3;
            case 4:
                return Context3DVertexBufferFormat.FLOAT_3;
            default:
                return null;
        }
    }
/**
	 * If indices have been condensed, this will contain the original index for each condensed index.
	 */

    public function get_condensedIndexLookUp():Vector<UInt> {
        return _condensedIndexLookUp;
    }

/**
	 * The amount of joints used when joint indices have been condensed.
	 */

    public function get_numCondensedJoints():Int {
        return _numCondensedJoints;
    }

/**
	 * The animated vertex positions when set explicitly if the skinning transformations couldn't be performed on GPU.
	 */

    public function get_animatedData():Vector<Float> {
        if (_animatedData != null) return _animatedData ;
        return _vertexData.concat();
    }

    public function updateAnimatedData(value:Vector<Float>):Void {
        _animatedData = value;
        invalidateBuffers(_vertexDataInvalid);
    }

/**
	 * Assigns the attribute stream for joint weights
	 * @param index The attribute stream index for the vertex shader
	 * @param stage3DProxy The Stage3DProxy to assign the stream to
	 */

    public function activateJointWeightsBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
        var contextIndex:Int = stage3DProxy._stage3DIndex;
        var context:Context3D = stage3DProxy._context3D;
        if (_jointWeightContext[contextIndex] != context || _jointWeightsBuffer[contextIndex] == null) {
            _jointWeightsBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _jointsPerVertex);
            _jointWeightContext[contextIndex] = context;
            _jointWeightsInvalid[contextIndex] = true;
        }
        if (_jointWeightsInvalid[contextIndex]) {
            _jointWeightsBuffer[contextIndex].uploadFromVector(_jointWeightsData, 0, Std.int(_jointWeightsData.length / _jointsPerVertex));
            _jointWeightsInvalid[contextIndex] = false;
        }
        context.setVertexBufferAt(index, _jointWeightsBuffer[contextIndex], 0, _bufferFormat);
    }

/**
	 * Assigns the attribute stream for joint indices
	 * @param index The attribute stream index for the vertex shader
	 * @param stage3DProxy The Stage3DProxy to assign the stream to
	 */

    public function activateJointIndexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
        var contextIndex:Int = stage3DProxy._stage3DIndex;
        var context:Context3D = stage3DProxy._context3D;
        if (_jointIndexContext[contextIndex] != context || _jointIndexBuffer[contextIndex] == null) {
            _jointIndexBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _jointsPerVertex);
            _jointIndexContext[contextIndex] = context;
            _jointIndicesInvalid[contextIndex] = true;
        }
        if (_jointIndicesInvalid[contextIndex]) {
            _jointIndexBuffer[contextIndex].uploadFromVector(_numCondensedJoints > (0) ? _condensedJointIndexData : _jointIndexData, 0, Std.int(_jointIndexData.length / _jointsPerVertex));
            _jointIndicesInvalid[contextIndex] = false;
        }
        context.setVertexBufferAt(index, _jointIndexBuffer[contextIndex], 0, _bufferFormat);
    }

    override private function uploadData(contextIndex:Int):Void {
        if (_animatedData != null) {
            _activeBuffer.uploadFromVector(_animatedData, 0, _numVertices);
            _vertexDataInvalid[contextIndex] = _activeDataInvalid = false;
        }

        else super.uploadData(contextIndex);
    }

/**
	 * Clones the current object.
	 * @return An exact duplicate of the current object.
	 */

    override public function clone():ISubGeometry {
        var clone:SkinnedSubGeometry = new SkinnedSubGeometry(_jointsPerVertex);
        clone.updateData(_vertexData.concat());
        clone.updateIndexData(_indices.concat());
        clone.updateJointIndexData(_jointIndexData.concat());
        clone.updateJointWeightsData(_jointWeightsData.concat());
        clone._autoDeriveVertexNormals = _autoDeriveVertexNormals;
        clone._autoDeriveVertexTangents = _autoDeriveVertexTangents;
        clone._numCondensedJoints = _numCondensedJoints;
        clone._condensedIndexLookUp = _condensedIndexLookUp;
        clone._condensedJointIndexData = _condensedJointIndexData;
        return clone;
    }

/**
	 * Cleans up any resources used by this object.
	 */

    override public function dispose():Void {
        super.dispose();
        disposeVertexBuffers(_jointWeightsBuffer);
        disposeVertexBuffers(_jointIndexBuffer);
    }

/**
	 */

    public function condenseIndexData():Void {
        var len:Int = _jointIndexData.length;
        var oldIndex:Int;
        var newIndex:Int = 0;
        var dic:IntMap<Int> = new IntMap<Int>();
        _condensedJointIndexData = new Vector<Float>(len, true);
        ArrayUtils.Prefill(_condensedJointIndexData,len,0);
        _condensedIndexLookUp = new Vector<UInt>();
        var i:Int = 0;
        while (i < len) {
            oldIndex = Std.int(_jointIndexData[i]);
// if we encounter a new index, assign it a new condensed index
            if (!dic.exists(oldIndex)) {
                dic.set(oldIndex, newIndex);
                _condensedIndexLookUp[newIndex++] = oldIndex;
                _condensedIndexLookUp[newIndex++] = oldIndex + 1;
                _condensedIndexLookUp[newIndex++] = oldIndex + 2;
            }
            _condensedJointIndexData[i] = dic.get(oldIndex);
            ++i;
        }
        _numCondensedJoints = Std.int(newIndex / 3);
        invalidateBuffers(_jointIndicesInvalid);
    }

/**
	 * The raw joint weights data.
	 */

    private function get_jointWeightsData():Vector<Float> {
        return _jointWeightsData;
    }

    public function updateJointWeightsData(value:Vector<Float>):Void {
// invalidate condensed stuff
        _numCondensedJoints = 0;
        _condensedIndexLookUp = null;
        _condensedJointIndexData = null;
        _jointWeightsData = value;
        invalidateBuffers(_jointWeightsInvalid);
    }

/**
	 * The raw joint index data.
	 */

    private function get_jointIndexData():Vector<Float> {
        return _jointIndexData;
    }

    public function updateJointIndexData(value:Vector<Float>):Void {
        _jointIndexData = value;
        invalidateBuffers(_jointIndicesInvalid);
    }

}

