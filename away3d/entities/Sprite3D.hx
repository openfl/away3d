package away3d.entities;

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

import openfl.display3D.IndexBuffer3D;
import openfl.geom.Matrix;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * Sprite3D is a 3D billboard, a renderable rectangular area that is always aligned with the projection plane.
 * As a result, no perspective transformation occurs on a Sprite3D object.
 *
 * todo: mvp generation or vertex shader code can be optimized
 */
class Sprite3D extends Entity implements IRenderable
{
	public var width(get, set):Float;
	public var height(get, set):Float;
	public var numTriangles(get, never):Int;
	public var sourceEntity(get, never):Entity;
	public var material(get, set):MaterialBase;
	public var animator(get, never):IAnimator;
	public var castsShadows(get, never):Bool;
	public var uvTransform(get, never):Matrix;
	public var uvTransform2(get, never):Matrix;
	public var vertexData(get, never):Vector<Float>;
	public var indexData(get, never):Vector<UInt>;
	public var UVData(get, never):Vector<Float>;
	public var numVertices(get, never):Int;
	public var vertexStride(get, never):Int;
	public var vertexNormalData(get, never):Vector<Float>;
	public var vertexTangentData(get, never):Vector<Float>;
	public var vertexOffset(get, never):Int;
	public var vertexNormalOffset(get, never):Int;
	public var vertexTangentOffset(get, never):Int;

	/**
	 * Whether to share geometry, if the geometry is not shared, the UVData can be modified dynamically
	 */
	public var shareGeometry:Bool = true;

	// TODO: Replace with CompactSubGeometry
	private var ___geometry:SubGeometry;
	private static var __geometry:SubGeometry;
	private var _geometry(get,set):SubGeometry;
	private function get__geometry():SubGeometry{
		return shareGeometry?__geometry:___geometry;
	}
	private function set__geometry(g:SubGeometry):SubGeometry{
		if(shareGeometry){
			__geometry = g;
			return __geometry;
		}
		___geometry = g;
		return ___geometry;
	}
	//private static var _pickingSubMesh:SubGeometry;
	
	private var _material:MaterialBase;
	private var _spriteMatrix:Matrix3D;
	private var _animator:IAnimator;
	
	private var _pickingSubMesh:SubMesh;
	private var _pickingTransform:Matrix3D;
	private var _camera:Camera3D;
	
	private var _width:Float;
	private var _height:Float;
	private var _shadowCaster:Bool = false;
	
	public function new(material:MaterialBase, width:Float, height:Float,shareGeometry:Bool = true)
	{
		super();
		this.shareGeometry = shareGeometry;
		this.material = material;
		_width = width;
		_height = height;
		_spriteMatrix = new Matrix3D();
		if (_geometry == null) {
			_geometry = new SubGeometry();
			_geometry.updateVertexData(Vector.ofArray([-.5, .5, .0, .5, .5, .0, .5, -.5, .0, -.5, -.5, .0]));
			_geometry.updateUVData(Vector.ofArray([ .0, .0, 1.0, .0, 1.0, 1.0, .0, 1.0]));
			_geometry.updateIndexData(Vector.ofArray([ 0, 1, 2, 0, 2, 3]));
			_geometry.updateVertexTangentData(Vector.ofArray([ 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0]));
			_geometry.updateVertexNormalData(Vector.ofArray([ .0, .0, -1.0, .0, .0, -1.0, .0, .0, -1.0, .0, .0, -1.0]));
		}
	}
	
	override private function set_pickingCollider(value:IPickingCollider):IPickingCollider
	{
		super.pickingCollider = value;
		if (value != null) { // bounds collider is the only null value
			_pickingSubMesh = new SubMesh(_geometry, null);
			_pickingTransform = new Matrix3D();
		}
		return value;
	}
	
	private function get_width():Float
	{
		return _width;
	}
	
	private function set_width(value:Float):Float
	{
		if (_width == value)
			return value;
		_width = value;
		invalidateTransform();
		return value;
	}
	
	private function get_height():Float
	{
		return _height;
	}
	
	private function set_height(value:Float):Float
	{
		if (_height == value)
			return value;
		_height = value;
		invalidateTransform();
		return value;
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
	
	private function get_numTriangles():Int
	{
		return 2;
	}
	
	private function get_sourceEntity():Entity
	{
		return this;
	}
	
	private function get_material():MaterialBase
	{
		return _material;
	}
	
	private function set_material(value:MaterialBase):MaterialBase
	{
		if (value == _material)
			return value;
		if (_material != null)
			_material.removeOwner(this);
		_material = value;
		if (_material != null)
			_material.addOwner(this);
		return value;
	}
	
	/**
	 * Defines the animator of the mesh. Act on the mesh's geometry. Defaults to null
	 */
	private function get_animator():IAnimator
	{
		return _animator;
	}
	
	private function get_castsShadows():Bool
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
	
	private function get_uvTransform():Matrix
	{
		return null;
	}
	
	private function get_uvTransform2():Matrix
	{
		return null;
	}
	
	private function get_vertexData():Vector<Float>
	{
		return _geometry.vertexData;
	}
	
	private function get_indexData():Vector<UInt>
	{
		return _geometry.indexData;
	}
	
	private function get_UVData():Vector<Float>
	{
		return _geometry.UVData;
	}
	
	private function get_numVertices():Int
	{
		return _geometry.numVertices;
	}
	
	private function get_vertexStride():Int
	{
		return _geometry.vertexStride;
	}
	
	private function get_vertexNormalData():Vector<Float>
	{
		return _geometry.vertexNormalData;
	}
	
	private function get_vertexTangentData():Vector<Float>
	{
		return _geometry.vertexTangentData;
	}
	
	private function get_vertexOffset():Int
	{
		return _geometry.vertexOffset;
	}
	
	private function get_vertexNormalOffset():Int
	{
		return _geometry.vertexNormalOffset;
	}
	
	private function get_vertexTangentOffset():Int
	{
		return _geometry.vertexTangentOffset;
	}
	
	@:allow(away3d) override private function collidesBefore(shortestCollisionDistance:Float, findClosest:Bool):Bool
	{
		var viewTransform:Matrix3D = _camera.inverseSceneTransform.clone();
		viewTransform.transpose();
		var rawViewTransform:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
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
		var comps:Vector<Vector3D> = Matrix3DUtils.decompose(camera.sceneTransform);
		var scale:Vector3D = comps[2];
		comps[0].x = scenePosition.x;
		comps[0].y = scenePosition.y;
		comps[0].z = scenePosition.z;
		scale.x = _width*_scaleX;
		scale.y = _height*_scaleY;
		_spriteMatrix.recompose(comps);
		return _spriteMatrix;
	}
}