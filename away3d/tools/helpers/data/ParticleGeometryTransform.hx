package away3d.tools.helpers.data;

import openfl.geom.Matrix;
import openfl.geom.Matrix3D;

/**
 * ...
 */
class ParticleGeometryTransform
{
	public var vertexTransform(get, set):Matrix3D;
	public var UVTransform(get, set):Matrix;
	public var invVertexTransform(get, never):Matrix3D;
	
	private var _defaultVertexTransform:Matrix3D;
	private var _defaultInvVertexTransform:Matrix3D;
	private var _defaultUVTransform:Matrix;
	
	public function new()
	{
	}
	
	private function set_vertexTransform(value:Matrix3D):Matrix3D
	{
		_defaultVertexTransform = value;
		_defaultInvVertexTransform = value.clone();
		_defaultInvVertexTransform.invert();
		_defaultInvVertexTransform.transpose();
		return value;
	}
	
	private function set_UVTransform(value:Matrix):Matrix
	{
		_defaultUVTransform = value;
		return value;
	}
	
	private function get_UVTransform():Matrix
	{
		return _defaultUVTransform;
	}
	
	private function get_vertexTransform():Matrix3D
	{
		return _defaultVertexTransform;
	}
	
	private function get_invVertexTransform():Matrix3D
	{
		return _defaultInvVertexTransform;
	}
}