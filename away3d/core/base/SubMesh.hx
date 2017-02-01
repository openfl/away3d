package away3d.core.base;

import away3d.animators.IAnimator;
import away3d.animators.data.AnimationSubGeometry;
import away3d.bounds.BoundingVolumeBase;
import away3d.cameras.Camera3D;
import away3d.core.managers.Stage3DProxy;
import away3d.entities.Entity;
import away3d.entities.Mesh;
import away3d.materials.MaterialBase;

import openfl.display3D.IndexBuffer3D;
import openfl.geom.Matrix;
import openfl.geom.Matrix3D;
import openfl.Vector;

/**
 * SubMesh wraps a SubGeometry as a scene graph instantiation. A SubMesh is owned by a Mesh object.
 *
 * @see away3d.core.base.SubGeometry
 * @see away3d.scenegraph.Mesh
 */
class SubMesh implements IRenderable
{
	public var shaderPickingDetails(get, never):Bool;
	
	public var offsetU(get, set):Float;
	public var offsetV(get, set):Float;
	public var scaleU(get, set):Float;
	public var scaleV(get, set):Float;
	public var uvRotation(get, set):Float;
	
	public var offsetU2(get, set):Float;
	public var offsetV2(get, set):Float;
	public var scaleU2(get, set):Float;
	public var scaleV2(get, set):Float;
	public var uvRotation2(get, set):Float;
	
	public var sourceEntity(get, never):Entity;
	public var subGeometry(get, set):ISubGeometry;
	public var material(get, set):MaterialBase;
	public var sceneTransform(get, never):Matrix3D;
	public var inverseSceneTransform(get, never):Matrix3D;
	public var numTriangles(get, never):Int;
	public var animator(get, never):IAnimator;
	public var mouseEnabled(get, never):Bool;
	public var castsShadows(get, never):Bool;
	@:allow(away3d) private var parentMesh(get, set):Mesh;
	public var uvTransform(get, never):Matrix;
	public var uvTransform2(get, never):Matrix;
	public var vertexData(get, never):Vector<Float>;
	public var indexData(get, never):Vector<UInt>;
	public var UVData(get, never):Vector<Float>;
	public var bounds(get, never):BoundingVolumeBase;
	public var visible(get, never):Bool;
	public var numVertices(get, never):Int;
	public var vertexStride(get, never):Int;
	public var UVStride(get, never):Int;
	public var vertexNormalData(get, never):Vector<Float>;
	public var vertexTangentData(get, never):Vector<Float>;
	public var UVOffset(get, never):Int;
	public var vertexOffset(get, never):Int;
	public var vertexNormalOffset(get, never):Int;
	public var vertexTangentOffset(get, never):Int;

	@:allow(away3d) private var _material:MaterialBase;
	private var _parentMesh:Mesh;
	private var _subGeometry:ISubGeometry;
	@:allow(away3d) private var _index:Int;
	
	private var _uvTransform:Matrix;
	private var _uvTransformDirty:Bool;
	private var _uvRotation:Float = 0;
	private var _scaleU:Float = 1;
	private var _scaleV:Float = 1;
	private var _offsetU:Float = 0;
	private var _offsetV:Float = 0;
	
	private var _uvTransform2:Matrix;
	private var _uvTransformDirty2:Bool;
	private var _uvRotation2:Float = 0;
	private var _scaleU2:Float = 1;
	private var _scaleV2:Float = 1;
	private var _offsetU2:Float = 0;
	private var _offsetV2:Float = 0;
	
	public var animationSubGeometry:AnimationSubGeometry;
	
	public var animatorSubGeometry:AnimationSubGeometry;
	
	/**
	 * Creates a new SubMesh object
	 * @param subGeometry The SubGeometry object which provides the geometry data for this SubMesh.
	 * @param parentMesh The Mesh object to which this SubMesh belongs.
	 * @param material An optional material used to render this SubMesh.
	 */
	public function new(subGeometry:ISubGeometry, parentMesh:Mesh, material:MaterialBase = null)
	{
		_parentMesh = parentMesh;
		_subGeometry = subGeometry;
		this.material = material;
	}
	
	private function get_shaderPickingDetails():Bool
	{
		return sourceEntity.shaderPickingDetails;
	}
	
	private function get_offsetU():Float
	{
		return _offsetU;
	}
	
