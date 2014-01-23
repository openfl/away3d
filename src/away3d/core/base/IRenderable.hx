/**
 * IRenderable provides an interface for objects that can be rendered in the rendering pipeline.
 */
package away3d.core.base;

import flash.Vector;
import away3d.cameras.Camera3D;
import away3d.core.managers.Stage3DProxy;
import away3d.entities.Entity;
import flash.display3D.IndexBuffer3D;
import flash.geom.Matrix;
import flash.geom.Matrix3D;

interface IRenderable extends IMaterialOwner {
    var sceneTransform(get_sceneTransform, never):Matrix3D;
    var inverseSceneTransform(get_inverseSceneTransform, never):Matrix3D;
    var mouseEnabled(get_mouseEnabled, never):Bool;
    var sourceEntity(get_sourceEntity, never):Entity;
    var castsShadows(get_castsShadows, never):Bool;
    var uvTransform(get_uvTransform, never):Matrix;
    var shaderPickingDetails(get_shaderPickingDetails, never):Bool;
    var numVertices(get_numVertices, never):Int;
    var numTriangles(get_numTriangles, never):Int;
    var vertexStride(get_vertexStride, never):Int;
    var vertexData(get_vertexData, never):Vector<Float>;
    var vertexNormalData(get_vertexNormalData, never):Vector<Float>;
    var vertexTangentData(get_vertexTangentData, never):Vector<Float>;
    var indexData(get_indexData, never):Vector<UInt>;
    var UVData(get_UVData, never):Vector<Float>;

/**
	 * The transformation matrix that transforms from model to world space.
	 */
    function get_sceneTransform():Matrix3D;
/**
	 * The transformation matrix that transforms from model to world space, adapted with any special operations needed to render.
	 * For example, assuring certain alignedness which is not inherent in the scene transform. By default, this would
	 * return the scene transform.
	 */
    function getRenderSceneTransform(camera:Camera3D):Matrix3D;
/**
	 * The inverse scene transform object that transforms from world to model space.
	 */
    function get_inverseSceneTransform():Matrix3D;
/**
	 * Indicates whether the IRenderable should trigger mouse events, and hence should be rendered for hit testing.
	 */
    function get_mouseEnabled():Bool;
/**
	 * The entity that that initially provided the IRenderable to the render pipeline.
	 */
    function get_sourceEntity():Entity;
/**
	 * Indicates whether the renderable can cast shadows
	 */
    function get_castsShadows():Bool;
/**
	 * Provides a Matrix object to transform the uv coordinates, if the material supports it.
	 * For TextureMaterial and TextureMultiPassMaterial, the animateUVs property should be set to true.
	 */
    function get_uvTransform():Matrix;
    function get_shaderPickingDetails():Bool;
/**
	 * The total amount of vertices in the SubGeometry.
	 */
    function get_numVertices():Int;
/**
	 * The amount of triangles that comprise the IRenderable geometry.
	 */
    function get_numTriangles():Int;
/**
	 * The number of data elements in the buffers per vertex.
	 * This always applies to vertices, normals and tangents.
	 */
    function get_vertexStride():Int;
/**
	 * Assigns the attribute stream for vertex positions.
	 * @param index The attribute stream index for the vertex shader
	 * @param stage3DProxy The Stage3DProxy to assign the stream to
	 */
    function activateVertexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void;
/**
	 * Assigns the attribute stream for UV coordinates
	 * @param index The attribute stream index for the vertex shader
	 * @param stage3DProxy The Stage3DProxy to assign the stream to
	 */
    function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void;
/**
	 * Assigns the attribute stream for a secondary set of UV coordinates
	 * @param index The attribute stream index for the vertex shader
	 * @param stage3DProxy The Stage3DProxy to assign the stream to
	 */
    function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void;
/**
	 * Assigns the attribute stream for vertex normals
	 * @param index The attribute stream index for the vertex shader
	 * @param stage3DProxy The Stage3DProxy to assign the stream to
	 */
    function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void;
/**
	 * Assigns the attribute stream for vertex tangents
	 * @param index The attribute stream index for the vertex shader
	 * @param stage3DProxy The Stage3DProxy to assign the stream to
	 */
    function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void;
/**
	 * Retrieves the IndexBuffer3D object that contains triangle indices.
	 * @param context The Context3D for which we request the buffer
	 * @return The VertexBuffer3D object that contains triangle indices.
	 */
    function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D;
/**
	 * Retrieves the object's vertices as a Number array.
	 */
    function get_vertexData():Vector<Float>;
/**
	 * Retrieves the object's normals as a Number array.
	 */
    function get_vertexNormalData():Vector<Float>;
/**
	 * Retrieves the object's tangents as a Number array.
	 */
    function get_vertexTangentData():Vector<Float>;
/**
	 * Retrieves the object's indices as a uint array.
	 */
    function get_indexData():Vector<UInt>;
/**
	 * Retrieves the object's uvs as a Number array.
	 */
    function get_UVData():Vector<Float>;
}

