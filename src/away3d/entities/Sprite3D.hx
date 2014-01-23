/**
 * Sprite3D is a 3D billboard, a renderable rectangular area that is always aligned with the projection plane.
 * As a result, no perspective transformation occurs on a Sprite3D object.
 *
 * todo: mvp generation or vertex shader code can be optimized
 */
package away3d.entities;

import flash.Vector;
import away3d.animators.IAnimator;

import away3d.bounds.AxisAlignedBoundingBox;
import away3d.bounds.BoundingVolumeBase;
import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.base.SubGeometry;
import away3d.core.base.SubMesh;
import away3d.core.managers.Stage3DProxy;
import away3d.core.math.Matrix3DUtils;
import away3d.core.partition.EntityNode;
import away3d.core.partition.RenderableNode;
import away3d.core.pick.IPickingCollider;
import away3d.materials.MaterialBase;
import flash.display3D.IndexBuffer3D;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

class Sprite3D extends Entity implements IRenderable {
    public var width(get_width, set_width):Float;
    public var height(get_height, set_height):Float;
    public var numTriangles(get_numTriangles, never):Int;
    public var sourceEntity(get_sourceEntity, never):Entity;
    public var material(get_material, set_material):MaterialBase;
    public var animator(get_animator, never):IAnimator;
    public var castsShadows(get_castsShadows, never):Bool;
    public var uvTransform(get_uvTransform, never):Matrix;
    public var vertexData(get_vertexData, never):Vector<Float>;
    public var indexData(get_indexData, never):Vector<UInt>;
    public var UVData(get_UVData, never):Vector<Float>;
    public var numVertices(get_numVertices, never):Int;
    public var vertexStride(get_vertexStride, never):Int;
    public var vertexNormalData(get_vertexNormalData, never):Vector<Float>;
    public var vertexTangentData(get_vertexTangentData, never):Vector<Float>;
    public var vertexOffset(get_vertexOffset, never):Int;
    public var vertexNormalOffset(get_vertexNormalOffset, never):Int;
    public var vertexTangentOffset(get_vertexTangentOffset, never):Int;

// TODO: Replace with CompactSubGeometry
    static private var _geometry:SubGeometry;
//private static var _pickingSubMesh:SubGeometry;
    private var _material:MaterialBase;
    private var _spriteMatrix:Matrix3D;
    private var _animator:IAnimator;
    private var _pickingSubMesh:SubMesh;
    private var _pickingTransform:Matrix3D;
    private var _camera:Camera3D;
    private var _width:Float;
    private var _height:Float;
    private var _shadowCaster:Bool;

    public function new(material:MaterialBase, width:Float, height:Float) {
        _shadowCaster = false;
        super();
        this.material = material;
        _width = width;
        _height = height;
        _spriteMatrix = new Matrix3D();
        if (_geometry == null) {
            _geometry = new SubGeometry();
            _geometry.updateVertexData(Vector.ofArray(cast [-.5, .5, .0, .5, .5, .0, .5, -.5, .0, -.5, -.5, .0]));
            _geometry.updateUVData(Vector.ofArray(cast [.0, .0, 1.0, .0, 1.0, 1.0, .0, 1.0]));
            _geometry.updateIndexData(Vector.ofArray(cast [0, 1, 2, 0, 2, 3]));
            _geometry.updateVertexTangentData(Vector.ofArray(cast [1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0]));
            _geometry.updateVertexNormalData(Vector.ofArray(cast [.0, .0, -1.0, .0, .0, -1.0, .0, .0, -1.0, .0, .0, -1.0]));
        }
    }

    override public function set_pickingCollider(value:IPickingCollider):IPickingCollider {
        super.pickingCollider = value;
        if (value != null) {
// bounds collider is the only null value
            _pickingSubMesh = new SubMesh(_geometry, null);
            _pickingTransform = new Matrix3D();
        }
        return value;
    }

    public function get_width():Float {
        return _width;
    }

    public function set_width(value:Float):Float {
        if (_width == value) return value;
        _width = value;
        invalidateTransform();
        return value;
    }

    public function get_height():Float {
        return _height;
    }

    public function set_height(value:Float):Float {
        if (_height == value) return value;
        _height = value;
        invalidateTransform();
        return value;
    }

