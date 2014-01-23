/**
 * A SkyBox class is used to render a sky in the scene. It's always considered static and 'at infinity', and as
 * such it's always centered at the camera's position and sized to exactly fit within the camera's frustum, ensuring
 * the sky box is always as large as possible without being clipped.
 */
package away3d.primitives;

import flash.Vector;
import away3d.animators.IAnimator;

import away3d.bounds.BoundingVolumeBase;
import away3d.bounds.NullBounds;
import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.base.SubGeometry;
import away3d.core.managers.Stage3DProxy;
import away3d.core.partition.EntityNode;
import away3d.core.partition.SkyBoxNode;
import away3d.entities.Entity;
import away3d.errors.AbstractMethodError;
import away3d.library.assets.AssetType;
import away3d.materials.MaterialBase;
import away3d.materials.SkyBoxMaterial;
import away3d.textures.CubeTextureBase;
import flash.display3D.IndexBuffer3D;
import flash.geom.Matrix;
import flash.geom.Matrix3D;

class SkyBox extends Entity implements IRenderable {
    public var animator(get_animator, never):IAnimator;
    public var numTriangles(get_numTriangles, never):Int;
    public var sourceEntity(get_sourceEntity, never):Entity;
    public var material(get_material, set_material):MaterialBase;
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

// todo: remove SubGeometry, use a simple single buffer with offsets
    private var _geometry:SubGeometry;
    private var _material:SkyBoxMaterial;
    private var _uvTransform:Matrix;
    private var _animator:IAnimator;

    public function get_animator():IAnimator {
        return _animator;
    }

    override private function getDefaultBoundingVolume():BoundingVolumeBase {
        return new NullBounds();
    }

/**
	 * Create a new SkyBox object.
	 * @param cubeMap The CubeMap to use for the sky box's texture.
	 */

    public function new(cubeMap:CubeTextureBase) {
        _uvTransform = new Matrix();
        super();
        _material = new SkyBoxMaterial(cubeMap);
        _material.addOwner(this);
        _geometry = new SubGeometry();
        buildGeometry(_geometry);
    }

/**
	 * @inheritDoc
	 */

    public function activateVertexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
        _geometry.activateVertexBuffer(index, stage3DProxy);
    }

/**
	 * @inheritDoc
	 */

    public function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
    }

/**
	 * @inheritDoc
	 */

    public function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
    }

/**
	 * @inheritDoc
	 */

    public function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
    }

    public function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void {
    }

/**
	 * @inheritDoc
	 */

    public function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D {
        return _geometry.getIndexBuffer(stage3DProxy);
    }

/**
	 * The amount of triangles that comprise the SkyBox geometry.
	 */

    public function get_numTriangles():Int {
        return _geometry.numTriangles;
    }

/**
	 * The entity that that initially provided the IRenderable to the render pipeline.
	 */

    public function get_sourceEntity():Entity {
        return null;
    }

/**
	 * The material with which to render the object.
	 */

    public function get_material():MaterialBase {
        return _material;
    }

    public function set_material(value:MaterialBase):MaterialBase {
        throw new AbstractMethodError("Unsupported method!");
        return value;
    }

    override public function get_assetType():String {
        return AssetType.SKYBOX;
    }

/**
	 * @inheritDoc
	 */

    override private function invalidateBounds():Void {
// dead end
    }

/**
	 * @inheritDoc
	 */

    override private function createEntityPartitionNode():EntityNode {
        return new SkyBoxNode(this);
    }

/**
	 * @inheritDoc
	 */

    override private function updateBounds():Void {
        _boundsInvalid = false;
    }

/**
	 * Builds the geometry that forms the SkyBox
	 */

    private function buildGeometry(target:SubGeometry):Void {

        var tmp:Array<Float> = [-1, 1, -1, 1, 1, -1, 1, 1, 1, -1, 1, 1, -1, -1, -1, 1, -1, -1, 1, -1, 1, -1, -1, 1];
        var vertices:Vector<Float> = Vector.ofArray(tmp);
        vertices.fixed = true;
        var indextmp:Array<UInt> = [0, 1, 2, 2, 3, 0, 6, 5, 4, 4, 7, 6, 2, 6, 7, 7, 3, 2, 4, 5, 1, 1, 0, 4, 4, 0, 3, 3, 7, 4, 2, 1, 5, 5, 6, 2];
        var indices:Vector<UInt> = Vector.ofArray(indextmp);
        target.updateVertexData(vertices);
        target.updateIndexData(indices);
    }

    public function get_castsShadows():Bool {
        return false;
    }

    public function get_uvTransform():Matrix {
        return _uvTransform;
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

    public function getRenderSceneTransform(camera:Camera3D):Matrix3D {
        return _sceneTransform;
    }

}

