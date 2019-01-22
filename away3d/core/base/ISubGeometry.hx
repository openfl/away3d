package away3d.core.base;

import away3d.core.managers.Stage3DProxy;

import openfl.display3D.IndexBuffer3D;
import openfl.geom.Matrix3D;
import openfl.Vector;

interface ISubGeometry
{
	/**
	 * The total amount of vertices in the SubGeometry.
	 */
	var numVertices(get, never):Int;
	
	/**
	 * The amount of triangles that comprise the IRenderable geometry.
	 */
	var numTriangles(get, never):Int;
	
	/**
	 * The distance between two consecutive vertex, normal or tangent elements
	 * This always applies to vertices, normals and tangents.
	 */
	var vertexStride(get, never):Int;
	
	/**
	 * The distance between two consecutive normal elements
	 * This always applies to vertices, normals and tangents.
	 */
	var vertexNormalStride(get, never):Int;
	
	/**
	 * The distance between two consecutive tangent elements
	 * This always applies to vertices, normals and tangents.
	 */
	var vertexTangentStride(get, never):Int;
	
	/**
	 * The distance between two consecutive UV elements
	 */
	var UVStride(get, never):Int;
	
	/**
	 * The distance between two secondary UV elements
	 */
	var secondaryUVStride(get, never):Int;
	
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
	 * The offset into vertexData where the vertices are placed
	 */
	var vertexOffset(get, never):Int;
	
	/**
	 * The offset into vertexNormalData where the normals are placed
	 */
	var vertexNormalOffset(get, never):Int;
	
	/**
	 * The offset into vertexTangentData where the tangents are placed
	 */
	var vertexTangentOffset(get, never):Int;
	
	/**
	 * The offset into UVData vector where the UVs are placed
	 */
	var UVOffset(get, never):Int;
	
	/**
	 * The offset into SecondaryUVData vector where the UVs are placed
	 */
	var secondaryUVOffset(get, never):Int;
	
	/**
	 * Retrieves the object's indices as a uint array.
	 */
	@:allow(away3d) private var indexData(get, never):Vector<UInt>;
	
	/**
	 * Retrieves the object's uvs as a Number array.
	 */
	var UVData(get, never):Vector<Float>;
	
	function applyTransformation(transform:Matrix3D):Void;
	
	function scale(scale:Float):Void;
	
	function dispose():Void;
	
	function clone():ISubGeometry;
	
	var scaleU(get, never):Float;
	
	var scaleV(get, never):Float;
	
	function scaleUV(scaleU:Float = 1, scaleV:Float = 1):Void;
	
	@:allow(away3d) private var parentGeometry(get, set):Geometry;
	
	@:allow(away3d) private var faceNormals(get, never):Vector<Float>;
	
	function cloneWithSeperateBuffers():SubGeometry;
	
	var autoDeriveVertexNormals(get, set):Bool;
	
	var autoDeriveVertexTangents(get, set):Bool;
	
	function fromVectors(vertices:Vector<Float>, uvs:Vector<Float>, normals:Vector<Float>, tangents:Vector<Float>):Void;
	
	var vertexPositionData(get, never):Vector<Float>;
}