package away3d.core.base;

	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.entities.Entity;
	
	import flash.display3D.IndexBuffer3D;
	import flash.geom.Matrix;
	import away3d.geom.Matrix3D;
	
	/**
	 * IRenderable provides an interface for objects that can be rendered in the rendering pipeline.
	 */
	interface IRenderable extends IMaterialOwner
	{
		/**
		 * The transformation matrix that transforms from model to world space.
		 */
		var sceneTransform(get, null):Matrix3D;
		
		/**
		 * The transformation matrix that transforms from model to world space, adapted with any special operations needed to render.
		 * For example, assuring certain alignedness which is not inherent in the scene transform. By default, this would
		 * return the scene transform.
		 */
		function getRenderSceneTransform(camera:Camera3D):Matrix3D;
		
		/**
		 * The inverse scene transform object that transforms from world to model space.
		 */
		var inverseSceneTransform(get, null):Matrix3D;
		
		/**
		 * Indicates whether the IRenderable should trigger mouse events, and hence should be rendered for hit testing.
		 */
		var mouseEnabled(get, null):Bool;
		
		/**
		 * The entity that that initially provided the IRenderable to the render pipeline.
		 */
		var sourceEntity(get, null):Entity;
		
		/**
		 * Indicates whether the renderable can cast shadows
		 */
		var castsShadows(get, null):Bool;

		/**
		 * Provides a Matrix object to transform the uv coordinates, if the material supports it.
		 * For TextureMaterial and TextureMultiPassMaterial, the animateUVs property should be set to true.
		 */
		var uvTransform(get, null):Matrix;
		
		var shaderPickingDetails(get, null):Bool;
		
		/**
		 * The total amount of vertices in the SubGeometry.
		 */
		var numVertices(get, null):UInt;
		
		/**
		 * The amount of triangles that comprise the IRenderable geometry.
		 */
		var numTriangles(get, null):UInt;
		
		/**
		 * The number of data elements in the buffers per vertex.
		 * This always applies to vertices, normals and tangents.
		 */
		var vertexStride(get, null):UInt;
		
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
		 * Retrieves the object's indices as a uint array.
		 */
		var indexData(get, null):Array<UInt>;
		
		/**
		 * Retrieves the object's uvs as a Number array.
		 */
		var UVData(get, null):Array<Float>;
	}

