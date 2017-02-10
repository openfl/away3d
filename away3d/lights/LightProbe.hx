package away3d.lights;

import away3d.*;
import away3d.bounds.*;
import away3d.cameras.*;
import away3d.core.base.*;
import away3d.core.partition.*;
import away3d.textures.*;

import openfl.errors.Error;
import openfl.geom.Matrix3D;

class LightProbe extends LightBase
{
	public var diffuseMap(get, set):CubeTextureBase;
	public var specularMap(get, set):CubeTextureBase;
	
	private var _diffuseMap:CubeTextureBase;
	private var _specularMap:CubeTextureBase;
	
	/**
	 * Creates a new LightProbe object.
	 */
	public function new(diffuseMap:CubeTextureBase, specularMap:CubeTextureBase = null)
	{
		super();
		_diffuseMap = diffuseMap;
		_specularMap = specularMap;
	}
	
	override private function createEntityPartitionNode():EntityNode
	{
		return new LightProbeNode(this);
	}
	
	private function get_diffuseMap():CubeTextureBase
	{
		return _diffuseMap;
	}
	
	private function set_diffuseMap(value:CubeTextureBase):CubeTextureBase
	{
		_diffuseMap = value;
		return value;
	}
	
	private function get_specularMap():CubeTextureBase
	{
		return _specularMap;
	}
	
	private function set_specularMap(value:CubeTextureBase):CubeTextureBase
	{
		_specularMap = value;
		return value;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateBounds():Void
	{
		//			super.updateBounds();
		_boundsInvalid = false;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getDefaultBoundingVolume():BoundingVolumeBase
	{
		// todo: consider if this can be culled?
		return new NullBounds();
	}
	
	/**
	 * @inheritDoc
	 */
	override private function getObjectProjectionMatrix(renderable:IRenderable, camera:Camera3D, target:Matrix3D = null):Matrix3D
	{
		// TODO: not used
		
		throw new Error("Object projection matrices are not supported for LightProbe objects!");
		return null;
	}
}