	private function set_offsetU(value:Float):Float
	{
		if (value == _offsetU)
			return value;
		_offsetU = value;
		_uvTransformDirty = true;
		return value;
	}
	
	private function get_offsetV():Float
	{
		return _offsetV;
	}
	
	private function set_offsetV(value:Float):Float
	{
		if (value == _offsetV)
			return value;
		_offsetV = value;
		_uvTransformDirty = true;
		return value;
	}
	
	private function get_scaleU():Float
	{
		return _scaleU;
	}
	
	private function set_scaleU(value:Float):Float
	{
		if (value == _scaleU)
			return value;
		_scaleU = value;
		_uvTransformDirty = true;
		return value;
	}
	
	private function get_scaleV():Float
	{
		return _scaleV;
	}
	
	private function set_scaleV(value:Float):Float
	{
		if (value == _scaleV)
			return value;
		_scaleV = value;
		_uvTransformDirty = true;
		return value;
	}
	
	private function get_uvRotation():Float
	{
		return _uvRotation;
	}
	
	private function set_uvRotation(value:Float):Float
	{
		if (value == _uvRotation)
			return value;
		_uvRotation = value;
		_uvTransformDirty = true;
		return value;
	}
	
	private function get_offsetU2():Float
	{
		return _offsetU2;
	}
	
	private function set_offsetU2(value:Float):Float
	{
		if (value == _offsetU2)
			return value;
		_offsetU2 = value;
		_uvTransformDirty2 = true;
		return value;
	}
	
	private function get_offsetV2():Float
	{
		return _offsetV2;
	}
	
	private function set_offsetV2(value:Float):Float
	{
		if (value == _offsetV2)
			return value;
		_offsetV2 = value;
		_uvTransformDirty2 = true;
		return value;
	}
	
	private function get_scaleU2():Float
	{
		return _scaleU2;
	}
	
	private function set_scaleU2(value:Float):Float
	{
		if (value == _scaleU2)
			return value;
		_scaleU2 = value;
		_uvTransformDirty2 = true;
		return value;
	}
	
	private function get_scaleV2():Float
	{
		return _scaleV2;
	}
	
	private function set_scaleV2(value:Float):Float
	{
		if (value == _scaleV2)
			return value;
		_scaleV2 = value;
		_uvTransformDirty2 = true;
		return value;
	}
	
	private function get_uvRotation2():Float
	{
		return _uvRotation2;
	}
	
	private function set_uvRotation2(value:Float):Float
	{
		if (value == _uvRotation2)
			return value;
		_uvRotation2 = value;
		_uvTransformDirty2 = true;
		return value;
	}
	
	/**
	 * The entity that that initially provided the IRenderable to the render pipeline (ie: the owning Mesh object).
	 */
	private function get_sourceEntity():Entity
	{
		return _parentMesh;
	}
	
	/**
	 * The SubGeometry object which provides the geometry data for this SubMesh.
	 */
	private function get_subGeometry():ISubGeometry
	{
		return _subGeometry;
	}
	
	private function set_subGeometry(value:ISubGeometry):ISubGeometry
	{
		_subGeometry = value;
		return value;
	}
	
	/**
	 * The material used to render the current SubMesh. If set to null, its parent Mesh's material will be used instead.
	 */
	private function get_material():MaterialBase
	{
		if (_material != null)
			return _material;
		return _parentMesh.material;
	}
	
	private function set_material(value:MaterialBase):MaterialBase
	{
		if (_material != null)
			_material.removeOwner(this);
		
		_material = value;
		
		if (_material != null)
			_material.addOwner(this);
		return value;
	}
	
	/**
	 * The scene transform object that transforms from model to world space.
	 */
	private function get_sceneTransform():Matrix3D
	{
		return _parentMesh.sceneTransform;
	}
	
	/**
	 * The inverse scene transform object that transforms from world to model space.
	 */
	private function get_inverseSceneTransform():Matrix3D
	{
		return _parentMesh.inverseSceneTransform;
	}
	
