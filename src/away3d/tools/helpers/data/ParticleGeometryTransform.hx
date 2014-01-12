package away3d.tools.helpers.data;

	import flash.geom.Matrix;
	import away3d.geom.Matrix3D;
	
	/**
	 * ...
	 */
	class ParticleGeometryTransform
	{
		var _defaultVertexTransform:Matrix3D;
		var _defaultInvVertexTransform:Matrix3D;
		var _defaultUVTransform:Matrix;
		
		public function new()
		{
		}
		
		public function set_vertexTransform(value:Matrix3D) : Void
		{
			_defaultVertexTransform = value;
			_defaultInvVertexTransform = value.clone();
			_defaultInvVertexTransform.invert();
			_defaultInvVertexTransform.transpose();
		}
		
		public function set_UVTransform(value:Matrix) : Void
		{
			_defaultUVTransform = value;
		}
		
		public var UVTransform(get, set) : Void;
		
		public function get_UVTransform() : Void
		{
			return _defaultUVTransform;
		}
		
		public var vertexTransform(get, set) : Void;
		
		public function get_vertexTransform() : Void
		{
			return _defaultVertexTransform;
		}
		
		public var invVertexTransform(get, null) : Matrix3D;
		
		public function get_invVertexTransform() : Matrix3D
		{
			return _defaultInvVertexTransform;
		}
	}