    public function activateVertexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
        _geometry.activateVertexBuffer(index, stage3DProxy);
    }

    public function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
        _geometry.activateUVBuffer(index, stage3DProxy);
    }

    public function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
        _geometry.activateSecondaryUVBuffer(index, stage3DProxy);
    }

    public function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
        _geometry.activateVertexNormalBuffer(index, stage3DProxy);
    }

    public function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
        _geometry.activateVertexTangentBuffer(index, stage3DProxy);
    }

    public function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D {
        return _geometry.getIndexBuffer(stage3DProxy);
    }

    public function get_numTriangles():Int {
        return 2;
    }

    public function get_sourceEntity():Entity {
        return this;
    }

    public function get_material():MaterialBase {
        return _material;
    }

    public function set_material(value:MaterialBase):MaterialBase {
        if (value == _material) return value;
        if (_material != null) _material.removeOwner(this);
        _material = value;
        if (_material != null) _material.addOwner(this);
        return value;
    }

/**
	 * Defines the animator of the mesh. Act on the mesh's geometry. Defaults to null
	 */

    public function get_animator():IAnimator {
        return _animator;
    }

    public function get_castsShadows():Bool {
        return _shadowCaster;
    }

    override private function getDefaultBoundingVolume():BoundingVolumeBase {
        return new AxisAlignedBoundingBox();
    }

    override private function updateBounds():Void {
        _bounds.fromExtremes(-.5 * _scaleX, -.5 * _scaleY, -.5 * _scaleZ, .5 * _scaleX, .5 * _scaleY, .5 * _scaleZ);
        _boundsInvalid = false;
    }

    override private function createEntityPartitionNode():EntityNode {
        return new RenderableNode(this);
    }

    override private function updateTransform():Void {
        super.updateTransform();
        _transform.prependScale(_width, _height, Math.max(_width, _height));
    }

    public function get_uvTransform():Matrix {
        return null;
    }

    public function get_vertexData():Vector<Float> {
        return _geometry.vertexData;
    }

    public function get_indexData():Vector<UInt> {
        return _geometry.indexData;
    }

    public function get_UVData():Vector<Float> {
        return _geometry.UVData;
    }

    public function get_numVertices():Int {
        return _geometry.numVertices;
    }

    public function get_vertexStride():Int {
        return _geometry.vertexStride;
    }

    public function get_vertexNormalData():Vector<Float> {
        return _geometry.vertexNormalData;
    }

    public function get_vertexTangentData():Vector<Float> {
        return _geometry.vertexTangentData;
    }

    public function get_vertexOffset():Int {
        return _geometry.vertexOffset;
    }

    public function get_vertexNormalOffset():Int {
        return _geometry.vertexNormalOffset;
    }

    public function get_vertexTangentOffset():Int {
        return _geometry.vertexTangentOffset;
    }

    override public function collidesBefore(shortestCollisionDistance:Float, findClosest:Bool):Bool {

        var viewTransform:Matrix3D = _camera.inverseSceneTransform.clone();
        viewTransform.transpose();
        var rawViewTransform:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
        viewTransform.copyRawDataTo(rawViewTransform);
        rawViewTransform[3] = 0;
        rawViewTransform[7] = 0;
        rawViewTransform[11] = 0;
        rawViewTransform[12] = 0;
        rawViewTransform[13] = 0;
        rawViewTransform[14] = 0;
        _pickingTransform.copyRawDataFrom(rawViewTransform);
        _pickingTransform.prependScale(_width, _height, Math.max(_width, _height));
        _pickingTransform.appendTranslation(scenePosition.x, scenePosition.y, scenePosition.z);
        _pickingTransform.invert();
        var localRayPosition:Vector3D = _pickingTransform.transformVector(_pickingCollisionVO.rayPosition);
        var localRayDirection:Vector3D = _pickingTransform.deltaTransformVector(_pickingCollisionVO.rayDirection);
        _pickingCollider.setLocalRay(localRayPosition, localRayDirection);
        _pickingCollisionVO.renderable = null;
        if (_pickingCollider.testSubMeshCollision(_pickingSubMesh, _pickingCollisionVO, shortestCollisionDistance)) _pickingCollisionVO.renderable = _pickingSubMesh;
        return _pickingCollisionVO.renderable != null;
    }

    public function getRenderSceneTransform(camera:Camera3D):Matrix3D {
        var comps:Vector<Vector3D> = camera.sceneTransform.decompose();
        var scale:Vector3D = comps[2];
        comps[0] = scenePosition;
        scale.x = _width * _scaleX;
        scale.y = _height * _scaleY;
        _spriteMatrix.recompose(comps);
        return _spriteMatrix;
    }

}

