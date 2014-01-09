package away3d.primitives;

	
	import away3d.animators.IAnimator;
	//import away3d.arcane;
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
	import away3d.geom.Matrix3D;
	
	//use namespace arcane;
	
	/**
	 * A SkyBox class is used to render a sky in the scene. It's always considered static and 'at infinity', and as
	 * such it's always centered at the camera's position and sized to exactly fit within the camera's frustum, ensuring
	 * the sky box is always as large as possible without being clipped.
	 */
	class SkyBox extends Entity implements IRenderable
	{
		// todo: remove SubGeometry, use a simple single buffer with offsets
		var _geometry:SubGeometry;
		var _material:SkyBoxMaterial;
		var _uvTransform:Matrix;
		var _animator:IAnimator;
		
		public var animator(get, null) : IAnimator;
		
		public function get_animator() : IAnimator
		{
			return _animator;
		}
		
		override private function getDefaultBoundingVolume():BoundingVolumeBase
		{
			return new NullBounds();
		}
		
		/**
		 * Create a new SkyBox object.
		 * @param cubeMap The CubeMap to use for the sky box's texture.
		 */
		public function new(cubeMap:CubeTextureBase)
		{
			super();
			_uvTransform = new Matrix();
			_material = new SkyBoxMaterial(cubeMap);
			_material.addOwner(this);
			_geometry = new SubGeometry();
			buildGeometry(_geometry);
		}
		
		/**
		 * @inheritDoc
		 */
		public function activateVertexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
			_geometry.activateVertexBuffer(index, stage3DProxy);
		}
		
		/**
		 * @inheritDoc
		 */
		public function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
		}
		
		public function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D
		{
			return _geometry.getIndexBuffer(stage3DProxy);
		}
		
		/**
		 * The amount of triangles that comprise the SkyBox geometry.
		 */
		public var numTriangles(get, null) : UInt;
		private function get_numTriangles() : UInt
		{
			return _geometry.numTriangles;
		}
		
		/**
		 * The entity that that initially provided the IRenderable to the render pipeline.
		 */
		public var sourceEntity(get, null) : Entity;
		private function get_sourceEntity() : Entity
		{
			return null;
		}
		
		/**
		 * The material with which to render the object.
		 */
		public var material(get, set) : MaterialBase;
		private function get_material() : MaterialBase
		{
			return _material;
		}
		
		private function set_material(value:MaterialBase) : MaterialBase
		{
			throw new AbstractMethodError("Unsupported method!");
			return value;
		}
		
		public override function get_assetType() : String
		{
			return AssetType.SKYBOX;
		}
		
		/**
		 * @inheritDoc
		 */
		override private function invalidateBounds():Void
		{
			// dead end
		}
		
		/**
		 * @inheritDoc
		 */
		override private function createEntityPartitionNode():EntityNode
		{
			return new SkyBoxNode(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override private function updateBounds():Void
		{
			_boundsInvalid = false;
		}
		
		/**
		 * Builds the geometry that forms the SkyBox
		 */
		private function buildGeometry(target:SubGeometry):Void
		{
			var vertices:Array<Float> = [
				-1, 1, -1, 1, 1, -1,
				1, 1, 1, -1, 1, 1,
				-1, -1, -1, 1, -1, -1,
				1, -1, 1, -1, -1, 1
				];
			
			var indices:Array<UInt> = [
				0, 1, 2, 2, 3, 0,
				6, 5, 4, 4, 7, 6,
				2, 6, 7, 7, 3, 2,
				4, 5, 1, 1, 0, 4,
				4, 0, 3, 3, 7, 4,
				2, 1, 5, 5, 6, 2
				];
			
			target.updateVertexData(vertices);
			target.updateIndexData(indices);
		}
		
		public var castsShadows(get, null) : Bool;
		private function get_castsShadows() : Bool
		{
			return false;
		}
		
		public var uvTransform(get, null) : Matrix;		
		private function get_uvTransform() : Matrix
		{
			return _uvTransform;
		}
		
		public var vertexData(get, null) : Array<Float>;
		private function get_vertexData() : Array<Float>
		{
			return _geometry.vertexData;
		}
		
		public var indexData(get, null) : Array<UInt>;
		private function get_indexData() : Array<UInt>
		{
			return _geometry.indexData;
		}
		
		public var UVData(get, null) : Array<Float>;
		private function get_UVData() : Array<Float>
		{
			return _geometry.UVData;
		}
		
		public var numVertices(get, null) : UInt;
		private function get_numVertices() : UInt
		{
			return _geometry.numVertices;
		}
		
		public var vertexStride(get, null) : UInt;
		private function get_vertexStride() : UInt
		{
			return _geometry.vertexStride;
		}
		
		public var vertexNormalData(get, null) : Array<Float>;
		private function get_vertexNormalData() : Array<Float>
		{
			return _geometry.vertexNormalData;
		}
		
		public var vertexTangentData(get, null) : Array<Float>;		
		private function get_vertexTangentData() : Array<Float>
		{
			return _geometry.vertexTangentData;
		}
		
		public var vertexOffset(get, null) : Int;		
		private function get_vertexOffset() : Int
		{
			return _geometry.vertexOffset;
		}
		
		public var vertexNormalOffset(get, null) : Int;		
		private function get_vertexNormalOffset() : Int
		{
			return _geometry.vertexNormalOffset;
		}
		
		public var vertexTangentOffset(get, null) : Int;		
		private function get_vertexTangentOffset() : Int
		{
			return _geometry.vertexTangentOffset;
		}
		
		public function getRenderSceneTransform(camera:Camera3D):Matrix3D
		{
			return _sceneTransform;
		}
	}