	/**
	 * @inheritDoc
	 */
	public function activateVertexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_subGeometry.activateVertexBuffer(index, stage3DProxy);
	}
	
	/**
	 * @inheritDoc
	 */
	public function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_subGeometry.activateVertexNormalBuffer(index, stage3DProxy);
	}
	
	/**
	 * @inheritDoc
	 */
	public function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_subGeometry.activateVertexTangentBuffer(index, stage3DProxy);
	}
	
	/**
	 * @inheritDoc
	 */
	public function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_subGeometry.activateUVBuffer(index, stage3DProxy);
	}
	
	/**
	 * @inheritDoc
	 */
	public function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_subGeometry.activateSecondaryUVBuffer(index, stage3DProxy);
	}
	
	/**
	 * @inheritDoc
	 */
	public function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D
	{
		return _subGeometry.getIndexBuffer(stage3DProxy);
	}
	
	/**
	 * The amount of triangles that make up this SubMesh.
	 */
	private function get_numTriangles():Int
	{
		return _subGeometry.numTriangles;
	}
	
	/**
	 * The animator object that provides the state for the SubMesh's animation.
	 */
	private function get_animator():IAnimator
	{
		return _parentMesh.animator;
	}
	
	/**
	 * Indicates whether the SubMesh should trigger mouse events, and hence should be rendered for hit testing.
	 */
	private function get_mouseEnabled():Bool
	{
		return _parentMesh.mouseEnabled || _parentMesh._ancestorsAllowMouseEnabled;
	}
	
	private function get_castsShadows():Bool
	{
		return _parentMesh.castsShadows;
	}
	
	/**
	 * A reference to the owning Mesh object
	 *
	 * @private
	 */
	private function get_parentMesh():Mesh
	{
		return _parentMesh;
	}
	
	private function set_parentMesh(value:Mesh):Mesh
	{
		_parentMesh = value;
		return value;
	}
	
	private function get_uvTransform():Matrix
	{
		if (_uvTransformDirty)
			updateUVTransform();
		return _uvTransform;
	}
	
	private function get_uvTransform2():Matrix
	{
		if (_uvTransformDirty2)
			updateUVTransform2();
		return _uvTransform2;
	}
	
	private function updateUVTransform():Void
	{
		if (_uvTransform == null)
			_uvTransform = new Matrix();
		_uvTransform.identity();
		if (_uvRotation != 0)
			_uvTransform.rotate(_uvRotation);
		if (_scaleU != 1 || _scaleV != 1)
			_uvTransform.scale(_scaleU, _scaleV);
		_uvTransform.translate(_offsetU, _offsetV);
		_uvTransformDirty = false;
	}
	
	private function updateUVTransform2():Void
	{
		if (_uvTransform2 == null)
			_uvTransform2 = new Matrix();
		_uvTransform2.identity();
		if (_uvRotation2 != 0)
			_uvTransform2.rotate(_uvRotation2);
		if (_scaleU2 != 1 || _scaleV2 != 1)
			_uvTransform2.scale(_scaleU2, _scaleV2);
		_uvTransform2.translate(_offsetU2, _offsetV2);
		_uvTransformDirty2 = false;
	}
	
	public function dispose():Void
	{
		material = null;
	}
	
	private function get_vertexData():Vector<Float>
	{
		return _subGeometry.vertexData;
	}
	
	private function get_indexData():Vector<UInt>
	{
		return _subGeometry.indexData;
	}
	
	private function get_UVData():Vector<Float>
	{
		return _subGeometry.UVData;
	}
	
	private function get_bounds():BoundingVolumeBase
	{
		return _parentMesh.bounds; // TODO: return smaller, sub mesh bounds instead
	}
	
	private function get_visible():Bool
	{
		return _parentMesh.visible;
	}
	
	private function get_numVertices():Int
	{
		return _subGeometry.numVertices;
	}
	
	private function get_vertexStride():Int
	{
		return _subGeometry.vertexStride;
	}
	
	private function get_UVStride():Int
	{
		return _subGeometry.UVStride;
	}
	
	private function get_vertexNormalData():Vector<Float>
	{
		return _subGeometry.vertexNormalData;
	}
	
	private function get_vertexTangentData():Vector<Float>
	{
		return _subGeometry.vertexTangentData;
	}
	
	private function get_UVOffset():Int
	{
		return _subGeometry.UVOffset;
	}
	
	private function get_vertexOffset():Int
	{
		return _subGeometry.vertexOffset;
	}
	
	private function get_vertexNormalOffset():Int
	{
		return _subGeometry.vertexNormalOffset;
	}
	
	private function get_vertexTangentOffset():Int
	{
		return _subGeometry.vertexTangentOffset;
	}
	
	public function getRenderSceneTransform(camera:Camera3D):Matrix3D
	{
		return _parentMesh.sceneTransform;
	}
}