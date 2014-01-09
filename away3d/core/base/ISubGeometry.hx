package away3d.core.base;

	import away3d.core.managers.Stage3DProxy;
	
	import flash.display3D.IndexBuffer3D;
	import away3d.geom.Matrix3D;
	
	interface ISubGeometry
	{
		/**
		 * The total amount of vertices in the SubGeometry.
		 */
		var numVertices(get, null):UInt;
		
		/**
		 * The amount of triangles that comprise the IRenderable geometry.
		 */
		var numTriangles(get, null):UInt;
		
		/**
		 * The distance between two consecutive vertex, normal or tangent elements
		 * This always applies to vertices, normals and tangents.
		 */
		var vertexStride(get, null):UInt;
		
		/**
		 * The distance between two consecutive normal elements
		 * This always applies to vertices, normals and tangents.
		 */
		var vertexNormalStride(get, null):UInt;
		
		/**
		 * The distance between two consecutive tangent elements
		 * This always applies to vertices, normals and tangents.
		 */
		var vertexTangentStride(get, null):UInt;
		
		/**
		 * The distance between two consecutive UV elements
		 */
		var UVStride(get, null):UInt;
		
		/**
		 * The distance between two secondary UV elements
		 */
		var secondaryUVStride(get, null):UInt;
		
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
		var vertexData(get, null):Array<Float>;
		
		/**
		 * Retrieves the object's normals as a Number array.
		 */
		var vertexNormalData(get, null):Array<Float>;
		
		/**
		 * Retrieves the object's tangents as a Number array.
		 */
		var vertexTangentData(get, null):Array<Float>;
		
		/**
		 * The offset into vertexData where the vertices are placed
		 */
		var vertexOffset(get, null):Int;
		
		/**
		 * The offset into vertexNormalData where the normals are placed
		 */
		var vertexNormalOffset(get, null):Int;
		
		/**
		 * The offset into vertexTangentData where the tangents are placed
		 */
		var vertexTangentOffset(get, null):Int;
		
		/**
		 * The offset into UVData vector where the UVs are placed
		 */
		var UVOffset(get, null):Int;
		
		/**
		 * The offset into SecondaryUVData vector where the UVs are placed
		 */
		var secondaryUVOffset(get, null):Int;
		
		/**
		 * Retrieves the object's indices as a uint array.
		 */
		var indexData(get, null):Array<UInt>;
		
		/**
		 * Retrieves the object's uvs as a Number array.
		 */
		var UVData(get, null):Array<Float>;
		
		function applyTransformation(transform:Matrix3D):Void;
		
		function scale(scale:Float):Void;
		
		function dispose():Void;
		
		function clone():ISubGeometry;
		
		var scaleU(get, null):Float;
		
		var scaleV(get, null):Float;
		
		function scaleUV(scaleU:Float = 1, scaleV:Float = 1):Void;
		
		var parentGeometry(get, set):Geometry;
		
		var faceNormals(get, null):Array<Float>;
		
		function cloneWithSeperateBuffers():SubGeometry;
		
		var autoDeriveVertexNormals(get, set):Bool;
		
		var autoDeriveVertexTangents(get, set):Bool;
		
		function fromVectors(vertices:Array<Float>, uvs:Array<Float>, normals:Array<Float>, tangents:Array<Float>):Void;
		
		var vertexPositionData(get, null):Array<Float>;
	}

