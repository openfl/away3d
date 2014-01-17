/**
 * SubMesh wraps a SubGeometry as a scene graph instantiation. A SubMesh is owned by a Mesh object.
 *
 * @see away3d.core.base.SubGeometry
 * @see away3d.scenegraph.Mesh
 */
package away3d.core.base;

import flash.Vector;
import away3d.animators.IAnimator;
import away3d.animators.data.AnimationSubGeometry;

import away3d.bounds.BoundingVolumeBase;
import away3d.cameras.Camera3D;
import away3d.core.managers.Stage3DProxy;
import away3d.entities.Entity;
import away3d.entities.Mesh;
import away3d.materials.MaterialBase;
import flash.display3D.IndexBuffer3D;
import flash.geom.Matrix;
import flash.geom.Matrix3D;

class SubMesh implements IRenderable {
    public var shaderPickingDetails(get_shaderPickingDetails, never):Bool;
    public var offsetU(get_offsetU, set_offsetU):Float;
    public var offsetV(get_offsetV, set_offsetV):Float;
    public var scaleU(get_scaleU, set_scaleU):Float;
    public var scaleV(get_scaleV, set_scaleV):Float;
    public var uvRotation(get_uvRotation, set_uvRotation):Float;
    public var sourceEntity(get_sourceEntity, never):Entity;
    public var subGeometry(get_subGeometry, set_subGeometry):ISubGeometry;
    public var material(get_material, set_material):MaterialBase;
    public var sceneTransform(get_sceneTransform, never):Matrix3D;
    public var inverseSceneTransform(get_inverseSceneTransform, never):Matrix3D;
    public var numTriangles(get_numTriangles, never):Int;
    public var animator(get_animator, never):IAnimator;
    public var mouseEnabled(get_mouseEnabled, never):Bool;
    public var castsShadows(get_castsShadows, never):Bool;
    public var parentMesh(get_parentMesh, set_parentMesh):Mesh;
    public var uvTransform(get_uvTransform, never):Matrix;
    public var vertexData(get_vertexData, never):Vector<Float>;
    public var indexData(get_indexData, never):Vector<UInt>;
    public var UVData(get_UVData, never):Vector<Float>;
    public var bounds(get_bounds, never):BoundingVolumeBase;
    public var visible(get_visible, never):Bool;
    public var numVertices(get_numVertices, never):Int;
    public var vertexStride(get_vertexStride, never):Int;
    public var UVStride(get_UVStride, never):Int;
    public var vertexNormalData(get_vertexNormalData, never):Vector<Float>;
    public var vertexTangentData(get_vertexTangentData, never):Vector<Float>;
    public var UVOffset(get_UVOffset, never):Int;
    public var vertexOffset(get_vertexOffset, never):Int;
    public var vertexNormalOffset(get_vertexNormalOffset, never):Int;
    public var vertexTangentOffset(get_vertexTangentOffset, never):Int;

    public var _material:MaterialBase;
    private var _parentMesh:Mesh;
    private var _subGeometry:ISubGeometry;
    public var _index:Int;
    private var _uvTransform:Matrix;
    private var _uvTransformDirty:Bool;
    private var _uvRotation:Float;
    private var _scaleU:Float;
    private var _scaleV:Float;
    private var _offsetU:Float;
    private var _offsetV:Float;
    public var animationSubGeometry:AnimationSubGeometry;
    public var animatorSubGeometry:AnimationSubGeometry;
/**
	 * Creates a new SubMesh object
	 * @param subGeometry The SubGeometry object which provides the geometry data for this SubMesh.
	 * @param parentMesh The Mesh object to which this SubMesh belongs.
	 * @param material An optional material used to render this SubMesh.
	 */

    public function new(subGeometry:ISubGeometry, parentMesh:Mesh, material:MaterialBase = null) {
        _uvRotation = 0;
        _scaleU = 1;
        _scaleV = 1;
        _offsetU = 0;
        _offsetV = 0;
        _parentMesh = parentMesh;
        _subGeometry = subGeometry;
        this.material = material;
    }

    public function get_shaderPickingDetails():Bool {
        return sourceEntity.shaderPickingDetails;
    }

    public function get_offsetU():Float {
        return _offsetU;
    }

    public function set_offsetU(value:Float):Float {
        if (value == _offsetU) return value;
        _offsetU = value;
        _uvTransformDirty = true;
        return value;
    }

    public function get_offsetV():Float {
        return _offsetV;
    }

    public function set_offsetV(value:Float):Float {
        if (value == _offsetV) return value;
        _offsetV = value;
        _uvTransformDirty = true;
        return value;
    }

    public function get_scaleU():Float {
        return _scaleU;
    }

    public function set_scaleU(value:Float):Float {
        if (value == _scaleU) return value;
        _scaleU = value;
        _uvTransformDirty = true;
        return value;
    }

    public function get_scaleV():Float {
        return _scaleV;
    }

    public function set_scaleV(value:Float):Float {
        if (value == _scaleV) return value;
        _scaleV = value;
        _uvTransformDirty = true;
        return value;
    }

    public function get_uvRotation():Float {
        return _uvRotation;
    }

