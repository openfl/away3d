package away3d.core.base;

import away3d.core.managers.Stage3DProxy;
import openfl.display3D.IndexBuffer3D;
import openfl.geom.Matrix3D;
import openfl.Vector;

interface ISubGeometry {
    var numVertices(get, never):Int;
    var numTriangles(get, never):Int;
    var vertexStride(get, never):Int;
    var vertexNormalStride(get, never):Int;
    var vertexTangentStride(get, never):Int;
    var UVStride(get, never):Int;
    var secondaryUVStride(get, never):Int;
    var vertexData(get, never):Vector<Float>;
    var vertexNormalData(get, never):Vector<Float>;
    var vertexTangentData(get, never):Vector<Float>;
    var vertexOffset(get, never):Int;
    var vertexNormalOffset(get, never):Int;
    var vertexTangentOffset(get, never):Int;
    var UVOffset(get, never):Int;
    var secondaryUVOffset(get, never):Int;
    var indexData(get, never):Vector<UInt>;
    var UVData(get, never):Vector<Float>;
    var scaleU(get, never):Float;
    var scaleV(get, never):Float;
    var parentGeometry(get, set):Geometry;
    var faceNormals(get, never):Vector<Float>;
    var autoDeriveVertexNormals(get, set):Bool;
    var autoDeriveVertexTangents(get, set):Bool;
    var vertexPositionData(get, never):Vector<Float>;

    /**
	 * The total amount of vertices in the SubGeometry.
	 */
    private function get_numVertices():Int;

    /**
	 * The amount of triangles that comprise the IRenderable geometry.
	 */
    private function get_numTriangles():Int;

    /**
	 * The distance between two consecutive vertex, normal or tangent elements
	 * This always applies to vertices, normals and tangents.
	 */
    private function get_vertexStride():Int;

    /**
	 * The distance between two consecutive normal elements
	 * This always applies to vertices, normals and tangents.
	 */
    private function get_vertexNormalStride():Int;

    /**
	 * The distance between two consecutive tangent elements
	 * This always applies to vertices, normals and tangents.
	 */
    private function get_vertexTangentStride():Int;

    /**
	 * The distance between two consecutive UV elements
	 */
    private function get_UVStride():Int;

    /**
	 * The distance between two secondary UV elements
	 */
    private function get_secondaryUVStride():Int;
    
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
    private function get_vertexData():Vector<Float>;

    /**
	 * Retrieves the object's normals as a Number array.
	 */
    private function get_vertexNormalData():Vector<Float>;

    /**
	 * Retrieves the object's tangents as a Number array.
	 */
    private function get_vertexTangentData():Vector<Float>;

    /**
	 * The offset into vertexData where the vertices are placed
	 */
    private function get_vertexOffset():Int;

    /**
	 * The offset into vertexNormalData where the normals are placed
	 */
    private function get_vertexNormalOffset():Int;

    /**
	 * The offset into vertexTangentData where the tangents are placed
	 */
    private function get_vertexTangentOffset():Int;

    /**
	 * The offset into UVData vector where the UVs are placed
	 */
    private function get_UVOffset():Int;

    /**
	 * The offset into SecondaryUVData vector where the UVs are placed
	 */
    private function get_secondaryUVOffset():Int;
    
    /**
	 * Retrieves the object's indices as a uint array.
	 */
    private function get_indexData():Vector<UInt>;

    /**
	 * Retrieves the object's uvs as a Number array.
	 */
    private function get_UVData():Vector<Float>;
    function applyTransformation(transform:Matrix3D):Void;
    function scale(scale:Float):Void;
    function dispose():Void;
    function clone():ISubGeometry;
    private function get_scaleU():Float;
    private function get_scaleV():Float;
    function scaleUV(scaleU:Float = 1, scaleV:Float = 1):Void;
    private function get_parentGeometry():Geometry;
    private function set_parentGeometry(value:Geometry):Geometry;
    private function get_faceNormals():Vector<Float>;
    function cloneWithSeperateBuffers():SubGeometry;
    private function get_autoDeriveVertexNormals():Bool;
    private function set_autoDeriveVertexNormals(value:Bool):Bool;
    private function get_autoDeriveVertexTangents():Bool;
    private function set_autoDeriveVertexTangents(value:Bool):Bool;
    function fromVectors(vertices:Vector<Float>, uvs:Vector<Float>, normals:Vector<Float>, tangents:Vector<Float>):Void;
    private function get_vertexPositionData():Vector<Float>;
}

