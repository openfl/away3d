package away3d.core.base;

import away3d.cameras.Camera3D;
import away3d.core.managers.Stage3DProxy;
import away3d.entities.Entity;

import openfl.display3D.IndexBuffer3D;
import openfl.geom.Matrix;
import openfl.geom.Matrix3D;
import openfl.Vector;

/**
 * IRenderable provides an interface for objects that can be rendered in the rendering pipeline.
 */
interface IRenderable extends IMaterialOwner
{
	/**
	 * The transformation matrix that transforms from model to world space.
	 */
	var sceneTransform(get, never):Matrix3D;
	
	/**
	 * The transformation matrix that transforms from model to world space, adapted with any special operations needed to render.
	 * For example, assuring certain alignedness which is not inherent in the scene transform. By default, this would
	 * return the scene transform.
	 */
	function getRenderSceneTransform(camera:Camera3D):Matrix3D;
	
	/**
	 * The inverse scene transform object that transforms from world to model space.
	 */
	var inverseSceneTransform(get, never):Matrix3D;
	
	/**
	 * Indicates whether the IRenderable should trigger mouse events, and hence should be rendered for hit testing.
	 */
	var mouseEnabled(get, never):Bool;
	
	/**
	 * The entity that that initially provided the IRenderable to the render pipeline.
	 */
	var sourceEntity(get, never):Entity;
	
	/**
	 * Indicates whether the renderable can cast shadows
	 */
	var castsShadows(get, never):Bool;

	/**
	 * Provides a Matrix object to transform the uv coordinates, if the material supports it.
	 * For TextureMaterial and TextureMultiPassMaterial, the animateUVs property should be set to true.
	 */
	var uvTransform(get, never):Matrix;
	var uvTransform2(get, never):Matrix;
	
	var shaderPickingDetails(get, never):Bool;
	
	/**
	 * The total amount of vertices in the SubGeometry.
	 */
	var numVertices(get, never):Int;
	
	/**
	 * The amount of triangles that comprise the IRenderable geometry.
	 */
	var numTriangles(get, never):Int;
	
	/**
	 * The number of data elements in the buffers per vertex.
	 * This always applies to vertices, normals and tangents.
	 */
	var vertexStride(get, never):Int;
	
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
	var vertexData(get, never):Vector<Float>;
	
	/**
	 * Retrieves the object's normals as a Number array.
	 */
	var vertexNormalData(get, never):Vector<Float>;
	
	/**
	 * Retrieves the object's tangents as a Number array.
	 */
	var vertexTangentData(get, never):Vector<Float>;
	
	/**
	 * Retrieves the object's indices as a UInt array.
	 */
	var indexData(get, never):Vector<UInt>;
	
	/**
	 * Retrieves the object's uvs as a Number array.
	 */
	var UVData(get, never):Vector<Float>;
}