package away3d.entities;

	import away3d.animators.IAnimator;
	//import away3d.arcane;
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
	import away3d.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	//use namespace arcane;
	
	/**
	 * Sprite3D is a 3D billboard, a renderable rectangular area that is always aligned with the projection plane.
	 * As a result, no perspective transformation occurs on a Sprite3D object.
	 *
	 * todo: mvp generation or vertex shader code can be optimized
	 */
	class Sprite3D extends Entity implements IRenderable
	{
		// TODO: Replace with CompactSubGeometry
		private static var _geometry:SubGeometry;
		//private static var _pickingSubMesh:SubGeometry;
		
		var _material:MaterialBase;
		var _spriteMatrix:Matrix3D;
		var _animator:IAnimator;
		
		var _pickingSubMesh:SubMesh;
		var _pickingTransform:Matrix3D;
		var _camera:Camera3D;
		
		var _width:Float;
		var _height:Float;
		var _shadowCaster:Bool = false;
		
		public function new(material:MaterialBase, width:Float, height:Float)
		{
			super();
			this.material = material;
			_width = width;
			_height = height;
			_spriteMatrix = new Matrix3D();
			if (!_geometry) {
				_geometry = new SubGeometry();
				_geometry.updateVertexData(Array<Float>([-.5, .5, .0, .5, .5, .0, .5, -.5, .0, -.5, -.5, .0]));
				_geometry.updateUVData(Array<Float>([.0, .0, 1.0, .0, 1.0, 1.0, .0, 1.0]));
				_geometry.updateIndexData(Array<UInt>([0, 1, 2, 0, 2, 3]));
				_geometry.updateVertexTangentData(Array<Float>([1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0]));
				_geometry.updateVertexNormalData(Array<Float>([.0, .0, -1.0, .0, .0, -1.0, .0, .0, -1.0, .0, .0, -1.0]));
			}
		}
		
		public var pickingCollider(null, set) : Void;
		
		override public function set_pickingCollider(value:IPickingCollider) : Void
		{
			super.pickingCollider = value;
			if (value) { // bounds collider is the only null value
				_pickingSubMesh = new SubMesh(_geometry, null);
				_pickingTransform = new Matrix3D();
			}
		}
		
		public var width(get, set) : Float;
		
		public function get_width() : Float
		{
			return _width;
		}
		
		public function set_width(value:Float) : Float
		{
			if (_width == value)
				return;
			_width = value;
			invalidateTransform();
		}
		
		public var height(get, set) : Float;
		
		public function get_height() : Float
		{
			return _height;
		}
		
		public function set_height(value:Float) : Float
		{
			if (_height == value)
				return;
			_height = value;
			invalidateTransform();
		}
		
		public function activateVertexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
			_geometry.activateVertexBuffer(index, stage3DProxy);
		}
		
		public function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
			_geometry.activateUVBuffer(index, stage3DProxy);
		}
		
		public function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
			_geometry.activateSecondaryUVBuffer(index, stage3DProxy);
		}
		
		public function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
			_geometry.activateVertexNormalBuffer(index, stage3DProxy);
		}
		
		public function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
			_geometry.activateVertexTangentBuffer(index, stage3DProxy);
		}
		
		public function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D
		{
			return _geometry.getIndexBuffer(stage3DProxy);
		}
		
		public var numTriangles(get, null) : UInt;
		
		public function get_numTriangles() : UInt
		{
			return 2;
		}
		
		public var sourceEntity(get, null) : Entity;
		
		public function get_sourceEntity() : Entity
		{
			return this;
		}
		
		public var material(get, set) : MaterialBase;
		
		public function get_material() : MaterialBase
		{
			return _material;
		}
		
		public function set_material(value:MaterialBase) : MaterialBase
		{
			if (value == _material)
				return;
			if (_material)
				_material.removeOwner(this);
			_material = value;
			if (_material)
				_material.addOwner(this);
		}
		
		/**
		 * Defines the animator of the mesh. Act on the mesh's geometry. Defaults to null
		 */
		public var animator(get, null) : IAnimator;
		public function get_animator() : IAnimator
		{
			return _animator;
		}
		
		public var castsShadows(get, null) : Bool;
		
		public function get_castsShadows() : Bool
		{
			return _shadowCaster;
		}
		
		override private function getDefaultBoundingVolume():BoundingVolumeBase
		{
			return new AxisAlignedBoundingBox();
		}
		
		override private function updateBounds():Void
		{
			_bounds.fromExtremes(-.5*_scaleX, -.5*_scaleY, -.5*_scaleZ, .5*_scaleX, .5*_scaleY, .5*_scaleZ);
			_boundsInvalid = false;
		}
		
		override private function createEntityPartitionNode():EntityNode
		{
			return new RenderableNode(this);
		}
		
		override private function updateTransform():Void
		{
			super.updateTransform();
			_transform.prependScale(_width, _height, Math.max(_width, _height));
		}
		
		public var uvTransform(get, null) : Matrix;
		public function get_uvTransform() : Matrix
		{
			return null;
		}
		
		public var vertexData(get, null) : Array<Float>;		
		public function get_vertexData() : Array<Float>
		{
			return _geometry.vertexData;
		}
		
		public var indexData(get, null) : Array<UInt>;		
		public function get_indexData() : Array<UInt>
		{
			return _geometry.indexData;
		}
		
		public var UVData(get, null) : Array<Float>;		
		public function get_UVData() : Array<Float>
		{
			return _geometry.UVData;
		}
		
		public var numVertices(get, null) : UInt;
		public function get_numVertices() : UInt
		{
			return _geometry.numVertices;
		}
		
		public var vertexStride(get, null) : UInt;		
		public function get_vertexStride() : UInt
		{
			return _geometry.vertexStride;
		}
		
		public var vertexNormalData(get, null) : Array<Float>;		
		public function get_vertexNormalData() : Array<Float>
		{
			return _geometry.vertexNormalData;
		}
		
		public var vertexTangentData(get, null) : Array<Float>;
		public function get_vertexTangentData() : Array<Float>
		{
			return _geometry.vertexTangentData;
		}
		
		public var vertexOffset(get, null) : Int;		
		public function get_vertexOffset() : Int
		{
			return _geometry.vertexOffset;
		}
		
		public var vertexNormalOffset(get, null) : Int;		
		public function get_vertexNormalOffset() : Int
		{
			return _geometry.vertexNormalOffset;
		}
		
		public var vertexTangentOffset(get, null) : Int;		
		public function get_vertexTangentOffset() : Int
		{
			return _geometry.vertexTangentOffset;
		}
		
		override public function collidesBefore(shortestCollisionDistance:Float, findClosest:Bool):Bool
		{
			findClosest = findClosest;
			var viewTransform:Matrix3D = _camera.inverseSceneTransform.clone();
			viewTransform.transpose();
			var rawViewTransform:Array<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
			viewTransform.copyRawDataTo(rawViewTransform);
			rawViewTransform[ 3  ] = 0;
			rawViewTransform[ 7  ] = 0;
			rawViewTransform[ 11 ] = 0;
			rawViewTransform[ 12 ] = 0;
			rawViewTransform[ 13 ] = 0;
			rawViewTransform[ 14 ] = 0;
			
			_pickingTransform.copyRawDataFrom(rawViewTransform);
			_pickingTransform.prependScale(_width, _height, Math.max(_width, _height));
			_pickingTransform.appendTranslation(scenePosition.x, scenePosition.y, scenePosition.z);
			_pickingTransform.invert();
			
			var localRayPosition:Vector3D = _pickingTransform.transformVector(_pickingCollisionVO.rayPosition);
			var localRayDirection:Vector3D = _pickingTransform.deltaTransformVector(_pickingCollisionVO.rayDirection);
			
			_pickingCollider.setLocalRay(localRayPosition, localRayDirection);
			
			_pickingCollisionVO.renderable = null;
			if (_pickingCollider.testSubMeshCollision(_pickingSubMesh, _pickingCollisionVO, shortestCollisionDistance))
				_pickingCollisionVO.renderable = _pickingSubMesh;
			
			return _pickingCollisionVO.renderable != null;
		}
		
		public function getRenderSceneTransform(camera:Camera3D):Matrix3D
		{
			var comps:Array<Vector3D> = camera.sceneTransform.decompose();
			var scale:Vector3D = comps[2];
			comps[0] = scenePosition;
			scale.x = _width*_scaleX;
			scale.y = _height*_scaleY;
			_spriteMatrix.recompose(comps);
			return _spriteMatrix;
		}
	}

