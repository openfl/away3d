package away3d.tools.commands;

	//import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.ISubGeometry;
	import away3d.entities.Mesh;
	import away3d.tools.utils.GeomUtil;
	
	//use namespace arcane;
	
	/**
	 * Class Explode make all vertices and uv's of a mesh unic<code>Explode</code>
	 */
	class Explode
	{
		
		var _keepNormals:Bool;
		
		public function new()
		{
		}
		
		/**
		 *  Apply the explode code to a given ObjectContainer3D.
		 * @param     object                ObjectContainer3D. The target Object3d object.
		 * @param     keepNormals        Boolean. If the vertexNormals of the object are preserved. Default is true.
		 */
		public function applyToContainer(ctr:ObjectContainer3D, keepNormals:Bool = true):Void
		{
			_keepNormals = keepNormals;
			parse(ctr);
		}
		
		public function apply(geom:Geometry, keepNormals:Bool = true):Void
		{
			var i:UInt = 0;
			
			_keepNormals = keepNormals;
			
			// For loop conversion - 						for (i = 0; i < geom.subGeometries.length; i++)
			
			for (i in 0...geom.subGeometries.length)
				explodeSubGeom(geom.subGeometries[i], geom);
		}
		
		/**
		 * recursive parsing of a container.
		 */
		private function parse(object:ObjectContainer3D):Void
		{
			var child:ObjectContainer3D;
			if (object is Mesh && object.numChildren == 0)
				apply(Mesh(object).geometry, _keepNormals);
			
			// For loop conversion - 						for (var i:UInt = 0; i < object.numChildren; ++i)
			
			var i:UInt = 0;
			
			for (i in 0...object.numChildren) {
				child = object.getChildAt(i);
				parse(child);
			}
		}
		
		private function explodeSubGeom(subGeom:ISubGeometry, geom:Geometry):Void
		{
			var i:UInt = 0;
			var len:UInt;
			var inIndices:Array<UInt>;
			var outIndices:Array<UInt>;
			var vertices:Array<Float>;
			var normals:Array<Float>;
			var uvs:Array<Float>;
			var vIdx:UInt, uIdx:UInt;
			var outSubGeoms:Array<ISubGeometry>;
			
			var vStride:UInt, nStride:UInt, uStride:UInt;
			var vOffs:UInt, nOffs:UInt, uOffs:UInt;
			var vd:Array<Float>, nd:Array<Float>, ud:Array<Float>;
			
			vd = subGeom.vertexData;
			vStride = subGeom.vertexStride;
			vOffs = subGeom.vertexOffset;
			nd = subGeom.vertexNormalData;
			nStride = subGeom.vertexNormalStride;
			nOffs = subGeom.vertexNormalOffset;
			ud = subGeom.UVData;
			uStride = subGeom.UVStride;
			uOffs = subGeom.UVOffset;
			
			inIndices = subGeom.indexData;
			outIndices = new Array<UInt>(inIndices.length, true);
			vertices = new Array<Float>(inIndices.length*3, true);
			normals = new Array<Float>(inIndices.length*3, true);
			uvs = new Array<Float>(inIndices.length*2, true);
			
			vIdx = 0;
			uIdx = 0;
			len = inIndices.length;
			// For loop conversion - 			for (i = 0; i < len; i++)
			for (i in 0...len) {
				var index:Int;
				
				index = inIndices[i];
				vertices[vIdx + 0] = vd[vOffs + index*vStride + 0];
				vertices[vIdx + 1] = vd[vOffs + index*vStride + 1];
				vertices[vIdx + 2] = vd[vOffs + index*vStride + 2];
				
				if (_keepNormals) {
					normals[vIdx + 0] = vd[nOffs + index*nStride + 0];
					normals[vIdx + 1] = vd[nOffs + index*nStride + 1];
					normals[vIdx + 2] = vd[nOffs + index*nStride + 2];
				} else
					normals[vIdx + 0] = normals[vIdx + 1] = normals[vIdx + 2] = 0;
				
				uvs[uIdx++] = ud[uOffs + index*uStride + 0];
				uvs[uIdx++] = ud[uOffs + index*uStride + 1];
				
				vIdx += 3;
				
				outIndices[i] = i;
			}
			
			outSubGeoms = GeomUtil.fromVectors(vertices, outIndices, uvs, normals, null, null, null);
			geom.removeSubGeometry(subGeom);
			// For loop conversion - 			for (i = 0; i < outSubGeoms.length; i++)
			for (i in 0...outSubGeoms.length) {
				outSubGeoms[i].autoDeriveVertexNormals = !_keepNormals;
				geom.addSubGeometry(outSubGeoms[i]);
			}
		}
	}

