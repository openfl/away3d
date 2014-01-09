package away3d.core.pick;

	import flash.geom.*;
	
	import away3d.tools.utils.GeomUtil;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.SubMesh;
	
	/**
	 * An abstract base class for all picking collider classes. It should not be instantiated directly.
	 */
	class PickingColliderBase
	{
		var rayPosition:Vector3D;
		var rayDirection:Vector3D;
		
		public function new()
		{
		
		}
		
		private function getCollisionNormal(indexData:Array<UInt>, vertexData:Array<Float>, triangleIndex:UInt):Vector3D
		{
			var normal:Vector3D = new Vector3D();
			var i0:UInt = indexData[ triangleIndex ]*3;
			var i1:UInt = indexData[ triangleIndex + 1 ]*3;
			var i2:UInt = indexData[ triangleIndex + 2 ]*3;
			var p0:Vector3D = new Vector3D(vertexData[ i0 ], vertexData[ i0 + 1 ], vertexData[ i0 + 2 ]);
			var p1:Vector3D = new Vector3D(vertexData[ i1 ], vertexData[ i1 + 1 ], vertexData[ i1 + 2 ]);
			var p2:Vector3D = new Vector3D(vertexData[ i2 ], vertexData[ i2 + 1 ], vertexData[ i2 + 2 ]);
			var side0:Vector3D = p1.subtract(p0);
			var side1:Vector3D = p2.subtract(p0);
			normal = side0.crossProduct(side1);
			normal.normalize();
			return normal;
		}
		
		private function getCollisionUV(indexData:Array<UInt>, uvData:Array<Float>, triangleIndex:UInt, v:Float, w:Float, u:Float, uvOffset:UInt, uvStride:UInt):Point
		{
			var uv:Point = new Point();
			var uIndex:UInt = indexData[ triangleIndex ]*uvStride + uvOffset;
			var uv0:Vector3D = new Vector3D(uvData[ uIndex ], uvData[ uIndex + 1 ]);
			uIndex = indexData[ triangleIndex + 1 ]*uvStride + uvOffset;
			var uv1:Vector3D = new Vector3D(uvData[ uIndex ], uvData[ uIndex + 1 ]);
			uIndex = indexData[ triangleIndex + 2 ]*uvStride + uvOffset;
			var uv2:Vector3D = new Vector3D(uvData[ uIndex ], uvData[ uIndex + 1 ]);
			uv.x = u*uv0.x + v*uv1.x + w*uv2.x;
			uv.y = u*uv0.y + v*uv1.y + w*uv2.y;
			return uv;
		}
		
		private function getMeshSubgeometryIndex(subGeometry:SubGeometry):UInt
		{
			return GeomUtil.getMeshSubgeometryIndex(subGeometry);
		}
		
		private function getMeshSubMeshIndex(subMesh:SubMesh):UInt
		{
			return GeomUtil.getMeshSubMeshIndex(subMesh);
		}
		
		/**
		 * @inheritDoc
		 */
		public function setLocalRay(localPosition:Vector3D, localDirection:Vector3D):Void
		{
			rayPosition = localPosition;
			rayDirection = localDirection;
		}
	}