    public function set_uvRotation(value:Float):Float {
        if (value == _uvRotation) return value;
        _uvRotation = value;
        _uvTransformDirty = true;
        return value;
    }

/**
	 * The entity that that initially provided the IRenderable to the render pipeline (ie: the owning Mesh object).
	 */

    public function get_sourceEntity():Entity {
        return _parentMesh;
    }

/**
	 * The SubGeometry object which provides the geometry data for this SubMesh.
	 */

    public function get_subGeometry():ISubGeometry {
        return _subGeometry;
    }

    public function set_subGeometry(value:ISubGeometry):ISubGeometry {
        _subGeometry = value;
        return value;
    }

/**
	 * The material used to render the current SubMesh. If set to null, its parent Mesh's material will be used instead.
	 */

    public function get_material():MaterialBase {
        if (_material != null)return _material ;
        return _parentMesh.material;
    }

    public function set_material(value:MaterialBase):MaterialBase {
        if (_material != null) _material.removeOwner(this);
        _material = value;
        if (_material != null) _material.addOwner(this);
        return value;

    }

/**
	 * The scene transform object that transforms from model to world space.
	 */

    public function get_sceneTransform():Matrix3D {
        return _parentMesh.sceneTransform;
    }

/**
	 * The inverse scene transform object that transforms from world to model space.
	 */

    public function get_inverseSceneTransform():Matrix3D {
        return _parentMesh.inverseSceneTransform;
    }

/**
	 * @inheritDoc
	 */

    public function activateVertexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
        _subGeometry.activateVertexBuffer(index, stage3DProxy);
    }

/**
	 * @inheritDoc
	 */

    public function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
        _subGeometry.activateVertexNormalBuffer(index, stage3DProxy);
    }

/**
	 * @inheritDoc
	 */

    public function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
        _subGeometry.activateVertexTangentBuffer(index, stage3DProxy);
    }

/**
	 * @inheritDoc
	 */

    public function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
        _subGeometry.activateUVBuffer(index, stage3DProxy);
    }

/**
	 * @inheritDoc
	 */

    public function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
        _subGeometry.activateSecondaryUVBuffer(index, stage3DProxy);
    }

/**
	 * @inheritDoc
	 */

    public function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D {
        return _subGeometry.getIndexBuffer(stage3DProxy);
    }

/**
	 * The amount of triangles that make up this SubMesh.
	 */

    public function get_numTriangles():Int {
        return _subGeometry.numTriangles;
    }

/**
	 * The animator object that provides the state for the SubMesh's animation.
	 */

    public function get_animator():IAnimator {
        return _parentMesh.animator;
    }

/**
	 * Indicates whether the SubMesh should trigger mouse events, and hence should be rendered for hit testing.
	 */

    public function get_mouseEnabled():Bool {
        return _parentMesh.mouseEnabled || _parentMesh._ancestorsAllowMouseEnabled;
    }

    public function get_castsShadows():Bool {
        return _parentMesh.castsShadows;
    }

/**
	 * A reference to the owning Mesh object
	 *
	 * @private
	 */

    private function get_parentMesh():Mesh {
        return _parentMesh;
    }

    private function set_parentMesh(value:Mesh):Mesh {
        _parentMesh = value;
        return value;
    }

    public function get_uvTransform():Matrix {
        if (_uvTransformDirty) updateUVTransform();
        return _uvTransform;
    }

    private function updateUVTransform():Void {
        if (_uvTransform == null)
            _uvTransform = new Matrix();
        _uvTransform.identity();
        if (_uvRotation != 0) _uvTransform.rotate(_uvRotation);
        if (_scaleU != 1 || _scaleV != 1) _uvTransform.scale(_scaleU, _scaleV);
        _uvTransform.translate(_offsetU, _offsetV);
        _uvTransformDirty = false;
    }

    public function dispose():Void {
        material = null;
    }

    public function get_vertexData():Vector<Float> {
        return _subGeometry.vertexData;
    }

    public function get_indexData():Vector<UInt> {
        return _subGeometry.indexData;
    }

    public function get_UVData():Vector<Float> {
        return _subGeometry.UVData;
    }

    public function get_bounds():BoundingVolumeBase {
        return _parentMesh.bounds;
// TODO: return smaller, sub mesh bounds instead
    }

    public function get_visible():Bool {
        return _parentMesh.visible;
    }

    public function get_numVertices():Int {
        return _subGeometry.numVertices;
    }

    public function get_vertexStride():Int {
        return _subGeometry.vertexStride;
    }

    public function get_UVStride():Int {
        return _subGeometry.UVStride;
    }

    public function get_vertexNormalData():Vector<Float> {
        return _subGeometry.vertexNormalData;
    }

    public function get_vertexTangentData():Vector<Float> {
        return _subGeometry.vertexTangentData;
    }

    public function get_UVOffset():Int {
        return _subGeometry.UVOffset;
    }

    public function get_vertexOffset():Int {
        return _subGeometry.vertexOffset;
    }

    public function get_vertexNormalOffset():Int {
        return _subGeometry.vertexNormalOffset;
    }

    public function get_vertexTangentOffset():Int {
        return _subGeometry.vertexTangentOffset;
    }

    public function getRenderSceneTransform(camera:Camera3D):Matrix3D {
        return _parentMesh.sceneTransform;
    }

}

